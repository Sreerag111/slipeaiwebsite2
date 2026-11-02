import { NextRequest, NextResponse } from 'next/server';
import { topazClient } from '@/lib/topaz';

interface CategoryConfig {
  endpoint: string;
  model: string;
  options: Record<string, any>;
  fallbackEndpoint?: string;
  fallbackModel?: string;
}

const CATEGORY_MAP: Record<string, CategoryConfig> = {
  // 1. AI super-resolution & facial details
  enhance_photos_quality: {
    endpoint: '/enhance',
    model: 'High Fidelity V3',
    options: {
      face_enhancement: true,
      face_enhancement_strength: 0.85,
    },
    fallbackEndpoint: '/enhance',
    fallbackModel: 'Standard V2',
  },

  // 2. Remove sensor dust, noise & spots
  cleanup_photos: {
    endpoint: '/denoise',
    model: 'Denoise Max',
    options: {},
    fallbackEndpoint: '/denoise',
    fallbackModel: 'Normal',
  },

  // 3. Authentic archival skin & colorization
  bw_to_color: {
    endpoint: '/enhance-gen/async',
    model: 'Wonder 3.5',
    options: {
      prompt: 'Restore with natural authentic human skin tones and full realistic color palette',
      face_enhancement: true,
    },
    fallbackEndpoint: '/lighting',
    fallbackModel: 'Adjust V2',
  },

  // 4. Dynamic exposure & shadow recovery
  fix_lighting: {
    endpoint: '/lighting',
    model: 'Adjust V2',
    options: {},
    fallbackEndpoint: '/lighting',
    fallbackModel: 'Adjust',
  },

  // 5. Repair vintage creases & sensor dust
  fix_dust_and_scratches: {
    endpoint: '/denoise',
    model: 'Extreme',
    options: {},
    fallbackEndpoint: '/denoise',
    fallbackModel: 'Strong',
  },

  // 6. Micro-texture & portrait refinement
  refine_photos: {
    endpoint: '/enhance',
    model: 'High Fidelity V3',
    options: {
      face_enhancement: true,
      face_enhancement_strength: 0.95,
      face_enhancement_creativity: 0.1,
    },
    fallbackEndpoint: '/enhance',
    fallbackModel: 'Standard V2',
  },

  // 7. Clear blur & crisp edge definition
  sharp_photos: {
    endpoint: '/sharpen',
    model: 'Strong',
    options: {
      face_enhancement: true,
    },
    fallbackEndpoint: '/sharpen',
    fallbackModel: 'Standard',
  },

  // 8. Calibrate tone & color temperature
  balance_colour: {
    endpoint: '/lighting',
    model: 'Adjust',
    options: {},
    fallbackEndpoint: '/lighting',
    fallbackModel: 'Adjust V2',
  },

  // 9. Ultra HD 4K lossless super-resolution
  upscale_photos: {
    endpoint: '/enhance',
    model: 'Standard V2',
    options: {
      output_width: 3840,
      crop_to_fill: false,
      face_enhancement: true,
    },
    fallbackEndpoint: '/enhance',
    fallbackModel: 'High Fidelity V3',
  },

  // 10. Studio alpha cutout for portraits
  remove_background: {
    endpoint: '/matting/async',
    model: 'Object',
    options: {
      output_format: 'png',
    },
  },
};

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

    // Retrieve the verified Topaz configuration for this category
    const config = CATEGORY_MAP[category] || CATEGORY_MAP.enhance_photos_quality;

    // 1. Primary Attempt with specific Topaz model
    let result = await topazClient.enhanceImage(config.endpoint, buffer, imageFile.type, {
      model: config.model,
      ...config.options,
    });

    // 2. Fallback attempt if primary model encountered an error
    if (!result.success && config.fallbackEndpoint && config.fallbackModel) {
      console.warn(`Primary model ${config.model} failed for ${category}: ${result.error}. Trying fallback ${config.fallbackModel}...`);
      result = await topazClient.enhanceImage(config.fallbackEndpoint, buffer, imageFile.type, {
        model: config.fallbackModel,
        ...config.options,
      });
    }

    if (result.success && result.dataUrl) {
      return NextResponse.json({
        success: true,
        enhancedUrl: result.dataUrl,
        category,
        model: config.model,
        endpoint: config.endpoint,
      });
    }

    // If Topaz API reported an explicit error
    console.error(`Topaz processing failed for category [${category}]:`, result.error);
    return NextResponse.json(
      {
        error: result.error || 'Failed to process image with Topaz engine. Please try again.',
      },
      { status: 502 }
    );
  } catch (error: any) {
    console.error('Enhance API route error:', error);
    return NextResponse.json(
      { error: error?.message || 'Internal processing error' },
      { status: 500 }
    );
  }
}
