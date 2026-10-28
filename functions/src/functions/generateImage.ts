import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  OPENAI_API_KEY,
  IMAGE_GEN_API_KEY,
  MEME_API_KEY,
  VEO_API_KEY,
} from "../config/secrets";
import { enhanceVisualPrompt, ChatHistoryMessage } from "../utils/promptEnhancer";
import {
  releaseFeatureUsage,
  reserveFeatureUsage,
  UsageReservation,
} from "../utils/entitlements";
import {assertAppVersionSupported} from "../utils/versionCheck";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const generateImage = onCall(
  {
    secrets: [OPENAI_API_KEY, IMAGE_GEN_API_KEY, MEME_API_KEY, VEO_API_KEY],
    timeoutSeconds: 300,
    memory: "1GiB",
  },
  async (request) => {
    let reservation: UsageReservation | null = null;
    let reservedUid: string | null = null;
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated.");
      }

      const {
        prompt,
        model = "gpt-image-2",
        size = "1024x1792",
        quality = "high",
        chatHistory,
        imageUrl: inputImageUrl,
        buildNumber,
      } = request.data || {};

      await assertAppVersionSupported(buildNumber);

      if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
        throw new HttpsError("invalid-argument", "Prompt string is required.");
      }
      reservedUid = request.auth.uid;
      reservation = await reserveFeatureUsage(reservedUid, "image");

      let apiKey = "";
      try {
        apiKey = IMAGE_GEN_API_KEY.value() || OPENAI_API_KEY.value();
      } catch {
        apiKey =
          process.env.IMAGE_GEN_API_KEY || process.env.OPENAI_API_KEY || "";
      }

      if (!apiKey || !apiKey.startsWith("sk-")) {
        throw new HttpsError(
          "internal",
          "Image Generation API Key is not configured on Cloud Functions.",
        );
      }

      let geminiApiKey = "";
      try {
        geminiApiKey = MEME_API_KEY.value() || VEO_API_KEY.value();
      } catch {
        geminiApiKey =
          process.env.MEME_API_KEY || process.env.VEO_API_KEY || "";
      }

      // Step 1: Multimodal prompt expansion matching ChatGPT & Gemini Imagen 3
      debugLog.log("\n=======================================================");
      debugLog.log("[IMAGE_PROMPT_DEBUG] --- INCOMING GENERATE IMAGE REQUEST ---");
      debugLog.log(`[IMAGE_PROMPT_DEBUG] User Raw Prompt: "${prompt.trim()}"`);
      debugLog.log(`[IMAGE_PROMPT_DEBUG] Chat History Turns: ${Array.isArray(chatHistory) ? chatHistory.length : 0}`);

      // Older app builds may still send the former landscape size. Treat that
      // selection as the new 4:5 option so size and prompt remain consistent.
      const outputSize = size === "1792x1008" || size === "1792x1024" ?
        "1408x1760" : size;
      const enhancedPrompt = await enhanceVisualPrompt(prompt, {
        imageUrl: inputImageUrl,
        chatHistory: Array.isArray(chatHistory)
          ? (chatHistory as ChatHistoryMessage[])
          : undefined,
        geminiApiKey,
        openAiApiKey: apiKey,
        mode: "image",
        aspectRatio: outputSize === "1408x1760" ? "4:5" : "9:16",
      });

      debugLog.log(`[IMAGE_PROMPT_DEBUG] Final Enhanced Prompt: "${enhancedPrompt}"`);
      debugLog.log("=======================================================\n");

      // Step 2: Call image generation with the requested output dimensions.
      const response = await fetch(
        "https://api.openai.com/v1/images/generations",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model,
            prompt: enhancedPrompt,
            n: 1,
            size: outputSize,
            quality,
          }),
        },
      );

      if (!response.ok) {
        const errorText = await response.text();
        debugLog.error("OpenAI Image Generation Error:", errorText);
        throw new HttpsError(
          "internal",
          `Image service request failed (HTTP ${response.status}).`,
        );
      }

      const data = (await response.json()) as {
        data?: Array<{ url?: string; b64_json?: string }>;
      };

      const imageUrl = data.data?.[0]?.url || "";
      const b64Json = data.data?.[0]?.b64_json || "";

      if (!imageUrl && !b64Json) {
        throw new HttpsError(
          "internal",
          "No image content returned from API.",
        );
      }

      // Convert image data to binary buffer
      let imageBuffer: Buffer;
      if (b64Json) {
        imageBuffer = Buffer.from(b64Json, "base64");
      } else {
        const imgRes = await fetch(imageUrl);
        if (!imgRes.ok) {
          throw new HttpsError(
            "internal",
            "Failed to retrieve generated image.",
          );
        }
        const arrayBuf = await imgRes.arrayBuffer();
        imageBuffer = Buffer.from(arrayBuf);
      }

      // Upload permanently to Firebase Storage
      const bucket = admin.storage().bucket();
      const crypto = await import("crypto");
      const downloadToken = crypto.randomUUID();
      const fileId =
        `${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
      const uid = request.auth.uid;
      const filePath = `users/${uid}/generated_images/${fileId}.png`;
      const file = bucket.file(filePath);

      await file.save(imageBuffer, {
        metadata: {
          contentType: "image/png",
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
            prompt: prompt.trim(),
            enhancedPrompt,
            uid: request.auth.uid,
          },
        },
      });

      const bucketName =
        bucket.name ||
        process.env.STORAGE_BUCKET ||
        "paceai-4733a.firebasestorage.app";
      const encodedPath = encodeURIComponent(filePath);
      const permanentUrl =
        `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
        `${encodedPath}?alt=media&token=${downloadToken}`;

      return {
        success: true,
        imageUrl: permanentUrl,
        prompt: prompt.trim(),
        enhancedPrompt,
      };
    } catch (error: unknown) {
      if (reservedUid) await releaseFeatureUsage(reservedUid, reservation);
      debugLog.error("generateImage Error:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", "Image generation failed. Please try again.");
    }
  },
);
