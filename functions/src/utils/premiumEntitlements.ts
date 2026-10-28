import * as admin from "firebase-admin";
import {HttpsError} from "firebase-functions/v2/https";

import {PremiumTier, premiumTierForPlan} from "../config/billingPlans";
import {isReviewAccessAccount} from "../config/reviewAccess";
import {hasPremiumAccess} from "./premiumStatus";

const FREE_PHOTO_ENHANCEMENTS = 2;

export interface VideoUsageReservation {
  counted: boolean;
  tier: PremiumTier | "free";
  rewarded?: boolean;
}

export interface PhotoUsageReservation {
  counted: boolean;
  tier: PremiumTier | "free";
  remaining: number | null;
  rewarded?: boolean;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

function activeTier(premium: Record<string, unknown>): PremiumTier | null {
  if (premium.isPremium !== true ||
      !hasPremiumAccess(premium.status, premium.accessUntil)) {
    return null;
  }
  if (premium.tier === "lite" || premium.tier === "pro") {
    return premium.tier;
  }
  return premiumTierForPlan(premium.planId);
}

/**
 * Reserves one of the two free photo enhancements, or allows paid tiers
 * without incrementing a counter. The transaction prevents parallel calls
 * from exceeding the free allowance.
 */
export async function authorizePhotoEnhancement(
  uid: string
): Promise<PhotoUsageReservation> {
  if (isReviewAccessAccount(uid)) {
    return {counted: false, tier: "pro", remaining: null};
  }
  const userRef = admin.firestore().collection("users").doc(uid);
  return admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const user = snapshot.data() ?? {};
    const premium = asRecord(user.premium);
    const tier = activeTier(premium);
    if (tier) return {counted: false, tier, remaining: null};

    const usage = asRecord(user.serverUsage);
    const current = Number(usage.photoEnhancementCount ?? 0);
    const safeCurrent = Number.isFinite(current) ? Math.max(0, current) : 0;
    if (safeCurrent >= FREE_PHOTO_ENHANCEMENTS) {
      if (Number(usage.rewardedPhotoCredits ?? 0) > 0) {
        transaction.set(userRef, {
          serverUsage: {...usage, photoEnhancementCount: safeCurrent + 1,
            rewardedPhotoCredits: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()},
        }, {merge: true});
        return {counted: true, tier: "free", remaining: 0, rewarded: true};
      }
      throw new HttpsError(
        "resource-exhausted",
        "Your two free photo enhancements have been used.",
        {reason: "PHOTO_FREE_LIMIT_REACHED", limit: FREE_PHOTO_ENHANCEMENTS}
      );
    }

    const next = safeCurrent + 1;
    transaction.set(userRef, {
      serverUsage: {
        ...usage,
        photoEnhancementCount: next,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, {merge: true});
    return {
      counted: true,
      tier: "free" as const,
      remaining: FREE_PHOTO_ENHANCEMENTS - next,
    };
  });
}

/** Gives a free photo attempt back when provider submission fails. */
export async function releasePhotoEnhancement(
  uid: string,
  reservation: PhotoUsageReservation | null
): Promise<void> {
  if (!reservation?.counted) return;
  const userRef = admin.firestore().collection("users").doc(uid);
  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const usage = asRecord(snapshot.data()?.serverUsage);
    const current = Number(usage.photoEnhancementCount ?? 0);
    transaction.set(userRef, {
      serverUsage: {
        ...usage,
        photoEnhancementCount: Math.max(0, current - 1),
        ...(reservation.rewarded ? {rewardedPhotoCredits: 1} : {}),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, {merge: true});
  });
}

/** Requires an active Pro entitlement for costly video processing. */
export async function requireProAccess(uid: string): Promise<void> {
  if (isReviewAccessAccount(uid)) return;
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  const premium = asRecord(snapshot.data()?.premium);
  if (activeTier(premium) !== "pro") {
    throw new HttpsError(
      "permission-denied",
      "Slipe AI Pro is required for video enhancement.",
      {reason: "PRO_REQUIRED"}
    );
  }
}

/**
 * Rejects before upload when an account does not have active Pro access.
 * Video remastering is strictly an exclusive Pro feature.
 */
export async function assertVideoEnhancementAvailable(
  uid: string
): Promise<void> {
  if (isReviewAccessAccount(uid)) return;
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  const user = snapshot.data() ?? {};
  const tier = activeTier(asRecord(user.premium));
  if (tier === "pro") return;

  throw new HttpsError(
    "permission-denied",
    "Slipe AI Pro is required for video remastering.",
    {reason: "PRO_REQUIRED"}
  );
}

/** Authorizes video enhancement strictly for active Pro subscribers. */
export async function authorizeVideoEnhancement(
  uid: string
): Promise<VideoUsageReservation> {
  if (isReviewAccessAccount(uid)) {
    return {counted: false, tier: "pro"};
  }
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  const user = snapshot.data() ?? {};
  const tier = activeTier(asRecord(user.premium));
  if (tier === "pro") {
    return {counted: false, tier: "pro"};
  }

  throw new HttpsError(
    "permission-denied",
    "Slipe AI Pro is required for video remastering.",
    {reason: "PRO_REQUIRED"}
  );
}

/** No-op for video since Pro users have unmetered video remastering. */
export async function releaseVideoEnhancement(
  _uid: string,
  _reservation: VideoUsageReservation | null
): Promise<void> {
  // Pro tier is unmetered; no counter decrement needed.
}

/** Requires either an active Lite or Pro entitlement. */
export async function requirePremiumAccess(uid: string): Promise<PremiumTier> {
  if (isReviewAccessAccount(uid)) return "pro";
  const snapshot = await admin.firestore().collection("users").doc(uid).get();
  const premium = asRecord(snapshot.data()?.premium);
  const tier = activeTier(premium);
  if (!tier) {
    throw new HttpsError(
      "permission-denied",
      "Premium is required for permanent attachment storage.",
      {reason: "PREMIUM_REQUIRED"}
    );
  }
  return tier;
}
