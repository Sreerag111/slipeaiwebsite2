import * as admin from "firebase-admin";
import {HttpsError} from "firebase-functions/v2/https";

import {BillingPlanDefinition} from "../config/billingPlans";
import {hasPremiumAccess} from "./premiumStatus";

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

export interface OneTimeActivationResult {
  accessUntil: unknown;
  hasUsedFreeTrial: boolean;
}

/** Idempotently grants a verified one-time Razorpay purchase. */
export async function activateOneTimePurchase(
  uid: string,
  orderId: string,
  paymentId: string,
  definition: BillingPlanDefinition
): Promise<OneTimeActivationResult> {
  if (definition.kind !== "one_time" || !definition.accessDays) {
    throw new HttpsError("invalid-argument", "Choose a one-time plan.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const orderRef = db.collection("razorpayOrders").doc(orderId);
  const purchaseRef = db.collection("razorpayOneTimePurchases").doc(paymentId);
  const intentRef = db.collection("oneTimeCheckoutIntents").doc(uid);
  const proposedAccessUntil = admin.firestore.Timestamp.fromMillis(
    Date.now() + definition.accessDays * 24 * 60 * 60 * 1000
  );

  return db.runTransaction(async (transaction) => {
    const [userSnapshot, purchaseSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(purchaseRef),
    ]);
    const hasUsedFreeTrial = Boolean(
      asRecord(userSnapshot.data()?.billing).trialUsedAt
    );
    if (purchaseSnapshot.exists) {
      if (purchaseSnapshot.data()?.uid !== uid ||
          purchaseSnapshot.data()?.orderId !== orderId) {
        throw new HttpsError(
          "permission-denied",
          "Payment ownership is invalid."
        );
      }
      return {
        accessUntil: purchaseSnapshot.data()?.accessUntil ??
          proposedAccessUntil,
        hasUsedFreeTrial,
      };
    }

    const premium = asRecord(userSnapshot.data()?.premium);
    if (premium.isPremium === true &&
        hasPremiumAccess(premium.status, premium.accessUntil)) {
      throw new HttpsError(
        "already-exists",
        "This account already has active Premium access."
      );
    }

    transaction.set(userRef, {
      premium: {
        isPremium: true,
        tier: definition.tier,
        purchaseType: "one_time",
        planId: definition.id,
        orderId,
        paymentId,
        subscriptionId: null,
        status: "prepaid_active",
        billingAmountPaise: definition.amountPaise,
        billingPeriod: definition.period,
        accessUntil: proposedAccessUntil,
        trialEndsAt: null,
        currentPeriodEnd: proposedAccessUntil,
        cancelAtPeriodEnd: false,
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, {merge: true});
    transaction.set(purchaseRef, {
      uid,
      planId: definition.id,
      orderId,
      paymentId,
      amountPaise: definition.amountPaise,
      currency: "INR",
      accessUntil: proposedAccessUntil,
      status: "captured",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(orderRef, {
      status: "paid",
      paymentId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.delete(intentRef);
    return {accessUntil: proposedAccessUntil, hasUsedFreeTrial};
  });
}
