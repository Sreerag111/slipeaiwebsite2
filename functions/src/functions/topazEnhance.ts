import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as fs from "fs/promises";
import * as os from "os";
import * as path from "path";
import {execFile} from "child_process";
import {promisify} from "util";
import {Readable} from "stream";
import {pipeline} from "stream/promises";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import ffmpegPath from "ffmpeg-static";

import {
  IMAGE_GEN_API_KEY,
  OPENAI_API_KEY,
  TOPAZ_API_KEY,
} from "../config/secrets";
import {
  assertVideoEnhancementAvailable,
  authorizePhotoEnhancement,
  authorizeVideoEnhancement,
  releasePhotoEnhancement,
  releaseVideoEnhancement,
  VideoUsageReservation,
} from "../utils/premiumEntitlements";
import {assertAppVersionSupported} from "../utils/versionCheck";

if (!admin.apps.length) admin.initializeApp();

const execFileAsync = promisify(execFile);
const imageBase = "https://api.topazlabs.com/image/v1";
const videoBase = "https://api.topazlabs.com/video";
const photoCollection = "topazPhotoJobs";
const videoCollection = "topazVideoJobs";
const maxPhotoBytes = 10 * 1024 * 1024;
const backgroundRemovalPendingLimitMs = 10 * 60 * 1000;
const maxVideoBytes = 75 * 1024 * 1024;
const historyCollection = "enhancements";
const backgroundRemovalModel = "gpt-image-2.5-sunburst";
const backgroundRemovalPrompt = `Extract the main subject from the input image and
isolate it on a fully transparent background. Preserve the subject's exact identity,
geometry, colors, texture, text, pose, and fine details. Do not stylize, cartoonify,
smooth skin, or redraw the subject. Retain natural photorealistic textures, lighting,
and original pixel details. Produce clean alpha edges without halos or fringing.
Do not add a backdrop, checkerboard, scenery, shadow, new objects, or styling.
Remove only the background.`;

type PhotoStyle = {
  model: string;
  endpoint: string;
  extension: "jpg" | "png";
  parameters?: Record<string, string>;
};
const photoStyles: Record<string, PhotoStyle> = {
  auto: {model: "Wonder 3.5", endpoint: "enhance-gen", extension: "jpg"},
  precision: {model: "Standard V2", endpoint: "enhance",
    extension: "jpg"},
  creative: {model: "Bloom 2", endpoint: "enhance-gen", extension: "jpg",
    parameters: {creativity: "6"}},
  sharpen: {model: "Standard", endpoint: "sharpen", extension: "jpg"},
  denoise: {model: "Denoise Max", endpoint: "denoise-gen", extension: "jpg"},
  restore: {model: "Dust-Scratch V2", endpoint: "restore-gen", extension: "jpg"},
  remove_background: {model: backgroundRemovalModel, endpoint: "images/edits",
    extension: "png"},
  relight: {model: "Adjust V2", endpoint: "lighting", extension: "jpg"},
  color_balance: {model: "White Balance", endpoint: "lighting", extension: "jpg",
    parameters: {colorCorrection: "true"}},
  colorize: {model: "Colorize", endpoint: "lighting", extension: "jpg",
    parameters: {saturation: "0.5"}},
};

type VideoStyle = {model: string; upscale: boolean; hdr?: boolean; slowmo?: boolean};
const videoStyles: Record<string, VideoStyle> = {
  auto: {model: "pnat-1", upscale: true},
  precision: {model: "prob-4", upscale: true},
  creative: {model: "ast-2", upscale: true},
  denoise: {model: "nxhf-1", upscale: false},
  slow_motion: {model: "apo-8", upscale: false, slowmo: true},
  motion_deblur: {model: "thm-2", upscale: false},
  hdr: {model: "hyp-2.5", upscale: false, hdr: true},
  colorize: {model: "color-1", upscale: false},
};

function selectedStyle<T>(
  value: unknown, styles: Record<string, T>, media: string,
): {category: string; style: T} {
  // Missing values retain compatibility with app versions predating the picker.
  const category = value === undefined ? "auto" : value;
  if (typeof category !== "string" ||
      !Object.prototype.hasOwnProperty.call(styles, category)) {
    throw new HttpsError("invalid-argument", `Choose a valid ${media} style.`);
  }
  return {category, style: styles[category]};
}

type Json = Record<string, unknown>;

// Server diagnostics are opt-in or requested by a debug app build.
const debugEnhancer = process.env.MEDIA_DEBUG_LOGS === "true" ||
  process.env.FUNCTIONS_EMULATOR === "true";

function debugFor(request: {data?: unknown}): boolean {
  const data = request.data;
  return debugEnhancer || (typeof data === "object" && data !== null &&
    (data as Json).debug === true);
}

function trace(stage: string, details: Record<string, string | number | boolean> = {},
  debug = false) {
  if (debugEnhancer || debug) console.info("[Enhancer]", stage, details);
}

function errorType(error: unknown): string {
  return error instanceof HttpsError ? error.code :
    error instanceof Error ? error.name : "unknown";
}

function safeProviderText(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const text = value.replace(/https?:\/\/\S+/gi, "[url]")
    .replace(/\b(api[_-]?key|authorization|bearer|token)\s*[:=]\s*[^\s,;]+/gi,
      "$1=[redacted]")
    .replace(/[A-Za-z0-9_-]{40,}/g, "[redacted]")
    .replace(/\s+/g, " ").trim();
  return text ? text.slice(0, 240) : undefined;
}

