'use client';

import React, { useState, useRef } from 'react';
import Image from 'next/image';
import { Video, Upload, Sparkles, Check, Lock, Zap, Film } from 'lucide-react';

interface VideoEnhancerProps {
  onOpenPricing: () => void;
}

export function VideoEnhancer({ onOpenPricing }: VideoEnhancerProps) {
  const [selectedCategory, setSelectedCategory] = useState('precision');
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const categories = [
    { id: 'precision', label: 'Precision Clarity', desc: 'Neural edge sharpness & micro-contrast', file: 'precision.webp' },
    { id: 'auto', label: 'Auto Upscale', desc: 'Automatic 2x/4k video super-resolution', file: 'auto.webp' },
    { id: 'slow_motion', label: 'Slow Motion', desc: 'Optical flow 60fps frame interpolation', file: 'slow_motion.webp' },
    { id: 'hdr', label: 'HDR Remaster', desc: 'Dynamic range & cinema tone mapping', file: 'hdr.webp' },
    { id: 'motion_deblur', label: 'Motion Deblur', desc: 'Reverse high-speed motion camera shake', file: 'motion_deblur.webp' },
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
    <section id="video" className="py-16 md:py-24 border-t border-neutral-900 bg-black">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto mb-12 space-y-3">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border border-neutral-800 bg-neutral-950 text-[11px] font-bold text-neutral-300">
            <Film className="h-3 w-3 text-white" />
            <span>Pro Video Remastering</span>
          </div>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-white tracking-tight">
            AI Video Upscaling & Frame Interpolation
          </h2>
          <p className="text-xs sm:text-sm text-neutral-400">
            Remaster vintage recordings, mobile clips, and drone footage to 60fps 4K clarity.
          </p>
        </div>

        {/* Video Categories Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 mb-10">
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`relative flex flex-col items-center p-3 rounded-none border text-center transition-all group ${
                  isSelected
                    ? 'border-white bg-neutral-950 halo-shadow scale-[1.02]'
                    : 'border-neutral-800 bg-neutral-950/60 hover:border-neutral-600'
                }`}
              >
                <div className="relative w-14 h-14 rounded overflow-hidden border border-neutral-800 mb-2">
                  <Image
                    src={`/assets/videos/remaster_categories/${cat.file}`}
                    alt={cat.label}
                    fill
                    className="object-cover"
                    unoptimized
                  />
                </div>
                <span className="text-xs font-black text-white leading-tight">{cat.label}</span>
                <span className="text-[10px] text-neutral-500 mt-1 line-clamp-2 leading-tight">
                  {cat.desc}
                </span>
                {isSelected && (
                  <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-white shadow-[0_0_8px_white]" />
                )}
              </button>
            );
          })}
        </div>

        {/* Video Upload Dropzone */}
        <div className="max-w-2xl mx-auto rounded-none border-2 border-white bg-neutral-950 p-6 sm:p-10 halo-shadow text-center space-y-6">
          <input
            ref={fileInputRef}
            type="file"
            accept="video/mp4"
            onChange={handleFileChange}
            className="hidden"
          />

          <div
            onClick={() => fileInputRef.current?.click()}
            className="border-2 border-dashed border-neutral-800 hover:border-white p-8 rounded-none cursor-pointer transition-colors bg-black flex flex-col items-center justify-center space-y-3"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-neutral-900 border border-neutral-700 text-white">
              <Video className="h-5 w-5 text-white" />
            </div>
            <div>
              <p className="text-sm font-bold text-white">
                {videoFile ? videoFile.name : 'Click to select MP4 Video'}
              </p>
              <p className="text-xs text-neutral-500 mt-0.5">MP4 format up to 75 MB</p>
            </div>
          </div>

          <div className="space-y-3 pt-2">
            <button
              onClick={handleStartRemaster}
              className="w-full flex items-center justify-center gap-2 py-3.5 rounded-none bg-white text-black font-black text-sm uppercase tracking-wider hover:bg-neutral-200 transition-all shadow-xl halo-shadow"
            >
              <Lock className="h-4 w-4" />
              <span>Unlock Video Remaster with Pro</span>
            </button>
            <p className="text-xs text-neutral-500">
              Video Remastering utilizes dedicated cloud GPU nodes. Included with Slipe AI Pro.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
