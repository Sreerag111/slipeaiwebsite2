import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {isReviewAccessAccount} from "../config/reviewAccess";
import {hasPremiumAccess} from "../utils/premiumStatus";

if (!admin.apps.length) {
  admin.initializeApp();
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

/**
 * Stores one server-side image-generation credit after the client reports a
 * completed rewarded ad. Credits cannot be stacked and are consumed in the
 * same transaction that reserves the next image generation.
 */
export const claimRewardedImageCredit = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const uid = request.auth.uid;
  if (isReviewAccessAccount(uid)) {
    throw new HttpsError(
      "failed-precondition",
      "Rewarded credits are only available to Free users."
    );
  }

  const userRef = admin.firestore().collection("users").doc(uid);
  const rewardedImageCredits = await admin.firestore().runTransaction(
    async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const user = snapshot.data() ?? {};
      const premium = asRecord(user.premium);
      if (premium.isPremium === true &&
          hasPremiumAccess(premium.status, premium.accessUntil)) {
        throw new HttpsError(
          "failed-precondition",
          "Rewarded credits are only available to Free users."
        );
      }

      const serverUsage = asRecord(user.serverUsage);
      const imageCount = Number(serverUsage.imageCount ?? 0);
      if (!Number.isFinite(imageCount) || imageCount < 1) {
        throw new HttpsError(
          "failed-precondition",
          "The free image-generation limit has not been reached."
        );
      }

      transaction.set(userRef, {
        serverUsage: {
          ...serverUsage,
          rewardedImageCredits: 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, {merge: true});
      return 1;
    }
  );

  return {success: true, rewardedImageCredits};
});
