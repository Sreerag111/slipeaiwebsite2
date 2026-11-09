export interface EnhancementCategory {
  id: string;
  label: string;
  desc: string;
  file: string;
  stepText: string;
  model: string;
  badge?: string;
  iconName: string;
}

export const ENHANCEMENT_CATEGORIES: EnhancementCategory[] = [
  {
    id: 'enhance_photos_quality',
    label: 'Enhance Quality',
    desc: 'Restore facial details, super-resolution sharpness, and authentic skin texture.',
    file: 'enhance_photos_quality.webp',
    stepText: 'Applying Topaz High Fidelity super-resolution...',
    model: 'High Fidelity V3',
    badge: 'Popular',
    iconName: 'Sparkles',
  },
  {
    id: 'cleanup_photos',
    label: 'Clean Up Photos',
    desc: 'Remove sensor dust, context noise, compression artifacts, and spots automatically.',
    file: 'cleanup_photos.webp',
    stepText: 'Running Topaz Denoise Max context reconstruction...',
    model: 'Denoise Max',
    badge: 'Restoration',
    iconName: 'Wand2',
  },
  {
    id: 'bw_to_color',
    label: 'B&W to Color',
    desc: 'Synthesize natural human skin tones and authentic colors for vintage photographs.',
    file: 'bw_to_color.webp',
    stepText: 'Synthesizing authentic archival skin tones & natural color...',
    model: 'Wonder 3.5',
    badge: 'Generative AI',
    iconName: 'Palette',
  },
  {
    id: 'fix_lighting',
    label: 'Fix Lighting',
    desc: 'Dynamic exposure balance, highlight shadow recovery, and HDR clarity correction.',
    file: 'fix_lighting.webp',
    stepText: 'Calibrating exposure, highlight dynamic range & shadows...',
    model: 'Adjust V2',
    iconName: 'SunMedium',
  },
  {
    id: 'fix_dust_and_scratches',
    label: 'Dust & Scratches',
    desc: 'Repair tears, paper creases, surface cracks, and vintage physical damage.',
    file: 'fix_dust_and_scratches.webp',
    stepText: 'Removing deep scratches, creases & paper tears...',
    model: 'Extreme',
    badge: 'Archival',
    iconName: 'ShieldAlert',
  },
  {
    id: 'refine_photos',
    label: 'Refine Photos',
    desc: 'Micro-texture reconstruction, iris clarity, and studio portrait refinement.',
    file: 'refine_photos.webp',
    stepText: 'Reconstructing micro-textures & high-fidelity portrait detail...',
    model: 'High Fidelity V3',
    iconName: 'ScanFace',
  },
  {
    id: 'sharp_photos',
    label: 'Sharp Photos',
    desc: 'Eliminate optical lens softness, camera shake, and high-speed motion blur.',
    file: 'sharp_photos.webp',
    stepText: 'Synthesizing Topaz AI optical & motion deblur...',
    model: 'Strong',
    iconName: 'Zap',
  },
  {
    id: 'balance_colour',
    label: 'Balance Colour',
    desc: 'Calibrate white balance, color temperature, tint, and tonal richness accurately.',
    file: 'balance_colour.webp',
    stepText: 'Calibrating tone, contrast, and color temperature...',
    model: 'Adjust',
    iconName: 'SlidersHorizontal',
  },
  {
    id: 'upscale_photos',
    label: 'Upscale 4K',
    desc: 'Enlarge low-resolution images to crystal-clear 4K Ultra-HD without quality loss.',
    file: 'upscale_photos.webp',
    stepText: 'Executing Topaz 4K Ultra-HD super-resolution upscale...',
    model: 'Standard V2',
    badge: 'Ultra HD',
    iconName: 'Maximize2',
  },
  {
    id: 'remove_background',
    label: 'Cutout BG',
    desc: 'Studio sub-pixel alpha matting to isolate subjects with transparent backgrounds.',
    file: 'remove_background.webp',
    stepText: 'Isolating subject with Topaz sub-pixel alpha matting...',
    model: 'Object',
    badge: 'Transparent PNG',
    iconName: 'Scissors',
  },
];
