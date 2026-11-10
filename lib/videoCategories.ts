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
    file: 'precision.mp4',
    iconName: 'Focus',
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
    file: 'hdr.mp4',
    iconName: 'SunMedium',
  },
  {
    id: 'motion_deblur',
    label: 'Motion Deblur',
    desc: 'Synthesize crisp frames by reversing high-speed action and camera shake.',
    file: 'motion_deblur.mp4',
    iconName: 'Zap',
  },
  {
    id: 'colorize',
    label: 'Colorize Videos',
    desc: 'Authentic archival historical film colorization with realistic tones.',
    file: 'colorize.mp4',
    iconName: 'Palette',
  },
  {
    id: 'denoise',
    label: 'Denoise Video',
    desc: 'Remove low-light sensor noise, grain, and high-ISO compression artifacts.',
    file: 'denoise.mp4',
    iconName: 'ShieldAlert',
  },
  {
    id: 'creative',
    label: 'Creative Detail',
    desc: 'Cinematic neural texture synthesis and micro-detail generation for vintage clips.',
    file: 'creative.mp4',
    iconName: 'Wand2',
  },
];
