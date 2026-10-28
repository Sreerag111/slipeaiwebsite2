import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import * as crypto from "crypto";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {getRazorpayClient} from "../config/razorpay";
import {billingPlan} from "../config/billingPlans";
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
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

function note(subscription: Record<string, unknown>, key: string): string | null {
  const notes = asRecord(subscription.notes);
  const value = notes[key];
  return typeof value === "string" && value.length > 0 ? value : null;
}

export const verifySubscription = onCall(
  {secrets: [KEY_ID, KEY_SECRET]},
  async (request) => {
    const {paymentId, subscriptionId, signature, planId} = request.data ?? {};
    if (!paymentId || !subscriptionId || !signature || !planId) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User not authenticated.");
    }
    const definition = billingPlan(planId);
    if (!definition || definition.kind !== "subscription") {
      throw new HttpsError("invalid-argument", "Choose a subscription plan.");
    }

    const body = `${paymentId}|${subscriptionId}`;
    const expectedSignature = crypto
      .createHmac("sha256", KEY_SECRET.value())
      .update(body)
      .digest("hex");
    const suppliedSignature = String(signature);
    const signaturesMatch = expectedSignature.length === suppliedSignature.length &&
      crypto.timingSafeEqual(
        Buffer.from(expectedSignature),
        Buffer.from(suppliedSignature)
      );
    if (!signaturesMatch) {
      throw new HttpsError("permission-denied", "Invalid payment signature.");
    }

    const db = admin.firestore();
    const planRef = db.collection("plans").doc(String(planId));
    const ownerRef = db
      .collection("razorpaySubscriptions")
      .doc(String(subscriptionId));
    const intentRef = db.collection("subscriptionCheckoutIntents").doc(uid);
    const userRef = db.collection("users").doc(uid);
    const [planSnapshot, ownerSnapshot] = await Promise.all([
      planRef.get(),
      ownerRef.get(),
    ]);
    if (!planSnapshot.exists || !planSnapshot.data()?.active) {
      throw new HttpsError("failed-precondition", "Plan is not active.");
    }

    const razorpay = getRazorpayClient(KEY_ID.value(), KEY_SECRET.value());
    const subscription = await razorpay.subscriptions.fetch(String(subscriptionId));
    const subscriptionRecord = subscription as unknown as Record<string, unknown>;
    const notesUid = note(subscriptionRecord, "uid");
    const notesPlanId = note(subscriptionRecord, "planId");
    const mappedUid = ownerSnapshot.data()?.uid;
    const mappingMatches = ownerSnapshot.exists && mappedUid === uid;
    const trustedNotesMatch = notesUid === uid && notesPlanId === planId;
    if (!mappingMatches && !trustedNotesMatch) {
      throw new HttpsError(
        "permission-denied",
        "Subscription ownership could not be verified."
      );
    }

    const expectedPlanId = planSnapshot.data()?.razorpayPlanId;
    if (!expectedPlanId || subscription.plan_id !== expectedPlanId) {
      throw new HttpsError(
        "failed-precondition",
        "Subscription plan does not match."
      );
    }
    const providerPlan = await razorpay.plans.fetch(subscription.plan_id);
    if (Number(providerPlan.item.amount) !== definition.amountPaise ||
        providerPlan.item.currency !== "INR" ||
        providerPlan.period !== definition.period ||
        providerPlan.interval !== 1) {
      throw new HttpsError(
        "failed-precondition",
        "Subscription billing does not match the selected plan."
      );
    }

    const status = subscription.status;
    if (!hasPremiumAccess(status)) {
      throw new HttpsError(
        "failed-precondition",
        `Subscription is not active (${status}).`
      );
    }

    const trialEndsAt = timestampFromUnixSeconds(subscription.start_at);
    const currentPeriodEnd = timestampFromUnixSeconds(subscription.current_end);
    const trialDays = Number(
      note(subscriptionRecord, "trialDays") ??
      ownerSnapshot.data()?.trialDays ??
      0
    );
    const isTrialActive = trialDays > 0 &&
      Number(subscription.paid_count ?? 0) === 0 &&
      trialEndsAt !== null &&
      trialEndsAt.toMillis() > Date.now();

    const outcome = await db.runTransaction(async (transaction) => {
      const [userSnapshot, intentSnapshot] = await Promise.all([
        transaction.get(userRef),
        transaction.get(intentRef),
      ]);
      const user = userSnapshot.data() ?? {};
      const billing = asRecord(user.billing);
      const premium = asRecord(user.premium);
      const firstTrialSubscriptionId = billing.firstTrialSubscriptionId;
      if (trialDays > 0 && billing.trialUsedAt &&
          firstTrialSubscriptionId !== subscriptionId) {
        return {accepted: false, reason: "trial_already_used"};
      }

      const otherSubscriptionId = premium.subscriptionId;
      if (typeof otherSubscriptionId === "string" &&
          otherSubscriptionId !== subscriptionId &&
          hasPremiumAccess(premium.status, premium.accessUntil)) {
        return {accepted: false, reason: "active_subscription_exists"};
      }

      transaction.set(userRef, {
        premium: {
          isPremium: true,
          tier: definition.tier,
          purchaseType: "subscription",
          planId,
          razorpayPlanId: subscription.plan_id,
          paymentId,
          subscriptionId,
          status,
          trialEndsAt,
          currentPeriodEnd,
          accessUntil: null,
          cancelAtPeriodEnd: false,
          billingAmountPaise: definition.amountPaise,
          billingPeriod: definition.period,
          activatedAt: premium.activatedAt ??
            admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        ...(trialDays > 0 && !billing.trialUsedAt ? {
          billing: {
            ...billing,
            trialUsedAt: admin.firestore.FieldValue.serverTimestamp(),
            firstTrialSubscriptionId: subscriptionId,
          },
        } : {}),
      }, {merge: true});
      transaction.set(ownerRef, {
        uid,
        planId,
        razorpayPlanId: subscription.plan_id,
        status,
        trialDays,
        createdAt: ownerSnapshot.data()?.createdAt ??
          admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      if (intentSnapshot.data()?.subscriptionId === subscriptionId) {
        transaction.delete(intentRef);
      }
      return {accepted: true};
    });

    if (!outcome.accepted) {
      try {
        await razorpay.subscriptions.cancel(String(subscriptionId), false);
      } catch (error) {
        debugLog.error("Unable to cancel rejected duplicate subscription", error);
      }
      throw new HttpsError(
        "already-exists",
        outcome.reason === "trial_already_used" ?
          "The free trial has already been used on this account." :
          "This account already has an active subscription."
      );
    }

    return {
      success: true,
      isPremium: true,
      isTrialActive,
      hasUsedFreeTrial: trialDays > 0,
      status,
      trialEndsAt,
      currentPeriodEnd,
      accessUntil: null,
      planId,
      tier: definition.tier,
      purchaseType: "subscription",
      billingAmountPaise: definition.amountPaise,
      billingPeriod: definition.period,
      message: "Premium Activated",
    };
  }
);
