import {debugLog} from "./debugLog";

/**
 * promptEnhancer.ts
 *
 * Advanced Multimodal Visual Director Prompt Enhancer matching the internal
 * mechanics of ChatGPT (DALL-E 3) and Gemini (Imagen 3).
 *
 * It uses Google Gemini (with multi-model fallback) or OpenAI (as backup) to:
 * 1. Inspect reference images (OCR handwriting, papers, objects, faces, layout).
 * 2. Resolve references from the last conversation messages.
 * 3. Formulate rich prompts in the requested aspect ratio.
 */

export interface ChatHistoryMessage {
  role?: string;
  content?: string;
}

export interface PromptEnhancerOptions {
  imageBase64?: string;
  referenceImageBase64?: string;
  referenceMimeType?: string;
  imageUrl?: string;
  mimeType?: string;
  chatHistory?: ChatHistoryMessage[];
  mode?: "image" | "image-edit";
  aspectRatio?: "9:16" | "4:5";
  geminiApiKey?: string;
  openAiApiKey?: string;
}

const GEMINI_IMAGE_PROMPT_SYSTEM =
  "You are the world's most advanced AI visual director and multimodal prompt expansion engine, matching the internal intelligence of ChatGPT (DALL-E) and Gemini (Imagen).\n" +
  "Your task is to analyze the user's request, recent conversation history, and any reference image provided (whether uploaded by user or previously generated in chat), and produce the single best prompt for image generation / editing.\n\n" +
  "AUTOMATIC INTELLIGENCE — DECIDE ACTION BASED ON USER INTENT:\n" +
  "1. SPECIFIC PARTIAL EDIT / MODIFICATION:\n" +
  "   - If the user asks to modify, replace, or add a specific element in the reference image (e.g., 'change that board behind the attendance sheet', 'make her jacket green', 'remove the background object', 'add glasses'):\n" +
  "   - Explicitly instruct preserving all other key subjects, exact foreground elements, text, handwriting, facial features, and composition 100% intact from the reference image.\n" +
  "   - Describe the modified element with matching lighting, seamless perspective, natural cast shadows, and photo-realistic blending.\n" +
  "2. FULL TRANSFORMATION / POSTER / CONCEPT CREATION:\n" +
  "   - If the user uploads a handwritten paper, note, sketch, attendance sheet, or document and asks for a poster, scene, or artistic transformation (e.g., 'make this as poster', 'a girl holding this attendance paper'):\n" +
  "   - Meticulously read and transcribe all visible text, headings, names, and numbers.\n" +
  "   - Formulate a breathtaking, ultra-professional 8k composition (photographic studio portrait or sleek modern graphic design poster) cleanly rendering that text into the scene without wrinkled paper/sketch artifacts or camera scan shadows.\n" +
  "3. ASPECT RATIO & SIZING RULES:\n" +
  "   - If editing an existing image: preserve the original image's aspect ratio, layout, and framing.\n" +
  "   - If creating a new text-to-image scene from scratch: honor the requested aspect ratio (9:16 or 4:5 portrait); default to 9:16 if none is specified.\n" +
  "4. OUTPUT FORMAT:\n" +
  "   - Output ONLY the final expanded prompt in natural, descriptive English without markdown, prefixes, or preamble.";

/**
 * Formats recent chat history into a readable context block for LLM prompt expansion.
 */
function formatChatHistory(history?: ChatHistoryMessage[]): string {
  if (!history || history.length === 0) return "";
  const recent = history.slice(-10); // Take up to the last 10 messages (~5 turns)
  const lines = recent.map((m) => {
    const speaker = m.role === "assistant" ? "Assistant" : "User";
    const text = (m.content || "").trim();
    return `${speaker}: ${text}`;
  });
  return `\n\n[RECENT CONVERSATION CONTEXT]:\n${lines.join("\n")}\n`;
}

function aspectRatioInstruction(options: PromptEnhancerOptions): string {
  if (options.mode === "image-edit") {
    return "Preserve the reference image's original aspect ratio and framing.";
  }
  const ratio = options.aspectRatio || "9:16";
  return `Generate the optimal ${ratio} portrait visual generation prompt.`;
}

