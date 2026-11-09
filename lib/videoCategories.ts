export interface VideoCategory {
  id: string;
  label: string;
  desc: string;
  file: string;
  iconName: string;
}

export const VIDEO_CATEGORIES: VideoCategory[] = [
  {
    id: 'precision',
    label: 'Precision Clarity',
    desc: 'Neural edge sharpness, texture definition, and micro-contrast enhancement.',
    file: 'precision.webp',
    iconName: 'Focus',
  },
  {
    id: 'auto',
    label: 'Auto Upscale',
    desc: 'Automatic 2x/4K video super-resolution with artifact suppression.',
    file: 'auto.webp',
    iconName: 'Maximize2',
  },
  {
    id: 'slow_motion',
    label: 'Slow Motion',
    desc: 'Optical flow 60fps frame interpolation for cinematic high-framerate fluid motion.',
    file: 'slow_motion.webp',
    iconName: 'PlayCircle',
  },
  {
    id: 'hdr',
    label: 'HDR Remaster',
    desc: 'Dynamic exposure balance, expanded dynamic range, and cinema tone mapping.',
    file: 'hdr.webp',
    iconName: 'SunMedium',
  },
  {
    id: 'motion_deblur',
    label: 'Motion Deblur',
    desc: 'Synthesize crisp frames by reversing high-speed action and camera shake.',
    file: 'motion_deblur.webp',
    iconName: 'Zap',
  },
  {
    id: 'colorize',
    label: 'Colorize Videos',
    desc: 'Authentic archival historical film colorization with realistic tones.',
    file: 'colorize.webp',
    iconName: 'Palette',
  },
  {
    id: 'denoise',
    label: 'Denoise Video',
    desc: 'Remove low-light sensor noise, grain, and high-ISO compression artifacts.',
    file: 'denoise.webp',
    iconName: 'ShieldAlert',
  },
  {
    id: 'creative',
    label: 'Creative Detail',
    desc: 'Cinematic neural texture synthesis and micro-detail generation for vintage clips.',
    file: 'creative.webp',
    iconName: 'Wand2',
  },
];
