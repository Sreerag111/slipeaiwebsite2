'use client';

import React from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowRight, Sparkles } from 'lucide-react';
import { ENHANCEMENT_CATEGORIES } from '@/lib/categories';

interface PhotoEnhancerProps {
  onOpenPricing?: () => void;
}

export function PhotoEnhancer({ onOpenPricing }: PhotoEnhancerProps) {
  const router = useRouter();

  const handleSelectCategory = (catId: string) => {
    router.push(`/enhance?category=${catId}`);
  };

  return (
    <section id="enhancer" className="py-14 sm:py-20 md:py-28 border-t border-slate-200/80 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-14 space-y-3">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-blue-200 bg-blue-50 text-[11px] sm:text-xs font-bold text-blue-900 shadow-sm">
            <Sparkles className="w-3.5 h-3.5 text-blue-600" />
            <span>Topaz Labs AI Inference Engine</span>
          </div>
          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
            Select Your Enhancement Category
          </h2>
          <p className="text-xs sm:text-sm md:text-base text-slate-600 font-semibold px-2">
            Click any feature to open the enhancement studio and upload your photo.
          </p>
        </div>

        {/* 10 Categories Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3 sm:gap-4.5 mb-8">
          {ENHANCEMENT_CATEGORIES.map((cat) => (
            <Link
              key={cat.id}
              href={`/enhance?category=${cat.id}`}
              className="relative flex flex-col p-3 sm:p-3.5 rounded-2xl border border-slate-200/90 bg-white hover:border-blue-500 hover:bg-blue-50/20 container-shade-sm hover:container-shade hover:-translate-y-1 transition-all duration-300 active:scale-[0.98] group text-left"
            >
              {/* Preview Thumbnail */}
              <div className="relative aspect-[4/3] w-full rounded-xl overflow-hidden border border-slate-100 mb-2.5 bg-slate-100 shadow-inner">
                <Image
                  src={`/assets/videos/enhance_categories/${cat.file}`}
                  alt={cat.label}
                  fill
                  sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 20vw"
                  className="object-cover group-hover:scale-105 transition-transform duration-500 ease-out"
                  unoptimized
                />
                {cat.badge && (
                  <span className="absolute top-2 left-2 text-[10px] font-black uppercase tracking-wider bg-slate-950/80 backdrop-blur-sm text-white px-2 py-0.5 rounded-md shadow-sm">
                    {cat.badge}
                  </span>
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-end p-2 pointer-events-none">
                  <span className="text-[10px] font-bold text-white bg-blue-600/95 px-2 py-0.5 rounded-md backdrop-blur-sm shadow-sm flex items-center gap-1">
                    Select Feature <ArrowRight className="w-2.5 h-2.5" />
                  </span>
                </div>
              </div>

              {/* Title & Description */}
              <div className="w-full space-y-1">
                <div className="flex items-center justify-between gap-1">
                  <span className="text-xs sm:text-sm font-black text-slate-950 group-hover:text-blue-700 transition-colors line-clamp-1">
                    {cat.label}
                  </span>
                  <ArrowRight className="w-3.5 h-3.5 text-slate-400 group-hover:text-blue-600 group-hover:translate-x-0.5 transition-all opacity-0 group-hover:opacity-100 shrink-0" />
                </div>
                <span className="text-[10px] sm:text-[11px] text-slate-500 font-semibold block line-clamp-2 leading-tight">
                  {cat.desc}
                </span>
              </div>
            </Link>
          ))}
        </div>

        {/* Bottom Helper Bar */}
        <div className="text-center pt-2">
          <p className="text-xs text-slate-500 font-medium">
            Selecting a feature takes you directly to the Photo Enhancement Studio with instant Topaz AI inference.
          </p>
        </div>
      </div>
    </section>
  );
}
