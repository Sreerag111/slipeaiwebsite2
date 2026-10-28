import crypto from "crypto";

export function verifySignature(
  orderId: string,
  paymentId: string,
  signature: string,
  secret: string,
): boolean {
  const body = `${orderId}|${paymentId}`;

  const expected = crypto
    .createHmac("sha256", secret)
    .update(body)
    .digest("hex");

  return expected === signature;
}