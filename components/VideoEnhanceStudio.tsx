'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft,
  Upload,
  Lock,
  Film,
  RotateCcw,
} from 'lucide-react';
import { VIDEO_CATEGORIES, VideoCategory } from '@/lib/videoCategories';

interface VideoEnhanceStudioProps {
  onOpenPricing: () => void;
}

export function VideoEnhanceStudio({ onOpenPricing }: VideoEnhanceStudioProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const categoryParam = searchParams.get('category');

  const [selectedCategory, setSelectedCategory] = useState<string>(
    categoryParam && VIDEO_CATEGORIES.some((c) => c.id === categoryParam)
      ? categoryParam
      : 'precision'
  );

  useEffect(() => {
    if (categoryParam && VIDEO_CATEGORIES.some((c) => c.id === categoryParam)) {
      setSelectedCategory(categoryParam);
    }
  }, [categoryParam]);

  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const activeCategory: VideoCategory =
    VIDEO_CATEGORIES.find((c) => c.id === selectedCategory) || VIDEO_CATEGORIES[0];

  const handleCategorySwitch = (catId: string) => {
    setSelectedCategory(catId);
    router.replace(`/video?category=${catId}`, { scroll: false });
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

  const handleReset = () => {
    if (videoUrl) {
      URL.revokeObjectURL(videoUrl);
    }
    setVideoFile(null);
    setVideoUrl(null);
  };

  return (
    <section className="py-10 sm:py-16 md:py-20 min-h-screen bg-[#F8FAFC]">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 space-y-5 sm:space-y-6">
        {/* Back Link & Header */}
        <div className="space-y-3">
          <Link
            href="/#video"
            className="inline-flex items-center gap-1.5 text-xs sm:text-sm font-bold text-slate-600 hover:text-slate-950 transition-colors group"
          >
            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
            <span>Back to All Features</span>
          </Link>

          <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-2 border-b border-slate-200/80">
            <div>
              <h1 className="text-2xl sm:text-3xl md:text-4xl font-extrabold text-slate-950 font-display tracking-tight">
                {activeCategory.label}
              </h1>
              <p className="text-xs sm:text-sm text-slate-600 font-display font-medium mt-0.5">
                {activeCategory.desc}
              </p>
            </div>

            {/* Choose Another Feature Trigger */}
            <Link
              href="/#video"
              className="self-start md:self-auto text-xs font-bold text-blue-600 hover:text-blue-800 underline transition-colors"
            >
              Browse all 7 video features
            </Link>
          </div>
        </div>

        {/* Very Small Compact Category Slide Bar */}
        <div className="flex items-center">
          <div className="p-1 rounded-xl bg-slate-100/90 border border-slate-200/80 shadow-xs overflow-x-auto scrollbar-none flex items-center gap-1 max-w-full">
            {VIDEO_CATEGORIES.map((cat) => {
              const isCurrent = selectedCategory === cat.id;
              return (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => handleCategorySwitch(cat.id)}
                  className={`flex items-center px-2.5 py-1 rounded-lg text-[11px] font-bold whitespace-nowrap transition-all shrink-0 ${
                    isCurrent
                      ? 'bg-slate-950 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-950 hover:bg-white/80'
                  }`}
                >
                  <span>{cat.label}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Upload & Workspace Area */}
        <div className="rounded-3xl border border-slate-200/90 bg-white p-5 sm:p-8 md:p-10 container-shade-xl">
          {!videoFile ? (
            /* Dropzone: Dedicated upload section */
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-slate-200 hover:border-blue-600 rounded-3xl p-8 sm:p-14 md:p-20 text-center cursor-pointer transition-colors bg-slate-50/70 hover:bg-blue-50/20 flex flex-col items-center justify-center space-y-4"
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="video/mp4"
                onChange={handleFileChange}
                className="hidden"
              />
              <div className="flex h-14 w-14 sm:h-16 sm:w-16 items-center justify-center rounded-2xl bg-white border border-slate-200 text-blue-600 shadow-md">
                <Upload className="h-6 w-6 sm:h-7 sm:w-7 text-blue-600" />
              </div>
              <div className="space-y-1.5">
                <p className="text-sm sm:text-lg font-bold text-slate-900 font-display">
                  Drag and drop your MP4 video here, or{' '}
                  <span className="underline text-blue-600 font-black">browse files</span>
                </p>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold font-display">
                  Supports MP4 video (up to 75 MB)
                </p>
              </div>
            </div>
          ) : (
            /* Active Video Workspace */
            <div className="space-y-6 sm:space-y-8">
              {/* File Info Bar */}
              <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-slate-100">
                <div className="flex flex-wrap items-center gap-2.5">
                  <Film className="w-4 h-4 text-blue-600" />
                  <span className="text-xs font-semibold text-slate-500">Video:</span>
                  <span className="text-xs sm:text-sm font-black text-slate-900 truncate max-w-[200px] sm:max-w-md">
                    {videoFile.name}
                  </span>
                  <span className="text-[11px] bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-bold">
                    {(videoFile.size / (1024 * 1024)).toFixed(1)} MB
                  </span>
                  <span className="text-xs bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-lg text-blue-900 font-bold">
                    {activeCategory.label}
                  </span>
                </div>

                <button
                  type="button"
                  onClick={handleReset}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-600 hover:text-slate-950 transition-colors"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>Choose Another Video</span>
                </button>
              </div>

              {/* Video Player Preview */}
              <div className="relative max-w-2xl mx-auto aspect-video rounded-2xl overflow-hidden bg-slate-950 shadow-xl border border-slate-200">
                {videoUrl && (
                  <video
                    src={videoUrl}
                    controls
                    className="w-full h-full object-contain"
                  />
                )}
              </div>

              {/* Remaster Action Box */}
              <div className="max-w-xl mx-auto space-y-3.5 text-center pt-2">
                <button
                  type="button"
                  onClick={onOpenPricing}
                  className="w-full flex items-center justify-center gap-2 py-4 px-6 rounded-2xl bg-slate-950 text-white font-extrabold text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl hover:scale-[1.01] active:scale-[0.98] font-display"
                >
                  <Lock className="h-4 w-4" />
                  <span>Unlock Video Remaster with Pro</span>
                </button>

                <p className="text-xs sm:text-sm text-slate-500 font-medium font-display leading-relaxed">
                  Video Remastering utilizes dedicated cloud GPU nodes. Included with Slipe AI Pro.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
