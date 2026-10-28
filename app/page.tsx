'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { Navbar } from '@/components/Navbar';
import { Hero } from '@/components/Hero';
import { PhotoEnhancer } from '@/components/PhotoEnhancer';
import { VideoEnhancer } from '@/components/VideoEnhancer';
import { AIChat } from '@/components/AIChat';
import { PaywallModal } from '@/components/PaywallModal';
import { Footer } from '@/components/Footer';
import { Sparkles, ShieldCheck, Zap, Download, Check, Star } from 'lucide-react';

export default function Home() {
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('enhancer');

  const scrollToEnhancer = () => {
    setActiveTab('enhancer');
    const el = document.getElementById('enhancer');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <main className="min-h-screen bg-black text-white selection:bg-white selection:text-black">
      {/* Navigation */}
      <Navbar
        onOpenPricing={() => setIsPricingOpen(true)}
        activeTab={activeTab}
        setActiveTab={setActiveTab}
      />

      {/* Hero with interactive Before/After split */}
      <Hero
        onStartEnhancing={scrollToEnhancer}
        onOpenPricing={() => setIsPricingOpen(true)}
      />

      {/* Photo Enhancer Suite (The 10 Categories) */}
      <PhotoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />

      {/* 2x2 Showcase Gallery Section */}
      <section id="showcase" className="py-16 md:py-24 border-t border-neutral-900 bg-black">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-12 space-y-3">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border border-neutral-800 bg-neutral-950 text-[11px] font-bold text-neutral-300">
              <Star className="h-3 w-3 text-white" />
              <span>Real Restoration Gallery</span>
            </div>
            <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-white tracking-tight">
              Before & After Neural Restorations
            </h2>
            <p className="text-xs sm:text-sm text-neutral-400">
              Genuine comparisons demonstrating facial recovery, historical damage inpainting, and studio colorization.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { id: 1, title: 'Archival Portrait Recovery', tag: 'Face Restoration' },
              { id: 2, title: 'Historical Colorization', tag: 'B&W to Color' },
              { id: 3, title: 'Micro-Texture Synthesis', tag: 'Super Resolution' },
              { id: 4, title: 'Sensor Scratch Inpainting', tag: 'Cleanup AI' },
            ].map((card) => (
              <div
                key={card.id}
                className="group relative overflow-hidden border-2 border-white bg-neutral-950 halo-shadow-sm transition-all duration-300 hover:halo-shadow hover:scale-[1.01]"
              >
                <div className="relative aspect-square w-full">
                  <Image
                    src={`/assets/images/premium_showcase_${card.id}.jpg`}
                    alt={card.title}
                    fill
                    className="object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent opacity-80 group-hover:opacity-60 transition-opacity" />
                  <div className="absolute bottom-3 left-3 right-3 text-left">
                    <span className="text-[10px] font-black uppercase tracking-wider text-black bg-white px-2 py-0.5 shadow">
                      {card.tag}
                    </span>
                    <h3 className="text-sm font-black text-white mt-1.5">{card.title}</h3>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="text-center mt-8">
            <button
              onClick={() => setIsPricingOpen(true)}
              className="inline-flex items-center gap-2 px-6 py-3 border border-neutral-800 bg-neutral-950 text-xs font-bold text-neutral-300 hover:text-white hover:border-neutral-600 transition-all rounded-none"
            >
              <Sparkles className="h-3.5 w-3.5 text-white" />
              <span>Unlock All Ultra HD Showcases with Pro</span>
            </button>
          </div>
        </div>
      </section>

      {/* Video Remaster Suite */}
      <VideoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />

      {/* Slipe AI Interactive Chat */}
      <AIChat />

      {/* Bottom CTA Banner */}
      <section className="py-16 md:py-20 border-t border-neutral-900 bg-neutral-950 text-center">
        <div className="mx-auto max-w-4xl px-4 sm:px-6 space-y-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-neutral-800 bg-black text-xs font-semibold text-neutral-300">
            <span>Also Available on Android</span>
          </div>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-white tracking-tight">
            Take Slipe AI Everywhere
          </h2>
          <p className="text-xs sm:text-sm text-neutral-400 max-w-xl mx-auto">
            Experience lightning-fast on-device camera enhancement and creative tools directly from your pocket.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full sm:w-auto flex items-center justify-center gap-2 px-7 py-3.5 rounded-none bg-white text-black font-black text-sm uppercase tracking-wider hover:bg-neutral-200 transition-all shadow-xl halo-shadow"
            >
              <Download className="h-4 w-4" />
              <span>Download on Google Play</span>
            </a>
            <button
              onClick={() => setIsPricingOpen(true)}
              className="w-full sm:w-auto px-7 py-3.5 rounded-none border border-neutral-800 bg-black text-white font-bold text-sm hover:border-neutral-600 transition-all"
            >
              View Web Pricing Plans
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <Footer />

      {/* Global Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </main>
  );
}
