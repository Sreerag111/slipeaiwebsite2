import * as admin from "firebase-admin";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {isReviewAccessAccount} from "../config/reviewAccess";
import {hasPremiumAccess} from "../utils/premiumStatus";

if (!admin.apps.length) admin.initializeApp();

/** One non-stackable credit, claimed after the SDK earned-reward callback. */
export const claimRewardedEnhancementCredit = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const feature = request.data?.feature;
  if (feature !== "photo") {
    throw new HttpsError(
      "permission-denied",
      "Rewarded ads are only available for photo enhancement. Video remastering requires Slipe AI Pro."
    );
  }
  const uid = request.auth.uid;
  const creditField = "rewardedPhotoCredits";
  const countField = "photoEnhancementCount";
  const limit = 2;
  const ref = admin.firestore().collection("users").doc(uid);
  await admin.firestore().runTransaction(async (transaction) => {
    const user = (await transaction.get(ref)).data() ?? {};
    const premium = user.premium ?? {};
    const hasPremium = premium.isPremium === true &&
      hasPremiumAccess(premium.status, premium.accessUntil);
    if (isReviewAccessAccount(uid) || hasPremium) {
      throw new HttpsError("failed-precondition",
        "Ads are available to Free users only.");
    }
    const usage = user.serverUsage ?? {};
    const count = Number(usage[countField] ?? 0);
    if (!Number.isFinite(count) || count < limit) {
      throw new HttpsError("failed-precondition", "Free allowance remains.");
    }
    transaction.set(ref, {
      serverUsage: {...usage, [creditField]: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()},
    }, {merge: true});
  });
  return {success: true, credits: 1};
});