function providerDiagnostics(data: Json) {
  const error = data.error;
  const errorData = typeof error === "object" && error !== null ?
    error as Json : {};
  const detail = data.detail;
  const firstDetail = Array.isArray(detail) ? detail[0] : undefined;
  const detailData = typeof firstDetail === "object" && firstDetail !== null ?
    firstDetail as Json : {};
  return {
    providerCode: safeProviderText(errorData.code || data.code ||
      detailData.type),
    providerMessage: safeProviderText(data.message || errorData.message ||
      data.failure_reason || data.failureReason || data.reason ||
      detailData.msg || (typeof detail === "string" ? detail : error)),
  };
}

async function photoStage<T>(stage: string, debug: boolean,
  operation: () => Promise<T>): Promise<T> {
  trace("photo step started", {stage}, debug);
  try {
    const result = await operation();
    trace("photo step completed", {stage}, debug);
    return result;
  } catch (error) {
    const errorMessage = error instanceof Error ?
      safeProviderText(error.message) : undefined;
    trace("photo step failed", {stage, errorType: errorType(error),
      ...(errorMessage ? {message: errorMessage} : {})}, debug);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Could not prepare photo enhancement.",
      debug ? {reason: "PHOTO_STAGE_FAILED", stage,
        errorType: errorType(error), errorMessage} : undefined);
  }
}

function uploadSigningFailureReason(error: unknown): string {
  const message = error instanceof Error ? error.message : "";
  if (/iam\.serviceAccounts\.signBlob/i.test(message)) {
    return "SIGN_BLOB_PERMISSION_DENIED";
  }
  if (/iamcredentials\.googleapis\.com/i.test(message)) {
    return "IAM_CREDENTIALS_API_UNAVAILABLE";
  }
  if (/bucket/i.test(message) && /not found|does not exist/i.test(message)) {
    return "STORAGE_BUCKET_NOT_FOUND";
  }
  return "UPLOAD_URL_SIGNING_FAILED";
}

function uidOf(request: {auth?: {uid: string}}): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to enhance media.");
  }
  return request.auth.uid;
}

function topazKey(): string {
  const key = TOPAZ_API_KEY.value() || process.env.TOPAZ_API_KEY || "";
  if (!key) {
    throw new HttpsError("failed-precondition", "Topaz API key is not configured.");
  }
  return key;
}

function openAiImageKey(): string {
  const key = IMAGE_GEN_API_KEY.value() || OPENAI_API_KEY.value() ||
    process.env.IMAGE_GEN_API_KEY || process.env.OPENAI_API_KEY || "";
  if (!key) {
    throw new HttpsError("failed-precondition",
      "OpenAI image API key is not configured.");
  }
  return key;
}

function isPng(buffer: Buffer): boolean {
  return buffer.length >= 26 && buffer.subarray(0, 8).equals(Buffer.from(
    [137, 80, 78, 71, 13, 10, 26, 10]));
}

function pngHasAlpha(buffer: Buffer): boolean {
  if (!isPng(buffer)) return false;
  const colorType = buffer[25];
  return colorType === 4 || colorType === 6 || buffer.includes(Buffer.from("tRNS"));
}

async function removeBackgroundWithOpenAi(
  bytes: Buffer, mimeType: string, filename: string, debug: boolean,
): Promise<Buffer> {
  const form = new FormData();
  form.append("image", new Blob([Uint8Array.from(bytes)], {type: mimeType}),
    filename);
  form.append("model", backgroundRemovalModel);
  form.append("prompt", backgroundRemovalPrompt);
  form.append("size", "auto");
  form.append("quality", "high");
  form.append("background", "transparent");
  form.append("output_format", "png");
  form.append("n", "1");

  const endpoint = "/v1/images/edits";
  const startedAt = Date.now();
  trace("background removal request", {endpoint,
    model: backgroundRemovalModel}, debug);
  let response: Response;
  try {
    response = await fetch(`https://api.openai.com${endpoint}`, {
      method: "POST",
      headers: {Authorization: `Bearer ${openAiImageKey()}`},
      body: form,
      signal: AbortSignal.timeout(280000),
    });
  } catch (error) {
    trace("background removal network failed", {endpoint,
      errorType: errorType(error)}, debug);
    throw new HttpsError("unavailable",
      "Could not connect to the background removal provider.",
      debug ? {reason: "OPENAI_NETWORK_ERROR", stage: "openai_request",
        endpoint, errorType: errorType(error)} : undefined);
  }

  const body = await response.text();
  trace("background removal response", {endpoint, status: response.status,
    durationMs: Date.now() - startedAt}, debug);
  let data: Json = {};
  try {
    const parsed: unknown = JSON.parse(body);
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      data = parsed as Json;
    }
  } catch {
    // The error below reports a safe provider summary in debug builds.
  }
  if (!response.ok) {
    const diagnostic = providerDiagnostics(data);
    throw new HttpsError(response.status === 429 ? "resource-exhausted" :
      "internal", `Background removal request failed (HTTP ${response.status}).`,
    debug ? {reason: "OPENAI_HTTP_ERROR", stage: "openai_request", endpoint,
      httpStatus: response.status, ...diagnostic} : undefined);
  }

  const images = data.data;
  const first = Array.isArray(images) && images.length > 0 &&
    typeof images[0] === "object" && images[0] !== null ? images[0] as Json : {};
  const encoded = typeof first.b64_json === "string" ? first.b64_json : "";
  if (!encoded) {
    throw new HttpsError("internal",
      "Background removal provider returned no image.",
      debug ? {reason: "OPENAI_MISSING_IMAGE", stage: "openai_response"} :
        undefined);
  }
  const result = Buffer.from(encoded, "base64");
  if (!pngHasAlpha(result)) {
    throw new HttpsError("internal",
      "Background removal provider did not return a transparent PNG.",
      debug ? {reason: "OPENAI_INVALID_TRANSPARENT_PNG",
        stage: "openai_response"} : undefined);
  }
  return result;
}

