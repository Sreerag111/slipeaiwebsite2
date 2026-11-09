'use client';

import React, { useRef, useState, useEffect } from 'react';
import {
  Sparkles,
  Wand2,
  Palette,
  SunMedium,
  ShieldAlert,
  ScanFace,
  Zap,
  SlidersHorizontal,
  Maximize2,
  Scissors,
  ChevronLeft,
  ChevronRight,
  ArrowRight,
  Upload,
  Check,
  CheckCircle2,
  RotateCcw,
  Eye,
  Columns,
  Loader2,
  Download,
} from 'lucide-react';
import { saveAs } from 'file-saver';
import { ENHANCEMENT_CATEGORIES, EnhancementCategory } from '@/lib/categories';

interface PhotoEnhancerProps {
  onOpenPricing?: () => void;
  initialCategory?: string;
}

const ICON_MAP: Record<string, React.ElementType> = {
  Sparkles,
  Wand2,
  Palette,
  SunMedium,
  ShieldAlert,
  ScanFace,
  Zap,
  SlidersHorizontal,
  Maximize2,
  Scissors,
};

export function PhotoEnhancer({ onOpenPricing, initialCategory }: PhotoEnhancerProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>(
    initialCategory || 'enhance_photos_quality'
  );

  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const studioRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

  // Active Category Object
  const activeCategory: EnhancementCategory =
    ENHANCEMENT_CATEGORIES.find((c) => c.id === selectedCategory) ||
    ENHANCEMENT_CATEGORIES[0];

  // Studio Workspace States
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
    if (enhancedUrl) setEnhancedUrl(null);
    setModelUsed(null);
    setErrorMessage(null);
  };

  // Convert WebP/heic to JPEG for Topaz API compatibility
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
    if (previewUrl) URL.revokeObjectURL(previewUrl);
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

  const startEnhancement = async () => {
    if (!file || !previewUrl) return;

    const isLocalhost =
      typeof window !== 'undefined' &&
      (window.location.hostname === 'localhost' ||
        window.location.hostname === '127.0.0.1' ||
        window.location.hostname.includes('192.168.'));

    const currentUses = parseInt(localStorage.getItem('slipeai_free_uses') || '0', 10);
    if (!isLocalhost && currentUses >= 5 && onOpenPricing) {
      onOpenPricing();
      return;
    }

    setIsProcessing(true);
    setErrorMessage(null);
    setProgress(15);
    setProcessStep('Connecting to SlipeAI inference engine...');

    const timer1 = setTimeout(() => {
      setProgress(40);
      setProcessStep(activeCategory.stepText || 'Analyzing pixels & facial landmarks...');
    }, 800);

    const timer2 = setTimeout(() => {
      setProgress(70);
      setProcessStep('Synthesizing high-frequency neural features...');
    }, 2400);

    const timer3 = setTimeout(() => {
      setProgress(90);
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
    <section id="enhancer" className="py-8 sm:py-12 md:py-16 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 space-y-8 sm:space-y-12">
        {/* Section Header: Styled exactly like select your enhancement category */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5">
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-950 font-display tracking-tight leading-tight">
            Select Your Enhancement Category
          </h2>

          <p className="text-sm sm:text-base md:text-lg text-slate-600 font-display font-medium max-w-2xl mx-auto px-2 leading-relaxed">
            These enhancements are done by SlipeAI
          </p>
        </div>

        {/* Video Showing Containers Carousel */}
        <div className="relative group/carousel">
          {/* Left Arrow Button */}
          {canScrollLeft && (
            <button
              type="button"
              onClick={() => handleScroll('left')}
              aria-label="Previous enhancement features"
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
              aria-label="Next enhancement features"
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
            {ENHANCEMENT_CATEGORIES.map((cat) => {
              const Icon = ICON_MAP[cat.iconName] || Sparkles;
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
                  {/* Media Visual: Animated WebP Video Preview */}
                  <div className="relative w-full aspect-[16/11] sm:aspect-[4/3] rounded-[18px] sm:rounded-[22px] overflow-hidden bg-slate-100 mb-3.5 sm:mb-4 shadow-inner border border-slate-100">
                    <img
                      src={`/assets/videos/enhance_categories/${cat.file}`}
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
                          <span>Select Feature</span>
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

        {/* Interactive Photo Enhancement Studio Workspace */}
        <div
          ref={studioRef}
          className="rounded-[28px] sm:rounded-[36px] border border-slate-200/90 bg-white p-5 sm:p-8 md:p-10 shadow-[0_8px_30px_rgba(0,0,0,0.06)] space-y-6"
        >
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
            /* Active Workspace with Preview & Comparison */
            <div className="space-y-6 font-display">
              {/* Workspace Header Status Bar */}
              <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-100">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-xs font-semibold text-slate-500">Photo:</span>
                  <span className="text-xs sm:text-sm font-bold text-slate-900 truncate max-w-[200px] sm:max-w-md">
                    {file?.name || 'Selected Photo'}
                  </span>
                  <span className="text-xs bg-blue-50 border border-blue-200 px-2.5 py-0.5 rounded-lg text-blue-900 font-bold">
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
                        title="Side by Side"
                      >
                        <Columns className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Side-by-Side</span>
                      </button>
                    </div>
                  )}

                  <button
                    type="button"
                    onClick={() => {
                      if (previewUrl) URL.revokeObjectURL(previewUrl);
                      setFile(null);
                      setPreviewUrl(null);
                      setEnhancedUrl(null);
                      setModelUsed(null);
                      setErrorMessage(null);
                    }}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:text-slate-950 hover:bg-slate-50 text-xs font-bold transition-all"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                    <span>Change Photo</span>
                  </button>
                </div>
              </div>

              {/* Error Alert */}
              {errorMessage && (
                <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 text-xs sm:text-sm font-semibold flex items-center gap-2">
                  <span>{errorMessage}</span>
                </div>
              )}

              {/* Processing Progress Stage */}
              {isProcessing && (
                <div className="p-6 rounded-2xl bg-blue-50/70 border border-blue-200 space-y-3">
                  <div className="flex items-center justify-between text-xs sm:text-sm font-bold text-blue-950">
                    <span className="flex items-center gap-2">
                      <Loader2 className="w-4 h-4 text-blue-600 animate-spin" />
                      <span>{processStep}</span>
                    </span>
                    <span>{progress}%</span>
                  </div>
                  <div className="h-2 w-full rounded-full bg-blue-100 overflow-hidden">
                    <div
                      className="h-full bg-blue-600 transition-all duration-300 ease-out"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Main Image Stage */}
              <div
                ref={containerRef}
                onPointerDown={enhancedUrl && viewMode === 'slider' ? handlePointerDown : undefined}
                onPointerUp={enhancedUrl && viewMode === 'slider' ? handlePointerUp : undefined}
                onPointerMove={enhancedUrl && viewMode === 'slider' ? handlePointerMove : undefined}
                className="relative mx-auto max-w-4xl max-h-[640px] aspect-[4/3] rounded-3xl overflow-hidden bg-slate-950 select-none border border-slate-200/90 shadow-xl touch-none flex items-center justify-center"
              >
                {!enhancedUrl ? (
                  /* Single Preview Image before enhancing */
                  <div className="relative w-full h-full flex items-center justify-center p-2">
                    <img
                      src={previewUrl}
                      alt="Original"
                      className="max-h-full max-w-full object-contain"
                    />
                    <div className="absolute top-4 left-4 bg-slate-900/80 backdrop-blur-md px-3 py-1 rounded-lg text-white text-xs font-bold">
                      Original Photo
                    </div>
                  </div>
                ) : viewMode === 'enhanced' ? (
                  /* Full Enhanced View */
                  <div className="relative w-full h-full flex items-center justify-center p-2">
                    <img
                      src={enhancedUrl}
                      alt="Enhanced"
                      className="max-h-full max-w-full object-contain"
                    />
                    <div className="absolute top-4 right-4 bg-blue-600 text-white px-3 py-1 rounded-lg text-xs font-bold shadow-md">
                      Enhanced Output
                    </div>
                  </div>
                ) : viewMode === 'sideBySide' ? (
                  /* Side-by-side View */
                  <div className="w-full h-full grid grid-cols-2 gap-2 p-2 bg-slate-950">
                    <div className="relative w-full h-full flex items-center justify-center overflow-hidden rounded-2xl bg-black">
                      <img
                        src={previewUrl}
                        alt="Original"
                        className="max-h-full max-w-full object-contain"
                      />
                      <span className="absolute top-3 left-3 bg-slate-900/80 text-white px-2.5 py-0.5 rounded text-[11px] font-bold">
                        Before
                      </span>
                    </div>
                    <div className="relative w-full h-full flex items-center justify-center overflow-hidden rounded-2xl bg-black">
                      <img
                        src={enhancedUrl}
                        alt="Enhanced"
                        className="max-h-full max-w-full object-contain"
                      />
                      <span className="absolute top-3 right-3 bg-blue-600 text-white px-2.5 py-0.5 rounded text-[11px] font-bold">
                        After
                      </span>
                    </div>
                  </div>
                ) : (
                  /* Interactive Split Slider */
                  <div className="relative w-full h-full flex items-center justify-center">
                    {/* Enhanced Image (Base) */}
                    <img
                      src={enhancedUrl}
                      alt="Enhanced"
                      className="absolute inset-0 w-full h-full object-contain"
                    />

                    {/* Original Image (Clipped) */}
                    <div
                      className="absolute inset-0 overflow-hidden"
                      style={{ width: `${sliderPos}%` }}
                    >
                      <img
                        src={previewUrl}
                        alt="Original"
                        className="absolute inset-0 w-full h-full object-contain max-w-none"
                      />
                    </div>

                    {/* Draggable Divider Line */}
                    <div
                      className="absolute top-0 bottom-0 w-1 bg-white shadow-[0_0_12px_rgba(0,0,0,0.5)] cursor-ew-resize z-20"
                      style={{ left: `${sliderPos}%` }}
                    >
                      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-white text-slate-900 shadow-xl flex items-center justify-center border-2 border-slate-300">
                        <SlidersHorizontal className="w-4 h-4 text-slate-800 rotate-90" />
                      </div>
                    </div>

                    {/* Labels */}
                    <div className="absolute top-4 left-4 bg-slate-900/80 backdrop-blur-md px-3 py-1 rounded-lg text-white text-xs font-bold pointer-events-none z-10">
                      Before
                    </div>
                    <div className="absolute top-4 right-4 bg-blue-600/90 backdrop-blur-md px-3 py-1 rounded-lg text-white text-xs font-bold pointer-events-none z-10">
                      After
                    </div>
                  </div>
                )}
              </div>

              {/* Bottom Actions Bar */}
              <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-2">
                <div className="text-xs text-slate-500 font-medium">
                  {enhancedUrl
                    ? `Enhanced using ${modelUsed || 'SlipeAI'}`
                    : `Ready to enhance with ${activeCategory.label}`}
                </div>

                <div className="flex items-center gap-3 w-full sm:w-auto">
                  {!enhancedUrl ? (
                    <button
                      type="button"
                      onClick={startEnhancement}
                      disabled={isProcessing}
                      className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-slate-950 hover:bg-slate-800 disabled:bg-slate-300 text-white font-black text-xs sm:text-sm uppercase tracking-wider transition-all shadow-lg active:scale-95"
                    >
                      <Wand2 className="w-4 h-4" />
                      <span>{isProcessing ? 'Enhancing...' : 'Enhance Photo Now'}</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={handleDownload}
                      className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-black text-xs sm:text-sm uppercase tracking-wider transition-all shadow-lg active:scale-95"
                    >
                      <Download className="w-4 h-4" />
                      <span>Download Enhanced Photo</span>
                    </button>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
