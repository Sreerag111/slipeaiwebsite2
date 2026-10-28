'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { Sparkles, Download, CheckCircle2, ArrowLeft, Maximize2 } from 'lucide-react';

interface HeroProps {
  onStartEnhancing: () => void;
  onOpenPricing: () => void;
}

interface HeroPhoto {
  id: string;
  label: string;
  title: string;
  subtitle: string;
  tag: string;
  src: string;
  alt: string;
  badge: string;
  objectPosition: string;
}

const HERO_PHOTOS: HeroPhoto[] = [
  {
    id: 'restore',
    label: 'Restore',
    title: 'Vintage Photo Restored',
    subtitle: 'Removes deep scratches, creases & paper tears without facial distortion',
    tag: 'Scratch Repair',
    src: '/assets/images/hero/restore.jpg',
    alt: 'Vintage Photo Scratch and Crease Restoration Before and After',
    badge: '100% Real Texture',
    objectPosition: 'object-center',
  },
  {
    id: 'unblur',
    label: 'Unblur',
    title: 'Camera Blur Removed',
    subtitle: 'Deblurs camera shake & recovers high-fidelity iris and skin details',
    tag: '4K Sharpening',
    src: '/assets/images/hero/unblur.jpg',
    alt: 'Face Unblur and Exposure Fix Comparison Before and After',
    badge: 'Ultra-HD Detail',
    objectPosition: 'object-center',
  },
  {
    id: 'colorize',
    label: 'Colorize',
    title: 'B&W Photo to Color',
    subtitle: 'Authentic historical palette recovery preserving true human skin tones',
    tag: 'Historical Color',
    src: '/assets/images/hero/colorize.jpg',
    alt: 'Black and White to Colorized Photo Comparison Before and After',
    badge: 'Natural Palette',
    objectPosition: 'object-center',
  },
  {
    id: 'remove_bg',
    label: 'Cutout',
    title: 'Background Removed',
    subtitle: 'Pixel-perfect cutout isolating complex hair strands with clean transparency',
    tag: 'Clean Cutout',
    src: '/assets/images/hero/remove_bg.jpg',
    alt: 'Background Removal and Cutout Comparison Before and After',
    badge: 'Sub-Pixel Edges',
    objectPosition: 'object-top',
  },
];

