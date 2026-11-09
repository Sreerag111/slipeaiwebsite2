'use client';

import React, { useRef, useState, useEffect } from 'react';
import Link from 'next/link';
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
} from 'lucide-react';
import { ENHANCEMENT_CATEGORIES } from '@/lib/categories';

interface PhotoEnhancerProps {
  onOpenPricing?: () => void;
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

export function PhotoEnhancer({ onOpenPricing }: PhotoEnhancerProps) {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

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

  return (
    <section id="enhancer" className="py-16 sm:py-20 md:py-28 border-t border-slate-200/80 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Section Header: Styled like the sample image */}
        <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-14 space-y-3">
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-950 font-display tracking-tight leading-tight">
            Select Your Enhancement Category
          </h2>

          <p className="text-sm sm:text-base md:text-lg text-slate-600 font-display font-medium max-w-2xl mx-auto px-2 leading-relaxed">
            Choose an enhancement feature tailored to your photo&apos;s specific restoration needs.
          </p>
        </div>

        {/* Carousel Container with Circular Navigation Buttons */}
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

          {/* Right Arrow Button (matches the circular arrow button in sample image) */}
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

          {/* Horizontal Scrollable Row of Prominent Cards */}
          <div
            ref={scrollContainerRef}
            onScroll={checkScroll}
            className="flex gap-4 sm:gap-6 overflow-x-auto scroll-smooth pb-6 pt-2 px-1 scrollbar-none snap-x snap-mandatory"
          >
            {ENHANCEMENT_CATEGORIES.map((cat) => {
              const Icon = ICON_MAP[cat.iconName] || Sparkles;

              return (
                <Link
                  key={cat.id}
                  href={`/enhance?category=${cat.id}`}
                  className="w-[280px] sm:w-[320px] md:w-[340px] shrink-0 snap-start flex flex-col p-3.5 sm:p-4 rounded-[24px] sm:rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] hover:shadow-[0_16px_36px_rgba(0,0,0,0.1)] hover:-translate-y-1.5 transition-all duration-300 active:scale-[0.98] group text-left"
                >
                  {/* Media Visual (Animated WebP Video: Large, prominent, and clearly visible) */}
                  <div className="relative w-full aspect-[16/11] sm:aspect-[4/3] rounded-[18px] sm:rounded-[22px] overflow-hidden bg-slate-100 mb-3.5 sm:mb-4 shadow-inner border border-slate-100">
                    <img
                      src={`/assets/videos/enhance_categories/${cat.file}`}
                      alt={cat.label}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
                      loading="eager"
                    />

                    {/* Hover indicator: "Select to Enhance ->" */}
                    <div className="absolute inset-0 bg-gradient-to-t from-slate-950/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-3 pointer-events-none">
                      <span className="text-[11px] font-bold text-white bg-blue-600/95 px-3 py-1 rounded-lg backdrop-blur-sm shadow-md flex items-center gap-1.5 font-display">
                        <span>Select to Enhance</span>
                        <ArrowRight className="w-3 h-3" />
                      </span>
                    </div>
                  </div>

                  {/* Card Info: Icon + Title row & clean description */}
                  <div className="space-y-1.5 flex-1 flex flex-col justify-between px-1 pb-1">
                    <div className="flex items-center gap-2.5">
                      <div className="flex items-center justify-center w-8 h-8 rounded-xl bg-slate-100 text-slate-900 group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0 shadow-sm">
                        <Icon className="w-4 h-4" />
                      </div>
                      <h3 className="text-base sm:text-lg font-bold text-slate-950 font-display tracking-tight group-hover:text-blue-700 transition-colors line-clamp-1">
                        {cat.label}
                      </h3>
                    </div>

                    <p className="text-xs sm:text-[13px] text-slate-600 font-medium leading-relaxed font-display line-clamp-2">
                      {cat.desc}
                    </p>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