/**
 * Extract the most recent image URL from chat history if present.
 */
function extractLatestImageUrlFromHistory(history?: ChatHistoryMessage[]): string | undefined {
  if (!history || history.length === 0) return undefined;
  for (let i = history.length - 1; i >= 0; i--) {
    const text = history[i].content || "";
    // Check for standard URL in text
    const urlMatch = text.match(/https:\/\/[^\s"'<>]+\.(?:png|jpg|jpeg|webp)/i);
    if (urlMatch) return urlMatch[0];
    const firebaseMatch = text.match(/https:\/\/firebasestorage\.googleapis\.com\/[^\s"'<>]+/i);
    if (firebaseMatch) return firebaseMatch[0];
  }
  return undefined;
}

/**
 * Calls Google Gemini (generativelanguage.googleapis.com) with automatic model fallback.
 */
async function callGemini(
  prompt: string,
  apiKey: string,
  options: PromptEnhancerOptions,
  systemInstruction: string,
): Promise<string | null> {
  const geminiModels = [
    "gemini-2.5-flash",
    "gemini-2.0-flash",
  ];

  let cleanImage = "";
  let mimeType = options.mimeType || "image/jpeg";

  if (options.imageBase64) {
    cleanImage = options.imageBase64.replace(
      /^data:image\/[a-zA-Z0-9+]+;base64,/,
      "",
    );
  } else if (options.imageUrl) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2500);
      const res = await fetch(options.imageUrl, { signal: controller.signal });
      clearTimeout(timeoutId);
      if (res.ok) {
        const arr = await res.arrayBuffer();
        cleanImage = Buffer.from(arr).toString("base64");
        const ct = res.headers.get("content-type");
        if (ct) mimeType = ct;
      }
    } catch (e) {
      debugLog.warn("[PromptEnhancer] Could not fetch options.imageUrl:", e);
    }
  }

  // If still no image, attempt extracting from recent chat history
  if (!cleanImage) {
    const historyImgUrl = extractLatestImageUrlFromHistory(options.chatHistory);
    if (historyImgUrl) {
      try {
        debugLog.log(`[PromptEnhancer] Found previous image in chat history: ${historyImgUrl}`);
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 2500);
        const res = await fetch(historyImgUrl, { signal: controller.signal });
        clearTimeout(timeoutId);
        if (res.ok) {
          const arr = await res.arrayBuffer();
          cleanImage = Buffer.from(arr).toString("base64");
          const ct = res.headers.get("content-type");
          if (ct) mimeType = ct;
        }
      } catch (e) {
        debugLog.warn("[PromptEnhancer] Could not fetch history image:", e);
      }
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const parts: any[] = [];
  if (options.referenceImageBase64) {
    const cleanRef = options.referenceImageBase64.replace(
      /^data:image\/[a-zA-Z0-9+]+;base64,/,
      "",
    );
    const refMime = options.referenceMimeType || "image/png";
    debugLog.log(`[PromptEnhancer] Sending Image 1: Style Reference (${refMime}, ${cleanRef.length} chars) to Gemini Vision`);
    parts.push({
      inlineData: {
        mimeType: refMime,
        data: cleanRef,
      },
    });
  }

  if (cleanImage) {
    debugLog.log(`[PromptEnhancer] Sending Image 2: User Photo (${mimeType}, ${cleanImage.length} base64 chars) to Gemini Vision`);
    parts.push({
      inlineData: {
        mimeType,
        data: cleanImage,
      },
    });
  }

  const multiImageNotice = options.referenceImageBase64 && cleanImage
    ? "\n\n[MULTI-IMAGE ROLES]:\n" +
      "• Image 1 (first image above) is the STYLE & AESTHETIC REFERENCE IMAGE. Analyze its visual composition, aesthetic, color palette, lighting, textures, outfit, and environment.\n" +
      "• Image 2 (second image above) is the USER'S UPLOADED PHOTOGRAPH. You MUST preserve the person's exact face, eyes, nose, lips, jawline, skin tone, and identity from Image 2 100%, and transform them into the look of Image 1.\n"
    : "";

  const historyContext = formatChatHistory(options.chatHistory);
  const userContent =
    `${historyContext}\n` +
    `Current User Request: "${prompt.trim()}".\n` +
    multiImageNotice +
    aspectRatioInstruction(options);

  parts.push({ text: userContent });

  for (const model of geminiModels) {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:` +
      `generateContent?key=${apiKey}`;

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 3500);
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemInstruction }] },
          contents: [{ parts }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 250,
          },
        }),
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const data = (await res.json()) as any;
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
        if (text && text.length > 10) {
          debugLog.log(
            `[PromptEnhancer] Gemini (${model}) successfully enhanced prompt: "${text.substring(0, 100)}..."`,
          );
          return text;
        }
      } else {
        const errBody = await res.text();
        debugLog.warn(`[PromptEnhancer] Gemini (${model}) HTTP error: ${res.status}`, errBody);
      }
    } catch (err) {
      debugLog.warn(`[PromptEnhancer] Gemini (${model}) failed:`, err);
    }
  }

  return null;
}

/**
 * Fallback to OpenAI (gpt-4o-mini / gpt-4o) if Gemini is unreachable or has no key.
 */
async function callOpenAI(
  prompt: string,
  apiKey: string,
  options: PromptEnhancerOptions,
  systemInstruction: string,
): Promise<string | null> {
  try {
    const historyContext = formatChatHistory(options.chatHistory);
    let cleanImage = "";
    if (options.imageBase64) {
      cleanImage = options.imageBase64.replace(
        /^data:image\/[a-zA-Z0-9+]+;base64,/,
        "",
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const userContent: any[] = [];
    if (cleanImage) {
      const mime = options.mimeType || "image/jpeg";
      userContent.push({
        type: "image_url",
        image_url: {
          url: `data:${mime};base64,${cleanImage}`,
          detail: "high",
        },
      });
    }

    userContent.push({
      type: "text",
      text:
        `${historyContext}\n` +
        `Current User Request: "${prompt.trim()}".\n` +
        aspectRatioInstruction(options),
    });

    const model = cleanImage ? "gpt-4o" : "gpt-4o-mini";
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: systemInstruction },
          { role: "user", content: userContent },
        ],
        max_tokens: 400,
        temperature: 0.7,
      }),
    });

    if (res.ok) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const data = (await res.json()) as any;
      const text = data?.choices?.[0]?.message?.content?.trim();
      if (text && text.length > 10) {
        debugLog.log(
          `[PromptEnhancer] OpenAI (${model}) successfully enhanced prompt: "${text.substring(0, 100)}..."`,
        );
        return text;
      }
    }
  } catch (err) {
    debugLog.warn("[PromptEnhancer] OpenAI fallback failed:", err);
  }
  return null;
}

/**
 * Main prompt enhancement function.
 * Takes the raw user instruction + optional photo + conversation history
 * and returns the best refined prompt.
 */
export async function enhanceVisualPrompt(
  prompt: string,
  options: PromptEnhancerOptions = {},
): Promise<string> {
  const trimmed = prompt.trim();
  if (!trimmed) return "";

  const systemInstruction = GEMINI_IMAGE_PROMPT_SYSTEM;

  // 1. Try Gemini if an API key is available
  const geminiKey = options.geminiApiKey || process.env.MEME_API_KEY || process.env.VEO_API_KEY;
  if (geminiKey && geminiKey.length > 10) {
    const geminiResult = await callGemini(trimmed, geminiKey, options, systemInstruction);
    if (geminiResult) return geminiResult;
  }

  // 2. Fallback to OpenAI if key is available
  const openAiKey = options.openAiApiKey || process.env.OPENAI_API_KEY;
  if (openAiKey && openAiKey.startsWith("sk-")) {
    const openAiResult = await callOpenAI(trimmed, openAiKey, options, systemInstruction);
    if (openAiResult) return openAiResult;
  }

  // 3. If all LLM calls fail, safely fallback to raw prompt
  return trimmed;
}
