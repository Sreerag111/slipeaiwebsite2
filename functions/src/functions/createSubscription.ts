import * as admin from "firebase-admin";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

import { getRazorpayClient } from "../config/razorpay";
import { RazorpayService } from "../services/razorpay.service";
import { SubscriptionController } from "../controllers/subscription.controller";
import {billingPlan} from "../config/billingPlans";

const KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

if (!admin.apps.length) {
  admin.initializeApp();
}

const SUBSCRIPTION_DEBUG_LOGS = true;

function debugLog(message: string, data: Record<string, unknown> = {}) {
  if (SUBSCRIPTION_DEBUG_LOGS) {
    logger.info(`[SubscriptionDebug] ${message}`, data);
  }
}

function errorDetails(error: unknown): Record<string, unknown> {
  if (!error || typeof error !== "object") {
    return {type: typeof error, value: String(error)};
  }

  const value = error as Record<string, unknown>;
  const nested = value.error && typeof value.error === "object" ?
    value.error as Record<string, unknown> : {};
  return {
    type: error.constructor?.name ?? "Object",
    statusCode: value.statusCode ?? null,
    code: nested.code ?? value.code ?? null,
    description: nested.description ?? value.message ?? null,
    reason: nested.reason ?? null,
    field: nested.field ?? null,
  };
}

export const createSubscription = onCall(
  {
    secrets: [KEY_ID, KEY_SECRET],
  },

  async (request) => {
    const requestId = request.rawRequest.get("x-cloud-trace-context")?.
      split("/")[0] ?? "unavailable";
    debugLog("Callable received", {
      requestId,
      authenticated: Boolean(request.auth),
      uidPrefix: request.auth?.uid.slice(0, 6) ?? null,
      appCheckPresent: Boolean(request.app),
      dataType: typeof request.data,
      requestedPlanId: request.data?.planId ?? null,
    });

    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "User must be logged in."
        );
      }

      const planId = request.data?.planId;

      const plan = billingPlan(planId);
      if (!plan || plan.kind !== "subscription") {
        throw new HttpsError(
          "invalid-argument",
          "A valid planId is required."
        );
      }

      const keyId = KEY_ID.value();
      const keySecret = KEY_SECRET.value();
      debugLog("Razorpay credential shape", {
        requestId,
        keyMode: keyId.startsWith("rzp_test_") ? "test" :
          keyId.startsWith("rzp_live_") ? "live" : "invalid-prefix",
        keyIdLength: keyId.length,
        keySecretLength: keySecret.length,
        keyIdHasWhitespace: /\s/.test(keyId),
        keySecretHasWhitespace: /\s/.test(keySecret),
        keyIdHasQuotes: /["']/.test(keyId),
        keySecretHasQuotes: /["']/.test(keySecret),
      });

      const razorpay = getRazorpayClient(keyId, keySecret);

      const service = new RazorpayService(razorpay);

      const controller = new SubscriptionController(service);

      const result = await controller.createSubscription(
        request.auth.uid,
        planId,
        requestId
      );
      debugLog("Callable completed", {
        requestId,
        planId,
        status: result.status,
        subscriptionIdPrefix: result.subscriptionId.slice(0, 10),
      });
      return result;
    } catch (error: unknown) {
      const details = errorDetails(error);
      logger.error("[SubscriptionDebug] Callable failed", {
        requestId,
        requestedPlanId: request.data?.planId ?? null,
        ...details,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      const message = details.statusCode === 401 ?
        "Razorpay authentication failed. Check that the key ID and secret " +
          "are a matching pair without extra text or spaces." :
        typeof details.description === "string" ?
          details.description :
          "Failed to create subscription.";

      throw new HttpsError("internal", message, {
        requestId,
        provider: "razorpay",
        providerStatusCode: details.statusCode,
        providerCode: details.code,
      });
    }
  }
);
