import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {getRazorpayClient} from "../config/razorpay";
import {RazorpayService} from "../services/razorpay.service";
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

export const cancelSubscription = onCall(
  {secrets: [KEY_ID, KEY_SECRET]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "User must be logged in."
      );
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userSnapshot = await userRef.get();
    const premium = asRecord(userSnapshot.data()?.premium);
    const subscriptionId = typeof premium.subscriptionId === "string" ?
      premium.subscriptionId :
      null;

    if (!subscriptionId) {
      throw new HttpsError(
        "failed-precondition",
        "No subscription was found for this account."
      );
    }

    const ownerRef = db
      .collection("razorpaySubscriptions")
      .doc(subscriptionId);
    const ownerSnapshot = await ownerRef.get();
    if (ownerSnapshot.data()?.uid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "The subscription does not belong to this account."
      );
    }

    const razorpay = getRazorpayClient(
      KEY_ID.value(),
      KEY_SECRET.value()
    );
    const service = new RazorpayService(razorpay);
    const current = await service.fetchSubscription(subscriptionId);

    if (current.status === "cancelled" || current.status === "completed") {
      throw new HttpsError(
        "failed-precondition",
        "The subscription has already ended."
      );
    }

    const requestedAtCycleEnd = request.data?.cancelAtCycleEnd !== false;
    const isPreBillingTrial = current.status === "authenticated" &&
      Number(current.paid_count ?? 0) === 0;

    // Razorpay cannot schedule cycle-end cancellation before billing starts.
    // Cancel the mandate during a trial and retain access until start_at.
    const useCycleEndCancellation =
      requestedAtCycleEnd && !isPreBillingTrial;
    const cancelled = await service.cancelSubscription(
      subscriptionId,
      useCycleEndCancellation
    );

    const accessUntil = isPreBillingTrial ?
      timestampFromUnixSeconds(current.start_at) :
      useCycleEndCancellation ?
        timestampFromUnixSeconds(current.current_end) :
        null;
    const status = cancelled.status;
    const isPremium = hasPremiumAccess(status, accessUntil);

    const batch = db.batch();
    batch.set(userRef, {
      premium: {
        ...premium,
        isPremium,
        status,
        subscriptionId,
        cancelAtPeriodEnd: useCycleEndCancellation,
        accessUntil,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, {merge: true});
    batch.set(ownerRef, {
      status,
      cancelAtPeriodEnd: useCycleEndCancellation,
      accessUntil,
      cancellationRequestedAt:
        admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();

    return {
      success: true,
      isPremium,
      isTrialActive: isPreBillingTrial && isPremium,
      status,
      cancelAtPeriodEnd: useCycleEndCancellation,
      accessUntil,
      trialEndsAt: premium.trialEndsAt ?? null,
      currentPeriodEnd: premium.currentPeriodEnd ?? null,
      planId: premium.planId ?? null,
    };
  }
);
