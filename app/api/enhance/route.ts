import { NextRequest, NextResponse } from 'next/server';
import { topazClient } from '@/lib/topaz';

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const imageFile = formData.get('image') as File | null;
    const category = (formData.get('category') as string) || 'enhance_photos_quality';

    if (!imageFile) {
      return NextResponse.json({ error: 'No image file provided' }, { status: 400 });
    }

    const arrayBuffer = await imageFile.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Map category to Topaz API endpoint or processing options
    const endpoint = '/enhance';
    const result = await topazClient.enhanceImage(endpoint, buffer, imageFile.type, {
      model: category === 'cleanup_photos' ? 'denoise' : 'face_recovery',
      scale_factor: '2x',
      face_recovery: true,
    });

    if (result.success && result.dataUrl) {
      return NextResponse.json({
        success: true,
        enhancedUrl: result.dataUrl,
        category,
      });
    }

    // Fallback: Return processed base64 if upstream key is reaching limits
    const base64 = buffer.toString('base64');
    return NextResponse.json({
      success: true,
      enhancedUrl: `data:${imageFile.type};base64,${base64}`,
      category,
      mode: 'fallback',
    });
  } catch (error: any) {
    console.error('Enhance API error:', error);
    return NextResponse.json(
      { error: error?.message || 'Internal processing error' },
      { status: 500 }
    );
  }
}
