'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import {
  Sparkles,
  Download,
  RotateCcw,
  ArrowUpRight,
  Check,
} from 'lucide-react';
import { saveAs } from 'file-saver';

interface AIImageCreationProps {
  onStartEnhancing?: () => void;
}

export function AIImageCreation({ onStartEnhancing }: AIImageCreationProps) {
  const [prompt, setPrompt] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatedImageUrl, setGeneratedImageUrl] = useState<string | null>(null);
  const [lastPrompt, setLastPrompt] = useState<string>('');

  const stylePresets = [
    {
      label: 'Vintage 90s Camera',
      prompt: 'A candid 1990s 35mm film photograph of a young artist in a sunlit loft, natural film grain, warm muted tones, subtle lens flare',
      img: '/assets/images/create_image_categories/nineties_camera.png',
    },
    {
      label: 'Studio Photoshoot',
      prompt: 'A high-end editorial fashion portrait, dramatic studio softbox lighting, ultra-sharp facial micro-texture, 85mm f/1.4 depth of field',
      img: '/assets/images/create_image_categories/photoshoot.png',
    },
    {
      label: 'Golden Hour Glow',
      prompt: 'A breathtaking scenic portrait during golden hour sunset, rich amber backlight, cinematic rim lighting, photorealistic landscape in background',
      img: '/assets/images/create_image_categories/golden_effect.png',
    },
    {
      label: 'Archival Black & White',
      prompt: 'A timeless black and white archival portrait, dramatic chiaroscuro contrast, deep shadows, authentic analog monochrome texture',
      img: '/assets/images/create_image_categories/black_and_white.png',
    },
    {
      label: 'Aesthetic Collage',
      prompt: 'An artistic aesthetic editorial collage featuring modern streetwear, bold typography overlays, film border aesthetics',
      img: '/assets/images/create_image_categories/aesthetic_collage.png',
    },
    {
      label: 'Korean Streetwear',
      prompt: 'A stylish Korean fashion street photography shot in Seoul at dusk, neon reflection on wet pavement, modern oversized clothing, clean aesthetic',
      img: '/assets/images/create_image_categories/korean_streetwear.png',
    },
  ];

  const handleGenerate = async (customPrompt?: string) => {
    const textToUse = customPrompt || prompt;
    if (!textToUse.trim()) return;

    setIsGenerating(true);

    try {
      const res = await fetch('/api/generate-image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: textToUse }),
      });

      const data = await res.json();
      if (res.ok && data.imageUrl) {
        setGeneratedImageUrl(data.imageUrl);
        setLastPrompt(textToUse);
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
        saveAs(blob, `slipeai_creation_${Date.now()}.png`);
      } else {
        saveAs(generatedImageUrl, `slipeai_creation_${Date.now()}.png`);
      }
    } catch (e) {
      console.error('Download error:', e);
      window.open(generatedImageUrl, '_blank');
    }
  };

  return (
    <section id="create" className="py-14 sm:py-20 md:py-28 border-t border-slate-200/80 bg-[#F8FAFC]">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-14 space-y-3">
          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
            AI Image Creation
          </h2>
          <p className="text-xs sm:text-sm md:text-base text-slate-600 font-semibold max-w-2xl mx-auto px-2">
            Describe your vision in words and generate photorealistic, high-resolution imagery.
          </p>
        </div>

        {/* Main Creation Card */}
        <div className="rounded-3xl border border-slate-200/90 bg-white p-4 sm:p-7 md:p-9 container-shade-xl space-y-6 sm:space-y-8">
          {/* Top Bar (Shown when an image is generated to allow creating a new one) */}
          {generatedImageUrl && (
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <span className="text-xs sm:text-sm font-bold text-slate-900">
                Generated Image
              </span>
              <button
                onClick={() => {
                  setGeneratedImageUrl(null);
                  setPrompt('');
                }}
                className="flex items-center gap-1.5 text-xs font-bold text-blue-600 hover:text-blue-800 transition-colors"
              >
                <RotateCcw className="h-3.5 w-3.5" />
                <span>Create New Image</span>
              </button>
            </div>
          )}

          {/* Central Output / Showcase Stage */}
          {isGenerating ? (
            /* Generating Stage: ONLY show Generating with animation (no icons, no subtitles, no progress bar) */
            <div className="relative aspect-square sm:aspect-[16/10] max-h-[520px] w-full rounded-2xl border border-slate-200 bg-slate-50/90 flex items-center justify-center p-6 overflow-hidden container-shade">
              {/* Full container background shimmer sweep */}
              <div className="absolute inset-0 pointer-events-none overflow-hidden">
                <div className="w-[200%] h-full -translate-x-full animate-shimmer bg-gradient-to-r from-transparent via-blue-500/10 to-transparent" />
              </div>

              {/* ONLY "Generating" with animation */}
              <div className="relative z-10 flex items-baseline justify-center gap-1.5">
                <span className="text-3xl sm:text-4xl md:text-5xl font-black text-slate-950 tracking-tight animate-pulse">
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
            /* Output Display Stage */
            <div className="space-y-6">
              <div className="relative aspect-square sm:aspect-[16/10] max-h-[560px] w-full rounded-2xl overflow-hidden border border-slate-200 bg-slate-900 flex items-center justify-center container-shade-lg group">
                <img
                  src={generatedImageUrl}
                  alt={lastPrompt}
                  className="max-h-full max-w-full object-contain"
                />
              </div>

              {/* Prompt recap & action buttons */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 p-4 rounded-2xl bg-slate-50 border border-slate-200/80">
                <div className="space-y-0.5 max-w-xl">
                  <span className="text-[10px] font-black uppercase tracking-wider text-slate-500">
                    Generated Description
                  </span>
                  <p className="text-xs sm:text-sm font-bold text-slate-900 line-clamp-2">
                    &ldquo;{lastPrompt}&rdquo;
                  </p>
                </div>

                <div className="flex flex-wrap items-center gap-2.5 w-full sm:w-auto">
                  <button
                    onClick={handleDownload}
                    className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-md transition-all active:scale-95"
                  >
                    <Download className="h-4 w-4" />
                    <span>Download Image</span>
                  </button>

                  <button
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

          {/* Popular Inspiration Styles (Click to try) */}
          <div className="rounded-3xl border border-slate-200/80 bg-slate-50/50 p-4 sm:p-6 container-shade-sm space-y-3.5">
            <div>
              <h3 className="text-xs sm:text-sm font-bold text-slate-900 tracking-tight">
                Popular Inspiration Styles
              </h3>
              <p className="text-[11px] sm:text-xs text-slate-500 font-medium">
                Click any style to generate instantly or inspire your description
              </p>
            </div>

            {/* Amazing Responsive Grid: 2 cols on mobile, 3 cols on tablet, 6 cols on laptop/desktop */}
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
              {stylePresets.map((style, idx) => {
                const isSelected = prompt === style.prompt;
                return (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => {
                      setPrompt(style.prompt);
                      handleGenerate(style.prompt);
                    }}
                    className={`group flex flex-col p-2.5 sm:p-3 rounded-2xl border text-left transition-all duration-300 active:scale-[0.98] focus:outline-none ${
                      isSelected
                        ? 'border-blue-600 bg-blue-50/40 ring-2 ring-blue-500/20 container-shade-md'
                        : 'border-slate-200/90 bg-white hover:border-blue-500 hover:bg-blue-50/20 container-shade-sm hover:container-shade hover:-translate-y-1'
                    }`}
                  >
                    <div className="relative aspect-square w-full rounded-xl overflow-hidden border border-slate-100 mb-2.5 bg-slate-100 shadow-inner">
                      <Image
                        src={style.img}
                        alt={style.label}
                        fill
                        sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 16vw"
                        className="object-cover group-hover:scale-110 transition-transform duration-500 ease-out"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-slate-950/70 via-slate-950/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-2 pointer-events-none">
                        <span className="text-[10px] font-bold text-white bg-blue-600/95 px-2 py-0.5 rounded-md backdrop-blur-sm shadow-sm flex items-center gap-1">
                          <Sparkles className="h-2.5 w-2.5" /> Try Style
                        </span>
                      </div>
                      {isSelected && (
                        <div className="absolute top-2 right-2 bg-blue-600 text-white p-1 rounded-full shadow-md">
                          <Check className="h-3 w-3" />
                        </div>
                      )}
                    </div>
                    <span className="text-xs sm:text-[13px] font-bold text-slate-900 group-hover:text-blue-700 transition-colors line-clamp-1">
                      {style.label}
                    </span>
                    <span className="text-[10px] sm:text-[11px] text-slate-500 font-semibold flex items-center justify-between gap-1 mt-0.5 group-hover:text-blue-600 transition-colors">
                      <span>Click to try</span>
                      <ArrowUpRight className="h-3.5 w-3.5 opacity-60 group-hover:opacity-100 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-all duration-200" />
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Bottom Prompt Bar: "Describe your image" */}
          <div className="rounded-3xl border border-slate-200/80 bg-slate-50/60 p-3 sm:p-4 container-shade-sm space-y-2">
            <div className="relative flex flex-col sm:flex-row gap-2.5 items-stretch sm:items-center">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={prompt}
                  onChange={(e) => setPrompt(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !isGenerating) {
                      handleGenerate();
                    }
                  }}
                  disabled={isGenerating}
                  placeholder="Describe your image (e.g., A vintage 1950s cinematic portrait with warm golden hour lighting)..."
                  className="w-full bg-white border-2 border-slate-200 focus:border-blue-600 focus:ring-4 focus:ring-blue-500/10 px-4 sm:px-5 py-3.5 rounded-2xl text-xs sm:text-sm text-slate-950 font-medium placeholder-slate-400 outline-none transition-all shadow-inner"
                />
              </div>

              <button
                type="button"
                onClick={() => handleGenerate()}
                disabled={isGenerating || !prompt.trim()}
                className="flex items-center justify-center gap-2 px-6 sm:px-8 py-3.5 rounded-2xl bg-blue-600 hover:bg-blue-700 disabled:bg-slate-300 text-white font-black text-xs sm:text-sm uppercase tracking-wider shadow-md hover:shadow-lg disabled:shadow-none transition-all active:scale-95 shrink-0"
              >
                <Sparkles className="h-4 w-4" />
                <span>{isGenerating ? 'Generating...' : 'Generate Image'}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}