function requireId(value: unknown): string {
  if (typeof value !== "string" || !/^[a-zA-Z0-9-]{16,80}$/.test(value)) {
    throw new HttpsError("invalid-argument", "Invalid enhancement job ID.");
  }
  return value;
}

async function topazJson(
  url: string,
  key: string,
  options: RequestInit = {},
  debug = false,
): Promise<Json> {
  const endpoint = new URL(url).pathname;
  const method = options.method || "GET";
  const start = Date.now();
  trace("provider request", {method, endpoint}, debug);
  let response: Response;
  try {
    response = await fetch(url, {
      ...options,
      headers: {"X-API-Key": key, ...options.headers},
      signal: AbortSignal.timeout(60000),
    });
  } catch (error) {
    trace("provider network failed", {method, endpoint, type: errorType(error)},
      debug);
    throw new HttpsError("unavailable", "Could not connect to enhancement provider.",
      debug ? {reason: "PROVIDER_NETWORK_ERROR", stage: "topaz_request",
        endpoint, errorType: errorType(error)} : undefined);
  }
  const body = await response.text();
  trace("provider response", {method, endpoint,
    status: response.status, durationMs: Date.now() - start}, debug);
  let data: Json = {};
  try {
    const parsed: unknown = JSON.parse(body);
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      data = parsed as Json;
    }
  } catch {
    // Plain-text API error.
  }
  if (!response.ok) {
    const diagnostic = providerDiagnostics(data);
    const providerMessage = diagnostic.providerMessage ||
      (debug ? safeProviderText(body) : undefined);
    trace("provider rejected", {endpoint, httpStatus: response.status,
      ...(diagnostic.providerCode ? {providerCode: diagnostic.providerCode} : {}),
      ...(providerMessage ? {providerMessage} : {})}, debug);
    throw new HttpsError(
      response.status === 402 ? "resource-exhausted" : "internal",
      `Enhancement provider request failed (HTTP ${response.status}).`,
      {reason: "PROVIDER_HTTP_ERROR",
        ...(debug ? {stage: "topaz_request", endpoint,
          httpStatus: response.status, ...diagnostic,
          ...(providerMessage ? {providerMessage} : {})} : {})},
    );
  }
  trace("provider response parsed", {endpoint,
    responseKeys: Object.keys(data).join(",")}, debug);
  return data;
}

async function ownedJob(uid: string, collection: string, id: string) {
  const ref = admin.firestore().collection(collection).doc(id);
  const snapshot = await ref.get();
  if (!snapshot.exists || snapshot.get("uid") !== uid) {
    throw new HttpsError("not-found", "Enhancement job not found.");
  }
  return {ref, data: snapshot.data() as Json};
}

function permanentUrl(filePath: string, token: string): string {
  const bucket = admin.storage().bucket();
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
    `${encodeURIComponent(filePath)}?alt=media&token=${token}`;
}

function historyRef(uid: string, id: string) {
  return admin.firestore().collection("users").doc(uid)
    .collection(historyCollection).doc(id);
}

