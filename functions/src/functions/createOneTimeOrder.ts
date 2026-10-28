import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {billingPlan} from "../config/billingPlans";
import {getRazorpayClient} from "../config/razorpay";
import {RazorpayService} from "../services/razorpay.service";
import {hasPremiumAccess} from "../utils/premiumStatus";

const KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
const CHECKOUT_WINDOW_MS = 30 * 60 * 1000;

if (!admin.apps.length) admin.initializeApp();

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

export const createOneTimeOrder = onCall(
  {secrets: [KEY_ID, KEY_SECRET]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be logged in.");
    }

    const definition = billingPlan(request.data?.planId);
    if (!definition || definition.kind !== "one_time" ||
        !definition.accessDays) {
      throw new HttpsError("invalid-argument", "Choose a one-time plan.");
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const intentRef = db.collection("oneTimeCheckoutIntents").doc(uid);
    const planRef = db.collection("plans").doc(definition.id);
    const [userSnapshot, intentSnapshot, planSnapshot] = await Promise.all([
      userRef.get(),
      intentRef.get(),
      planRef.get(),
    ]);
    if (!planSnapshot.exists || planSnapshot.data()?.active !== true) {
      throw new HttpsError("failed-precondition", "Plan is not active.");
    }

    const premium = asRecord(userSnapshot.data()?.premium);
    if (premium.isPremium === true &&
        hasPremiumAccess(premium.status, premium.accessUntil)) {
      throw new HttpsError(
        "already-exists",
        "This account already has active Premium access."
      );
    }

    const intent = intentSnapshot.data() ?? {};
    const expiresAt = intent.expiresAt;
    if (intent.planId === definition.id &&
        typeof intent.orderId === "string" &&
        expiresAt instanceof admin.firestore.Timestamp &&
        expiresAt.toMillis() > Date.now()) {
      return {
        orderId: intent.orderId,
        planId: definition.id,
        planName: definition.name,
        amountPaise: definition.amountPaise,
        currency: "INR",
        accessDays: definition.accessDays,
        reused: true,
      };
    }

    const service = new RazorpayService(
      getRazorpayClient(KEY_ID.value(), KEY_SECRET.value())
    );
    const order = await service.createOrder(
      definition.amountPaise,
      `lite_${uid.slice(0, 8)}_${Date.now()}`,
      {
        uid,
        planId: definition.id,
        tier: definition.tier,
        accessDays: String(definition.accessDays),
      }
    );
    const expires = admin.firestore.Timestamp.fromMillis(
      Date.now() + CHECKOUT_WINDOW_MS
    );
    const batch = db.batch();
    batch.set(intentRef, {
      uid,
      planId: definition.id,
      orderId: order.id,
      status: "checkout_open",
      expiresAt: expires,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batch.set(db.collection("razorpayOrders").doc(order.id), {
      uid,
      planId: definition.id,
      amountPaise: definition.amountPaise,
      currency: "INR",
      accessDays: definition.accessDays,
      status: order.status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return {
      orderId: order.id,
      planId: definition.id,
      planName: definition.name,
      amountPaise: definition.amountPaise,
      currency: "INR",
      accessDays: definition.accessDays,
      reused: false,
    };
  }
);
