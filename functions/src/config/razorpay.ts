import Razorpay from "razorpay";

export function getRazorpayClient(
  keyId: string,
  keySecret: string
): Razorpay {
  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });
}