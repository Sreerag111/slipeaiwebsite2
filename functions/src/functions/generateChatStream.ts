import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import { onRequest } from "firebase-functions/v2/https";
import { OPENAI_API_KEY } from "../config/secrets";
import { performWebSearch, shouldPerformWebSearch } from "../utils/webSearch";
import {
  releaseFeatureUsage,
  reserveFeatureUsage,
  UsageReservation,
} from "../utils/entitlements";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const generateChatStream = onRequest(
  {
    secrets: [OPENAI_API_KEY],
    cors: true,
    minInstances: 1,
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({ error: "Method not allowed" });
      return;
    }

    // Authenticate
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      response.status(401).json({ error: "Unauthorized" });
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid = "";
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      uid = decodedToken.uid;
    } catch {
      response.status(401).json({ error: "Invalid token" });
      return;
    }

    let apiKey = "";
    try {
      apiKey = OPENAI_API_KEY.value();
    } catch {
      apiKey = process.env.OPENAI_API_KEY || "";
    }

    if (!apiKey || !apiKey.startsWith("sk-")) {
      response.status(500).json({ error: "OpenAI API Key is not configured." });
      return;
    }

    const {
      messages,
      model = "gpt-5.6-luna",
      systemPrompt = "You are Slipe AI, a helpful assistant. When citing research, facts, or external documentation, provide source URLs at the end under '### Sources'.",
    } = request.body || {};

    if (!messages || !Array.isArray(messages)) {
      response.status(400).json({ error: "Messages array is required." });
      return;
    }

    let usageReservation: UsageReservation | null = null;
    try {
      usageReservation = await reserveFeatureUsage(uid, "chat");
    } catch (error) {
      if (error instanceof Error && "code" in error) {
        const code = String((error as {code?: unknown}).code);
        const status = code.includes("resource-exhausted") ? 429 : 403;
        response.status(status).json({error: error.message});
        return;
      }
      response.status(500).json({error: "Could not verify chat access."});
      return;
    }
    // Flush SSE headers immediately so the app can show its waiting state while
    // optional search and model setup are still running.
    response.setHeader("Content-Type", "text/event-stream");
    response.setHeader("Cache-Control", "no-cache");
    response.setHeader("Connection", "keep-alive");
    response.setHeader("X-Accel-Buffering", "no");
    response.flushHeaders();
    response.write(": connected\n\n");

    // Prevent proxies and the mobile client's idle timeout from closing a
    // healthy request while the model is preparing its first token.
    const heartbeat = setInterval(() => {
      if (!response.writableEnded) {
        response.write(": keep-alive\n\n");
      }
    }, 10000);
    const writeStreamError = (message: string) => {
      if (!response.writableEnded) {
        response.write(`data: ${JSON.stringify({ error: message })}\n\n`);
        response.end();
      }
    };

    let webContext = "";
    try {
      const lastUserMsg =
        [...messages]
          .reverse()
          .find(
            (m: { role?: string; content?: string }) =>
              m.role !== "system" && m.role !== "assistant"
          )?.content || "";

      if (shouldPerformWebSearch(lastUserMsg)) {
        const searchResults = await performWebSearch(lastUserMsg, 5);
        if (searchResults.length > 0) {
          webContext =
            `\n\n[LIVE WEB SEARCH RESULTS FOR: "${lastUserMsg}"]:\n` +
            searchResults
              .map(
                (r, i) =>
                  `${i + 1}. Title: ${r.title}\n   URL: ${r.url}\n   Snippet: ${r.snippet}`
              )
              .join("\n\n") +
            `\n\nINSTRUCTIONS FOR USING WEB RESULTS:\n` +
            `- Answer the user's question accurately using the live search results above.\n` +
            `- DO NOT claim you lack live news access, because real live web results are provided above.\n` +
            `- Cite the sources at the bottom under '### Sources' in this format:\n` +
            `### Sources\n` +
            searchResults.map((r) => `- [${r.title}](${r.url})`).join("\n");
        }
      }
    } catch (searchErr) {
      debugLog.warn("Web search lookup failed, continuing without web results:", searchErr);
    }

    const formattedMessages = [
      { role: "system", content: systemPrompt + webContext },
      ...messages.map((m: { role?: string; content?: string }) => ({
        role: m.role || "user",
        content: m.content || "",
      })),
    ];

    try {
      const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: formattedMessages,
          max_completion_tokens: 2500,
          stream: true,
        }),
      });

      if (!openaiResponse.ok) {
        const errorText = await openaiResponse.text();
        debugLog.error("OpenAI Stream Error:", errorText);
        writeStreamError(
          `OpenAI API returned error: ${openaiResponse.status}`,
        );
        await releaseFeatureUsage(uid, usageReservation);
        return;
      }

      const reader = openaiResponse.body?.getReader();
      if (!reader) {
        writeStreamError("No response stream from OpenAI.");
        await releaseFeatureUsage(uid, usageReservation);
        return;
      }

      const decoder = new TextDecoder();
      let buffer = "";

      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (!line.startsWith("data: ")) continue;
          const data = line.slice(6).trim();
          if (data === "[DONE]") {
            response.write("data: [DONE]\n\n");
            continue;
          }
          if (!data) continue;

          try {
            const parsed = JSON.parse(data);
            const content = parsed.choices?.[0]?.delta?.content;
            if (content) {
              response.write(`data: ${JSON.stringify({ content })}\n\n`);
            }
          } catch {
            // Skip malformed JSON
          }
        }
      }

      response.end();
    } catch (error) {
      debugLog.error("generateChatStream Error:", error);
      await releaseFeatureUsage(uid, usageReservation);
      writeStreamError("Chat response failed. Please try again.");
    } finally {
      clearInterval(heartbeat);
    }
  }
);
