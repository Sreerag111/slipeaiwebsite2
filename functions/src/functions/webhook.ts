import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import * as crypto from "crypto";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";

import {getRazorpayClient} from "../config/razorpay";
import {billingPlan, premiumTierForPlan} from "../config/billingPlans";
import {activateOneTimePurchase} from "../utils/oneTimePurchase";
import {
  hasPremiumAccess,
  timestampFromUnixSeconds,
} from "../utils/premiumStatus";

const WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");
const KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

if (!admin.apps.length) {
  admin.initializeApp();
}

interface SubscriptionEntity {
  id?: unknown;
  plan_id?: unknown;
  status?: unknown;
  start_at?: unknown;
  current_end?: unknown;
  paid_count?: unknown;
  cancel_at_cycle_end?: unknown;
  notes?: unknown;
}

interface PaymentEntity {
  id?: unknown;
  order_id?: unknown;
  amount?: unknown;
  currency?: unknown;
  status?: unknown;
}

const SUPPORTED_SUBSCRIPTION_EVENTS = new Set([
  "subscription.authenticated",
  "subscription.activated",
  "subscription.charged",
  "subscription.cancelled",
  "subscription.completed",
  "subscription.paused",
  "subscription.halted",
  "subscription.pending",
  "subscription.resumed",
  "subscription.updated",
]);

interface WebhookBody {
  event?: unknown;
  created_at?: unknown;
  payload?: {
    subscription?: {
      entity?: SubscriptionEntity;
    };
    payment?: {
      entity?: PaymentEntity;
    };
  };
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value) ?
    value as Record<string, unknown> : {};
}

function readNote(notes: unknown, key: string): string | null {
  const value = asRecord(notes)[key];
  return typeof value === "string" && value.length > 0 ? value : null;
}

