import { NextRequest, NextResponse } from 'next/server';

export const maxDuration = 60; // Allow sufficient time for AI image synthesis

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const prompt = body?.prompt;
    const requestedRatio = body?.aspectRatio || '1:1';

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return NextResponse.json(
        { error: 'Please enter a description for your image.' },
        { status: 400 }
      );
    }

    const trimmedPrompt = prompt.trim();

    // Map aspect ratios to exact dimensions supported by OpenAI image generation models
    let targetSize = '1024x1024';
    let normalizedRatio = '1:1';

    if (requestedRatio === '9:16' || requestedRatio === 'portrait') {
      targetSize = '1024x1792';
      normalizedRatio = '9:16';
    } else if (requestedRatio === '16:9' || requestedRatio === 'landscape') {
      targetSize = '1792x1024';
      normalizedRatio = '16:9';
    } else if (body?.size) {
      targetSize = body.size;
    }

    const primaryKey = process.env.IMAGE_GEN_API_KEY || '';
    const secondaryKey = process.env.OPENAI_API_KEY || '';

    const keysToTry = [primaryKey, secondaryKey].filter(Boolean);

    // Try OpenAI models: gpt-image-2 (primary verified), gpt-image-1.5, chatgpt-image-latest, dall-e-3
    for (const key of keysToTry) {
      const modelsToTry = ['gpt-image-2', 'gpt-image-1.5', 'chatgpt-image-latest', 'dall-e-3'];
      for (const model of modelsToTry) {
        try {
          const payload: any = {
            model,
            prompt: trimmedPrompt,
            n: 1,
            size: targetSize,
          };

          const response = await fetch('https://api.openai.com/v1/images/generations', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${key}`,
            },
            body: JSON.stringify(payload),
          });

          if (response.ok) {
            const data = await response.json();
            const firstItem = data.data?.[0];
            if (firstItem) {
              let imageUrl = '';
              if (firstItem.b64_json) {
                imageUrl = firstItem.b64_json.startsWith('data:')
                  ? firstItem.b64_json
                  : `data:image/png;base64,${firstItem.b64_json}`;
              } else if (firstItem.url) {
                imageUrl = firstItem.url;
              }

              if (imageUrl) {
                return NextResponse.json({
                  success: true,
                  imageUrl,
                  prompt: trimmedPrompt,
                  model,
                  aspectRatio: normalizedRatio,
                  size: targetSize,
                });
              }
            }
          } else {
            const errText = await response.text();
            console.warn(`OpenAI image generation error with model ${model} (size: ${targetSize}):`, errText);
          }
        } catch (callErr) {
          console.warn(`Error invoking OpenAI model ${model}:`, callErr);
        }
      }
    }

    return NextResponse.json(
      { error: 'Image generation engine is currently busy. Please try again.' },
      { status: 500 }
    );
  } catch (error: any) {
    console.error('generate-image API route error:', error);
    return NextResponse.json(
      { error: error?.message || 'Failed to generate image' },
      { status: 500 }
    );
  }
}
