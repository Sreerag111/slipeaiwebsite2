'use client';

import React, { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  Upload,
  Sparkles,
  SlidersHorizontal,
  Download,
  RotateCcw,
  AlertCircle,
  CheckCircle2,
  Eye,
  Columns,
  ArrowLeft,
} from 'lucide-react';
import { saveAs } from 'file-saver';
import { ENHANCEMENT_CATEGORIES } from '@/lib/categories';

interface PhotoEnhanceStudioProps {
  onOpenPricing: () => void;
}

export function PhotoEnhanceStudio({ onOpenPricing }: PhotoEnhanceStudioProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const categoryParam = searchParams.get('category');

  const [selectedCategory, setSelectedCategory] = useState<string>(
    categoryParam && ENHANCEMENT_CATEGORIES.some((c) => c.id === categoryParam)
      ? categoryParam
      : 'enhance_photos_quality'
  );

  useEffect(() => {
    if (categoryParam && ENHANCEMENT_CATEGORIES.some((c) => c.id === categoryParam)) {
      setSelectedCategory(categoryParam);
    }
  }, [categoryParam]);

  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [enhancedUrl, setEnhancedUrl] = useState<string | null>(null);
  const [modelUsed, setModelUsed] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [processStep, setProcessStep] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [sliderPos, setSliderPos] = useState(50);
  const [isDragging, setIsDragging] = useState(false);
  const [viewMode, setViewMode] = useState<'slider' | 'enhanced' | 'sideBySide'>('slider');

  const containerRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const activeCategory =
    ENHANCEMENT_CATEGORIES.find((c) => c.id === selectedCategory) ||
    ENHANCEMENT_CATEGORIES[0];

  // Helper to ensure WebP images are converted to JPEG for Topaz API compatibility
  const ensureJpegOrPng = async (inputFile: File): Promise<File> => {
    if (inputFile.type === 'image/jpeg' || inputFile.type === 'image/png') {
      return inputFile;
    }
    return new Promise((resolve) => {
      const img = document.createElement('img');
      const objectUrl = URL.createObjectURL(inputFile);
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.naturalWidth || img.width;
        canvas.height = img.naturalHeight || img.height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.drawImage(img, 0, 0);
          canvas.toBlob(
            (blob) => {
              URL.revokeObjectURL(objectUrl);
              if (blob) {
                const converted = new File(
                  [blob],
                  inputFile.name.replace(/\.[^/.]+$/, '.jpg'),
                  { type: 'image/jpeg' }
                );
                resolve(converted);
              } else {
                resolve(inputFile);
              }
            },
            'image/jpeg',
            0.98
          );
        } else {
          URL.revokeObjectURL(objectUrl);
          resolve(inputFile);
        }
      };
      img.onerror = () => {
        URL.revokeObjectURL(objectUrl);
        resolve(inputFile);
      };
      img.src = objectUrl;
    });
  };

  const processSelectedFile = async (rawFile: File) => {
    if (rawFile.size > 15 * 1024 * 1024) {
      setErrorMessage('File size exceeds 15 MB limit. Please select a smaller photo.');
      return;
    }
    const compatibleFile = await ensureJpegOrPng(rawFile);
    setFile(compatibleFile);
    setPreviewUrl(URL.createObjectURL(compatibleFile));
    setEnhancedUrl(null);
    setModelUsed(null);
    setErrorMessage(null);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      processSelectedFile(e.target.files[0]);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      processSelectedFile(e.dataTransfer.files[0]);
    }
  };

  const handleCategorySwitch = (catId: string) => {
    setSelectedCategory(catId);
    if (enhancedUrl) setEnhancedUrl(null);
    setModelUsed(null);
    setErrorMessage(null);
    router.replace(`/enhance?category=${catId}`, { scroll: false });
  };

  const startEnhancement = async () => {
    if (!file || !previewUrl) return;

    // Check free uses gating (bypass on localhost/dev so developer and user can freely test)
    const isLocalhost =
      typeof window !== 'undefined' &&
      (window.location.hostname === 'localhost' ||
        window.location.hostname === '127.0.0.1' ||
        window.location.hostname.includes('192.168.'));

    const currentUses = parseInt(localStorage.getItem('slipeai_free_uses') || '0', 10);
    if (!isLocalhost && currentUses >= 5) {
      onOpenPricing();
      return;
    }

    setIsProcessing(true);
    setErrorMessage(null);
    setProgress(10);
    setProcessStep('Connecting to AI inference engine...');

    const timer1 = setTimeout(() => {
      setProgress(35);
      setProcessStep(activeCategory.stepText || 'Analyzing image pixels & facial landmarks...');
    }, 800);

    const timer2 = setTimeout(() => {
      setProgress(65);
      setProcessStep('Synthesizing high-frequency neural features...');
    }, 2400);

    const timer3 = setTimeout(() => {
      setProgress(85);
      setProcessStep('Finalizing lossless image reconstruction...');
    }, 4500);

    try {
      const formData = new FormData();
      formData.append('image', file);
      formData.append('category', selectedCategory);

      const res = await fetch('/api/enhance', {
        method: 'POST',
        body: formData,
      });

      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);

      if (res.ok) {
        const data = await res.json();
        if (data.enhancedUrl) {
          setEnhancedUrl(data.enhancedUrl);
          setModelUsed(data.model || activeCategory.model);
          setProgress(100);
          setProcessStep('Enhancement complete!');
          localStorage.setItem('slipeai_free_uses', (currentUses + 1).toString());
        } else {
          setErrorMessage('Failed to retrieve enhanced image. Please try again.');
        }
      } else {
        const errJson = await res.json().catch(() => ({}));
        setErrorMessage(
          errJson.error ||
            'Engine encountered an error while enhancing this photo. Please try again.'
        );
      }
    } catch (err: any) {
      clearTimeout(timer1);
      clearTimeout(timer2);
      clearTimeout(timer3);
      console.error('Enhancement error:', err);
      setErrorMessage(err?.message || 'Network error communicating with enhancement engine.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    setIsDragging(true);
    e.currentTarget.setPointerCapture(e.pointerId);
    updateSlider(e.clientX);
  };

  const handlePointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    setIsDragging(false);
    try {
      e.currentTarget.releasePointerCapture(e.pointerId);
    } catch {
      // Ignore
    }
  };

  const updateSlider = (clientX: number) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = Math.max(0, Math.min(clientX - rect.left, rect.width));
    const percent = Math.max(0, Math.min(100, (x / rect.width) * 100));
    setSliderPos(percent);
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!isDragging) return;
    updateSlider(e.clientX);
  };

  const handleDownload = () => {
    if (enhancedUrl) {
      const isPng =
        selectedCategory === 'remove_background' || enhancedUrl.startsWith('data:image/png');
      const ext = isPng ? 'png' : 'jpg';
      saveAs(enhancedUrl, `slipeai_${selectedCategory}_${Date.now()}.${ext}`);
    }
  };

  return (
    <section className="py-10 sm:py-16 md:py-20 min-h-screen bg-[#F8FAFC]">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8 space-y-5 sm:space-y-6">
        {/* Back Link & Header */}
        <div className="space-y-3">
          <Link
            href="/#enhancer"
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
              href="/#enhancer"
              className="self-start md:self-auto text-xs font-bold text-blue-600 hover:text-blue-800 underline transition-colors"
            >
              Browse all 10 features
            </Link>
          </div>
        </div>

        {/* Very Small Compact Category Slide Bar */}
        <div className="flex items-center">
          <div className="p-1 rounded-xl bg-slate-100/90 border border-slate-200/80 shadow-xs overflow-x-auto scrollbar-none flex items-center gap-1 max-w-full">
            {ENHANCEMENT_CATEGORIES.map((cat) => {
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
          {!previewUrl ? (
            /* Upload Dropzone with Dotted Grid Pattern on White Theme */
            <div
              onDragOver={(e) => e.preventDefault()}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
              className="relative overflow-hidden rounded-[26px] sm:rounded-[32px] border border-slate-200/90 hover:border-blue-500 bg-white p-8 sm:p-14 md:p-16 text-center cursor-pointer transition-all duration-300 shadow-[0_8px_30px_rgba(0,0,0,0.04)] hover:shadow-[0_12px_36px_rgba(0,0,0,0.08)] flex flex-col items-center justify-center space-y-6 group"
              style={{
                backgroundImage: 'radial-gradient(rgba(100, 116, 139, 0.22) 1.3px, transparent 1.3px)',
                backgroundSize: '20px 20px',
                backgroundPosition: 'center',
              }}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={handleFileChange}
                className="hidden"
              />

              {/* Text Description */}
              <div className="relative z-10 space-y-1.5 font-display max-w-lg mx-auto">
                <p className="text-base sm:text-lg md:text-xl font-bold text-slate-900 tracking-tight">
                  Drag and drop your photo here, or <span className="underline text-blue-600 font-black hover:text-blue-700 transition-colors">browse files</span>
                </p>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold">
                  Supports JPEG, PNG, and WebP (up to 15 MB)
                </p>
              </div>

              {/* Primary Upload Action Button */}
              <div className="relative z-10 flex items-center justify-center pt-1">
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    fileInputRef.current?.click();
                  }}
                  className="flex items-center gap-2 px-7 sm:px-8 py-2.5 sm:py-3 rounded-xl sm:rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs sm:text-sm shadow-md shadow-blue-600/25 active:scale-95 transition-all font-display cursor-pointer"
                >
                  <Upload className="w-4 h-4 sm:w-4.5 sm:h-4.5 stroke-[2.5]" />
                  <span>Upload</span>
                </button>
              </div>
            </div>
          ) : (
            /* Active Workspace */
            <div className="space-y-5 sm:space-y-7">
              {/* Top status bar */}
              <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-slate-100">
                <div className="flex flex-wrap items-center gap-2.5">
                  <span className="text-xs font-semibold text-slate-500">File:</span>
                  <span className="text-xs sm:text-sm font-black text-slate-900 truncate max-w-[200px] sm:max-w-md">
                    {file?.name || 'Selected Photo'}
                  </span>
                  <span className="text-xs bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-lg text-blue-900 font-bold">
                    {activeCategory.label}
                  </span>
                  {enhancedUrl && (
                    <span className="inline-flex items-center gap-1 text-[11px] bg-emerald-50 border border-emerald-200 text-emerald-800 font-bold px-2 py-0.5 rounded-md">
                      <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                      <span>Enhanced</span>
                    </span>
                  )}
                </div>

                <div className="flex items-center gap-2">
                  {/* View mode switcher when enhanced */}
                  {enhancedUrl && (
                    <div className="inline-flex items-center p-1 rounded-xl bg-slate-100 border border-slate-200 text-xs">
                      <button
                        type="button"
                        onClick={() => setViewMode('slider')}
                        className={`flex items-center gap-1 px-2.5 py-1 rounded-lg font-bold transition-all ${
                          viewMode === 'slider'
                            ? 'bg-white text-slate-950 shadow-sm'
                            : 'text-slate-600 hover:text-slate-950'
                        }`}
                        title="Before & After Slider"
                      >
                        <SlidersHorizontal className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Slider</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setViewMode('enhanced')}
                        className={`flex items-center gap-1 px-2.5 py-1 rounded-lg font-bold transition-all ${
                          viewMode === 'enhanced'
                            ? 'bg-white text-slate-950 shadow-sm'
                            : 'text-slate-600 hover:text-slate-950'
                        }`}
                        title="Full Enhanced Output"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Enhanced</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setViewMode('sideBySide')}
                        className={`flex items-center gap-1 px-2.5 py-1 rounded-lg font-bold transition-all ${
                          viewMode === 'sideBySide'
                            ? 'bg-white text-slate-950 shadow-sm'
                            : 'text-slate-600 hover:text-slate-950'
                        }`}
                        title="Side-by-Side View"
                      >
                        <Columns className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Side by Side</span>
                      </button>
                    </div>
                  )}

                  <button
                    onClick={() => {
                      setFile(null);
                      setPreviewUrl(null);
                      setEnhancedUrl(null);
                      setModelUsed(null);
                      setErrorMessage(null);
                    }}
                    className="flex items-center gap-1.5 text-xs sm:text-sm font-semibold text-slate-500 hover:text-slate-950 transition-colors ml-2"
                  >
                    <RotateCcw className="h-4 w-4" />
                    <span>Choose Another</span>
                  </button>
                </div>
              </div>

              {/* Error Alert if any */}
              {errorMessage && (
                <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
                  <div className="text-xs sm:text-sm">
                    <p className="font-bold">Enhancement Error</p>
                    <p className="text-rose-700 mt-0.5">{errorMessage}</p>
                  </div>
                </div>
              )}

              {/* Viewer: Large & prominent */}
              {!enhancedUrl ? (
                /* Processing or Pre-Enhance View */
                <div className="relative aspect-[4/3] sm:aspect-video min-h-[380px] sm:min-h-[500px] max-h-[640px] w-full overflow-hidden border border-slate-200 rounded-2xl bg-slate-50 flex items-center justify-center">
                  <img
                    src={previewUrl}
                    alt="Original Upload"
                    className="max-h-full max-w-full object-contain"
                  />
                  {isProcessing && (
                    <div className="absolute inset-0 bg-white/90 backdrop-blur-sm flex flex-col items-center justify-center p-6 space-y-4">
                      {/* Radar animation */}
                      <div className="relative flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-20" />
                        <div className="h-11 w-11 sm:h-12 sm:w-12 rounded-full border-3 border-blue-600 border-t-transparent animate-spin" />
                      </div>
                      <div className="text-center max-w-xs space-y-1.5">
                        <p className="text-sm sm:text-base font-black text-slate-950">{processStep}</p>
                        <p className="text-xs font-semibold text-slate-500">{progress}% completed</p>
                      </div>
                      <div className="w-48 sm:w-56 bg-slate-200 h-2 rounded-full overflow-hidden">
                        <div
                          className="bg-blue-600 h-full transition-all duration-300"
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              ) : viewMode === 'enhanced' ? (
                /* Full Enhanced Output View */
                <div className="relative aspect-[4/3] sm:aspect-video min-h-[400px] sm:min-h-[540px] max-h-[680px] w-full overflow-hidden border border-slate-200 rounded-2xl bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] [background-size:16px_16px] bg-slate-100 flex items-center justify-center p-3 shadow-inner">
                  <img
                    src={enhancedUrl}
                    alt="Full Enhanced Output"
                    className="max-h-full max-w-full object-contain rounded-xl shadow-lg"
                  />
                  <span className="absolute top-4 right-4 bg-slate-950 text-white text-xs font-black px-3 py-1 uppercase tracking-wider rounded-lg shadow-md">
                    Enhanced Result
                  </span>
                </div>
              ) : viewMode === 'sideBySide' ? (
                /* Side-by-Side View */
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="relative aspect-square w-full rounded-2xl border border-slate-200 bg-slate-50 overflow-hidden flex items-center justify-center p-2 shadow-sm">
                    <img
                      src={previewUrl}
                      alt="Original"
                      className="max-h-full max-w-full object-contain"
                    />
                    <span className="absolute top-3 left-3 bg-white/95 border border-slate-200 text-slate-900 text-xs font-black px-2.5 py-0.5 rounded-lg shadow-sm">
                      Original
                    </span>
                  </div>
                  <div className="relative aspect-square w-full rounded-2xl border border-slate-200 bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] [background-size:16px_16px] bg-slate-100 overflow-hidden flex items-center justify-center p-2 shadow-sm">
                    <img
                      src={enhancedUrl}
                      alt="Enhanced"
                      className="max-h-full max-w-full object-contain"
                    />
                    <span className="absolute top-3 right-3 bg-slate-950 text-white text-xs font-black px-2.5 py-0.5 rounded-lg shadow-sm">
                      Enhanced
                    </span>
                  </div>
                </div>
              ) : (
                /* Enhanced Split Slider Comparison */
                <div className="space-y-3">
                  <div
                    ref={containerRef}
                    onPointerDown={handlePointerDown}
                    onPointerUp={handlePointerUp}
                    onPointerMove={handlePointerMove}
                    className="relative aspect-[4/3] sm:aspect-video min-h-[400px] sm:min-h-[540px] max-h-[680px] w-full select-none overflow-hidden cursor-ew-resize border border-slate-200 rounded-2xl bg-[radial-gradient(#e2e8f0_1px,transparent_1px)] [background-size:16px_16px] bg-slate-100 touch-none shadow-inner"
                  >
                    {/* Enhanced layer */}
                    <div className="absolute inset-0 flex items-center justify-center">
                      <img
                        src={enhancedUrl}
                        alt="Enhanced Result"
                        className="w-full h-full object-contain"
                      />
                      <span className="absolute top-3 right-3 sm:top-4 sm:right-4 bg-slate-950 text-white text-[10px] sm:text-xs font-black px-2.5 py-1 uppercase tracking-wider rounded-lg shadow-md">
                        Enhanced
                      </span>
                    </div>

                    {/* Original layer */}
                    <div
                      className="absolute inset-0 overflow-hidden flex items-center justify-center"
                      style={{ clipPath: `polygon(0 0, ${sliderPos}% 0, ${sliderPos}% 100%, 0 100%)` }}
                    >
                      <img
                        src={previewUrl}
                        alt="Original Photo"
                        className="w-full h-full object-contain"
                      />
                      <span className="absolute top-3 left-3 sm:top-4 sm:left-4 bg-white/95 border border-slate-200 text-slate-900 text-[10px] sm:text-xs font-black px-2.5 py-1 uppercase tracking-wider rounded-lg shadow-md">
                        Original
                      </span>
                    </div>

                    {/* Split line */}
                    <div
                      className="absolute top-0 bottom-0 w-0.5 bg-white shadow-[0_0_10px_rgba(0,0,0,0.4)]"
                      style={{ left: `${sliderPos}%` }}
                    >
                      <div className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 h-9 w-9 sm:h-11 sm:w-11 rounded-full bg-white border-2 border-slate-900 text-slate-900 flex items-center justify-center shadow-xl active:scale-110 transition-transform">
                        <SlidersHorizontal className="h-4 w-4 sm:h-5 sm:w-5 text-slate-900" />
                      </div>
                    </div>
                  </div>
                  {/* Instructions */}
                  <p className="text-center text-xs sm:text-sm font-semibold text-slate-500">
                    Drag the center handle horizontally to compare original vs enhanced output
                  </p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3.5 pt-2">
                {!enhancedUrl ? (
                  <button
                    onClick={startEnhancement}
                    disabled={isProcessing}
                    className="w-full sm:w-auto flex-1 flex items-center justify-center gap-2.5 py-4 px-8 rounded-2xl bg-slate-950 text-white font-black text-xs sm:text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl container-shade disabled:opacity-50 active:scale-98"
                  >
                    <Sparkles className="h-4 w-4" />
                    <span>{isProcessing ? 'Enhancing photo...' : 'Run AI Enhancement'}</span>
                  </button>
                ) : (
                  <>
                    <button
                      onClick={handleDownload}
                      className="w-full sm:w-auto flex-1 flex items-center justify-center gap-2.5 py-4 px-8 rounded-2xl bg-slate-950 text-white font-black text-xs sm:text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl container-shade active:scale-98"
                    >
                      <Download className="h-4 w-4" />
                      <span>Download Enhanced HD Image</span>
                    </button>
                    <button
                      onClick={onOpenPricing}
                      className="w-full sm:w-auto px-6 py-4 rounded-2xl border border-slate-300 bg-white text-slate-900 font-bold text-xs sm:text-sm hover:bg-slate-50 transition-all shadow-sm active:scale-98"
                    >
                      Unlock Unlimited 4K Batch
                    </button>
                  </>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
