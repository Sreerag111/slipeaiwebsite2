'use client';

import React, { useRef, useState, useEffect } from 'react';
import {
  Focus,
  Maximize2,
  PlayCircle,
  SunMedium,
  Zap,
  Palette,
  ShieldAlert,
  Wand2,
  ChevronLeft,
  ChevronRight,
  ArrowRight,
  Upload,
  Check,
  RotateCcw,
  Film,
  Sparkles,
  Lock,
} from 'lucide-react';
import { VIDEO_CATEGORIES, VideoCategory } from '@/lib/videoCategories';

interface VideoEnhancerProps {
  onOpenPricing?: () => void;
  initialCategory?: string;
}

const ICON_MAP: Record<string, React.ElementType> = {
  Focus,
  Maximize2,
  PlayCircle,
  SunMedium,
  Zap,
  Palette,
  ShieldAlert,
  Wand2,
};

export function VideoEnhancer({ onOpenPricing, initialCategory }: VideoEnhancerProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>(
    initialCategory || 'precision'
  );

  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const studioRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

  // Active Category
  const activeCategory: VideoCategory =
    VIDEO_CATEGORIES.find((c) => c.id === selectedCategory) || VIDEO_CATEGORIES[0];

  // Video Studio States
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);

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

  const handleSelectCategory = (catId: string) => {
    setSelectedCategory(catId);
  };

  const processSelectedFile = (file: File) => {
    if (!file.type.includes('mp4') && !file.name.toLowerCase().endsWith('.mp4')) {
      alert('Please upload an MP4 video file.');
      return;
    }
    if (file.size > 75 * 1024 * 1024) {
      alert('Please choose an MP4 video under 75 MB.');
      return;
    }
    setVideoFile(file);
    if (videoUrl) {
      URL.revokeObjectURL(videoUrl);
    }
    setVideoUrl(URL.createObjectURL(file));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      processSelectedFile(e.target.files[0]);
    }
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processSelectedFile(e.dataTransfer.files[0]);
    }
  };

  const handleReset = () => {
    if (videoUrl) {
      URL.revokeObjectURL(videoUrl);
    }
    setVideoFile(null);
    setVideoUrl(null);
  };

  return (
    <section id="video" className="py-8 sm:py-12 md:py-16 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 space-y-8 sm:space-y-12">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-950 font-display tracking-tight leading-tight">
            AI Video Upscaling & Frame Interpolation
          </h2>

          <p className="text-sm sm:text-base md:text-lg text-slate-600 font-display font-medium max-w-2xl mx-auto px-2 leading-relaxed">
            Remaster vintage recordings, mobile clips, and drone footage to 60fps 4K clarity.
          </p>
        </div>

        {/* Video Showing Containers Carousel */}
        <div className="relative group/carousel">
          {/* Left Arrow Button */}
          {canScrollLeft && (
            <button
              type="button"
              onClick={() => handleScroll('left')}
              aria-label="Previous video features"
              className="absolute -left-3 sm:-left-5 top-1/2 -translate-y-1/2 z-20 w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-white text-slate-900 border border-slate-200/90 shadow-xl flex items-center justify-center transition-all hover:scale-105 hover:bg-slate-50 active:scale-95"
            >
              <ChevronLeft className="w-5 h-5 sm:w-6 sm:h-6 text-slate-800" />
            </button>
          )}

          {/* Right Arrow Button */}
          {canScrollRight && (
            <button
              type="button"
              onClick={() => handleScroll('right')}
              aria-label="Next video features"
              className="absolute -right-3 sm:-right-5 top-1/2 -translate-y-1/2 z-20 w-11 h-11 sm:w-12 sm:h-12 rounded-full bg-white text-slate-900 border border-slate-200/90 shadow-xl flex items-center justify-center transition-all hover:scale-105 hover:bg-slate-50 active:scale-95"
            >
              <ChevronRight className="w-5 h-5 sm:w-6 sm:h-6 text-slate-800" />
            </button>
          )}

          {/* Horizontal Scrollable Row of Video Showing Containers */}
          <div
            ref={scrollContainerRef}
            onScroll={checkScroll}
            className="flex gap-4 sm:gap-6 overflow-x-auto scroll-smooth pb-6 pt-2 px-1 scrollbar-none snap-x snap-mandatory"
          >
            {VIDEO_CATEGORIES.map((cat) => {
              const Icon = ICON_MAP[cat.iconName] || Maximize2;
              const isSelected = selectedCategory === cat.id;

              return (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => {
                    handleSelectCategory(cat.id);
                    studioRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
                  }}
                  className={`w-[280px] sm:w-[320px] md:w-[340px] shrink-0 snap-start flex flex-col p-3.5 sm:p-4 rounded-[24px] sm:rounded-[28px] bg-white border transition-all duration-300 active:scale-[0.98] group text-left cursor-pointer ${
                    isSelected
                      ? 'border-blue-600 ring-4 ring-blue-500/20 shadow-[0_16px_36px_rgba(0,0,0,0.12)] scale-[1.01]'
                      : 'border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] hover:shadow-[0_16px_36px_rgba(0,0,0,0.1)] hover:-translate-y-1.5'
                  }`}
                >
                  {/* Media Visual (Animated WebP Video: Large, prominent, and clearly visible) */}
                  <div className="relative w-full aspect-[16/11] sm:aspect-[4/3] rounded-[18px] sm:rounded-[22px] overflow-hidden bg-slate-100 mb-3.5 sm:mb-4 shadow-inner border border-slate-100">
                    <img
                      src={`/assets/videos/remaster_categories/${cat.file}`}
                      alt={cat.label}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
                      loading="eager"
                    />

                    {/* Selected Badge or Hover Pill */}
                    {isSelected ? (
                      <div className="absolute top-3 right-3 bg-blue-600 text-white p-1 rounded-full shadow-md z-10 flex items-center justify-center">
                        <Check className="w-3.5 h-3.5" />
                      </div>
                    ) : (
                      <div className="absolute inset-0 bg-gradient-to-t from-slate-950/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-3 pointer-events-none">
                        <span className="text-[11px] font-bold text-white bg-blue-600/95 px-3 py-1 rounded-lg backdrop-blur-sm shadow-md flex items-center gap-1.5 font-display">
                          <span>Select Remaster</span>
                          <ArrowRight className="w-3 h-3" />
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Card Info: Icon + Title row & clean description */}
                  <div className="space-y-1.5 flex-1 flex flex-col justify-between px-1 pb-1">
                    <div className="flex items-center gap-2.5">
                      <div
                        className={`flex items-center justify-center w-8 h-8 rounded-xl transition-colors shrink-0 shadow-sm ${
                          isSelected
                            ? 'bg-blue-600 text-white'
                            : 'bg-slate-100 text-slate-900 group-hover:bg-blue-600 group-hover:text-white'
                        }`}
                      >
                        <Icon className="w-4 h-4" />
                      </div>
                      <h3
                        className={`text-base sm:text-lg font-bold font-display tracking-tight transition-colors line-clamp-1 ${
                          isSelected ? 'text-blue-700' : 'text-slate-950 group-hover:text-blue-700'
                        }`}
                      >
                        {cat.label}
                      </h3>
                    </div>

                    <p className="text-xs sm:text-[13px] text-slate-600 font-medium leading-relaxed font-display line-clamp-2">
                      {cat.desc}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Video Remaster Studio Workspace */}
        <div
          ref={studioRef}
          className="rounded-[28px] sm:rounded-[36px] border border-slate-200/90 bg-white p-5 sm:p-8 md:p-10 shadow-[0_8px_30px_rgba(0,0,0,0.06)] space-y-6"
        >
          {/* Active Category Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100 font-display">
            <div className="space-y-1">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-200 text-blue-900 text-xs font-bold">
                <span>Active Remaster Mode</span>
                <span className="font-extrabold">&bull;</span>
                <span>{activeCategory.label}</span>
              </div>
              <h3 className="text-xl sm:text-2xl font-black text-slate-950 tracking-tight">
                Remaster Footage with {activeCategory.label}
              </h3>
              <p className="text-xs sm:text-sm text-slate-600 font-medium">
                {activeCategory.desc}
              </p>
            </div>

            {/* Quick Category Selector Pills */}
            <div className="flex items-center gap-1.5 overflow-x-auto scrollbar-none py-1">
              {VIDEO_CATEGORIES.slice(0, 4).map((cat) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => handleSelectCategory(cat.id)}
                  className={`px-2.5 py-1 rounded-lg text-[11px] font-bold whitespace-nowrap transition-all ${
                    selectedCategory === cat.id
                      ? 'bg-slate-950 text-white shadow-xs'
                      : 'bg-slate-100 text-slate-600 hover:text-slate-950 hover:bg-slate-200'
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          </div>

          {!videoUrl ? (
            /* Upload Dropzone */
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-slate-200 hover:border-blue-600 rounded-3xl p-8 sm:p-14 md:p-16 text-center cursor-pointer transition-colors bg-slate-50/70 hover:bg-blue-50/20 flex flex-col items-center justify-center space-y-4 group"
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="video/mp4"
                onChange={handleFileChange}
                className="hidden"
              />
              <div className="flex h-14 w-14 sm:h-16 sm:w-16 items-center justify-center rounded-2xl bg-white border border-slate-200 text-blue-600 shadow-md group-hover:scale-105 transition-transform">
                <Upload className="h-6 w-6 sm:h-7 sm:w-7 text-blue-600" />
              </div>
              <div className="space-y-1.5 font-display">
                <p className="text-sm sm:text-lg font-bold text-slate-900">
                  Drag and drop your MP4 clip here, or <span className="underline text-blue-600 font-black">browse files</span>
                </p>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold">
                  Supports MP4 up to 75 MB &bull; Rendered at up to 60fps 4K
                </p>
              </div>
            </div>
          ) : (
            /* Active Video Player & Remaster Workspace */
            <div className="space-y-6 font-display">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <Film className="w-4 h-4 text-blue-600" />
                  <span className="text-xs sm:text-sm font-bold text-slate-900 truncate max-w-xs sm:max-w-md">
                    {videoFile?.name || 'Selected Video'}
                  </span>
                  <span className="text-xs bg-blue-50 border border-blue-200 px-2 py-0.5 rounded text-blue-900 font-bold">
                    {activeCategory.label}
                  </span>
                </div>

                <button
                  type="button"
                  onClick={handleReset}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:text-slate-950 hover:bg-slate-50 text-xs font-bold transition-all"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>Choose Another Clip</span>
                </button>
              </div>

              {/* Video Player Display */}
              <div className="relative mx-auto max-w-4xl max-h-[580px] aspect-video rounded-3xl overflow-hidden bg-black border border-slate-200/90 shadow-xl flex items-center justify-center">
                <video
                  src={videoUrl}
                  controls
                  className="max-h-full max-w-full object-contain"
                />
              </div>

              {/* Remaster Action Panel */}
              <div className="p-4 sm:p-6 rounded-2xl bg-slate-50 border border-slate-200/90 flex flex-col sm:flex-row items-center justify-between gap-4">
                <div className="space-y-0.5 text-center sm:text-left">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                    Engine Pipeline
                  </span>
                  <p className="text-sm font-bold text-slate-900">
                    60fps Neural Frame Interpolation + 4K Super-Resolution
                  </p>
                </div>

                <button
                  type="button"
                  onClick={onOpenPricing}
                  className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-slate-950 hover:bg-slate-800 text-white font-black text-xs sm:text-sm uppercase tracking-wider transition-all shadow-lg active:scale-95"
                >
                  <Sparkles className="w-4 h-4" />
                  <span>Start 4K Remastering</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
