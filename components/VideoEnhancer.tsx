'use client';

import React, { useState, useRef } from 'react';
import Image from 'next/image';
import { Video, Lock } from 'lucide-react';

interface VideoEnhancerProps {
  onOpenPricing: () => void;
}

export function VideoEnhancer({ onOpenPricing }: VideoEnhancerProps) {
  const [selectedCategory, setSelectedCategory] = useState('precision');
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const categories = [
    { id: 'precision', label: 'Precision Clarity', desc: 'Neural edge sharpness & micro-contrast', file: 'precision.webp' },
    { id: 'auto', label: 'Auto Upscale', desc: 'Automatic 2x/4k video super-resolution', file: 'auto.webp' },
    { id: 'slow_motion', label: 'Slow Motion', desc: 'Optical flow 60fps frame interpolation', file: 'slow_motion.webp' },
    { id: 'hdr', label: 'HDR Remaster', desc: 'Dynamic range & cinema tone mapping', file: 'hdr.webp' },
    { id: 'motion_deblur', label: 'Motion Deblur', desc: 'Reverse high-speed motion camera shake', file: 'motion_deblur.webp' },
    { id: 'colorize', label: 'Colorize Videos', desc: 'Authentic archival historical film colorization', file: 'colorize.webp' },
    { id: 'denoise', label: 'Denoise Video', desc: 'Low-light sensor noise & grain removal', file: 'denoise.webp' },
    { id: 'creative', label: 'Creative Detail', desc: 'Cinematic neural texture & micro-detail', file: 'creative.webp' },
  ];

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      if (file.size > 75 * 1024 * 1024) {
        alert('Please choose an MP4 video under 75 MB.');
        return;
      }
      setVideoFile(file);
    }
  };

  const handleStartRemaster = () => {
    // Video remaster is gated to Pro tier in Slipe AI
    onOpenPricing();
  };

  return (
    <section id="video" className="py-14 sm:py-20 md:py-28 border-t border-slate-200/80 bg-slate-50/70">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-14 space-y-3">
          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
            AI Video Upscaling & Frame Interpolation
          </h2>
          {/* Subheading: Semi Bold */}
          <p className="text-xs sm:text-sm md:text-base text-slate-600 font-semibold px-2">
            Remaster vintage recordings, mobile clips, and drone footage to 60fps 4K clarity.
          </p>
        </div>

        {/* Video Categories Grid: Substantially larger animated video cards (8 categories) */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 sm:gap-4.5 mb-10 sm:mb-14">
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`relative flex flex-col p-3 sm:p-3.5 rounded-2xl border transition-all duration-200 active:scale-[0.98] group ${
                  isSelected
                    ? 'border-blue-600 bg-blue-50/40 text-blue-950 container-shade-md ring-2 ring-blue-500/20 scale-[1.02]'
                    : 'border-slate-200/90 bg-white hover:border-slate-300 container-shade-sm hover:container-shade hover:-translate-y-0.5'
                }`}
              >
                {/* Large prominent video preview for desktop & mobile */}
                <div className="relative aspect-[4/3] w-full rounded-xl overflow-hidden border border-slate-100 mb-2.5 bg-slate-100 shadow-inner">
                  <Image
                    src={`/assets/videos/remaster_categories/${cat.file}`}
                    alt={cat.label}
                    fill
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 20vw"
                    className="object-cover group-hover:scale-105 transition-transform duration-300"
                    unoptimized
                  />
                </div>
                <div className="w-full text-center space-y-0.5">
                  <span className="text-xs sm:text-sm font-black text-slate-950 block leading-tight">{cat.label}</span>
                  {/* Description: Semi Bold */}
                  <span className="text-[10px] sm:text-[11px] text-slate-500 font-semibold block line-clamp-2 leading-tight">
                    {cat.desc}
                  </span>
                </div>
              </button>
            );
          })}
        </div>

        {/* Video Upload Dropzone: Increased Size (max-w-4xl) */}
        <div className="max-w-4xl mx-auto rounded-3xl border border-slate-200/90 bg-white p-6 sm:p-10 md:p-12 container-shade-xl text-center space-y-5 sm:space-y-7">
          <input
            ref={fileInputRef}
            type="file"
            accept="video/mp4"
            onChange={handleFileChange}
            className="hidden"
          />

          <div
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-slate-200 hover:border-blue-600 p-8 sm:p-12 rounded-3xl cursor-pointer transition-colors bg-slate-50/70 hover:bg-blue-50/20 flex flex-col items-center justify-center space-y-3.5"
          >
            <div className="flex h-14 w-14 sm:h-16 sm:w-16 items-center justify-center rounded-2xl bg-white border border-slate-200 text-blue-600 shadow-md">
              <Video className="h-6 w-6 sm:h-7 sm:w-7 text-blue-600" />
            </div>
            <div>
              <p className="text-sm sm:text-base font-bold text-slate-900">
                {videoFile ? videoFile.name : 'Click to select MP4 Video'}
              </p>
              {/* Description: Semi Bold */}
              <p className="text-xs sm:text-sm text-slate-500 font-semibold mt-1">MP4 format up to 75 MB</p>
            </div>
          </div>

          <div className="space-y-3 pt-1">
            <button
              onClick={handleStartRemaster}
              className="w-full flex items-center justify-center gap-2 py-4 rounded-2xl bg-slate-950 text-white font-black text-xs sm:text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl container-shade active:scale-98"
            >
              <Lock className="h-4 w-4" />
              <span>Unlock Video Remaster with Pro</span>
            </button>
            {/* Note: Semi Bold */}
            <p className="text-xs sm:text-sm text-slate-500 font-semibold">
              Video Remastering utilizes dedicated cloud GPU nodes. Included with Slipe AI Pro.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
