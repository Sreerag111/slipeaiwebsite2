import * as admin from "firebase-admin";
import {debugLog} from "../utils/debugLog";
import { onCall, HttpsError } from "firebase-functions/v2/https";
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

export const generateChat = onCall(
  {
    secrets: [OPENAI_API_KEY],
  },
  async (request) => {
    let reservation: UsageReservation | null = null;
    let uid: string | null = null;
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be authenticated.");
      }

      const {
        messages,
        model = "gpt-5.6-luna",
        systemPrompt = "You are Slipe AI, a helpful assistant. When citing research, facts, or external documentation, provide source URLs at the end under '### Sources'.",
      } = request.data || {};
      if (!messages || !Array.isArray(messages)) {
        throw new HttpsError("invalid-argument", "Messages array is required.");
      }
      uid = request.auth.uid;
      reservation = await reserveFeatureUsage(uid, "chat");

      let apiKey = "";
      try {
        apiKey = OPENAI_API_KEY.value();
      } catch {
        apiKey = process.env.OPENAI_API_KEY || "";
      }

      if (!apiKey || !apiKey.startsWith("sk-")) {
        throw new HttpsError(
          "internal",
          "OpenAI API Key is not configured on Cloud Functions."
        );
      }

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

      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model,
          messages: formattedMessages,
          max_completion_tokens: 2500,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        debugLog.error("OpenAI Chat Completion Error:", errorText);
        throw new HttpsError(
          "internal",
          `OpenAI API returned error: ${response.status}`
        );
      }

      const data = (await response.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
        model?: string;
      };

      const reply = data.choices?.[0]?.message?.content || "";
      return {
        success: true,
        content: reply,
        model: data.model || model,
      };
    } catch (error: unknown) {
      if (uid) await releaseFeatureUsage(uid, reservation);
      debugLog.error("generateChat Error:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError("internal", "Chat generation failed. Please try again.");
    }
  }
);
