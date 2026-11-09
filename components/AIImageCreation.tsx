'use client';

import React, { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import {
  Sparkles,
  Download,
  RotateCcw,
  ArrowUpRight,
  ArrowRight,
  ChevronLeft,
  ChevronRight,
  Check,
  Plus,
  X,
  Camera,
  SunMedium,
  Palette,
  Layers,
  Zap,
  Image as ImageIcon,
  Wand2,
  Paintbrush,
  PenTool,
  Film,
} from 'lucide-react';
import { saveAs } from 'file-saver';

interface AIImageCreationProps {
  onStartEnhancing?: () => void;
  onStartRemasterVideo?: () => void;
}

export type AspectRatio = '9:16' | '16:9' | '1:1';

interface StylePreset {
  label: string;
  desc: string;
  prompt: string;
  img: string;
  icon: React.ElementType;
}

export function AIImageCreation({
  onStartEnhancing,
  onStartRemasterVideo,
}: AIImageCreationProps) {
  const [prompt, setPrompt] = useState('');
  const [aspectRatio, setAspectRatio] = useState<AspectRatio>('9:16');
  const [generatedRatio, setGeneratedRatio] = useState<AspectRatio>('9:16');
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatedImageUrl, setGeneratedImageUrl] = useState<string | null>(null);
  const [lastPrompt, setLastPrompt] = useState<string>('');

  // Image Upload state for reference image
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [uploadedPreviewUrl, setUploadedPreviewUrl] = useState<string | null>(null);
  const fileUploadInputRef = useRef<HTMLInputElement>(null);

  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const promptInputRef = useRef<HTMLInputElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

  const stylePresets: StylePreset[] = [
    {
      label: "Vintage 90's Camera",
      desc: 'Authentic 35mm film grain, warm nostalgic tones, and analog color.',
      prompt: 'A candid 1990s 35mm film photograph of a young artist in a sunlit loft, natural film grain, warm muted tones, subtle lens flare',
      img: '/assets/images/create_image_categories/nineties_camera.png',
      icon: Camera,
    },
    {
      label: 'AI Photoshoot',
      desc: 'High-end editorial fashion portrait with dramatic softbox studio lighting.',
      prompt: 'A high-end editorial fashion portrait, dramatic studio softbox lighting, ultra-sharp facial micro-texture, 85mm f/1.4 depth of field',
      img: '/assets/images/create_image_categories/photoshoot.png',
      icon: Sparkles,
    },
    {
      label: 'Golden Hour Glow',
      desc: 'Breathtaking sunset backlighting with cinematic amber rim light.',
      prompt: 'A breathtaking scenic portrait during golden hour sunset, rich amber backlight, cinematic rim lighting, photorealistic landscape in background',
      img: '/assets/images/create_image_categories/golden_effect.png',
      icon: SunMedium,
    },
    {
      label: 'Archival Black & White',
      desc: 'Timeless chiaroscuro monochrome portrait with deep shadows and contrast.',
      prompt: 'A timeless black and white archival portrait, dramatic chiaroscuro contrast, deep shadows, authentic analog monochrome texture',
      img: '/assets/images/create_image_categories/black_and_white.png',
      icon: Palette,
    },
    {
      label: 'Aesthetic Collage',
      desc: 'Modern editorial collage with bold typography and film borders.',
      prompt: 'An artistic aesthetic editorial collage featuring modern streetwear, bold typography overlays, film border aesthetics',
      img: '/assets/images/create_image_categories/aesthetic_collage.png',
      icon: Layers,
    },
    {
      label: 'Korean Streetwear',
      desc: 'Seoul neon reflections on wet pavement with modern oversized styling.',
      prompt: 'A stylish Korean fashion street photography shot in Seoul at dusk, neon reflection on wet pavement, modern oversized clothing, clean aesthetic',
      img: '/assets/images/create_image_categories/korean_streetwear.png',
      icon: Zap,
    },
    {
      label: 'Polaroid Film',
      desc: 'Classic instant camera framing with soft pastel vintage tones.',
      prompt: 'An authentic vintage instant Polaroid photo with retro frame, soft analog lens flare, warm pastel color temperature, nostalgic tone',
      img: '/assets/images/create_image_categories/polaroid_frame.png',
      icon: ImageIcon,
    },
    {
      label: 'Y2K Retro Vibe',
      desc: 'Futuristic 2000s cyber aesthetic with vibrant holographic colors.',
      prompt: 'A vibrant Y2K cyber aesthetic photo, holographic chromatic styling, early 2000s futuristic fashion, glossy metallic highlights',
      img: '/assets/images/create_image_categories/y2k_style.png',
      icon: Wand2,
    },
    {
      label: 'Anime & Cartoon',
      desc: 'Vibrant 3D animated character styling with expressive features.',
      prompt: 'A vibrant modern 3D anime cinematic character concept art, high-definition expressive eyes, Pixar-grade studio lighting, soft color grading',
      img: '/assets/images/create_image_categories/cartoon_look.png',
      icon: Paintbrush,
    },
    {
      label: 'Fine Art Sketch',
      desc: 'Hand-drawn graphite pencil drawing with cross-hatched shading.',
      prompt: 'A masterful fine art charcoal and graphite pencil sketch, delicate cross-hatching, museum archival paper texture, artistic realism',
      img: '/assets/images/create_image_categories/personality_sketch.png',
      icon: PenTool,
    },
  ];

  const checkScroll = () => {
    if (!scrollContainerRef.current) return;
    const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;
    setCanScrollLeft(scrollLeft > 10);
    setCanScrollRight(scrollLeft < scrollWidth - clientWidth - 10);
  };

  useEffect(() => {
    checkScroll();
    window.addEventListener('resize', checkScroll);
    return () => window.removeEventListener('resize', checkScroll);
  }, []);

  const handleScroll = (direction: 'left' | 'right') => {
    if (!scrollContainerRef.current) return;
    const scrollAmount = Math.min(scrollContainerRef.current.clientWidth * 0.8, 680);
    scrollContainerRef.current.scrollBy({
      left: direction === 'left' ? -scrollAmount : scrollAmount,
      behavior: 'smooth',
    });
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setUploadedFile(file);
      if (uploadedPreviewUrl) {
        URL.revokeObjectURL(uploadedPreviewUrl);
      }
      setUploadedPreviewUrl(URL.createObjectURL(file));
      if (!prompt.trim()) {
        setPrompt(`Remaster and transform this photo in ${aspectRatio} ratio with realistic high-end texture`);
      }
    }
  };

  const handleRemoveUploadedFile = () => {
    if (uploadedPreviewUrl) {
      URL.revokeObjectURL(uploadedPreviewUrl);
    }
    setUploadedFile(null);
    setUploadedPreviewUrl(null);
    if (fileUploadInputRef.current) {
      fileUploadInputRef.current.value = '';
    }
  };

  const handleGenerate = async (customPrompt?: string) => {
    const textToUse = customPrompt || prompt;
    if (!textToUse.trim()) return;

    setIsGenerating(true);

    try {
      const res = await fetch('/api/generate-image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt: textToUse,
          aspectRatio,
        }),
      });

      const data = await res.json();
      if (res.ok && data.imageUrl) {
        setGeneratedImageUrl(data.imageUrl);
        setLastPrompt(textToUse);
        setGeneratedRatio(data.aspectRatio || aspectRatio);
      } else {
        alert(data.error || 'Failed to generate image. Please try again.');
      }
    } catch (err) {
      console.error('Image generation error:', err);
      alert('Network error connecting to image generation service.');
    } finally {
      setIsGenerating(false);
    }
  };

  const handleDownload = () => {
    if (!generatedImageUrl) return;
    try {
      const ratioTag = generatedRatio.replace(':', 'x');
      if (generatedImageUrl.startsWith('data:')) {
        const parts = generatedImageUrl.split(',');
        const mime = parts[0].match(/:(.*?);/)?.[1] || 'image/png';
        const byteCharacters = atob(parts[1]);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: mime });
        saveAs(blob, `slipeai_creation_${ratioTag}_${Date.now()}.png`);
      } else {
        saveAs(generatedImageUrl, `slipeai_creation_${ratioTag}_${Date.now()}.png`);
      }
    } catch (e) {
      console.error('Download error:', e);
      window.open(generatedImageUrl, '_blank');
    }
  };

  // Dynamic layout classes based on aspect ratio
  const stageRatioClass =
    aspectRatio === '9:16'
      ? 'aspect-[9/16] max-h-[580px] max-w-sm mx-auto'
      : aspectRatio === '16:9'
      ? 'aspect-video max-h-[520px] w-full'
      : 'aspect-square max-h-[520px] max-w-xl mx-auto';

  const outputRatioClass =
    generatedRatio === '9:16'
      ? 'aspect-[9/16] max-h-[640px] max-w-sm sm:max-w-md mx-auto'
      : generatedRatio === '16:9'
      ? 'aspect-video max-h-[560px] w-full'
      : 'aspect-square max-h-[560px] max-w-xl mx-auto';

  return (
    <section id="create" className="pt-8 pb-16 sm:pt-12 sm:pb-20 md:pt-16 md:pb-28 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 space-y-8 sm:space-y-12">
        {/* Central Search / Image Creation Bar with '+' File Upload Option */}
        <div className="max-w-3xl mx-auto w-full space-y-3">
          <div className="relative rounded-full border border-slate-200/90 bg-white shadow-[0_8px_30px_rgba(0,0,0,0.06)] px-2 sm:px-3 py-2 flex items-center gap-2 transition-all focus-within:border-blue-600 focus-within:ring-4 focus-within:ring-blue-500/10">
            {/* '+' File Upload Button with 'More options' Tooltip (Matches reference image) */}
            <div className="relative group/more shrink-0">
              <input
                ref={fileUploadInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handleFileUpload}
                className="hidden"
              />

              <button
                type="button"
                onClick={() => fileUploadInputRef.current?.click()}
                className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-700 flex items-center justify-center transition-all active:scale-95 shadow-2xs"
                aria-label="Upload photo or file"
              >
                <Plus className="w-4 h-4 sm:w-5 sm:h-5 text-slate-800" />
              </button>

              {/* Floating Tooltip: 'More options' (matches reference image) */}
              <div className="absolute -top-9 left-1/2 -translate-x-1/2 opacity-0 group-hover/more:opacity-100 pointer-events-none transition-opacity duration-200 bg-white text-slate-900 border border-slate-200 shadow-md text-[11px] font-bold px-2.5 py-0.5 rounded-lg whitespace-nowrap font-display z-20">
                <span>More options</span>
              </div>
            </div>

            {/* Uploaded File Chip (if user selected a photo) */}
            {uploadedPreviewUrl && (
              <div className="inline-flex items-center gap-1.5 p-1 pr-2 rounded-full bg-blue-50 border border-blue-200 text-blue-950 shrink-0">
                <img
                  src={uploadedPreviewUrl}
                  alt="Uploaded preview"
                  className="w-6 h-6 rounded-full object-cover"
                />
                <span className="text-[11px] font-bold truncate max-w-[80px] sm:max-w-[120px] font-display">
                  {uploadedFile?.name || 'Photo'}
                </span>
                <button
                  type="button"
                  onClick={handleRemoveUploadedFile}
                  className="p-0.5 rounded-full hover:bg-blue-200 text-blue-700 transition-colors"
                  aria-label="Remove uploaded photo"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            )}

            {/* Main Prompt Input Field */}
            <input
              ref={promptInputRef}
              type="text"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !isGenerating) {
                  handleGenerate();
                }
              }}
              disabled={isGenerating}
              placeholder={`Describe your idea in ${aspectRatio} ratio (e.g. Vintage 90s portrait)...`}
              className="flex-1 min-w-0 bg-transparent border-none text-xs sm:text-sm text-slate-900 font-display font-medium placeholder-slate-400 focus:outline-none px-2"
            />

            {/* Aspect Ratio Selector Pills */}
            <div className="inline-flex items-center gap-1 p-0.5 bg-slate-100/90 rounded-full border border-slate-200/80 shrink-0">
              {(['9:16', '16:9', '1:1'] as AspectRatio[]).map((r) => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setAspectRatio(r)}
                  className={`px-2 sm:px-2.5 py-1 rounded-full text-[10.5px] sm:text-[11px] font-bold font-display transition-all ${
                    aspectRatio === r
                      ? 'bg-blue-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-950 hover:bg-white/80'
                  }`}
                >
                  {r}
                </button>
              ))}
            </div>

            {/* Generate Action Button */}
            <button
              type="button"
              onClick={() => handleGenerate()}
              disabled={isGenerating || !prompt.trim()}
              className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-slate-950 hover:bg-slate-800 disabled:bg-slate-300 text-white flex items-center justify-center transition-all shadow-sm active:scale-95 shrink-0 font-display"
              aria-label="Generate Image"
            >
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Output & Generating Workspace Stage */}
        {(isGenerating || generatedImageUrl) && (
          <div className="max-w-4xl mx-auto rounded-[28px] sm:rounded-[32px] border border-slate-200/90 bg-white p-5 sm:p-8 md:p-10 shadow-[0_4px_24px_rgba(0,0,0,0.05)] space-y-6">
            {generatedImageUrl && (
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <span className="text-xs sm:text-sm font-bold text-slate-950 font-display">
                  Generated Image
                </span>
                <button
                  type="button"
                  onClick={() => {
                    setGeneratedImageUrl(null);
                    setPrompt('');
                  }}
                  className="flex items-center gap-1.5 text-xs font-bold text-blue-600 hover:text-blue-800 transition-colors font-display"
                >
                  <RotateCcw className="h-3.5 w-3.5" />
                  <span>Create New Image</span>
                </button>
              </div>
            )}

            {isGenerating ? (
              /* Generating animation stage */
              <div className={`relative ${stageRatioClass} w-full rounded-[24px] sm:rounded-[28px] border border-slate-200/90 bg-white flex items-center justify-center p-6 overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.05)] transition-all duration-300`}>
                <div className="absolute inset-0 pointer-events-none overflow-hidden">
                  <div className="w-[200%] h-full -translate-x-full animate-shimmer bg-gradient-to-r from-transparent via-blue-500/10 to-transparent" />
                </div>

                <div className="relative z-10 flex items-baseline justify-center gap-1.5 font-display">
                  <span className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-950 tracking-tight animate-pulse">
                    Generating
                  </span>
                  <span className="inline-flex gap-1.5 items-center mb-1">
                    <span className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-blue-600 animate-bounce [animation-delay:-0.3s]" />
                    <span className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-blue-600 animate-bounce [animation-delay:-0.15s]" />
                    <span className="h-2 w-2 sm:h-2.5 sm:w-2.5 rounded-full bg-blue-600 animate-bounce" />
                  </span>
                </div>
              </div>
            ) : generatedImageUrl ? (
              /* Generated Image Display */
              <div className="space-y-6">
                <div className={`relative ${outputRatioClass} w-full rounded-[24px] sm:rounded-[28px] overflow-hidden border border-slate-200/90 bg-slate-950 flex items-center justify-center shadow-xl transition-all duration-300`}>
                  <img
                    src={generatedImageUrl}
                    alt={lastPrompt}
                    className="max-h-full max-w-full object-contain"
                  />

                  {/* Ratio Badge */}
                  <div className="absolute top-3 right-3 flex items-center bg-slate-950/85 backdrop-blur-md border border-white/10 text-white text-[11px] font-bold px-2.5 py-1 rounded-lg shadow-md font-display">
                    <span className="text-blue-400">{generatedRatio}</span>
                  </div>
                </div>

                {/* Prompt recap & action buttons */}
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-4 sm:p-5 rounded-[22px] sm:rounded-[26px] bg-slate-50/80 border border-slate-200/80 font-display">
                  <div className="space-y-0.5 max-w-xl">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500">
                      Generated Description ({generatedRatio})
                    </span>
                    <p className="text-xs sm:text-sm font-bold text-slate-900 line-clamp-2">
                      &ldquo;{lastPrompt}&rdquo;
                    </p>
                  </div>

                  <div className="flex flex-wrap items-center gap-2.5 w-full sm:w-auto">
                    <button
                      type="button"
                      onClick={handleDownload}
                      className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-slate-950 hover:bg-slate-800 text-white font-bold text-xs shadow-md transition-all active:scale-95"
                    >
                      <Download className="h-4 w-4" />
                      <span>Download Image ({generatedRatio})</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        if (onStartEnhancing) {
                          onStartEnhancing();
                        } else {
                          const el = document.getElementById('enhancer');
                          if (el) el.scrollIntoView({ behavior: 'smooth' });
                        }
                      }}
                      className="flex-1 sm:flex-none flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl border border-blue-200 bg-blue-50 text-blue-900 hover:bg-blue-100 font-bold text-xs transition-all active:scale-95"
                    >
                      <span>Upscale in Slipe AI</span>
                      <ArrowUpRight className="h-3.5 w-3.5 text-blue-700" />
                    </button>
                  </div>
                </div>
              </div>
            ) : null}
          </div>
        )}

        {/* Featured Styles & Presets Carousel (Clearly visible large cards) */}
        <div className="pt-2">
          {/* Carousel Container with Circular Navigation Buttons */}
          <div className="relative group/carousel">
            {canScrollLeft && (
              <button
                type="button"
                onClick={() => handleScroll('left')}
                aria-label="Previous styles"
                className="absolute -left-3 sm:-left-5 top-1/2 -translate-y-1/2 z-20 w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-white text-slate-900 border border-slate-200/90 shadow-xl flex items-center justify-center transition-all hover:scale-105 hover:bg-slate-50 active:scale-95"
              >
                <ChevronLeft className="w-5 h-5 sm:w-6 sm:h-6 text-slate-800" />
              </button>
            )}

            {canScrollRight && (
              <button
                type="button"
                onClick={() => handleScroll('right')}
                aria-label="Next styles"
                className="absolute -right-3 sm:-right-5 top-1/2 -translate-y-1/2 z-20 w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-white text-slate-900 border border-slate-200/90 shadow-xl flex items-center justify-center transition-all hover:scale-105 hover:bg-slate-50 active:scale-95"
              >
                <ChevronRight className="w-5 h-5 sm:w-6 sm:h-6 text-slate-800" />
              </button>
            )}

            {/* Horizontal Scrollable Row of Style Cards */}
            <div
              ref={scrollContainerRef}
              onScroll={checkScroll}
              className="flex gap-4 sm:gap-6 overflow-x-auto scroll-smooth pb-6 pt-2 px-1 scrollbar-none snap-x snap-mandatory"
            >
              {stylePresets.map((style, idx) => {
                const Icon = style.icon;
                const isSelected = prompt === style.prompt;

                return (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => {
                      setPrompt(style.prompt);
                      handleGenerate(style.prompt);
                      promptInputRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }}
                    className={`w-[280px] sm:w-[320px] md:w-[340px] shrink-0 snap-start flex flex-col p-3.5 sm:p-4 rounded-[24px] sm:rounded-[28px] bg-white border transition-all duration-300 active:scale-[0.98] group text-left ${
                      isSelected
                        ? 'border-blue-600 ring-2 ring-blue-500/20 shadow-[0_16px_36px_rgba(0,0,0,0.1)] scale-[1.01]'
                        : 'border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] hover:shadow-[0_16px_36px_rgba(0,0,0,0.1)] hover:-translate-y-1.5'
                    }`}
                  >
                    {/* Media Visual */}
                    <div className="relative w-full aspect-[16/11] sm:aspect-[4/3] rounded-[18px] sm:rounded-[22px] overflow-hidden bg-slate-100 mb-3.5 sm:mb-4 shadow-inner border border-slate-100">
                      <img
                        src={style.img}
                        alt={style.label}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
                        loading="eager"
                      />

                      {/* Hover indicator: "Try Style ->" */}
                      <div className="absolute inset-0 bg-gradient-to-t from-slate-950/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-3 pointer-events-none">
                        <span className="text-[11px] font-bold text-white bg-blue-600/95 px-3 py-1 rounded-lg backdrop-blur-sm shadow-md flex items-center gap-1.5 font-display">
                          <span>Try Style</span>
                          <ArrowRight className="w-3 h-3" />
                        </span>
                      </div>

                      {isSelected && (
                        <div className="absolute top-3 right-3 bg-blue-600 text-white p-1 rounded-full shadow-md z-10">
                          <Check className="h-3.5 w-3.5" />
                        </div>
                      )}
                    </div>

                    {/* Card Info */}
                    <div className="space-y-1.5 flex-1 flex flex-col justify-between px-1 pb-1">
                      <div className="flex items-center gap-2.5">
                        <div className="flex items-center justify-center w-8 h-8 rounded-xl bg-slate-100 text-slate-900 group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0 shadow-sm">
                          <Icon className="w-4 h-4" />
                        </div>
                        <h4 className="text-base sm:text-lg font-bold text-slate-950 font-display tracking-tight group-hover:text-blue-700 transition-colors line-clamp-1">
                          {style.label}
                        </h4>
                      </div>

                      <p className="text-xs sm:text-[13px] text-slate-600 font-medium leading-relaxed font-display line-clamp-2">
                        {style.desc}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
