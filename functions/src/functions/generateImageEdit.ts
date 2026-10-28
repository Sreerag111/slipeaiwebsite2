import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import * as crypto from "crypto";
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

interface ImageDimensions {
  width: number;
  height: number;
  aspectRatio: number;
}

function detectImageDimensions(buffer: Buffer): ImageDimensions {
  try {
    // PNG
    if (
      buffer.length > 24 &&
      buffer[0] === 0x89 &&
      buffer[1] === 0x50 &&
      buffer[2] === 0x4e &&
      buffer[3] === 0x47
    ) {
      const width = buffer.readUInt32BE(16);
      const height = buffer.readUInt32BE(20);
      if (width > 0 && height > 0) {
        return { width, height, aspectRatio: width / height };
      }
    }

    // JPEG
    if (buffer.length > 4 && buffer[0] === 0xff && buffer[1] === 0xd8) {
      let offset = 2;
      while (offset < buffer.length - 8) {
        if (buffer[offset] !== 0xff) {
          offset++;
          continue;
        }
        const marker = buffer[offset + 1];
        if (
          (marker >= 0xc0 && marker <= 0xc3) ||
          (marker >= 0xc5 && marker <= 0xc7) ||
          (marker >= 0xc9 && marker <= 0xcb) ||
          (marker >= 0xcd && marker <= 0xcf)
        ) {
          const height = buffer.readUInt16BE(offset + 5);
          const width = buffer.readUInt16BE(offset + 7);
          if (width > 0 && height > 0) {
            return { width, height, aspectRatio: width / height };
          }
        }
        const length = buffer.readUInt16BE(offset + 2);
        offset += 2 + length;
      }
    }
  } catch (e) {
    debugLog.warn("Dimension detection error:", e);
  }
  return { width: 1024, height: 1024, aspectRatio: 1.0 };
}

/**
 * generateImageEdit — Edits / transforms an uploaded photo using OpenAI + Gemini Vision.
 * Accepts the user's photo as base64 + a text instruction + chat history, and returns
 * a Firebase Storage URL of the edited image so it persists permanently.
 */