/** Start the selected one-file image transformation. */
export const startPhotoEnhancement = onCall({
  secrets: [TOPAZ_API_KEY, IMAGE_GEN_API_KEY, OPENAI_API_KEY],
  timeoutSeconds: 300, memory: "1GiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  await assertAppVersionSupported(request.data?.buildNumber);
  const {category, style} = selectedStyle(request.data?.category,
    photoStyles, "photo");
  const encoded = request.data?.imageBase64;
  const mimeType = request.data?.mimeType;
  if (typeof encoded !== "string" || encoded.length > maxPhotoBytes * 1.4 ||
      !["image/jpeg", "image/png", "image/tiff", "image/webp"].includes(mimeType)) {
    throw new HttpsError("invalid-argument", "Choose a JPEG, PNG, WEBP, or TIFF under 10 MB.");
  }
  const bytes = Buffer.from(encoded, "base64");
  trace("photo start", {bytes: bytes.length, category, mimeType,
    model: style.model, endpoint: style.endpoint}, debug);
  if (bytes.length === 0 || bytes.length > maxPhotoBytes) {
    throw new HttpsError("invalid-argument", "Photo must be under 10 MB.");
  }
  const usageReservation = await authorizePhotoEnhancement(uid);
  const filename = mimeType === "image/png" ? "photo.png" :
    mimeType === "image/tiff" ? "photo.tiff" :
    mimeType === "image/webp" ? "photo.webp" : "photo.jpg";
  if (category === "remove_background") {
    const processId = crypto.randomUUID();
    let result: Buffer;
    try {
      result = await photoStage("openai_background_removal", debug, () =>
        removeBackgroundWithOpenAi(bytes, mimeType, filename, debug));
    } catch (error) {
      await releasePhotoEnhancement(uid, usageReservation).catch(
        (releaseError) => trace("photo allowance release failed",
          {type: errorType(releaseError)}, debug));
      throw error;
    }
    const originalExtension = mimeType === "image/png" ? "png" :
      mimeType === "image/tiff" ? "tiff" :
      mimeType === "image/webp" ? "webp" : "jpg";
    const originalPath = `users/${uid}/enhancer_originals/photos/` +
      `${processId}.${originalExtension}`;
    const resultPath = `users/${uid}/enhanced_photos/${processId}.png`;
    const originalToken = crypto.randomUUID();
    const resultToken = crypto.randomUUID();
    const bucket = admin.storage().bucket();
    await photoStage("background_storage", debug, async () => {
      await Promise.all([
        bucket.file(originalPath).save(bytes, {metadata: {
          contentType: mimeType,
          metadata: {firebaseStorageDownloadTokens: originalToken},
        }}),
        bucket.file(resultPath).save(result, {metadata: {
          contentType: "image/png",
          metadata: {firebaseStorageDownloadTokens: resultToken, uid,
            openAiModel: backgroundRemovalModel},
        }}),
      ]);
    });
    const originalUrl = permanentUrl(originalPath, originalToken);
    const resultUrl = permanentUrl(resultPath, resultToken);
    await photoStage("background_records", debug, async () => {
      const batch = admin.firestore().batch();
      batch.set(admin.firestore().collection(photoCollection).doc(processId), {
        uid, status: "Completed", progress: 100,
        model: backgroundRemovalModel, provider: "openai", category,
        resultExtension: "png", originalPath, originalUrl, resultPath,
        resultUrl, createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      batch.set(historyRef(uid, processId), {
        type: "photo", status: "complete", category, originalUrl, originalPath,
        resultUrl, resultPath, provider: "openai", model: backgroundRemovalModel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await batch.commit();
    });
    trace("background removal completed", {bytes: result.length,
      model: backgroundRemovalModel}, debug);
    return {jobId: processId};
  }
  const form = new FormData();
  form.append("image", new Blob([bytes], {type: mimeType}),
    filename);
  form.append("model", style.model);
  form.append("output_format", style.extension === "png" ? "png" : "jpeg");
  for (const [name, value] of Object.entries(style.parameters || {})) {
    form.append(name, value);
  }
  trace("photo request configured", {category, model: style.model,
    endpoint: style.endpoint,
    outputFormat: style.extension === "png" ? "png" : "jpeg",
    parameters: JSON.stringify(style.parameters || {})}, debug);
  let result: Json;
  try {
    result = await photoStage("topaz_submit", debug, () => topazJson(
      `${imageBase}/${style.endpoint}/async`, topazKey(),
      {method: "POST", body: form}, debug));
  } catch (error) {
    await releasePhotoEnhancement(uid, usageReservation).catch(
      (releaseError) => trace("photo allowance release failed",
        {type: errorType(releaseError)}, debug));
    throw error;
  }
  if (typeof result.process_id !== "string") {
    await releasePhotoEnhancement(uid, usageReservation).catch(
      (releaseError) => trace("photo allowance release failed",
        {type: errorType(releaseError)}, debug));
    throw new HttpsError("internal", "Topaz did not return a photo job ID.",
      debug ? {reason: "PROVIDER_MISSING_PROCESS_ID",
        stage: "topaz_response",
        responseKeys: Object.keys(result).join(",")} : undefined);
  }
  const processId = requireId(result.process_id);
  const extension = mimeType === "image/png" ? "png" :
    mimeType === "image/tiff" ? "tiff" :
    mimeType === "image/webp" ? "webp" : "jpg";
  const originalPath = `users/${uid}/enhancer_originals/photos/${processId}.${extension}`;
  const originalToken = crypto.randomUUID();
  await photoStage("original_storage", debug, () =>
    admin.storage().bucket().file(originalPath).save(bytes, {
      metadata: {contentType: mimeType, metadata: {
        firebaseStorageDownloadTokens: originalToken,
      }},
    }));
  const originalUrl = permanentUrl(originalPath, originalToken);
  await photoStage("job_record", debug, () =>
    admin.firestore().collection(photoCollection).doc(processId).set({
      uid, status: "Pending", model: style.model, category,
      resultExtension: style.extension, originalPath, originalUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
  await photoStage("history_record", debug, () =>
    historyRef(uid, processId).set({
      type: "photo", status: "processing", category, originalUrl, originalPath,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
  trace("photo queued", {jobCreated: true}, debug);
  return {jobId: processId};
});

/** Poll the image job and copy its expiring result into durable Storage. */
export const getPhotoEnhancementStatus = onCall({
  secrets: [TOPAZ_API_KEY], timeoutSeconds: 120, memory: "512MiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  const id = requireId(request.data?.jobId);
  const job = await photoStage("job_lookup", debug, () =>
    ownedJob(uid, photoCollection, id));
  if (typeof job.data.resultUrl === "string") {
    return {status: "Completed", progress: 100, resultUrl: job.data.resultUrl,
      originalUrl: job.data.originalUrl, category: job.data.category};
  }
  const key = topazKey();
  const state = await photoStage("topaz_status", debug, () =>
    topazJson(`${imageBase}/status/${id}`, key, {}, debug));
  const status = String(state.status || "Pending");
  const progress = Number(state.progress || 0);
  trace("photo status", {status, progress}, debug);
  if (status === "Completed") {
    const download = await photoStage("topaz_download_link", debug, () =>
      topazJson(`${imageBase}/download/${id}`, key, {}, debug));
    const signedUrl = download.url || download.download_url;
    if (typeof signedUrl !== "string" || !signedUrl) {
      throw new HttpsError("internal", "Topaz did not return the enhanced photo.");
    }
    const buffer = await photoStage("result_download", debug, async () => {
      const response = await fetch(signedUrl, {
        signal: AbortSignal.timeout(60000),
      });
      trace("photo result download", {status: response.status}, debug);
      if (!response.ok) {
        throw new HttpsError("internal", "Could not download enhanced photo.",
          debug ? {reason: "PHOTO_DOWNLOAD_HTTP_ERROR",
            stage: "result_download", httpStatus: response.status} : undefined);
      }
      return Buffer.from(await response.arrayBuffer());
    });
    const extension = job.data.resultExtension === "png" ? "png" : "jpg";
    if (extension === "png" &&
        !buffer.subarray(0, 8).equals(Buffer.from(
          [137, 80, 78, 71, 13, 10, 26, 10]))) {
      throw new HttpsError("internal", "Topaz did not return a PNG image.");
    }
    if (buffer.length > 50 * 1024 * 1024) {
      throw new HttpsError("resource-exhausted", "Enhanced photo is too large.");
    }
    const contentType = extension === "png" ? "image/png" : "image/jpeg";
    const filePath = `users/${uid}/enhanced_photos/${id}.${extension}`;
    const token = crypto.randomUUID();
    await photoStage("result_storage", debug, () =>
      admin.storage().bucket().file(filePath).save(buffer, {
        metadata: {contentType, metadata: {
          firebaseStorageDownloadTokens: token, uid,
          topazModel: String(job.data.model),
        }},
      }));
    const resultUrl = permanentUrl(filePath, token);
    await photoStage("job_completion", debug, () =>
      job.ref.update({status, progress: 100, resultUrl}));
    await photoStage("history_completion", debug, () =>
      historyRef(uid, id).set({
        status: "complete", resultUrl, resultPath: filePath,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true}));
    trace("photo archived", {bytes: buffer.length}, debug);
    return {status, progress: 100, resultUrl,
      originalUrl: job.data.originalUrl, category: job.data.category};
  }
  const createdAt = job.data.createdAt;
  const submittedAtMs = createdAt instanceof admin.firestore.Timestamp ?
    createdAt.toMillis() : null;
  if (job.data.category === "remove_background" && status === "Pending" &&
      progress === 0 && submittedAtMs !== null &&
      Date.now() - submittedAtMs >= backgroundRemovalPendingLimitMs) {
    const message = "Background removal is taking too long at Topaz. Please try again.";
    trace("background removal stalled", {jobId: id,
      pendingMs: Date.now() - submittedAtMs}, debug);
    await photoStage("job_timeout", debug, () =>
      job.ref.update({status: "Failed", progress: 0,
        failureReason: "PROVIDER_STALLED"}));
    await photoStage("history_timeout", debug, () =>
      historyRef(uid, id).set({status: "failed"}, {merge: true}));
    return {status: "Failed", progress: 0, message,
      originalUrl: job.data.originalUrl,
      ...(debug ? {debugFailure: {reason: "PROVIDER_STALLED",
        category: "remove_background", model: String(job.data.model),
        pendingMs: Date.now() - submittedAtMs}} : {})};
  }
  await photoStage("job_progress", debug, () => job.ref.update({status, progress}));
  if (status === "Failed" || status === "Cancelled") {
    const diagnostic = providerDiagnostics(state);
    const debugFailure = debug ? {
      reason: "PROVIDER_JOB_FAILED", jobId: id,
      category: String(job.data.category || "unknown"),
      model: String(job.data.model || "unknown"),
      responseKeys: Object.keys(state).join(","),
      ...(typeof state.output_format === "string" ?
        {outputFormat: safeProviderText(state.output_format) || "unknown"} : {}),
      ...(diagnostic.providerCode ?
        {providerCode: diagnostic.providerCode} : {}),
      ...(diagnostic.providerMessage ?
        {providerMessage: diagnostic.providerMessage} : {}),
    } : undefined;
    trace("photo provider job failed", debugFailure || {status}, debug);
    await photoStage("history_failure", debug, () =>
      historyRef(uid, id).set({status: "failed"}, {merge: true}));
    return {status, progress, originalUrl: job.data.originalUrl,
      ...(debugFailure ? {debugFailure} : {})};
  }
  return {status, progress, originalUrl: job.data.originalUrl};
});

/** Obtain a short-lived user-scoped upload URL; no Storage rules are assumed. */
export const prepareVideoEnhancementUpload = onCall({
  timeoutSeconds: 60, memory: "256MiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  await assertAppVersionSupported(request.data?.buildNumber);
  await assertVideoEnhancementAvailable(uid);
  const size = Number(request.data?.size);
  trace("video upload prepare", {bytes: size}, debug);
  if (!Number.isInteger(size) || size <= 0 || size > maxVideoBytes) {
    throw new HttpsError("invalid-argument", "Choose an MP4 video under 75 MB.");
  }
  const uploadId = crypto.randomUUID();
  const filePath = `users/${uid}/enhancer_uploads/${uploadId}.mp4`;
  let uploadUrl: string;
  try {
    [uploadUrl] = await admin.storage().bucket().file(filePath).getSignedUrl({
      version: "v4", action: "write", expires: Date.now() + 15 * 60 * 1000,
      contentType: "video/mp4",
    });
  } catch (error) {
    const reason = uploadSigningFailureReason(error);
    trace("video upload signing failed", {type: errorType(error), reason}, debug);
    throw new HttpsError("internal", "Could not prepare video upload.", {reason});
  }
  trace("video upload prepared", {}, debug);
  return {uploadId, uploadUrl};
});

function video1080pDimensions(width: number, height: number) {
  const landscape = width >= height;
  const maxWidth = landscape ? 1920 : 1080;
  const maxHeight = landscape ? 1080 : 1920;
  const factor = Math.min(2, maxWidth / width, maxHeight / height);
  return {
    width: Math.max(4, Math.floor(width * factor / 4) * 4),
    height: Math.max(4, Math.floor(height * factor / 4) * 4),
  };
}

function video1080pFrame(width: number, height: number) {
  return width >= height ?
    {width: 1920, height: 1080} :
    {width: 1080, height: 1920};
}

async function probeVideo(localPath: string) {
  if (!ffmpegPath) throw new HttpsError("internal", "Video probe is unavailable.");
  let report = "";
  try {
    await execFileAsync(ffmpegPath, ["-hide_banner", "-i", localPath], {
      timeout: 30000, maxBuffer: 1024 * 1024,
    });
  } catch (error) {
    report = String((error as {stderr?: string}).stderr || "");
  }
  const duration = /Duration:\s*(\d+):(\d+):([\d.]+)/.exec(report);
  const video = /Video:[^\n]*?(\d{2,5})x(\d{2,5})[^\n]*?(\d+(?:\.\d+)?) fps/.exec(report);
  if (!duration || !video) {
    throw new HttpsError("invalid-argument", "Could not read MP4 video metadata.");
  }
  const seconds = Number(duration[1]) * 3600 + Number(duration[2]) * 60 +
    Number(duration[3]);
  const width = Number(video[1]);
  const height = Number(video[2]);
  const frameRate = Number(video[3]);
  if (seconds <= 0 || frameRate <= 0 || width <= 0 || height <= 0) {
    throw new HttpsError("invalid-argument", "Invalid MP4 video metadata.");
  }
  return {seconds, width, height, frameRate,
    frameCount: Math.round(seconds * frameRate)};
}

/** Create a provider request using the selected video capability. */
export const createVideoEnhancement = onCall({
  secrets: [TOPAZ_API_KEY], timeoutSeconds: 120, memory: "512MiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  await assertAppVersionSupported(request.data?.buildNumber);
  const {category, style} = selectedStyle(request.data?.category,
    videoStyles, "video");
  const uploadId = requireId(request.data?.uploadId);
  const filePath = `users/${uid}/enhancer_uploads/${uploadId}.mp4`;
  const file = admin.storage().bucket().file(filePath);
  const [metadata] = await file.getMetadata();
  const size = Number(metadata.size);
  trace("video create", {bytes: size, category}, debug);
  if (size <= 0 || size > maxVideoBytes || metadata.contentType !== "video/mp4") {
    throw new HttpsError("invalid-argument", "Choose an MP4 video under 75 MB.");
  }
  let usageReservation: VideoUsageReservation | null = null;
  try {
    usageReservation = await authorizeVideoEnhancement(uid);
    const originalToken = crypto.randomUUID();
    await file.setMetadata({metadata: {
      firebaseStorageDownloadTokens: originalToken,
    }});
    const originalUrl = permanentUrl(filePath, originalToken);
    const localPath = path.join(os.tmpdir(), `${uploadId}.mp4`);
    let source;
    try {
      await file.download({destination: localPath});
      source = await probeVideo(localPath);
      trace("video probed", {width: source.width, height: source.height,
        seconds: Math.round(source.seconds), frames: source.frameCount}, debug);
    } finally {
      await fs.rm(localPath, {force: true});
    }
    // Astra is an end-to-end generative pipeline documented around standard
    // 1080p frames. Colorization enforces the same minimum.
    const model = style.model;
    const requires1080pFrame = model === "ast-2" || model === "color-1";
    const output = requires1080pFrame ?
      video1080pFrame(source.width, source.height) :
      style.upscale ? video1080pDimensions(source.width, source.height) :
        {width: source.width, height: source.height};
    trace("video output selected", {width: output.width,
      height: output.height}, debug);
    const filter = style.slowmo ?
      {model, slowmo: 2, fps: source.frameRate} : {model};
    trace("video model selected", {category, model}, debug);
    const outputSettings = {
      container: "mp4", resolution: output,
      frameRate: source.frameRate, audioTransfer: "Copy", audioCodec: "AAC",
      videoEncoder: "H264", videoProfile: "High",
      dynamicCompressionLevel: "High",
      ...(requires1080pFrame ? {cropToFit: true} : {}),
    };
    trace("video output configured", {encoder: outputSettings.videoEncoder,
      profile: outputSettings.videoProfile}, debug);
    const result = await topazJson(`${videoBase}/`, topazKey(), {
      method: "POST", headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        source: {container: "mp4", size, duration: source.seconds,
          frameCount: source.frameCount, frameRate: source.frameRate,
          resolution: {width: source.width, height: source.height}},
        filters: [filter],
        output: outputSettings,
      }),
    }, debug);
    const requestId = requireId(result.requestId);
    await admin.firestore().collection(videoCollection).doc(requestId).set({
      uid, uploadId, filePath, size, status: "requested", category,
      model,
      freeUsageCounted: usageReservation.counted,
      originalUrl,
      estimates: result.estimates || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await historyRef(uid, requestId).set({
      type: "video", status: "requested", category, originalUrl,
      originalPath: filePath,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    trace("video request created", {}, debug);
    return {jobId: requestId, estimates: result.estimates || {}};
  } catch (error) {
    trace("video create failed", {type: errorType(error)}, debug);
    await releaseVideoEnhancement(uid, usageReservation).catch(
      (releaseError) => trace("video allowance release failed",
        {type: errorType(releaseError)}, debug));
    await file.delete({ignoreNotFound: true}).catch((cleanupError) =>
      trace("video cleanup failed", {type: errorType(cleanupError)}, debug));
    throw error;
  }
});

/** Release a source upload when the user declines the no-charge estimate. */
export const discardVideoEnhancement = onCall({
  timeoutSeconds: 60, memory: "256MiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  const id = requireId(request.data?.jobId);
  const job = await ownedJob(uid, videoCollection, id);
  if (job.data.status !== "requested") {
    throw new HttpsError("failed-precondition", "Enhancement is already underway.");
  }
  await admin.storage().bucket().file(String(job.data.filePath)).delete({
    ignoreNotFound: true,
  });
  await job.ref.update({status: "discarded"});
  await historyRef(uid, id).set({status: "discarded"}, {merge: true});
  trace("video request discarded", {}, debug);
  return {discarded: true};
});

/** Cancel a queued or processing provider request and release its source file. */
export const cancelVideoEnhancement = onCall({
  secrets: [TOPAZ_API_KEY], timeoutSeconds: 120, memory: "256MiB",
  invoker: "public",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  const id = requireId(request.data?.jobId);
  const job = await ownedJob(uid, videoCollection, id);
  const currentStatus = String(job.data.status || "").toLowerCase();
  if (currentStatus === "canceled" || currentStatus === "cancelled" ||
      currentStatus === "discarded") {
    return {canceled: true};
  }
  if (currentStatus === "complete" || currentStatus === "completed" ||
      typeof job.data.resultUrl === "string") {
    throw new HttpsError("failed-precondition",
      "Completed video enhancements cannot be canceled.");
  }

  const providerState = await topazJson(`${videoBase}/${id}/status`, topazKey(),
    {}, debug);
  const providerStatus = String(providerState.status || "").toLowerCase();
  const providerProgress = Number(providerState.progress || 0);
  if (providerStatus === "complete" || providerStatus === "completed" ||
      providerProgress >= 100) {
    trace("video cancellation skipped", {providerStatus, providerProgress}, debug);
    return {canceled: false, reason: "already_processed"};
  }

  await topazJson(`${videoBase}/${id}`, topazKey(), {method: "DELETE"}, debug);
  const filePath = typeof job.data.filePath === "string" ? job.data.filePath : null;
  if (filePath) {
    await admin.storage().bucket().file(filePath).delete({ignoreNotFound: true})
      .catch((error) => trace("canceled video cleanup failed",
        {type: errorType(error)}, debug));
  }
  await job.ref.update({
    status: "canceled",
    canceledAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await historyRef(uid, id).set({
    status: "canceled",
    canceledAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  trace("video request canceled", {}, debug);
  return {canceled: true};
});

/** Reserve Topaz credits, transfer the video, and queue enhancement. */
export const acceptVideoEnhancement = onCall({
  secrets: [TOPAZ_API_KEY], timeoutSeconds: 540, memory: "1GiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  const id = requireId(request.data?.jobId);
  const job = await ownedJob(uid, videoCollection, id);
  if (job.data.status !== "requested" && job.data.status !== "accepted") {
    throw new HttpsError("failed-precondition", "This enhancement was already accepted.");
  }
  const key = topazKey();
  const accepted = await topazJson(`${videoBase}/${id}/accept`, key,
    {method: "PATCH"}, debug);
  const urls = accepted.urls;
  trace("video request accepted",
    {uploadParts: Array.isArray(urls) ? urls.length : 0}, debug);
  if (!Array.isArray(urls) || urls.length !== 1 || typeof urls[0] !== "string") {
    throw new HttpsError("internal", "Topaz returned an unsupported upload response.");
  }
  await job.ref.update({status: "accepted"});
  const [bytes] = await admin.storage().bucket().file(String(job.data.filePath)).download();
  trace("video source read", {bytes: bytes.length}, debug);
  let uploadResponse: Response;
  try {
    uploadResponse = await fetch(urls[0], {
      method: "PUT", headers: {"Content-Type": "video/mp4"},
      body: new Uint8Array(bytes),
      signal: AbortSignal.timeout(300000),
    });
  } catch (error) {
    trace("video provider upload failed", {type: errorType(error)}, debug);
    throw new HttpsError("unavailable", "Video transfer to enhancement provider failed.");
  }
  trace("video provider upload", {status: uploadResponse.status}, debug);
  if (!uploadResponse.ok) {
    throw new HttpsError("internal", "Could not upload video to Topaz.");
  }
  const eTag = uploadResponse.headers.get("etag");
  if (!eTag) {
    throw new HttpsError("internal", "Video transfer confirmation is missing.");
  }
  await topazJson(`${videoBase}/${id}/complete-upload/`, key, {
    method: "PATCH", headers: {"Content-Type": "application/json"},
    body: JSON.stringify({uploadResults: [{partNum: 1, eTag}]}),
  }, debug);
  await job.ref.update({status: "processing"});
  await historyRef(uid, id).set({status: "processing"}, {merge: true});
  trace("video processing queued", {}, debug);
  return {jobId: id};
});

/** Return current video progress and Topaz's time-limited output URL. */
export const getVideoEnhancementStatus = onCall({
  secrets: [TOPAZ_API_KEY], timeoutSeconds: 540, memory: "1GiB",
}, async (request) => {
  const debug = debugFor(request);
  const uid = uidOf(request);
  const id = requireId(request.data?.jobId);
  const job = await ownedJob(uid, videoCollection, id);
  if (typeof job.data.resultUrl === "string" &&
      job.data.resultUrl.includes("firebasestorage.googleapis.com")) {
    return {status: "complete", progress: 100, resultUrl: job.data.resultUrl,
      originalUrl: job.data.originalUrl, category: job.data.category};
  }
  const state = await topazJson(`${videoBase}/${id}/status`, topazKey(),
    {}, debug);
  const status = String(state.status || "processing");
  const progress = Number(state.progress || 0);
  const providerMessage = safeProviderText(state.message);
  const model = typeof job.data.model === "string" ? job.data.model : "unknown";
  trace("video status", {status, progress, model,
    ...(providerMessage ? {providerMessage} : {})}, debug);
  const metricsTimestamp = job.data.metricsCheckedAt as
    {toMillis?: () => number} | undefined;
  const lastMetricsCheck = typeof metricsTimestamp?.toMillis === "function" ?
    metricsTimestamp.toMillis() : 0;
  if (debug && (status === "initializing" || status === "processing") &&
      Date.now() - lastMetricsCheck >= 60000) {
    try {
      const metrics = await topazJson(`${videoBase}/${id}/metrics`, topazKey(),
        {}, debug);
      const minutesInState = safeProviderText(JSON.stringify(
        metrics.minutesInState || {}));
      trace("video metrics", {
        ...(minutesInState ? {minutesInState} : {}),
        inputFrames: Number(metrics.inputFrames || 0),
        outputFrames: Number(metrics.outputFrames || 0),
        chunks: Array.isArray(metrics.chunks) ? metrics.chunks.length : 0,
      }, debug);
      await job.ref.update({
        metricsCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      trace("video metrics unavailable", {type: errorType(error)}, debug);
    }
  }
  const download = state.download as Json | undefined;
  let resultUrl = null;
  if (status === "complete" && download && typeof download.url === "string") {
    const resultPath = `users/${uid}/enhanced_videos/${id}.mp4`;
    const resultFile = admin.storage().bucket().file(resultPath);
    const [exists] = await resultFile.exists();
    if (!exists) {
      const response = await fetch(download.url, {
        signal: AbortSignal.timeout(480000),
      });
      trace("video result download", {status: response.status}, debug);
      if (!response.ok || !response.body) {
        throw new HttpsError("internal", "Could not archive enhanced video.");
      }
      const token = crypto.randomUUID();
      await pipeline(
        Readable.fromWeb(response.body as unknown as
          import("stream/web").ReadableStream),
        resultFile.createWriteStream({metadata: {
          contentType: "video/mp4", metadata: {
            firebaseStorageDownloadTokens: token,
          },
        }}),
      );
      resultUrl = permanentUrl(resultPath, token);
    } else {
      const [metadata] = await resultFile.getMetadata();
      const token = String(metadata.metadata?.firebaseStorageDownloadTokens || "");
      if (!token) throw new HttpsError("internal", "Enhanced video access is unavailable.");
      resultUrl = permanentUrl(resultPath, token);
    }
    await job.ref.update({status, progress: 100, resultUrl});
    await historyRef(uid, id).set({
      status: "complete", resultUrl, resultPath,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    trace("video archived", {}, debug);
  } else {
    await job.ref.update({status, progress});
    if (status === "failed" || status === "canceled") {
      await historyRef(uid, id).set({status: "failed"}, {merge: true});
    }
  }
  return {status, progress, resultUrl, originalUrl: job.data.originalUrl,
    category: job.data.category, model,
    message: typeof state.message === "string" ? state.message : null};
});
