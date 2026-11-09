'use client';

import React, { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { PhotoEnhancer } from '@/components/PhotoEnhancer';
import { VideoEnhancer } from '@/components/VideoEnhancer';
import { AIImageCreation } from '@/components/AIImageCreation';
import { PaywallModal } from '@/components/PaywallModal';
import { Footer } from '@/components/Footer';
import { Download } from 'lucide-react';

function HomeContent() {
  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');

  const [activeTab, setActiveTab] = useState<'create' | 'enhance' | 'video'>('create');
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isDesktopSidebarCollapsed, setIsDesktopSidebarCollapsed] = useState(false);

  useEffect(() => {
    if (tabParam === 'enhance' || tabParam === 'enhancer') {
      setActiveTab('enhance');
    } else if (tabParam === 'video') {
      setActiveTab('video');
    } else if (tabParam === 'create') {
      setActiveTab('create');
    }
  }, [tabParam]);

  const handleToggleSidebar = () => {
    if (typeof window !== 'undefined' && window.innerWidth < 1024) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsDesktopSidebarCollapsed((prev) => !prev);
    }
  };

  const handleSelectSection = (sectionId: string) => {
    if (sectionId === 'enhance' || sectionId === 'enhancer') {
      setActiveTab('enhance');
    } else if (sectionId === 'video') {
      setActiveTab('video');
    } else {
      setActiveTab('create');
    }
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
        onSelectSection={handleSelectSection}
      />

      {/* Main Content Canvas (Right Side) */}
      <div
        className={`flex-1 min-w-0 flex flex-col justify-between transition-all duration-300 ${
          isDesktopSidebarCollapsed ? 'lg:pl-0' : 'lg:pl-64 xl:pl-72'
        }`}
      >
        {/* Top Navigation */}
        <Navbar
          onOpenPricing={() => setIsPricingOpen(true)}
          activeTab={activeTab}
          setActiveTab={(tab) => handleSelectSection(tab)}
          onToggleSidebar={handleToggleSidebar}
        />

        {/* Dynamic Section Display: Only the selected section is shown on the right side (No Scrolling Flow) */}
        <main className="flex-1">
          {activeTab === 'create' && (
            <AIImageCreation
              onStartEnhancing={() => setActiveTab('enhance')}
              onStartRemasterVideo={() => setActiveTab('video')}
            />
          )}

          {activeTab === 'enhance' && (
            <PhotoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
          )}

          {activeTab === 'video' && (
            <VideoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
          )}
        </main>

        {/* Bottom CTA Banner with Light Shade Design */}
        <section className="py-12 sm:py-16 border-t border-slate-200/80 bg-white text-center">
          <div className="mx-auto max-w-5xl px-4 sm:px-6 space-y-4">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-slate-200 bg-slate-50 text-[11px] sm:text-xs font-semibold text-slate-700 shadow-sm container-shade-sm">
              <span>Also Available on Android</span>
            </div>
            <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
              Take Slipe AI Everywhere
            </h2>
            <p className="text-xs sm:text-sm text-slate-600 font-semibold max-w-xl mx-auto px-2 leading-relaxed">
              Experience lightning-fast on-device camera enhancement and creative tools directly from your pocket.
            </p>
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-center gap-3.5 pt-2">
              <a
                href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto flex items-center justify-center gap-2 px-7 py-3.5 rounded-2xl bg-slate-950 text-white font-black text-xs sm:text-sm uppercase tracking-wider hover:bg-slate-800 transition-all shadow-xl hover:scale-[1.01] active:scale-98"
              >
                <Download className="h-4 w-4" />
                <span>Download on Google Play</span>
              </a>
              <Link
                href="/pricing"
                className="w-full sm:w-auto flex items-center justify-center px-7 py-3.5 rounded-2xl border border-slate-200 bg-white text-slate-900 font-bold text-xs sm:text-sm hover:bg-slate-50 transition-all shadow-sm active:scale-98"
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

export default function Home() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F8FAFC]" />}>
      <HomeContent />
    </Suspense>
  );
}
