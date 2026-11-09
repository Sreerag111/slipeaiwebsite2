export interface EnhancementCategory {
  id: string;
  label: string;
  desc: string;
  file: string;
  stepText: string;
  model: string;
  badge?: string;
}

export const ENHANCEMENT_CATEGORIES: EnhancementCategory[] = [
  {
    id: 'enhance_photos_quality',
    label: 'Enhance Quality',
    desc: 'Topaz High Fidelity AI super-resolution & facial details',
    file: 'enhance_photos_quality.webp',
    stepText: 'Applying Topaz High Fidelity super-resolution...',
    model: 'High Fidelity V3',
    badge: 'Popular',
  },
  {
    id: 'cleanup_photos',
    label: 'Clean Up Photos',
    desc: 'Topaz Denoise Max context noise & sensor dust reduction',
    file: 'cleanup_photos.webp',
    stepText: 'Running Topaz Denoise Max context reconstruction...',
    model: 'Denoise Max',
    badge: 'Restoration',
  },
  {
    id: 'bw_to_color',
    label: 'B&W to Color',
    desc: 'Topaz Wonder 3.5 authentic archival skin & colorization',
    file: 'bw_to_color.webp',
    stepText: 'Synthesizing authentic archival skin tones & natural color...',
    model: 'Wonder 3.5',
    badge: 'Generative AI',
  },
  {
    id: 'fix_lighting',
    label: 'Fix Lighting',
    desc: 'Topaz Adjust V2 dynamic exposure & shadow recovery',
    file: 'fix_lighting.webp',
    stepText: 'Calibrating exposure, highlight dynamic range & shadows...',
    model: 'Adjust V2',
  },
  {
    id: 'fix_dust_and_scratches',
    label: 'Dust & Scratches',
    desc: 'Topaz Extreme repair for vintage creases & damage',
    file: 'fix_dust_and_scratches.webp',
    stepText: 'Removing deep scratches, creases & paper tears...',
    model: 'Extreme',
  },
  {
    id: 'refine_photos',
    label: 'Refine Photos',
    desc: 'Topaz micro-texture & portrait facial refinement',
    file: 'refine_photos.webp',
    stepText: 'Reconstructing micro-textures & high-fidelity portrait detail...',
    model: 'High Fidelity V3',
  },
  {
    id: 'sharp_photos',
    label: 'Sharp Photos',
    desc: 'Topaz Strong camera shake & optical lens deblur',
    file: 'sharp_photos.webp',
    stepText: 'Synthesizing Topaz AI optical & motion deblur...',
    model: 'Strong',
  },
  {
    id: 'balance_colour',
    label: 'Balance Colour',
    desc: 'Topaz Adjust tone, white balance & color temperature',
    file: 'balance_colour.webp',
    stepText: 'Calibrating tone, contrast, and color temperature...',
    model: 'Adjust',
  },
  {
    id: 'upscale_photos',
    label: 'Upscale 4K',
    desc: 'Topaz Standard V2 Ultra HD 4K lossless enlargement',
    file: 'upscale_photos.webp',
    stepText: 'Executing Topaz 4K Ultra-HD super-resolution upscale...',
    model: 'Standard V2',
  },
  {
    id: 'remove_background',
    label: 'Cutout BG',
    desc: 'Topaz Object sub-pixel alpha matting for transparent portraits',
    file: 'remove_background.webp',
    stepText: 'Isolating subject with Topaz sub-pixel alpha matting...',
    model: 'Object',
    badge: 'Transparent PNG',
  },
];
