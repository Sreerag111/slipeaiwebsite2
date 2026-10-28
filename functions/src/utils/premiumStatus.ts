import * as admin from "firebase-admin";

const ACCESS_STATUSES = new Set(["authenticated", "active"]);

export function hasPremiumAccess(
  status: unknown,
  accessUntil?: unknown
): boolean {
  if (typeof status === "string" && ACCESS_STATUSES.has(status)) {
    return true;
  }

  return (status === "cancelled" || status === "prepaid_active") &&
    isFutureTimestamp(accessUntil);
}

export function timestampFromUnixSeconds(
  value: unknown
): admin.firestore.Timestamp | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    return null;
  }
  return admin.firestore.Timestamp.fromMillis(value * 1000);
}

export function isFutureTimestamp(value: unknown): boolean {
  return value instanceof admin.firestore.Timestamp &&
    value.toMillis() > Date.now();
}
