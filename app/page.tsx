'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { Hero } from '@/components/Hero';
import { PhotoEnhancer } from '@/components/PhotoEnhancer';
import { VideoEnhancer } from '@/components/VideoEnhancer';
import { AIImageCreation } from '@/components/AIImageCreation';
import { PaywallModal } from '@/components/PaywallModal';
import { Footer } from '@/components/Footer';
import { Download } from 'lucide-react';

export default function Home() {
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('create');
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isDesktopSidebarCollapsed, setIsDesktopSidebarCollapsed] = useState(false);

  const handleToggleSidebar = () => {
    if (typeof window !== 'undefined' && window.innerWidth < 1024) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsDesktopSidebarCollapsed((prev) => !prev);
    }
  };

  const scrollToEnhancer = () => {
    setActiveTab('enhancer');
    const el = document.getElementById('enhancer');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  const scrollToVideo = () => {
    setActiveTab('video');
    const el = document.getElementById('video');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  const scrollToCreate = () => {
    setActiveTab('create');
    const el = document.getElementById('create');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 selection:bg-slate-900 selection:text-white flex">
      {/* Left Sidebar with Enhance Photos, Remaster Videos, New Creation & Profile */}
      <Sidebar
        isOpen={isMobileSidebarOpen}
        isCollapsed={isDesktopSidebarCollapsed}
        onClose={() => setIsMobileSidebarOpen(false)}
        onToggleCollapse={() => setIsDesktopSidebarCollapsed(!isDesktopSidebarCollapsed)}
        onOpenPricing={() => setIsPricingOpen(true)}
        activeItem={activeTab}
        onSelectSection={(sectionId) => setActiveTab(sectionId)}
      />

      {/* Main Content Canvas */}
      <div
        className={`flex-1 min-w-0 flex flex-col justify-between transition-all duration-300 ${
          isDesktopSidebarCollapsed ? 'lg:pl-0' : 'lg:pl-64 xl:pl-72'
        }`}
      >
        {/* Top Navigation */}
        <Navbar
          onOpenPricing={() => setIsPricingOpen(true)}
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          onToggleSidebar={handleToggleSidebar}
        />

        {/* Main View: Prominently display AI Image Creation Section first */}
        <div id="create">
          <AIImageCreation onStartEnhancing={scrollToEnhancer} />
        </div>

        {/* Photo Enhancer Suite (The 10 Categories) */}
        <div id="enhancer">
          <PhotoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
        </div>

        {/* Video Remaster Suite */}
        <div id="video">
          <VideoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
        </div>

        {/* Interactive Before/After Showcase */}
        <Hero
          onStartEnhancing={scrollToEnhancer}
          onOpenPricing={() => setIsPricingOpen(true)}
        />

        {/* Bottom CTA Banner with Light Shade Design */}
        <section className="py-16 sm:py-20 md:py-28 border-t border-slate-200/80 bg-white text-center">
          <div className="mx-auto max-w-5xl px-4 sm:px-6 space-y-4 sm:space-y-6">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-slate-200 bg-slate-50 text-[11px] sm:text-xs font-semibold text-slate-700 shadow-sm container-shade-sm">
              <span>Also Available on Android</span>
            </div>
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
              Take Slipe AI Everywhere
            </h2>
            <p className="text-xs sm:text-sm md:text-base text-slate-600 font-semibold max-w-xl mx-auto px-2 leading-relaxed">
              Experience lightning-fast on-device camera enhancement and creative tools directly from your pocket.
            </p>
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-center gap-3.5 pt-2">
              <a
                href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-7 py-4 rounded-2xl bg-slate-950 text-white font-black text-xs sm:text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl container-shade hover:scale-[1.01] active:scale-98"
              >
                <Download className="h-4 w-4" />
                <span>Download on Google Play</span>
              </a>
              <Link
                href="/pricing"
                className="w-full sm:w-auto flex items-center justify-center px-7 py-4 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold text-xs sm:text-sm hover:bg-slate-50 transition-all shadow-sm container-shade-sm active:scale-98"
              >
                View Web Pricing Plans
              </Link>
            </div>
          </div>
        </section>

        {/* Footer */}
        <Footer />
      </div>

      {/* Global Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </div>
  );
}
