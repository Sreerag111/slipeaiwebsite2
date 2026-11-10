// Types and configurations for Slipe AI GIF Studio

export type GifMode = 'image-to-gif' | 'text-to-gif';

export type AnimationStyleId =
  | 'natural_motion'
  | 'cinematic_motion'
  | 'face_animation'
  | 'hair_movement'
  | 'zoom_in'
  | 'zoom_out'
  | 'motion_3d'
  | 'cartoon'
  | 'dreamy'
  | 'loop'
  | 'custom';

export interface AnimationStyle {
  id: AnimationStyleId;
  label: string;
  tagline: string;
  description: string;
  iconName: string;
  badge?: string;
  promptGuidance: string;
  previewBg: string; // Gradient or styling for attractive card preview
}

export const ANIMATION_STYLES: AnimationStyle[] = [
  {
    id: 'natural_motion',
    label: 'Natural Motion',
    tagline: 'Subtle organic lifelike breathing',
    description: 'Natural ambient motion, gentle breathing, and realistic environmental micro-dynamics.',
    iconName: 'Wind',
    badge: 'Popular',
    promptGuidance: 'Apply subtle natural organic movement, gentle body breathing rhythm, and realistic atmospheric dynamics while preserving identity perfectly.',
    previewBg: 'from-blue-600 via-indigo-600 to-sky-500',
  },
  {
    id: 'cinematic_motion',
    label: 'Cinematic Motion',
    tagline: 'Hollywood camera push & lighting bloom',
    description: 'Slow dramatic dolly glide, shallow depth-of-field shift, and cinematic lighting rays.',
    iconName: 'Film',
    badge: 'Pro',
    promptGuidance: 'Dramatic cinematic slow motion with subtle lens push-in, shallow depth of field, and elegant cinema lighting rays.',
    previewBg: 'from-amber-600 via-rose-600 to-purple-600',
  },
  {
    id: 'face_animation',
    label: 'Face Animation',
    tagline: 'Gentle blink, warm smile & eye glance',
    description: 'Preserve 100% facial identity while adding natural eye blinking, gentle smile, and micro-expressions.',
    iconName: 'Smile',
    badge: 'Identity Locked',
    promptGuidance: 'Keep facial structure, bone structure, eye shape, teeth, and skin tone 100% identical. Animate natural eyelid blink and subtle warm smile expression easing.',
    previewBg: 'from-emerald-600 via-teal-600 to-cyan-600',
  },
  {
    id: 'hair_movement',
    label: 'Hair Movement',
    tagline: 'Breeze flowing through strands',
    description: 'Soft wind flowing through hair and fabric while keeping facial features strictly stationary.',
    iconName: 'Sparkles',
    promptGuidance: 'Generate realistic fluid wind blowing gently through strands of hair and clothing edges, keeping the face and body stable.',
    previewBg: 'from-purple-600 via-fuchsia-600 to-pink-500',
  },
  {
    id: 'zoom_in',
    label: 'Zoom In',
    tagline: 'Optical push into key details',
    description: 'Ultra-smooth optical camera zoom gliding toward the subject with crisp edge sharpness.',
    iconName: 'ZoomIn',
    promptGuidance: 'Smooth progressive optical zoom-in toward the central subject, maintaining crisp edge resolution and micro-textures.',
    previewBg: 'from-blue-500 via-cyan-500 to-teal-500',
  },
  {
    id: 'zoom_out',
    label: 'Zoom Out',
    tagline: 'Expanding environmental reveal',
    description: 'Smooth optical pull-back gradually revealing surrounding scene atmosphere and background depth.',
    iconName: 'ZoomOut',
    promptGuidance: 'Smooth progressive optical zoom-out from the subject, revealing surrounding atmospheric environment and depth.',
    previewBg: 'from-slate-700 via-slate-800 to-slate-950',
  },
  {
    id: 'motion_3d',
    label: '3D Motion',
    tagline: 'Dimensional perspective parallax',
    description: 'Simulates multi-layer 2.5D/3D camera parallax with foreground separation and realistic depth.',
    iconName: 'Layers',
    badge: 'Parallax',
    promptGuidance: 'Create a 3D parallax perspective shift where the foreground subject subtly shifts relative to the deep background.',
    previewBg: 'from-violet-600 via-purple-700 to-indigo-900',
  },
  {
    id: 'cartoon',
    label: 'Cartoon Animation',
    tagline: 'Stylized 2D animation energy',
    description: 'Vibrant illustrative animation with expressive frame-by-frame energy and character dynamism.',
    iconName: 'Palette',
    promptGuidance: 'Infuse animated illustrative charm and expressive movement while maintaining character recognition.',
    previewBg: 'from-amber-500 via-orange-500 to-red-500',
  },
  {
    id: 'dreamy',
    label: 'Dreamy Animation',
    tagline: 'Surreal soft light & particle glow',
    description: 'Floating ambient bokeh, shimmering particle dust, and soft ethereal light breathing.',
    iconName: 'Sun',
    promptGuidance: 'Ethereal dreamy light drift, glowing soft ambient bokeh particles, and surreal atmospheric aura.',
    previewBg: 'from-pink-500 via-rose-500 to-amber-400',
  },
  {
    id: 'loop',
    label: 'Loop Animation',
    tagline: 'Perfect seamless cycle',
    description: 'Continuous ping-pong or cycle motion engineered so the ending connects seamlessly back to the start.',
    iconName: 'Repeat',
    badge: 'Seamless',
    promptGuidance: 'Design a cyclic motion loop that concludes at the exact visual state of frame 1 for seamless infinite looping.',
    previewBg: 'from-emerald-500 via-blue-600 to-indigo-600',
  },
  {
    id: 'custom',
    label: 'Custom Animation',
    tagline: 'Full prompt creative control',
    description: 'Provide your own custom prompt directions to choreograph exact motion and interactions.',
    iconName: 'Sliders',
    promptGuidance: 'Follow user-provided custom animation instructions with high fidelity and temporal consistency.',
    previewBg: 'from-slate-800 via-slate-900 to-black',
  },
];

