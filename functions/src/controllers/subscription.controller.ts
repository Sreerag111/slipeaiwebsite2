import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as logger from "firebase-functions/logger";
import {HttpsError} from "firebase-functions/v2/https";

import {RazorpayService} from "../services/razorpay.service";
import {billingPlan} from "../config/billingPlans";
import {hasPremiumAccess} from "../utils/premiumStatus";

const CHECKOUT_WINDOW_SECONDS = 30 * 60;
const CREATION_LEASE_SECONDS = 60;

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

function isFutureTimestamp(value: unknown): value is admin.firestore.Timestamp {
  return value instanceof admin.firestore.Timestamp &&
    value.toMillis() > Date.now();
}

interface CheckoutClaim {
  action: "create" | "reuse";
  attemptId: string;
  subscriptionId?: string;
  trialDays: number;
}

interface CheckoutResponse {
  subscriptionId: string;
  planId: string;
  planName: unknown;
  trialDays: number;
  hasTrial: boolean;
  hasUsedFreeTrial: boolean;
  status: string;
  reused: boolean;
}

export class SubscriptionController {
  constructor(private readonly razorpayService: RazorpayService) {}

  async createSubscription(
    uid: string,
    planId: string,
    requestId: string
  ): Promise<CheckoutResponse> {
    const db = admin.firestore();
    const planRef = db.collection("plans").doc(planId);
    const userRef = db.collection("users").doc(uid);
    const intentRef = db.collection("subscriptionCheckoutIntents").doc(uid);
    const attemptId = crypto.randomUUID();

    logger.info("[SubscriptionDebug] Resolving checkout", {
      requestId,
      uidPrefix: uid.slice(0, 6),
      planId,
    });

    const planSnapshot = await planRef.get();
    if (!planSnapshot.exists) {
      throw new HttpsError("not-found", "Plan not found.");
    }

    const plan = planSnapshot.data() ?? {};
    const definition = billingPlan(planId);
    if (!definition || definition.kind !== "subscription") {
      throw new HttpsError("invalid-argument", "Choose a subscription plan.");
    }
    if (!plan.active) {
      throw new HttpsError("failed-precondition", "Plan is not active.");
    }

    const razorpayPlanId = plan.razorpayPlanId;
    if (typeof razorpayPlanId !== "string" || !razorpayPlanId) {
      throw new HttpsError(
        "failed-precondition",
        "Razorpay Plan ID is missing."
      );
    }

    // The UI prices are fixed. Fail closed if Firestore points to an older
    // Razorpay plan, especially the former ₹799/month "max" plan.
    const expectedAmount = definition.amountPaise;
    const expectedPeriod = definition.period;
    const razorpayPlan = await this.razorpayService.fetchPlan(razorpayPlanId);
    if (Number(razorpayPlan.item.amount) !== expectedAmount ||
        razorpayPlan.item.currency !== "INR" ||
        razorpayPlan.period !== expectedPeriod ||
        razorpayPlan.interval !== 1) {
      throw new HttpsError(
        "failed-precondition",
        "Billing plan is not configured for the displayed price."
      );
    }

    const claim = await db.runTransaction<CheckoutClaim>(async (transaction) => {
      const [userSnapshot, intentSnapshot] = await Promise.all([
        transaction.get(userRef),
        transaction.get(intentRef),
      ]);
      const user = userSnapshot.data() ?? {};
      const premium = asRecord(user.premium);
      if (hasPremiumAccess(premium.status, premium.accessUntil)) {
        throw new HttpsError(
          "already-exists",
          "This account already has an active subscription."
        );
      }

      const billing = asRecord(user.billing);
      const rawTrialDays = Number(plan.trialDays ?? 0);
      const configuredTrialDays = Number.isFinite(rawTrialDays) ?
        Math.max(0, Math.floor(rawTrialDays)) : 0;
      const allowedTrialDays = definition.trialDays === null ?
        configuredTrialDays : definition.trialDays;
      const trialDays = billing.trialUsedAt ? 0 : allowedTrialDays;
      const intent = intentSnapshot.data() ?? {};
      const samePlan = intent.planId === planId;
      const checkoutIsOpen = intent.status === "checkout_open" &&
        typeof intent.subscriptionId === "string" &&
        isFutureTimestamp(intent.expiresAt);
      if (samePlan && checkoutIsOpen) {
        return {
          action: "reuse",
          attemptId: String(intent.attemptId ?? ""),
          subscriptionId: intent.subscriptionId,
          trialDays: Number(intent.trialDays ?? trialDays),
        };
      }

      if (intent.status === "creating" &&
          isFutureTimestamp(intent.creationLeaseUntil)) {
        throw new HttpsError(
          "resource-exhausted",
          "A subscription checkout is already being prepared. Please wait."
        );
      }

      const now = admin.firestore.Timestamp.now();
      transaction.set(intentRef, {
        uid,
        planId,
        attemptId,
        trialDays,
        status: "creating",
        createdAt: intent.createdAt ?? now,
        updatedAt: now,
        creationLeaseUntil: admin.firestore.Timestamp.fromMillis(
          Date.now() + CREATION_LEASE_SECONDS * 1000
        ),
        expiresAt: admin.firestore.Timestamp.fromMillis(
          Date.now() + CHECKOUT_WINDOW_SECONDS * 1000
        ),
      });

      return {action: "create", attemptId, trialDays};
    });

    if (claim.action === "reuse" && claim.subscriptionId) {
      try {
        const existing = await this.razorpayService.fetchSubscription(
          claim.subscriptionId
        );
        if (existing.status === "created") {
          logger.info("[SubscriptionDebug] Reusing pending checkout", {
            requestId,
            uidPrefix: uid.slice(0, 6),
            planId,
            subscriptionIdPrefix: existing.id.slice(0, 10),
          });
          return this.checkoutResponse(existing, planId, plan, claim.trialDays, true);
        }
      } catch (error) {
        logger.warn("[SubscriptionDebug] Pending checkout could not be reused", {
          requestId,
          uidPrefix: uid.slice(0, 6),
          planId,
          error,
        });
      }

      await intentRef.set({
        status: "expired",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        creationLeaseUntil: null,
      }, {merge: true});
      return this.createSubscription(uid, planId, requestId);
    }

    const trialDays = claim.trialDays;
    const nowSeconds = Math.floor(Date.now() / 1000);
    const startAt = trialDays > 0 ?
      nowSeconds + trialDays * 24 * 60 * 60 : undefined;
    const expireBy = nowSeconds + CHECKOUT_WINDOW_SECONDS;
    const maxTotalCount = definition.maxTotalCount ?? 30;
    const rawTotalCount = Number(plan.totalCount ?? maxTotalCount);
    const totalCount = Number.isFinite(rawTotalCount) && rawTotalCount > 0 ?
      Math.min(Math.floor(rawTotalCount), maxTotalCount) : maxTotalCount;

    try {
      const subscription = await this.razorpayService.createSubscription(
        razorpayPlanId,
        totalCount,
        1,
        startAt,
        expireBy,
        {
          uid,
          planId,
          trialDays: String(trialDays),
          checkoutAttemptId: claim.attemptId,
        }
      );

      await intentRef.set({
        subscriptionId: subscription.id,
        razorpayPlanId,
        status: "checkout_open",
        expiresAt: admin.firestore.Timestamp.fromMillis(expireBy * 1000),
        creationLeaseUntil: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      logger.info("[SubscriptionDebug] Checkout created", {
        requestId,
        uidPrefix: uid.slice(0, 6),
        planId,
        trialDays,
        totalCount,
        expireBy,
        subscriptionIdPrefix: subscription.id.slice(0, 10),
      });
      return this.checkoutResponse(subscription, planId, plan, trialDays, false);
    } catch (error) {
      await intentRef.set({
        status: "failed",
        creationLeaseUntil: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      throw error;
    }
  }

  private checkoutResponse(
    subscription: {id: string; status: string},
    planId: string,
    plan: Record<string, unknown>,
    trialDays: number,
    reused: boolean
  ): CheckoutResponse {
    return {
      subscriptionId: subscription.id,
      planId,
      planName: plan.name ?? "",
      trialDays,
      hasTrial: trialDays > 0,
      hasUsedFreeTrial: trialDays === 0,
      status: subscription.status,
      reused,
    };
  }
}
