import * as admin from "firebase-admin";
import { debugLog } from "./debugLog";
import { HttpsError } from "firebase-functions/v2/https";

import { hasPremiumAccess } from "./premiumStatus";
import {isReviewAccessAccount} from "../config/reviewAccess";

export type MeteredFeature = "chat" | "image" | "meme";

const FREE_LIMITS: Partial<Record<MeteredFeature, number>> = {
  chat: 10,
  image: 1,
  meme: 1,
};

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

export interface UsageReservation {
  counted: boolean;
  feature: MeteredFeature;
  counterField?: string;
  rewardCreditConsumed?: boolean;
}

export async function reserveFeatureUsage(
  uid: string,
  feature: MeteredFeature
): Promise<UsageReservation> {
  if (isReviewAccessAccount(uid)) {
    return {counted: false, feature};
  }
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  return db.runTransaction<UsageReservation>(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const user = snapshot.data() ?? {};
    const premium = asRecord(user.premium);
    const hasPremium = premium.isPremium === true &&
      hasPremiumAccess(premium.status, premium.accessUntil);

    if (hasPremium) {
      return { counted: false, feature };
    }

    const limit = FREE_LIMITS[feature];
    if (limit === undefined) {
      throw new HttpsError("permission-denied", "This feature requires Premium.");
    }

    const serverUsage = asRecord(user.serverUsage);
    const field = `${feature}Count`;
    const current = Number(serverUsage[field] ?? 0);
    if (current >= limit) {
      const rewardedImageCredits = Number(
        serverUsage.rewardedImageCredits ?? 0
      );
      if (feature === "image" && rewardedImageCredits > 0) {
        transaction.set(userRef, {
          serverUsage: {
            ...serverUsage,
            [field]: current + 1,
            rewardedImageCredits: Math.max(0, rewardedImageCredits - 1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        }, { merge: true });
        return {
          counted: true,
          feature,
          counterField: field,
          rewardCreditConsumed: true,
        };
      }
      throw new HttpsError(
        "resource-exhausted",
        `Your free ${feature} limit has been reached.`
      );
    }

    transaction.set(userRef, {
      serverUsage: {
        ...serverUsage,
        [field]: current + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });
    return { counted: true, feature, counterField: field };
  });
}

export async function releaseFeatureUsage(
  uid: string,
  reservation: UsageReservation | null
): Promise<void> {
  if (!reservation?.counted) return;

  try {
    const userRef = admin.firestore().collection("users").doc(uid);
    const field = reservation.counterField ?? `${reservation.feature}Count`;
    await admin.firestore().runTransaction(async (transaction) => {
      const snapshot = await transaction.get(userRef);
      const serverUsage = asRecord(snapshot.data()?.serverUsage);
      const current = Number(serverUsage[field] ?? 0);
      const rewardedImageCredits = Number(
        serverUsage.rewardedImageCredits ?? 0
      );
      transaction.set(userRef, {
        serverUsage: {
          ...serverUsage,
          [field]: Math.max(0, current - 1),
          ...(reservation.rewardCreditConsumed ? {
            rewardedImageCredits: Math.max(1, rewardedImageCredits),
          } : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      }, { merge: true });
    });
  } catch (error) {
    debugLog.error("Unable to release failed usage reservation", {
      uid,
      feature: reservation.feature,
      error,
    });
  }
}