export const generateImageEdit = onCall(
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
        imageBase64,
        referenceImageBase64,
        referenceMimeType = "image/png",
        imageUrl: inputImageUrl,
        mimeType = "image/jpeg",
        size = "auto",
        chatHistory,
        model = "gpt-image-2",
        buildNumber,
      } = request.data || {};

      await assertAppVersionSupported(buildNumber);

      if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
        throw new HttpsError("invalid-argument", "Prompt string is required.");
      }
      reservedUid = request.auth.uid;
      reservation = await reserveFeatureUsage(reservedUid, "image");

      let imageBuffer: Buffer;
      let effectiveMimeType = mimeType;

      if (imageBase64 && typeof imageBase64 === "string" && imageBase64.length > 50) {
        const cleanBase64 = imageBase64
          .replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "")
          .trim();
        imageBuffer = Buffer.from(cleanBase64, "base64");
      } else if (inputImageUrl && typeof inputImageUrl === "string" && inputImageUrl.startsWith("http")) {
        debugLog.log(`[generateImageEdit] Downloading reference image from: ${inputImageUrl}`);
        const imgRes = await fetch(inputImageUrl);
        if (!imgRes.ok) {
          throw new HttpsError(
            "invalid-argument",
            `Failed to download reference image (${imgRes.status}).`,
          );
        }
        const arrayBuf = await imgRes.arrayBuffer();
        imageBuffer = Buffer.from(arrayBuf);
        const ct = imgRes.headers.get("content-type");
        if (ct) effectiveMimeType = ct;
      } else {
        throw new HttpsError(
          "invalid-argument",
          "A valid image (imageBase64 or imageUrl) is required for image editing.",
        );
      }

      let referenceBuffer: Buffer | null = null;
      const effectiveRefMime = referenceMimeType || "image/png";
      if (
        referenceImageBase64 &&
        typeof referenceImageBase64 === "string" &&
        referenceImageBase64.length > 50
      ) {
        const cleanRef = referenceImageBase64
          .replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "")
          .trim();
        referenceBuffer = Buffer.from(cleanRef, "base64");
      }

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

      // Determine dimensions and optimal target size for OpenAI to avoid cropping
      const dims = detectImageDimensions(imageBuffer);
      debugLog.log(
        `[generateImageEdit] Input dimensions: ${dims.width}x${dims.height}, aspectRatio: ${dims.aspectRatio.toFixed(3)}`,
      );

      let targetSize: string;
      if (size && size !== "1024x1024" && size !== "auto") {
        targetSize = size;
      } else {
        // Keep the uploaded photo's composition instead of forcing every
        // portrait/landscape into one preset shape. GPT Image 2 requires both
        // edges to be multiples of 16 and an aspect ratio no wider than 3:1.
        const ratio = Number.isFinite(dims.aspectRatio) &&
          dims.aspectRatio > 0 ? dims.aspectRatio : 1;
        if (ratio >= 0.95 && ratio <= 1.05) {
          targetSize = "1024x1024";
        } else if (ratio > 1) {
          const height = Math.max(608,
            Math.round((1792 / ratio) / 16) * 16);
          targetSize = `1792x${Math.min(height, 1792)}`;
        } else {
          const width = Math.max(608,
            Math.round((1792 * ratio) / 16) * 16);
          targetSize = `${Math.min(width, 1792)}x1792`;
        }
      }

      debugLog.log(`[generateImageEdit] Selected target size: ${targetSize}`);

      // Step 1: Multimodal prompt expansion or direct preset pass-through
      let enhancedPrompt = prompt.trim();
      const isPresetEdit = Boolean(referenceBuffer);

      if (!isPresetEdit) {
        debugLog.log("[generateImageEdit] Free-form chat prompt, applying Gemini multimodal prompt expansion.");
        enhancedPrompt = await enhanceVisualPrompt(prompt, {
          imageBase64: imageBuffer.toString("base64"),
          mimeType: effectiveMimeType,
          chatHistory: Array.isArray(chatHistory)
            ? (chatHistory as ChatHistoryMessage[])
            : undefined,
          geminiApiKey,
          openAiApiKey: apiKey,
          mode: "image-edit",
        });
      } else {
        debugLog.log("[generateImageEdit] Preset Try-It mode detected: bypassing Gemini expansion to preserve full prompt fidelity.");
        // Provide multi-image role guidance to gpt-image-2 for reference fusion
        enhancedPrompt =
          `[IMAGE ROLES]: Image 1 is the user's uploaded photograph to edit. Image 2 is the visual style, concept, and aesthetic reference.\n\n` +
          `${prompt.trim()}`;
      }

      debugLog.log(`[IMAGE_EDIT_PROMPT_DEBUG] Final Prompt for OpenAI: "${enhancedPrompt.substring(0, 150)}..."`);
      debugLog.log(`[IMAGE_EDIT_PROMPT_DEBUG] Selected Target Size: ${targetSize}`);

      // Determine file extension from mimeType
      const ext = effectiveMimeType.split("/")[1]?.replace("jpeg", "jpg") || "jpg";

      // Build multipart form data for OpenAI images/edits endpoint
      const boundary =
        "----FormBoundary" + crypto.randomBytes(8).toString("hex");
      const CRLF = "\r\n";

      const parts: Buffer[] = [];

      // field: model
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="model"${CRLF}${CRLF}` +
          `${model || "gpt-image-2"}${CRLF}`,
        ),
      );

      // field: prompt
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="prompt"${CRLF}${CRLF}` +
          `${enhancedPrompt}${CRLF}`,
        ),
      );

      // field: size
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="size"${CRLF}${CRLF}` +
          `${targetSize}${CRLF}`,
        ),
      );

      // field: n
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="n"${CRLF}${CRLF}` +
          `1${CRLF}`,
        ),
      );

      // field: image[] (Image 1: User's photo to edit)
      const primaryFieldName = referenceBuffer ? "image[]" : "image";
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="${primaryFieldName}"; filename="user_photo.${ext}"${CRLF}` +
          `Content-Type: ${effectiveMimeType}${CRLF}${CRLF}`,
        ),
      );
      parts.push(imageBuffer);
      parts.push(Buffer.from(CRLF));

      // field: image[] (Image 2: Preset style reference image if provided)
      if (referenceBuffer) {
        const refExt =
          effectiveRefMime.split("/")[1]?.replace("jpeg", "jpg") || "png";
        parts.push(
          Buffer.from(
            `--${boundary}${CRLF}` +
            `Content-Disposition: form-data; name="image[]"; filename="style_reference.${refExt}"${CRLF}` +
            `Content-Type: ${effectiveRefMime}${CRLF}${CRLF}`,
          ),
        );
        parts.push(referenceBuffer);
        parts.push(Buffer.from(CRLF));
      }

      // closing boundary
      parts.push(Buffer.from(`--${boundary}--${CRLF}`));

      const body = Buffer.concat(parts);

      debugLog.log(
        "[generateImageEdit] Calling OpenAI images/edits. " +
        `targetSize=${targetSize}, promptLength=${enhancedPrompt.length}, hasReference=${Boolean(referenceBuffer)}`,
      );

      const response = await fetch("https://api.openai.com/v1/images/edits", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": `multipart/form-data; boundary=${boundary}`,
        },
        body,
      });

      if (!response.ok) {
        const errorText = await response.text();
        debugLog.error("[generateImageEdit] OpenAI error:", errorText);
        throw new HttpsError(
          "internal",
          `Image edit service request failed (HTTP ${response.status}).`,
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
          "No image content returned from edit API.",
        );
      }

      // Download image and upload to Firebase Storage for permanent URL
      let imageResultBuffer: Buffer;
      if (b64Json) {
        imageResultBuffer = Buffer.from(b64Json, "base64");
      } else {
        const imgRes = await fetch(imageUrl);
        if (!imgRes.ok) {
          throw new HttpsError(
            "internal",
            "Failed to retrieve edited image from OpenAI.",
          );
        }
        imageResultBuffer = Buffer.from(await imgRes.arrayBuffer());
      }

      // Upload to Firebase Storage
      const bucket = admin.storage().bucket();
      const downloadToken = crypto.randomUUID();
      const fileId = `${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
      const uid = request.auth.uid;
      const filePath = `users/${uid}/edited_images/${fileId}.png`;
      const file = bucket.file(filePath);

      await file.save(imageResultBuffer, {
        metadata: {
          contentType: "image/png",
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
            prompt: prompt.trim(),
            enhancedPrompt,
            uid,
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

      debugLog.log(`[generateImageEdit] Success. Permanent URL: ${permanentUrl}`);

      return {
        success: true,
        imageUrl: permanentUrl,
        prompt: prompt.trim(),
        enhancedPrompt,
      };
    } catch (error: unknown) {
      if (reservedUid) await releaseFeatureUsage(reservedUid, reservation);
      debugLog.error("[generateImageEdit] Error:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", "Image editing failed. Please try again.");
    }
  },
);
