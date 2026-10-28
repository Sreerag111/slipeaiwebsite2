import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {getRazorpayClient} from "../config/razorpay";
import {premiumTierForPlan} from "../config/billingPlans";
import {isReviewAccessAccount} from "../config/reviewAccess";
import {
  hasPremiumAccess,
  timestampFromUnixSeconds,
} from "../utils/premiumStatus";

const KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

if (!admin.apps.length) {
  admin.initializeApp();
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ?
    value as Record<string, unknown> :
    {};
}

export const getPremiumStatus = onCall(
  {secrets: [KEY_ID, KEY_SECRET]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userSnapshot = await userRef.get();
    const premium = asRecord(userSnapshot.data()?.premium);
    const billing = asRecord(userSnapshot.data()?.billing);
    const hasUsedFreeTrial = Boolean(billing.trialUsedAt);
    if (isReviewAccessAccount(uid)) {
      await userRef.set({
        premium: {
          isPremium: true,
          reviewBypass: true,
          tier: "pro",
          planId: "review_access",
          purchaseType: "review",
          status: "active",
          cancelAtPeriodEnd: false,
          subscriptionId: admin.firestore.FieldValue.delete(),
          razorpayPlanId: admin.firestore.FieldValue.delete(),
          orderId: admin.firestore.FieldValue.delete(),
          accessUntil: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, {merge: true});
      return {
        isPremium: true,
        isTrialActive: false,
        status: "active",
        cancelAtPeriodEnd: false,
        accessUntil: null,
        trialEndsAt: null,
        currentPeriodEnd: null,
        planId: "review_access",
        tier: "pro",
        purchaseType: "review",
        billingAmountPaise: null,
        billingPeriod: null,
        hasUsedFreeTrial,
        reviewBypass: true,
      };
    }
    if (premium.purchaseType === "one_time") {
      const accessUntil = premium.accessUntil;
      const tier = premium.tier ?? premiumTierForPlan(premium.planId) ?? "lite";
      const isPremium = hasPremiumAccess("prepaid_active", accessUntil);
      const status = isPremium ? "prepaid_active" : "prepaid_expired";
      await userRef.set({
        premium: {
          ...premium,
          isPremium,
          tier,
          status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, {merge: true});
      return {
        isPremium,
        isTrialActive: false,
        status,
        cancelAtPeriodEnd: false,
        accessUntil: accessUntil ?? null,
        trialEndsAt: null,
        currentPeriodEnd: accessUntil ?? null,
        planId: premium.planId ?? null,
        tier,
        billingAmountPaise: premium.billingAmountPaise ?? null,
        billingPeriod: premium.billingPeriod ?? "weekly",
        purchaseType: "one_time",
        hasUsedFreeTrial,
      };
    }
    const subscriptionId = typeof premium.subscriptionId === "string" ?
      premium.subscriptionId :
      null;

    if (!subscriptionId) {
      await userRef.set({
        premium: {
          ...premium,
          isPremium: false,
          status: "inactive",
          cancelAtPeriodEnd: false,
          accessUntil: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, {merge: true});

      return {
        isPremium: false,
        isTrialActive: false,
        status: "inactive",
        cancelAtPeriodEnd: false,
        accessUntil: null,
        hasUsedFreeTrial,
      };
    }

    let stage = "razorpay_subscription_fetch";
    try {
      const razorpay = getRazorpayClient(
        KEY_ID.value(),
        KEY_SECRET.value()
      );
      const subscription = await razorpay.subscriptions.fetch(subscriptionId);
      let billingAmountPaise: number | null = null;
      let billingPeriod: string | null = null;
      try {
        const plan = await razorpay.plans.fetch(subscription.plan_id);
        const amount = Number(plan.item.amount);
        if (Number.isFinite(amount)) billingAmountPaise = amount;
        billingPeriod = plan.period;
      } catch (planError) {
        debugLog.warn("Unable to fetch subscription plan details", planError);
      }
      const status = subscription.status;
      const trialEndsAt = timestampFromUnixSeconds(subscription.start_at);
      const currentPeriodEnd =
        timestampFromUnixSeconds(subscription.current_end);
      const providerAccessUntil = status === "cancelled" ?
        (Number(subscription.paid_count ?? 0) === 0 ?
          trialEndsAt : currentPeriodEnd) : null;
      const accessUntil = status === "cancelled" ?
        providerAccessUntil ?? premium.accessUntil ?? null : null;
      const isPremium = hasPremiumAccess(status, accessUntil);
      const isTrialActive = isPremium &&
        Number(subscription.paid_count ?? 0) === 0 &&
        trialEndsAt !== null &&
        trialEndsAt.toMillis() > Date.now();
      const trialWasGranted = Boolean(premium.trialEndsAt) || isTrialActive;
      const effectiveHasUsedFreeTrial = hasUsedFreeTrial || trialWasGranted;
      const tier = premium.tier ?? premiumTierForPlan(premium.planId);

      stage = "firestore_update";
      await userRef.set({
        premium: {
          ...premium,
          isPremium,
          tier,
          status,
          subscriptionId,
          razorpayPlanId: subscription.plan_id,
          billingAmountPaise,
          billingPeriod,
          trialEndsAt,
          currentPeriodEnd,
          accessUntil,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        ...(trialWasGranted && !hasUsedFreeTrial ? {
          billing: {
            ...billing,
            trialUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            firstTrialSubscriptionId: subscriptionId,
          },
        } : {}),
      }, {merge: true});

      return {
        isPremium,
        isTrialActive,
        status,
        cancelAtPeriodEnd: premium.cancelAtPeriodEnd === true,
        accessUntil,
        trialEndsAt,
        currentPeriodEnd,
        planId: premium.planId ?? null,
        tier: tier ?? null,
        purchaseType: premium.purchaseType ?? "subscription",
        billingAmountPaise,
        billingPeriod,
        hasUsedFreeTrial: effectiveHasUsedFreeTrial,
      };
    } catch (error) {
      const failure = error !== null && typeof error === "object" ?
        error as Record<string, unknown> : {};
      const nested = failure.error !== null &&
        typeof failure.error === "object" ?
        failure.error as Record<string, unknown> : {};
      logger.error("Premium status refresh failed", {
        stage,
        type: error instanceof Error ? error.name : typeof error,
        statusCode: typeof failure.statusCode === "number" ?
          failure.statusCode : null,
        code: typeof nested.code === "string" ? nested.code :
          typeof failure.code === "string" ? failure.code : null,
      });
      throw new HttpsError(
        "unavailable",
        "Unable to refresh subscription status."
      );
    }
  }
);
