import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  MEME_API_KEY,
  IMAGE_GEN_API_KEY,
  OPENAI_API_KEY,
} from "../config/secrets";
import { MemeService } from "../services/meme.service";
import { MemeController } from "../controllers/meme.controller";
import {
  releaseFeatureUsage,
  reserveFeatureUsage,
  UsageReservation,
} from "../utils/entitlements";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const generateMeme = onCall(
  {
    secrets: [MEME_API_KEY, IMAGE_GEN_API_KEY, OPENAI_API_KEY],
    timeoutSeconds: 300,
    memory: "1GiB",
  },
  async (request) => {
    let usageReservation: UsageReservation | null = null;
    let uid = "";
    try {
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "User must be authenticated.",
        );
      }
      uid = request.auth.uid;

      const {
        prompt,
        imageBase64,
        mimeType = "image/jpeg",
        format = "image",
      } = request.data || {};

      if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
        throw new HttpsError(
          "invalid-argument",
          "Prompt string is required.",
        );
      }

      usageReservation = await reserveFeatureUsage(uid, "meme");

      let memeApiKey = "";
      try {
        memeApiKey = MEME_API_KEY.value();
      } catch {
        memeApiKey = process.env.MEME_API_KEY || "";
      }

      let imageGenApiKey = "";
      try {
        imageGenApiKey = IMAGE_GEN_API_KEY.value() || OPENAI_API_KEY.value();
      } catch {
        imageGenApiKey =
          process.env.IMAGE_GEN_API_KEY || process.env.OPENAI_API_KEY || "";
      }

      let cleanFormat: "image" | "video" | "gif" = "image";
      if (format === "video") {
        cleanFormat = "video";
      } else if (format === "gif") {
        cleanFormat = "gif";
      }

      const service = new MemeService(memeApiKey, imageGenApiKey);
      const controller = new MemeController(service);

      return await controller.generateMeme(
        uid,
        prompt.trim(),
        imageBase64,
        mimeType,
        cleanFormat,
      );
    } catch (error: unknown) {
      debugLog.error("[generateMeme] Cloud Function Error:", error);

      if (uid) {
        await releaseFeatureUsage(uid, usageReservation);
      }

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Meme generation failed. Please try again.");
    }
  },
);
