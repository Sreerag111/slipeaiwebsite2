import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import * as crypto from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {requirePremiumAccess} from "../utils/premiumEntitlements";

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * uploadUserAttachment — Accepts a user-uploaded image as base64 and
 * stores it permanently in Firebase Storage. Returns a permanent download URL.
 * Used to persist chat attachment images so they remain visible after reload.
 */
export const uploadUserAttachment = onCall(
  {
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated.");
      }
      const uid = request.auth.uid;
      await requirePremiumAccess(uid);

      const {
        imageBase64,
        filename = "attachment.jpg",
        contentType = "image/jpeg",
      } = request.data || {};

      if (!imageBase64 || typeof imageBase64 !== "string" || imageBase64.length < 10) {
        throw new HttpsError("invalid-argument", "imageBase64 is required.");
      }

      const cleanBase64 = imageBase64.replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "").trim();
      const imageBuffer = Buffer.from(cleanBase64, "base64");

      const bucket = admin.storage().bucket();
      const downloadToken = crypto.randomUUID();
      const fileId = `${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
      const ext = (filename.split(".").pop() || "jpg").toLowerCase();
      const filePath = `users/${uid}/attachments/${fileId}.${ext}`;
      const file = bucket.file(filePath);

      await file.save(imageBuffer, {
        metadata: {
          contentType,
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
            originalFilename: filename,
            uid,
          },
        },
      });

      const bucketName =
        bucket.name ||
        process.env.STORAGE_BUCKET ||
        "paceai-4733a.firebasestorage.app";
      const encodedPath = encodeURIComponent(filePath);
      const url =
        `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
        `${encodedPath}?alt=media&token=${downloadToken}`;

      debugLog.log(`[uploadUserAttachment] Uploaded ${filename} for uid ${uid}: ${url}`);

      return { success: true, url };
    } catch (error: unknown) {
      debugLog.error("[uploadUserAttachment] Error:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Attachment upload failed. Please try again.");
    }
  },
);
