import { NextRequest, NextResponse } from 'next/server';
import { startGifJob } from '@/lib/gifJobManager';
import { GifMode, AnimationStyleId } from '@/lib/gifStudioTypes';

export const maxDuration = 120; // 2 minutes max for long-running Next.js execution

export async function POST(req: NextRequest) {
  try {
    const contentType = req.headers.get('content-type') || '';

    let mode: GifMode = 'image-to-gif';
    let style: AnimationStyleId = 'natural_motion';
    let prompt = '';
    let duration = 3;
    let fps = 12;
    let quality: 'standard' | 'high' = 'high';
    let aspectRatio: 'original' | '1:1' | '4:5' | '9:16' | '16:9' = 'original';
    let imageBuffer: Buffer | undefined;
    let imageMimeType: string | undefined;
    let originalImageBase64: string | undefined;

    if (contentType.includes('multipart/form-data')) {
      const formData = await req.formData();
      mode = (formData.get('mode') as GifMode) || 'image-to-gif';
      style = (formData.get('style') as AnimationStyleId) || 'natural_motion';
      prompt = (formData.get('prompt') as string) || '';
      duration = parseInt(formData.get('duration') as string, 10) || 3;
      fps = parseInt(formData.get('fps') as string, 10) || 12;
      quality = (formData.get('quality') as 'standard' | 'high') || 'high';
      aspectRatio = (formData.get('aspectRatio') as any) || 'original';

      const file = formData.get('image') as File | null;
      if (file && file.size > 0) {
        // Validation: Max file size 20MB
        if (file.size > 20 * 1024 * 1024) {
          return NextResponse.json(
            { error: 'Image size exceeds 20 MB limit. Please upload a smaller image.' },
            { status: 400 }
          );
        }

        const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
        if (!validTypes.includes(file.type)) {
          return NextResponse.json(
            { error: 'Unsupported image format. Please upload JPG, PNG, or WebP.' },
            { status: 400 }
          );
        }

        const arrayBuffer = await file.arrayBuffer();
        imageBuffer = Buffer.from(arrayBuffer);
        imageMimeType = file.type;
      }
    } else {
      const body = await req.json();
      mode = body.mode || 'image-to-gif';
      style = body.style || 'natural_motion';
      prompt = body.prompt || '';
      duration = body.duration || 3;
      fps = body.fps || 12;
      quality = body.quality || 'high';
      aspectRatio = body.aspectRatio || 'original';
      originalImageBase64 = body.originalImageBase64;
    }

    // Input Validation
    if (mode === 'image-to-gif' && !imageBuffer && !originalImageBase64) {
      return NextResponse.json(
        { error: 'Please upload an image to animate.' },
        { status: 400 }
      );
    }

    if (mode === 'text-to-gif' && (!prompt || !prompt.trim())) {
      return NextResponse.json(
        { error: 'Please enter a description for your GIF animation.' },
        { status: 400 }
      );
    }

    // Start background asynchronous generation job
    const { jobId, creditCost } = await startGifJob({
      mode,
      style,
      prompt,
      duration,
      fps,
      quality,
      aspectRatio,
      imageBuffer,
      imageMimeType,
      originalImageBase64,
    });

    return NextResponse.json({
      success: true,
      jobId,
      creditCost,
      status: 'queued',
      message: 'GIF generation job enqueued successfully.',
    });
  } catch (err: any) {
    console.error('Error in /api/gif/generate:', err);
    return NextResponse.json(
      { error: err.message || 'Failed to start GIF generation. Please try again.' },
      { status: 500 }
    );
  }
}