export function Hero({ onStartEnhancing, onOpenPricing }: HeroProps) {
  const [selectedPhotoId, setSelectedPhotoId] = useState<string | null>(null);

  const activePhoto = HERO_PHOTOS.find((p) => p.id === selectedPhotoId) || null;

  return (
    <section className="relative overflow-hidden pt-8 pb-14 sm:pt-14 sm:pb-20 md:pt-20 md:pb-28 bg-gradient-to-b from-white via-slate-50/50 to-[#F8FAFC]">
      {/* Background soft ambient glow */}
      <div className="pointer-events-none absolute -top-40 left-1/2 -translate-x-1/2 h-[350px] sm:h-[450px] w-[500px] sm:w-[700px] rounded-full bg-slate-200/50 blur-[100px] sm:blur-[120px]" />

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 sm:gap-10 lg:gap-12 items-center">
          {/* Left Column: Copy & Actions */}
          <div className="lg:col-span-6 space-y-5 sm:space-y-6 text-center lg:text-left">
            {/* Main Headline */}
            <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-5xl xl:text-6xl font-black tracking-tight text-slate-950 leading-[1.15] sm:leading-[1.1]">
              Bring your photos back to life{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-slate-950 via-slate-800 to-slate-600">
                without losing original look!
              </span>
            </h1>

            {/* Sub-headline: Semi Bold */}
            <p className="text-xs sm:text-sm md:text-base lg:text-lg text-slate-600 font-semibold max-w-2xl mx-auto lg:mx-0 leading-relaxed">
              These enhancements are done in SlipeAI not fake. Restore historical damage, remove camera blur, boost resolution up to 4K, and preserve natural human skin textures.
            </p>

            {/* CTAs */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-center lg:justify-start gap-3 sm:gap-3.5 pt-1 sm:pt-2">
              <button
                onClick={onStartEnhancing}
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 sm:px-8 py-3.5 sm:py-4 rounded-2xl bg-slate-950 text-white font-extrabold text-xs sm:text-sm hover:bg-slate-800 transition-all duration-200 shadow-xl container-shade hover:scale-[1.02] active:scale-95"
              >
                <Sparkles className="h-4 w-4" />
                <span>Enhance Photo Now</span>
              </button>

              <a
                href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-5 sm:px-7 py-3.5 sm:py-4 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold text-xs sm:text-sm hover:bg-slate-50 transition-all duration-200 shadow-sm container-shade-sm active:scale-95"
              >
                <Download className="h-4 w-4 text-slate-600" />
                <span>Google Play App</span>
              </a>
            </div>

            {/* Key Value Props */}
            <div className="grid grid-cols-2 gap-3 sm:gap-6 pt-5 sm:pt-6 border-t border-slate-200 max-w-md mx-auto lg:mx-0 text-center sm:text-left">
              <div className="p-1">
                <p className="text-lg sm:text-xl md:text-2xl font-black text-slate-950">4K Ultra</p>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold mt-0.5">Neural Upscaling</p>
              </div>
              <div className="p-1 border-l border-slate-200 pl-4 sm:pl-6">
                <p className="text-lg sm:text-xl md:text-2xl font-black text-slate-950">100% Real</p>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold mt-0.5">True Face Texture</p>
              </div>
            </div>
          </div>

          {/* Right Column: Individual Square Photos Showcase */}
          <div className="lg:col-span-6 flex flex-col items-center justify-center w-full">
            {/* Top Navigation Switcher Pills */}
            <div className="flex items-center justify-center gap-1 sm:gap-1.5 p-1 rounded-full bg-white border border-slate-200/90 shadow-sm mb-3.5 max-w-full overflow-x-auto no-scrollbar">
              <button
                type="button"
                onClick={() => setSelectedPhotoId(null)}
                className={`px-3 py-1 rounded-full text-[11px] sm:text-xs font-bold transition-all duration-200 whitespace-nowrap ${
                  selectedPhotoId === null
                    ? 'bg-slate-950 text-white shadow-sm'
                    : 'text-slate-600 hover:text-slate-950 hover:bg-slate-100'
                }`}
              >
                All 4 Photos
              </button>
              {HERO_PHOTOS.map((photo) => {
                const isActive = selectedPhotoId === photo.id;
                return (
                  <button
                    key={photo.id}
                    type="button"
                    onClick={() => setSelectedPhotoId(photo.id)}
                    className={`px-3 py-1 rounded-full text-[11px] sm:text-xs font-bold transition-all duration-200 whitespace-nowrap ${
                      isActive
                        ? 'bg-slate-950 text-white shadow-sm'
                        : 'text-slate-600 hover:text-slate-950 hover:bg-slate-100'
                    }`}
                  >
                    {photo.label}
                  </button>
                );
              })}
            </div>

            {/* View Mode 1: Responsive 2x2 Grid of Individual Square Photos */}
            {activePhoto === null ? (
              <div className="grid grid-cols-2 gap-2.5 sm:gap-3.5 md:gap-4 w-full max-w-[540px] mx-auto select-none">
                {HERO_PHOTOS.map((photo) => (
                  <div
                    key={photo.id}
                    onClick={() => setSelectedPhotoId(photo.id)}
                    className="group relative cursor-pointer rounded-2xl sm:rounded-3xl border border-slate-200/90 bg-white p-2 sm:p-2.5 container-shade hover:container-shade-xl hover:border-slate-400 transition-all duration-300 hover:scale-[1.02] flex flex-col justify-between"
                  >
                    {/* Individual Square Photo */}
                    <div className="relative aspect-square w-full overflow-hidden rounded-xl sm:rounded-2xl bg-slate-100 border border-slate-100 shadow-inner">
                      <Image
                        src={photo.src}
                        alt={photo.alt}
                        fill
                        sizes="(max-width: 640px) 170px, (max-width: 1024px) 250px, 270px"
                        className={`object-cover ${photo.objectPosition} transition-transform duration-500 group-hover:scale-105`}
                        priority
                      />

                      {/* Feature Tag */}
                      <div className="absolute top-2 left-2 z-10 bg-slate-950/90 backdrop-blur-sm text-white text-[9px] sm:text-[10px] font-extrabold px-2 py-0.5 rounded-md shadow-sm">
                        {photo.tag}
                      </div>

                      {/* Inspect Icon on Hover */}
                      <div className="absolute top-2 right-2 z-10 opacity-0 group-hover:opacity-100 transition-opacity bg-white/90 text-slate-900 p-1 rounded-md shadow-sm">
                        <Maximize2 className="w-3 h-3" />
                      </div>
                    </div>

                    {/* Card Title & Badge */}
                    <div className="pt-2 pb-0.5 px-0.5 text-center">
                      <p className="text-[11px] sm:text-xs font-black text-slate-900 truncate">
                        {photo.title}
                      </p>
                      <p className="text-[9px] sm:text-[10px] text-slate-500 font-semibold truncate mt-0.5">
                        {photo.badge}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              /* View Mode 2: Large Single Square Photo View */
              <div className="relative w-full max-w-[500px] mx-auto rounded-3xl sm:rounded-[36px] border border-slate-200/90 bg-white p-3 sm:p-4 container-shade-xl transition-all duration-300">
                {/* Header with back button */}
                <div className="flex items-center justify-between pb-2.5 border-b border-slate-100">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                    <span className="text-xs sm:text-sm font-extrabold text-slate-950">
                      {activePhoto.title}
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => setSelectedPhotoId(null)}
                    className="flex items-center gap-1 text-[11px] sm:text-xs font-bold text-slate-600 hover:text-slate-950 px-2.5 py-1 rounded-lg hover:bg-slate-100 transition-colors"
                  >
                    <ArrowLeft className="w-3 h-3" />
                    <span>All 4 Photos</span>
                  </button>
                </div>

                {/* Main Square Photo Viewport */}
                <div className="relative aspect-square w-full overflow-hidden rounded-2xl sm:rounded-3xl bg-slate-100 border border-slate-100 shadow-inner mt-2.5">
                  <Image
                    src={activePhoto.src}
                    alt={activePhoto.alt}
                    fill
                    priority
                    sizes="(max-width: 640px) 340px, (max-width: 1024px) 460px, 500px"
                    className={`object-cover ${activePhoto.objectPosition}`}
                  />

                  {/* Feature Tag */}
                  <div className="absolute top-3 left-3 bg-slate-950 text-white text-[10px] sm:text-xs font-black px-2.5 py-1 rounded-lg shadow-md">
                    {activePhoto.tag}
                  </div>
                </div>

                {/* Subtitle & Details */}
                <div className="pt-3 text-center">
                  <p className="text-xs sm:text-sm font-semibold text-slate-800">
                    {activePhoto.subtitle}
                  </p>
                  <p className="text-[11px] sm:text-xs text-slate-500 font-semibold mt-0.5 flex items-center justify-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 inline" />
                    <span>Real Slipe AI Model Enhancement • 100% Real Texture</span>
                  </p>
                </div>
              </div>
            )}

            {/* Sub-caption below showcase */}
            <div className="mt-3 text-center max-w-md px-2">
              <p className="text-[11px] sm:text-xs text-slate-500 font-semibold">
                Tap any square photo to inspect the high-resolution enhancement
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