export const razorpayWebhook = onRequest(
  {secrets: [WEBHOOK_SECRET, KEY_ID, KEY_SECRET]},
  async (req, res) => {
    const suppliedSignature = req.header("x-razorpay-signature") ?? "";
    const expectedSignature = crypto
      .createHmac("sha256", WEBHOOK_SECRET.value())
      .update(req.rawBody)
      .digest("hex");
    const validSignature = suppliedSignature.length === expectedSignature.length &&
      crypto.timingSafeEqual(
        Buffer.from(suppliedSignature),
        Buffer.from(expectedSignature)
      );

    if (!validSignature) {
      res.status(401).send("Invalid signature");
      return;
    }

    const body = req.body as WebhookBody;
    const event = typeof body.event === "string" ? body.event : "";
    const db = admin.firestore();
    const eventId = req.header("x-razorpay-event-id") ??
      crypto.createHash("sha256").update(req.rawBody).digest("hex");
    const eventRef = db.collection("razorpayWebhookEvents").doc(eventId);

    if (event === "payment.captured") {
      const payment = body.payload?.payment?.entity;
      const paymentId = typeof payment?.id === "string" ? payment.id : null;
      const orderId = typeof payment?.order_id === "string" ?
        payment.order_id : null;
      if (!payment || !paymentId || !orderId) {
        res.status(400).send("Missing one-time payment details");
        return;
      }

      const existingEvent = await eventRef.get();
      if (existingEvent.exists) {
        res.status(200).send("Already processed");
        return;
      }
      const orderRef = db.collection("razorpayOrders").doc(orderId);
      const orderSnapshot = await orderRef.get();
      if (!orderSnapshot.exists) {
        res.status(200).send("Non-one-time payment ignored");
        return;
      }
      const orderData = orderSnapshot.data() ?? {};
      const uid = typeof orderData.uid === "string" ? orderData.uid : null;
      const definition = billingPlan(orderData.planId);
      if (!uid || !definition || definition.kind !== "one_time" ||
          Number(payment.amount) !== definition.amountPaise ||
          payment.currency !== "INR" || payment.status !== "captured") {
        await eventRef.set({
          event,
          orderId,
          paymentId,
          processed: false,
          reason: "one_time_payment_mismatch",
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.status(202).send("One-time payment could not be matched");
        return;
      }

      try {
        await activateOneTimePurchase(
          uid,
          orderId,
          paymentId,
          definition
        );
        await eventRef.set({
          event,
          uid,
          orderId,
          paymentId,
          processed: true,
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.status(200).send("One-time purchase activated");
      } catch (error) {
        debugLog.error("Unable to activate captured one-time payment", {
          orderId,
          paymentId,
          error,
        });
        res.status(500).send("One-time purchase activation failed");
      }
      return;
    }

    const subscription = body.payload?.subscription?.entity;
    if (!SUPPORTED_SUBSCRIPTION_EVENTS.has(event) || !subscription) {
      res.status(200).send("Ignored");
      return;
    }

    const subscriptionId = typeof subscription.id === "string" ?
      subscription.id : null;
    const status = typeof subscription.status === "string" ?
      subscription.status : null;
    if (!subscriptionId || !status) {
      res.status(400).send("Missing subscription details");
      return;
    }

    const ownerRef = db.collection("razorpaySubscriptions").doc(subscriptionId);
    const initialOwner = await ownerRef.get();
    let uid = typeof initialOwner.data()?.uid === "string" ?
      initialOwner.data()?.uid as string : readNote(subscription.notes, "uid");

    if (!uid) {
      const matchingUsers = await db
        .collection("users")
        .where("premium.subscriptionId", "==", subscriptionId)
        .limit(1)
        .get();
      uid = matchingUsers.empty ? null : matchingUsers.docs[0].id;
    }

    if (!uid) {
      await eventRef.set({
        event,
        subscriptionId,
        status,
        processed: false,
        reason: "owner_not_found",
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      res.status(202).send("Subscription owner not found");
      return;
    }

    // Some update events arrive while checkout is still unverified. Preserve
    // the temporary intent until Razorpay reports mandate authorization.
    if (status === "created") {
      await eventRef.set({
        event,
        subscriptionId,
        uid,
        status,
        processed: true,
        reason: "awaiting_authorization",
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      res.status(200).send("Awaiting authorization");
      return;
    }

    const eventSeconds = typeof body.created_at === "number" ?
      body.created_at : Math.floor(Date.now() / 1000);
    const eventTime = admin.firestore.Timestamp.fromMillis(eventSeconds * 1000);
    const userRef = db.collection("users").doc(uid);
    const intentRef = db.collection("subscriptionCheckoutIntents").doc(uid);
    const outcome = await db.runTransaction(async (transaction) => {
      const [eventSnapshot, userSnapshot, ownerSnapshot, intentSnapshot] =
        await Promise.all([
          transaction.get(eventRef),
          transaction.get(userRef),
          transaction.get(ownerRef),
          transaction.get(intentRef),
        ]);
      if (eventSnapshot.exists) return {kind: "duplicate" as const};

      const user = userSnapshot.data() ?? {};
      const existingPremium = asRecord(user.premium);
      const existingBilling = asRecord(user.billing);
      const activeSubscriptionId = existingPremium.subscriptionId;
      const trialDays = Number(
        ownerSnapshot.data()?.trialDays ??
        readNote(subscription.notes, "trialDays") ??
        0
      );
      const firstTrialSubscriptionId = existingBilling.firstTrialSubscriptionId;
      const hasDuplicateTrial = trialDays > 0 &&
        Boolean(existingBilling.trialUsedAt) &&
        firstTrialSubscriptionId !== subscriptionId;
      const hasDifferentActiveSubscription =
        typeof activeSubscriptionId === "string" &&
        activeSubscriptionId !== subscriptionId &&
        hasPremiumAccess(existingPremium.status, existingPremium.accessUntil);

      if (hasDifferentActiveSubscription || hasDuplicateTrial) {
        transaction.set(eventRef, {
          event,
          subscriptionId,
          uid,
          status,
          processed: false,
          reason: hasDuplicateTrial ?
            "trial_already_used" : "active_subscription_exists",
          receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(ownerRef, {
          uid,
          planId: readNote(subscription.notes, "planId"),
          status: "rejected_duplicate",
          providerStatus: status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        return {kind: "rejected" as const};
      }

      const previousEventAt = existingPremium.lastEventAt;
      const currentPeriodEnd =
        timestampFromUnixSeconds(subscription.current_end);
      let accessUntil = null;
      const cancelAtPeriodEnd = subscription.cancel_at_cycle_end === true ||
        subscription.cancel_at_cycle_end === 1;
      const trialWasGranted = trialDays > 0;
      const resolvedPlanId = readNote(subscription.notes, "planId") ??
        ownerSnapshot.data()?.planId ?? existingPremium.planId ?? null;
      if (status === "cancelled") {
        accessUntil = (Number(subscription.paid_count ?? 0) === 0 ?
          timestampFromUnixSeconds(subscription.start_at) :
          currentPeriodEnd) ?? existingPremium.accessUntil ?? null;
      }

      transaction.set(eventRef, {
        event,
        subscriptionId,
        uid,
        status,
        processed: true,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.set(ownerRef, {
        uid,
        planId: readNote(subscription.notes, "planId") ??
          ownerSnapshot.data()?.planId ?? null,
        trialDays,
        status,
        cancelAtPeriodEnd,
        currentPeriodEnd,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      if (!(previousEventAt instanceof admin.firestore.Timestamp) ||
          previousEventAt.toMillis() <= eventTime.toMillis()) {
        transaction.set(userRef, {
          premium: {
            ...existingPremium,
            isPremium: hasPremiumAccess(status, accessUntil),
            tier: premiumTierForPlan(resolvedPlanId) ??
              existingPremium.tier ?? null,
            purchaseType: "subscription",
            planId: resolvedPlanId,
            status,
            subscriptionId,
            razorpayPlanId: typeof subscription.plan_id === "string" ?
              subscription.plan_id : existingPremium.razorpayPlanId ?? null,
            trialEndsAt: timestampFromUnixSeconds(subscription.start_at),
            currentPeriodEnd,
            accessUntil,
            cancelAtPeriodEnd,
            lastEventAt: eventTime,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          ...(trialWasGranted && !existingBilling.trialUsedAt ? {
            billing: {
              ...existingBilling,
              trialUsedAt: admin.firestore.FieldValue.serverTimestamp(),
              firstTrialSubscriptionId: subscriptionId,
            },
          } : {}),
        }, {merge: true});
      }

      if (intentSnapshot.data()?.subscriptionId === subscriptionId) {
        transaction.delete(intentRef);
      }
      return {kind: "accepted" as const};
    });

    if (outcome.kind === "duplicate") {
      res.status(200).send("Already processed");
      return;
    }

    if (outcome.kind === "rejected") {
      try {
        const razorpay = getRazorpayClient(KEY_ID.value(), KEY_SECRET.value());
        const cancelled = await razorpay.subscriptions.cancel(
          subscriptionId,
          false
        );
        await ownerRef.set({
          status: cancelled.status,
          providerStatus: cancelled.status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      } catch (error) {
        debugLog.error("Unable to cancel duplicate subscription", {
          subscriptionId,
          error,
        });
      }
      res.status(200).send("Duplicate subscription rejected");
      return;
    }

    res.status(200).send("OK");
  }
);
