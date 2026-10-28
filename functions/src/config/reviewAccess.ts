const REVIEW_BYPASS_UIDS = new Set([
  "yeyx0T6dLDhyp42Ld53RqE7VBCx1",
]);

/** Accounts that always receive Pro access without a billing entitlement. */
export function isReviewAccessAccount(uid: string): boolean {
  return REVIEW_BYPASS_UIDS.has(uid);
}
