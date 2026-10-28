import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import * as crypto from "crypto";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { execFile } from "child_process";
import ffmpegPath from "ffmpeg-static";
import { HttpsError } from "firebase-functions/v2/https";

export interface MemeGenerationResult {
  success: boolean;
  url: string;
  imageUrl?: string;
  videoUrl?: string;
  caption: string;
  prompt: string;
  format: "image" | "video" | "gif";
  isVideo: boolean;
  isGif: boolean;
  isImage?: boolean;
  duration?: number;
  creditsUsed: number;
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

export class MemeService {
  constructor(
    private readonly memeApiKey: string,
    private readonly imageGenApiKey?: string,
  ) { }

  async generateMeme(
    uid: string,
    prompt: string,
    imageBase64?: string,
    mimeType?: string,
    format: "image" | "video" | "gif" = "image",
  ): Promise<MemeGenerationResult> {
    const cleanPrompt = (prompt || "").trim();
    if (!cleanPrompt) {
      throw new HttpsError("invalid-argument", "Prompt cannot be empty.");
    }

    // 1. If format is image, handle via OpenAI Image Gen / Image Edit
    if (format === "image") {
      return this.generateImageMeme(uid, cleanPrompt, imageBase64, mimeType);
    }

    // 2. Video / GIF meme generation via Veo / Gemini
    if (!this.memeApiKey || this.memeApiKey === "default_key") {
      throw new HttpsError(
        "internal",
        "MEME_API_KEY is not configured on Cloud Functions.",
      );
    }

    debugLog.log(
      `[MemeService] Starting meme generation for uid: ${uid}. ` +
      `Prompt: "${cleanPrompt}", HasImage: ${Boolean(imageBase64)}, ` +
      `Format: ${format}`,
    );

    // Analyze image & generate enhanced animation prompt + meme caption
    const { animationPrompt, caption } = await this.expandMemePromptAndCaption(
      cleanPrompt,
      imageBase64,
      mimeType,
    );

    debugLog.log(
      `[MemeService] Enhanced animation prompt: "${animationPrompt}" | ` +
      `Caption: "${caption}"`,
    );

    // Generate video via Google Veo 3.1 / Gemini
    let mp4Buffer: Buffer;
    try {
      mp4Buffer = await this.callVeoMemeApi(
        animationPrompt,
        imageBase64,
        mimeType,
      );
    } catch (err: unknown) {
      if (
        imageBase64 &&
        err instanceof HttpsError &&
        err.message.includes("Safety Filter")
      ) {
        debugLog.warn(
          "[MemeService] Input image filtered by Google AI Safety Policy, falling back to text-to-video meme...",
        );
        mp4Buffer = await this.callVeoMemeApi(animationPrompt);
      } else {
        throw err;
      }
    }

    // Convert to GIF if user selected GIF format
    let finalBuffer = mp4Buffer;
    let contentType = "video/mp4";
    let fileExt: "mp4" | "gif" = "mp4";

    if (format === "gif") {
      debugLog.log("[MemeService] Converting MP4 to GIF using ffmpeg...");
      finalBuffer = await this.convertMp4ToGif(mp4Buffer);
      contentType = "image/gif";
      fileExt = "gif";
      debugLog.log(
        `[MemeService] Converted GIF buffer size: ${finalBuffer.byteLength}`,
      );
    }

    // Upload to Firebase Storage
    const bucket = admin.storage().bucket();
    const downloadToken = crypto.randomUUID();
    const fileId = `${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
    const filePath = `users/${uid}/memes/${fileId}.${fileExt}`;
    const file = bucket.file(filePath);

    await file.save(finalBuffer, {
      metadata: {
        contentType,
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
          prompt: cleanPrompt,
          caption,
          format,
          uid,
        },
      },
    });

    const bucketName =
      bucket.name ||
      process.env.STORAGE_BUCKET ||
      "paceai-4733a.firebasestorage.app";
    const encodedPath = encodeURIComponent(filePath);
    const downloadUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
      `${encodedPath}?alt=media&token=${downloadToken}`;

    debugLog.log(
      `[MemeService] Meme generated and uploaded successfully: ${downloadUrl}`,
    );

    const isVideo = format === "video";
    const isGif = format === "gif";

    return {
      success: true,
      url: downloadUrl,
      imageUrl: isGif ? downloadUrl : undefined,
      videoUrl: isVideo ? downloadUrl : undefined,
      caption,
      prompt: cleanPrompt,
      format,
      isVideo,
      isGif,
      isImage: false,
      duration: 8,
      creditsUsed: 1,
    };
  }

  // Converts a raw user instruction like "create funny meme of the guy" into
  // a short punchy meme caption like "Me explaining this for the 5th time".
  // Converts a raw user instruction like "create funny meme of the guy" into
  // a short punchy meme caption like "Me explaining this for the 5th time".
  // This ensures the image caption is viral meme text, NOT the user's request text.
  // eslint-disable-next-line valid-jsdoc
  private async generateMemeCaptionFromIntent(
    userIntent: string,
    imageBase64?: string,
    mimeType = "image/jpeg",
  ): Promise<{ caption: string; reaction: string }> {
    const systemInstruction =
      "You are a world-class meme creator and comedy writer. Your ONLY job is to produce short, punchy, " +
      "viral meme captions — the kind you see on Instagram memes, Reddit, and Twitter.\n" +
      "RULES:\n" +
      "1. Understand what the user wants to joke about.\n" +
      "2. Generate an original, hilarious, relatable meme caption (4–10 words max).\n" +
      "   - DO NOT repeat or quote the user's instruction.\n" +
      "   - DO NOT write meta text like 'create a meme' or 'funny meme of the guy'.\n" +
      "   - Write the punchy joke text that should appear on top of the image (e.g. 'When the code works on the first try 💀', 'Me pretending I understood what they just said').\n" +
      "   - Use relatable humor, internet slang, or emojis.\n" +
      "3. Describe a 1-sentence reaction expression for the person.\n" +
      "Return ONLY valid JSON: {\"caption\": \"...\", \"reaction\": \"...\"}";

    const cleanImage = imageBase64 ?
      imageBase64.replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "").trim() :
      "";

    // 1. Try Gemini Flash models first
    if (this.memeApiKey && this.memeApiKey !== "default_key") {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const contentParts: any[] = [];
      if (cleanImage) {
        contentParts.push({ inlineData: { mimeType, data: cleanImage } });
      }
      contentParts.push({
        text: `User's meme request: "${userIntent}"\nReturn JSON with caption and reaction.`,
      });

