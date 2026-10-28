import { HttpsError } from "firebase-functions/v2/https";
import { MemeService, MemeGenerationResult } from "../services/meme.service";

export class MemeController {
  constructor(private readonly memeService: MemeService) {}

  async generateMeme(
    uid: string,
    prompt: string,
    imageBase64?: string,
    mimeType?: string,
    format: "image" | "video" | "gif" = "image",
  ): Promise<MemeGenerationResult> {
    if (!uid) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const cleanPrompt = prompt ? prompt.trim() : "";
    if (!cleanPrompt) {
      throw new HttpsError("invalid-argument", "Prompt is required.");
    }

    try {
      return await this.memeService.generateMeme(
        uid,
        cleanPrompt,
        imageBase64,
        mimeType,
        format,
      );
    } catch (error: unknown) {
      if (error instanceof HttpsError) {
        throw error;
      }
      const msg =
        error instanceof Error ? error.message : "Meme generation failed.";
      throw new HttpsError("internal", msg);
    }

  }
}