export interface GifGenerationSettings {
  duration: 2 | 3 | 4 | 5; // seconds
  fps: 8 | 12 | 15;
  quality: 'standard' | 'high';
  aspectRatio: 'original' | '1:1' | '4:5' | '9:16' | '16:9';
  loop: 'infinite';
  style: AnimationStyleId;
  prompt?: string;
  referenceImageUrl?: string;
}

export type GifJobStage =
  | 'queued'
  | 'uploading'
  | 'preparing'
  | 'generating_frames'
  | 'processing_frames'
  | 'encoding_gif'
  | 'optimizing'
  | 'completed'
  | 'failed';

export interface GifJobResult {
  jobId: string;
  gifUrl: string;
  originalImageUrl?: string;
  width: number;
  height: number;
  duration: number;
  fps: number;
  frameCount: number;
  fileSizeBytes: number;
  fileSizeFormatted: string;
  creditCost: number;
  createdAt: string;
  completedAt: string;
  mode: GifMode;
  style: AnimationStyleId;
  prompt: string;
}

export interface GifJob {
  id: string;
  userId: string;
  mode: GifMode;
  status: GifJobStage;
  progress: number; // 0 - 100
  stepLabel: string;
  error?: string;
  settings: GifGenerationSettings;
  creditCost: number;
  originalImageBase64?: string;
  originalImageUrl?: string;
  result?: GifJobResult;
  createdAt: string;
  updatedAt: string;
}

export interface GifHistoryItem {
  id: string;
  gifUrl: string;
  thumbnailUrl?: string;
  originalImageUrl?: string;
  mode: GifMode;
  style: AnimationStyleId;
  prompt: string;
  duration: number;
  fps: number;
  frameCount: number;
  fileSizeFormatted: string;
  createdAt: string;
}