      const geminiModels = [
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-1.5-flash-latest",
        "gemini-1.5-pro",
      ];

      for (const model of geminiModels) {
        const url =
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:` +
          `generateContent?key=${this.memeApiKey}`;
        try {
          const res = await fetch(url, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              systemInstruction: { parts: [{ text: systemInstruction }] },
              contents: [{ parts: contentParts }],
              generationConfig: {
                responseMimeType: "application/json",
                temperature: 1.0,
              },
            }),
          });
          if (res.ok) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const data = (await res.json()) as any;
            const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              const parsed = JSON.parse(text);
              if (parsed.caption && parsed.caption.length < 200) {
                debugLog.log(
                  `[MemeService] Gemini generated caption: "${parsed.caption}" | reaction: "${parsed.reaction}"`,
                );
                return { caption: parsed.caption, reaction: parsed.reaction || "" };
              }
            }
          }
        } catch (err) {
          debugLog.warn(`[MemeService] Gemini caption failed on ${model}:`, err);
        }
      }
    }

    // 2. Fallback: Try OpenAI gpt-4o-mini for caption generation
    const openaiKey =
      this.imageGenApiKey ||
      process.env.IMAGE_GEN_API_KEY ||
      process.env.OPENAI_API_KEY ||
      "";
    if (openaiKey && openaiKey.startsWith("sk-")) {
      try {
        debugLog.log("[MemeService] Generating meme caption via OpenAI gpt-4o-mini...");
        const res = await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${openaiKey}`,
          },
          body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [
              { role: "system", content: systemInstruction },
              { role: "user", content: `User meme request: "${userIntent}"` },
            ],
            response_format: { type: "json_object" },
            temperature: 0.9,
          }),
        });
        if (res.ok) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const data = (await res.json()) as any;
          const content = data?.choices?.[0]?.message?.content;
          if (content) {
            const parsed = JSON.parse(content);
            if (parsed.caption && parsed.caption.length < 200) {
              debugLog.log(
                `[MemeService] OpenAI generated caption: "${parsed.caption}" | reaction: "${parsed.reaction}"`,
              );
              return { caption: parsed.caption, reaction: parsed.reaction || "" };
            }
          }
        }
      } catch (err) {
        debugLog.warn("[MemeService] OpenAI caption generation error:", err);
      }
    }

    // 3. Guaranteed creative viral fallback (never repeats the user's raw prompt)
    const viralFallbacks = [
      "When you realize what just happened 💀",
      "Me pretending everything is under control",
      "Nobody warned me about this part 😭",
      "POV: You thought it would be simple",
      "That moment when reality hits you",
      "Me trying my absolute best every single day",
    ];
    const fallbackCaption =
      viralFallbacks[Math.floor(Math.random() * viralFallbacks.length)];
    return {
      caption: fallbackCaption,
      reaction: "hilarious expressive reaction",
    };
  }

  async generateImageMeme(
    uid: string,
    prompt: string,
    imageBase64?: string,
    mimeType = "image/jpeg",
  ): Promise<MemeGenerationResult> {
    const cleanPrompt = (prompt || "").trim();
    const apiKey =
      this.imageGenApiKey ||
      process.env.IMAGE_GEN_API_KEY ||
      process.env.OPENAI_API_KEY ||
      "";

    if (!apiKey || !apiKey.startsWith("sk-")) {
      throw new HttpsError(
        "internal",
        "IMAGE_GEN_API_KEY is not configured on Cloud Functions.",
      );
    }

    debugLog.log(
      `[MemeService] Generating image meme for uid: ${uid}. ` +
      `Prompt: "${cleanPrompt}", HasImage: ${Boolean(imageBase64)}`,
    );

    // Step 1: Generate a real punchy meme caption (never prints raw user instructions)
    const { caption: memeCaption } = await this.generateMemeCaptionFromIntent(
      cleanPrompt,
      imageBase64,
      mimeType,
    );

    debugLog.log(`[MemeService] Using viral caption: "${memeCaption}"`);

    let imageBuffer: Buffer;

    if (imageBase64 && imageBase64.length > 100) {
      const cleanBase64 = imageBase64
        .replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "")
        .trim();
      const inputBuffer = Buffer.from(cleanBase64, "base64");
      const ext = mimeType.split("/")[1]?.replace("jpeg", "jpg") || "jpg";
      const boundary =
        "----FormBoundary" + crypto.randomBytes(8).toString("hex");
      const CRLF = "\r\n";

      // Detect dimensions & preserve portrait/landscape ratio without cropping
      const dims = detectImageDimensions(inputBuffer);
      let targetSize = "1024x1024";
      if (dims.aspectRatio < 0.82) {
        targetSize = "1024x1536";
      } else if (dims.aspectRatio > 1.25) {
        targetSize = "1536x1024";
      }

      debugLog.log(
        `[MemeService] Image meme detected aspect ratio: ${dims.aspectRatio.toFixed(3)}, size: ${targetSize}`,
      );

      // Prompt optimized for strict face preservation and high-quality meme overlay
      const viralMemePrompt =
        "Transform this reference image into a viral social media meme. " +
        `Add a bold meme caption header banner at the TOP of the image showing EXACTLY this text: "${memeCaption}". ` +
        "CRITICAL REQUIREMENTS:\n" +
        "1. STRICT FACE & IDENTITY PRESERVATION: Keep the EXACT same person from the input image. Their face, facial features, eyes, nose, mouth, facial structure, skin tone, hair, and likeness MUST be 100% identical to the reference photo. Do NOT replace or alter their identity.\n" +
        "2. FULL FRAMING: Maintain the exact aspect ratio and framing of the reference photo without cropping.\n" +
        `3. MEME CAPTION: Render the text "${memeCaption}" clearly in bold high-contrast font with internal margins so no text is cut off.`;

      const parts: Buffer[] = [];
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="model"${CRLF}${CRLF}` +
          `gpt-image-2${CRLF}`,
        ),
      );
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="quality"${CRLF}${CRLF}` +
          `high${CRLF}`,
        ),
      );
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="prompt"${CRLF}${CRLF}` +
          `${viralMemePrompt}${CRLF}`,
        ),
      );
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="size"${CRLF}${CRLF}` +
          `${targetSize}${CRLF}`,
        ),
      );
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="n"${CRLF}${CRLF}` +
          `1${CRLF}`,
        ),
      );
      parts.push(
        Buffer.from(
          `--${boundary}${CRLF}` +
          `Content-Disposition: form-data; name="image"; filename="image.${ext}"${CRLF}` +
          `Content-Type: ${mimeType}${CRLF}${CRLF}`,
        ),
      );
      parts.push(inputBuffer);
      parts.push(Buffer.from(CRLF));
      parts.push(Buffer.from(`--${boundary}--${CRLF}`));

      const body = Buffer.concat(parts);

      debugLog.log("[MemeService] Calling OpenAI images/edits with gpt-image-2 (high quality)...");
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
        debugLog.error("[MemeService] OpenAI Image Edit error:", errorText);
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
          "No image content returned from image edit API.",
        );
      }

      if (b64Json) {
        imageBuffer = Buffer.from(b64Json, "base64");
      } else {
        const imgRes = await fetch(imageUrl);
        if (!imgRes.ok) {
          throw new HttpsError(
            "internal",
            "Failed to retrieve edited image from OpenAI.",
          );
        }
        imageBuffer = Buffer.from(await imgRes.arrayBuffer());
      }
    } else {
      // Text-only meme: generate from scratch with the clean caption
      const viralTextMemePrompt =
        "A viral social media meme (Instagram / Reddit / Twitter style). " +
        `The meme caption text at the top of the image must read EXACTLY: "${memeCaption}". ` +
        "The caption must be bold Impact/meme-style font, white text on black background, with generous padding and internal margins. " +
        "High visual comedy, high production quality, no text bleeding off edges.";

      debugLog.log("[MemeService] Calling OpenAI images/generations with gpt-image-2 (high quality)...");
      const response = await fetch(
        "https://api.openai.com/v1/images/generations",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model: "gpt-image-2",
            prompt: viralTextMemePrompt,
            n: 1,
            size: "1024x1024",
            quality: "high",
          }),
        },
      );

      if (!response.ok) {
        const errorText = await response.text();
        debugLog.error("[MemeService] OpenAI Image Gen error:", errorText);
        throw new HttpsError(
          "internal",
          `Image generation API error: ${response.status}`,
        );
      }

      const data = (await response.json()) as {
        data?: Array<{ url?: string; b64_json?: string }>;
      };
      const imageUrl = data.data?.[0]?.url || "";
      const b64Json = data.data?.[0]?.b64_json || "";

      if (!imageUrl && !b64Json) {
        throw new HttpsError("internal", "No image content returned from API.");
      }

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
        imageBuffer = Buffer.from(await imgRes.arrayBuffer());
      }
    }

    // Upload permanently to Firebase Storage
    const bucket = admin.storage().bucket();
    const downloadToken = crypto.randomUUID();
    const fileId = `${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
    const filePath = `users/${uid}/memes/${fileId}.png`;
    const file = bucket.file(filePath);

    await file.save(imageBuffer, {
      metadata: {
        contentType: "image/png",
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
          prompt: cleanPrompt,
          format: "image",
          uid,
        },
      },
    });

    const bucketName =
      bucket.name ||
      process.env.STORAGE_BUCKET ||
      "paceai-4733a.firebasestorage.app";
    const encodedPath = encodeURIComponent(filePath);
    const downloadUrl =
      `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
      `${encodedPath}?alt=media&token=${downloadToken}`;

    debugLog.log(`[MemeService] Image meme created and uploaded: ${downloadUrl}`);

    return {
      success: true,
      url: downloadUrl,
      imageUrl: downloadUrl,
      caption: cleanPrompt,
      prompt: cleanPrompt,
      format: "image",
      isVideo: false,
      isGif: false,
      isImage: true,
      duration: 0,
      creditsUsed: 1,
    };
  }

  // Uses Gemini Vision to analyze photo and create targeted animation prompt
  private async expandMemePromptAndCaption(
    prompt: string,
    imageBase64?: string,
    mimeType = "image/jpeg",
  ): Promise<{ animationPrompt: string; caption: string }> {
    let cleanImage = "";
    if (imageBase64) {
      cleanImage = imageBase64.replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "").trim();
    }

    const systemInstruction =
      "You are a world-class AI Meme Director and Comedy Creator.\n" +
      "CRITICAL RULE: If a photo is provided, you MUST preserve the EXACT person — " +
      "same face, identity, skin tone, hair color/style, clothing, and background. " +
      "DO NOT replace, merge, or alter the person's appearance in any way.\n" +
      "Your tasks:\n" +
      "1. 'animationPrompt': Write Veo 3.1 animation instructions that:\n" +
      "   - Start with: 'The exact same person from the reference photo, " +
      "preserving their face, hair, clothing, and setting without any changes.'\n" +
      "   - Then describe ONLY the specific facial expression/movement requested " +
      "(e.g. 'slowly breaks into a huge grin, eyes crinkling', " +
      "'eyes go wide with shock, jaw drops slightly', " +
      "'confused head tilt with raised eyebrow').\n" +
      "   - Keep camera static or use a subtle cinematic zoom. Natural lighting.\n" +
      "   - NO new people, NO background changes, NO clothing changes.\n" +
      "2. 'caption': A punchy, hilarious, relatable 1-2 line meme caption " +
      "that matches the reaction/expression.\n" +
      "Output ONLY JSON: {\"animationPrompt\": \"...\", \"caption\": \"...\"}";

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const parts: any[] = [];
    if (cleanImage) {
      parts.push({
        inlineData: {
          mimeType,
          data: cleanImage,
        },
      });
    }
    parts.push({
      text:
        `User Meme Request: "${prompt}".\n` +
        "Return the JSON with animationPrompt and caption.",
    });

    const geminiModels = [
      "gemini-omni-flash-preview",
      "gemini-2.5-flash",
      "gemini-2.0-flash",
      "gemini-1.5-flash",
    ];

    for (const model of geminiModels) {
      const url =
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:` +
        `generateContent?key=${this.memeApiKey}`;
      try {
        const res = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: systemInstruction }] },
            contents: [{ parts }],
            generationConfig: {
              responseMimeType: "application/json",
              temperature: 0.85,
            },
          }),
        });

        if (res.ok) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const data = (await res.json()) as any;
          const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) {
            const parsed = JSON.parse(text);
            if (parsed.animationPrompt && parsed.caption) {
              return {
                animationPrompt: parsed.animationPrompt,
                caption: parsed.caption,
              };
            }
          }
        }
      } catch (err) {
        debugLog.warn(`Gemini meme prompt expansion failed on ${model}:`, err);
      }
    }

    // Fallback if Gemini expansion fails
    return {
      animationPrompt:
        `A hilarious animated meme video: ${prompt}. ` +
        "Realistic facial expressions, smooth animation, humorous timing.",
      caption: prompt,
    };
  }

  // Calls Google Veo / Gemini predictLongRunning and returns MP4 Buffer
  private async callVeoMemeApi(
    prompt: string,
    imageBase64?: string,
    mimeType = "image/jpeg",
  ): Promise<Buffer> {
    const models = [
      "gemini-omni-flash-preview",
      "veo-3.1-generate-preview",
      "veo-2.0-generate-001",
      "veo-2.0",
    ];

    let cleanImage = "";
    if (imageBase64) {
      cleanImage = imageBase64.replace(/^data:image\/[a-zA-Z0-9+]+;base64,/, "").trim();
    }

    let operationName = "";
    const attemptErrors: Array<{ model: string; text: string }> = [];

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const instanceObj: Record<string, any> = { prompt };
    if (cleanImage) {
      instanceObj.image = {
        bytesBase64Encoded: cleanImage,
        mimeType,
      };
    }

    for (const model of models) {
      const url =
        "https://generativelanguage.googleapis.com/v1beta/models/" +
        `${model}:predictLongRunning?key=${this.memeApiKey}`;

      try {
        debugLog.log(`[MemeService] Requesting Veo on model ${model}...`);
        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": this.memeApiKey,
          },
          body: JSON.stringify({
            instances: [instanceObj],
            parameters: {
              sampleCount: 1,
              durationSeconds: 8,
              aspectRatio: "16:9",
            },
          }),
        });

        if (!res.ok) {
          const errText = await res.text();
          debugLog.warn(`[MemeService] Model ${model} failed (${res.status}): ${errText}`);
          attemptErrors.push({ model, text: errText });
          continue;
        }

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const data = (await res.json()) as any;
        if (data.name) {
          operationName = data.name;
          debugLog.log(
            `[MemeService] Started generation operation on ${model}: ${operationName}`,
          );
          break;
        }
      } catch (err) {
        debugLog.warn(`[MemeService] Network error on model ${model}:`, err);
        attemptErrors.push({ model, text: String(err) });
      }
    }

    if (!operationName) {
      const details = attemptErrors
        .map((e) => `[${e.model}: ${e.text.substring(0, 150)}]`)
        .join("; ");
      throw new HttpsError(
        "internal",
        `Failed to start meme video generation on all models: ${details}`,
      );
    }

    // Poll operation until complete (up to 4.5 minutes)
    const pollUrl =
      `https://generativelanguage.googleapis.com/v1beta/${operationName}` +
      `?key=${this.memeApiKey}`;

    debugLog.log(`[MemeService] Polling operation: ${operationName}...`);
    const startTime = Date.now();
    const maxPollMs = 270000;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let rawResult: any = null;

    while (Date.now() - startTime < maxPollMs) {
      await new Promise((resolve) => setTimeout(resolve, 5000));

      try {
        const pollRes = await fetch(pollUrl, {
          headers: { "x-goog-api-key": this.memeApiKey },
        });
        if (!pollRes.ok) {
          debugLog.warn(`[MemeService] Poll HTTP status: ${pollRes.status}`);
          continue;
        }

        rawResult = await pollRes.json();
        if (rawResult.done) {
          debugLog.log("[MemeService] Operation marked DONE.");
          break;
        }
      } catch (pollErr) {
        debugLog.warn("[MemeService] Polling network warning:", pollErr);
      }
    }

    if (!rawResult || !rawResult.done) {
      throw new HttpsError("deadline-exceeded", "Meme video generation timed out.");
    }

    if (rawResult.error) {
      throw new HttpsError(
        "internal",
        `Meme generation error: ${rawResult.error.message || JSON.stringify(rawResult.error)}`,
      );
    }

    // Check for RAI Safety Filter
    const raiFilteredCount =
      rawResult.response?.generateVideoResponse?.raiMediaFilteredCount ?? 0;
    if (raiFilteredCount > 0) {
      const reasons =
        rawResult.response?.generateVideoResponse?.raiMediaFilteredReasons;
      let reasonMsg = "Safety policy triggered";
      if (Array.isArray(reasons)) {
        reasonMsg = reasons.join(", ");
      }
      debugLog.warn(
        `[MemeService] RAI Safety filter caught video generation: ${reasonMsg}`,
      );
      throw new HttpsError(
        "failed-precondition",
        `Safety Filter: Video generation was blocked because of AI safety restrictions (${reasonMsg}).`,
      );
    }

    const samples =
      rawResult.response?.generateVideoResponse?.generatedSamples ||
      rawResult.response?.generatedSamples;

    if (Array.isArray(samples) && samples.length > 0) {
      const sample = samples[0];
      const videoUri = sample.video?.videoUri || sample.videoUri;

      if (videoUri) {
        debugLog.log(`[MemeService] Fetching video from URI: ${videoUri}`);
        let downloadUrl = `${videoUri}?key=${this.memeApiKey}`;
        if (videoUri.includes("?")) {
          downloadUrl = `${videoUri}&key=${this.memeApiKey}`;
        }

        const videoRes = await fetch(downloadUrl);
        if (videoRes.ok) {
          const arrayBuf = await videoRes.arrayBuffer();
          return Buffer.from(arrayBuf);
        }
      }

      const b64 =
        sample.video?.bytesBase64Encoded || sample.bytesBase64Encoded;
      if (b64) {
        return Buffer.from(b64, "base64");
      }
    }

    const snippet = JSON.stringify(rawResult).substring(0, 300);
    throw new HttpsError(
      "internal",
      `Meme video completed but payload could not be extracted: ${snippet}`,
    );
  }

  // Convert MP4 Buffer to high-quality animated GIF with ffmpeg
  private async convertMp4ToGif(mp4Buffer: Buffer): Promise<Buffer> {
    const tmpDir = os.tmpdir();
    const id = crypto.randomBytes(8).toString("hex");
    const inPath = path.join(tmpDir, `meme_in_${id}.mp4`);
    const outPath = path.join(tmpDir, `meme_out_${id}.gif`);

    try {
      await fs.promises.writeFile(inPath, mp4Buffer);

      const ffmpeg = (ffmpegPath as unknown as string) || "ffmpeg";
      const vfFilter =
        "fps=12,scale=480:-1:flags=lanczos,split[s0][s1];" +
        "[s0]palettegen[p];[s1][p]paletteuse";

      await new Promise<void>((resolve, reject) => {
        execFile(
          ffmpeg,
          ["-y", "-i", inPath, "-vf", vfFilter, outPath],
          (error) => {
            if (error) {
              return reject(error);
            }
            resolve();
          },
        );
      });

      return await fs.promises.readFile(outPath);
    } catch (err) {
      debugLog.error("[MemeService] ffmpeg GIF conversion failed:", err);
      // Fallback: return original MP4 if GIF conversion fails
      return mp4Buffer;
    } finally {
      await fs.promises.unlink(inPath).catch((e) => {
        debugLog.warn("Temp inPath cleanup:", e);
      });
      await fs.promises.unlink(outPath).catch((e) => {
        debugLog.warn("Temp outPath cleanup:", e);
      });
    }
  }
}
