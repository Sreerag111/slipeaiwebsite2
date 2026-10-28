'use client';

import React, { useState, useRef } from 'react';
import Image from 'next/image';
import { Sparkles, ArrowRight, ShieldCheck, Zap, Download, SlidersHorizontal, Image as ImageIcon } from 'lucide-react';

interface HeroProps {
  onStartEnhancing: () => void;
  onOpenPricing: () => void;
}

export function Hero({ onStartEnhancing, onOpenPricing }: HeroProps) {
  const [sliderPos, setSliderPos] = useState(50);
  const [isDragging, setIsDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const handlePointerDown = () => setIsDragging(true);
  const handlePointerUp = () => setIsDragging(false);

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!isDragging || !containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
    const percent = Math.max(0, Math.min(100, (x / rect.width) * 100));
    setSliderPos(percent);
  };

  return (
    <section className="relative overflow-hidden pt-12 pb-20 md:pt-20 md:pb-28">
      {/* Background glow effects */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 h-[450px] w-[700px] rounded-full bg-white/[0.04] blur-[120px]" />

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          {/* Left Column: Copy & Actions */}
          <div className="lg:col-span-7 space-y-6 text-center lg:text-left">
            {/* Pill Badge */}
            <div className="inline-flex items-center gap-2 rounded-full border border-neutral-800 bg-neutral-950 px-3.5 py-1.5 text-xs font-semibold text-neutral-300">
              <span className="flex h-2 w-2 rounded-full bg-white animate-pulse" />
              <span>Next-Gen Neural Restoration</span>
              <span className="text-neutral-500">•</span>
              <span className="text-white">v1.0.32 Live</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black tracking-tight text-white leading-[1.1]">
              Bring your photos back to life{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-white via-neutral-200 to-neutral-400">
                without losing original look!
              </span>
            </h1>

            {/* Sub-headline */}
            <p className="text-base sm:text-lg text-neutral-400 font-medium max-w-2xl mx-auto lg:mx-0">
              These enhancements are done in SlipeAI not fake. Restore historical damage, remove camera blur, boost resolution up to 4K, and preserve natural human skin textures.
            </p>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3.5 pt-2">
              <button
                onClick={onStartEnhancing}
                className="w-full sm:w-auto flex items-center justify-center gap-2.5 px-7 py-3.5 rounded-xl bg-white text-black font-extrabold text-sm hover:bg-neutral-200 transition-all duration-200 shadow-xl halo-shadow hover:scale-[1.02]"
              >
                <Sparkles className="h-4 w-4" />
                <span>Enhance Photo Now</span>
              </button>

              <a
                href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto flex items-center justify-center gap-2.5 px-6 py-3.5 rounded-xl border border-neutral-800 bg-neutral-950/80 text-white font-bold text-sm hover:border-neutral-600 transition-all duration-200"
              >
                <Download className="h-4 w-4 text-neutral-400" />
                <span>Google Play App</span>
              </a>
            </div>

            {/* Key Value Props */}
            <div className="grid grid-cols-3 gap-4 pt-6 border-t border-neutral-900 max-w-lg mx-auto lg:mx-0 text-left">
              <div>
                <p className="text-lg md:text-xl font-black text-white">4K Ultra</p>
                <p className="text-xs text-neutral-500 font-medium">Neural Upscaling</p>
              </div>
              <div>
                <p className="text-lg md:text-xl font-black text-white">100% Real</p>
                <p className="text-xs text-neutral-500 font-medium">True Face Texture</p>
              </div>
              <div>
                <p className="text-lg md:text-xl font-black text-white">Zero Cloud Leak</p>
                <p className="text-xs text-neutral-500 font-medium">Private & Encrypted</p>
              </div>
            </div>
          </div>

          {/* Right Column: Live Interactive Before/After Split Viewer */}
          <div className="lg:col-span-5 flex justify-center">
            <div className="w-full max-w-md">
              <div className="relative rounded-none border-2 border-white bg-neutral-950 p-1 halo-shadow">
                {/* Header tag */}
                <div className="flex items-center justify-between px-3 py-2 border-b border-neutral-800 bg-black text-xs font-semibold text-neutral-400">
                  <div className="flex items-center gap-2">
                    <span className="h-2 w-2 rounded-full bg-white" />
                    <span className="text-white font-bold uppercase tracking-wider text-[11px]">
                      Slipe AI Interactive Split
                    </span>
                  </div>
                  <span className="text-neutral-500 text-[10px]">Drag slider to compare</span>
                </div>

                {/* Slider Container */}
                <div
                  ref={containerRef}
                  onPointerDown={handlePointerDown}
                  onPointerUp={handlePointerUp}
                  onPointerMove={handlePointerMove}
                  className="relative aspect-square w-full select-none overflow-hidden cursor-ew-resize bg-neutral-950"
                >
                  {/* Enhanced Image (Base Layer) */}
                  <div className="absolute inset-0">
                    <Image
                      src="/assets/images/premium_showcase_1.jpg"
                      alt="Slipe AI Enhanced Photo"
                      fill
                      className="object-cover"
                      priority
                    />
                    <div className="absolute top-3 right-3 bg-white text-black text-[10px] font-black px-2 py-0.5 uppercase tracking-wider shadow">
                      After
                    </div>
                  </div>

                  {/* Original / Damaged Image (Clipped Overlay Layer) */}
                  <div
                    className="absolute inset-0 overflow-hidden"
                    style={{ clipPath: `polygon(0 0, ${sliderPos}% 0, ${sliderPos}% 100%, 0 100%)` }}
                  >
                    <div className="relative w-full h-full filter sepia-[0.35] contrast-[0.9] blur-[0.4px]">
                      <Image
                        src="/assets/images/premium_showcase_1.jpg"
                        alt="Original Damaged Photo"
                        fill
                        className="object-cover scale-[1.01]"
                      />
                    </div>
                    <div className="absolute top-3 left-3 bg-black/80 border border-neutral-700 text-white text-[10px] font-black px-2 py-0.5 uppercase tracking-wider shadow">
                      Before
                    </div>
                  </div>

                  {/* Draggable Divider Line & Knob */}
                  <div
                    className="absolute top-0 bottom-0 w-0.5 bg-white shadow-[0_0_10px_rgba(255,255,255,0.8)]"
                    style={{ left: `${sliderPos}%` }}
                  >
                    <div className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 h-8 w-8 rounded-full bg-black border-2 border-white flex items-center justify-center shadow-xl">
                      <SlidersHorizontal className="h-3.5 w-3.5 text-white" />
                    </div>
                  </div>
                </div>

                {/* Bottom caption */}
                <div className="p-3 bg-neutral-950 text-center">
                  <p className="text-xs font-semibold text-neutral-300">
                    Original vintage portrait restored using Slipe AI Face Recovery
                  </p>
                  <p className="text-[11px] text-neutral-500 mt-0.5">
                    Crisp facial geometry without synthetic AI hallucination
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
