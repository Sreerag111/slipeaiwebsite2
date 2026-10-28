import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {billingPlan} from "../config/billingPlans";
import {getRazorpayClient} from "../config/razorpay";
import {RazorpayService} from "../services/razorpay.service";
import {activateOneTimePurchase} from "../utils/oneTimePurchase";

const KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

if (!admin.apps.length) admin.initializeApp();

export const verifyOneTimePayment = onCall(
  {secrets: [KEY_ID, KEY_SECRET]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const {paymentId, orderId, signature, planId} = request.data ?? {};
    if (typeof paymentId !== "string" || typeof orderId !== "string" ||
        typeof signature !== "string") {
      throw new HttpsError("invalid-argument", "Missing payment details.");
    }
    const definition = billingPlan(planId);
    if (!definition || definition.kind !== "one_time" ||
        !definition.accessDays) {
      throw new HttpsError("invalid-argument", "Choose a one-time plan.");
    }

    const expected = crypto.createHmac("sha256", KEY_SECRET.value())
      .update(`${orderId}|${paymentId}`)
      .digest("hex");
    if (expected.length !== signature.length ||
        !crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature))) {
      throw new HttpsError("permission-denied", "Invalid payment signature.");
    }

    const db = admin.firestore();
    const orderRef = db.collection("razorpayOrders").doc(orderId);
    const orderMapping = await orderRef.get();
    if (orderMapping.data()?.uid !== uid ||
        orderMapping.data()?.planId !== definition.id) {
      throw new HttpsError("permission-denied", "Payment ownership is invalid.");
    }

    const service = new RazorpayService(
      getRazorpayClient(KEY_ID.value(), KEY_SECRET.value())
    );
    const [order, payment] = await Promise.all([
      service.fetchOrder(orderId),
      service.fetchPayment(paymentId),
    ]);
    const paymentData = payment as unknown as Record<string, unknown>;
    if (Number(order.amount) !== definition.amountPaise ||
        order.currency !== "INR" ||
        order.status !== "paid" ||
        paymentData.order_id !== orderId ||
        Number(paymentData.amount) !== definition.amountPaise ||
        paymentData.currency !== "INR" || paymentData.status !== "captured") {
      throw new HttpsError(
        "failed-precondition",
        "Payment has not been captured for the selected plan."
      );
    }

    const result = await activateOneTimePurchase(
      uid,
      orderId,
      paymentId,
      definition
    );

    return {
      success: true,
      isPremium: true,
      isTrialActive: false,
      hasUsedFreeTrial: result.hasUsedFreeTrial,
      status: "prepaid_active",
      cancelAtPeriodEnd: false,
      accessUntil: result.accessUntil,
      currentPeriodEnd: result.accessUntil,
      trialEndsAt: null,
      planId: definition.id,
      tier: definition.tier,
      billingAmountPaise: definition.amountPaise,
      billingPeriod: definition.period,
      purchaseType: "one_time",
    };
  }
);
