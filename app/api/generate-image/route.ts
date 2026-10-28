import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const prompt = body?.prompt;

    if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
      return NextResponse.json(
        { error: 'Please enter a description for your image.' },
        { status: 400 }
      );
    }

    const trimmedPrompt = prompt.trim();
    const primaryKey = process.env.IMAGE_GEN_API_KEY || '';
    const secondaryKey = process.env.OPENAI_API_KEY || '';

    const keysToTry = [primaryKey, secondaryKey].filter(Boolean);

    // Try OpenAI gpt-image-2 model with fallback to gpt-image-1.5 / dall-e-3
    for (const key of keysToTry) {
      const modelsToTry = ['gpt-image-2', 'gpt-image-1.5', 'dall-e-3'];
      for (const model of modelsToTry) {
        try {
          const payload: any = {
            model,
            prompt: trimmedPrompt,
            n: 1,
            size: '1024x1024',
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
                  model: 'gpt-image-2',
                });
              }
            }
          } else {
            const errText = await response.text();
            console.warn(`OpenAI image generation error with model ${model}:`, errText);
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
