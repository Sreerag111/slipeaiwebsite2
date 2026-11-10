'use client';

import React, { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { PhotoEnhancer } from '@/components/PhotoEnhancer';
import { VideoEnhancer } from '@/components/VideoEnhancer';
import { AIImageCreation } from '@/components/AIImageCreation';
import { AudioEnhanceSection } from '@/components/AudioEnhanceSection';
import { AIGifStudio } from '@/components/AIGifStudio';
import { PaywallModal } from '@/components/PaywallModal';

function HomeContent() {
  const searchParams = useSearchParams();
  const tabParam = searchParams.get('tab');

  const [activeTab, setActiveTab] = useState<'create' | 'enhance' | 'video' | 'audio' | 'gif'>('create');
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isDesktopSidebarCollapsed, setIsDesktopSidebarCollapsed] = useState(true);

  useEffect(() => {
    try {
      const saved = localStorage.getItem('slipeai_sidebar_collapsed');
      if (saved !== null) {
        setIsDesktopSidebarCollapsed(saved === 'true');
      } else {
        setIsDesktopSidebarCollapsed(true);
      }
    } catch {
      setIsDesktopSidebarCollapsed(true);
    }
  }, []);

  useEffect(() => {
    if (tabParam === 'enhance' || tabParam === 'enhancer') {
      setActiveTab('enhance');
    } else if (tabParam === 'video') {
      setActiveTab('video');
    } else if (tabParam === 'audio') {
      setActiveTab('audio');
    } else if (tabParam === 'gif') {
      setActiveTab('gif');
    } else if (tabParam === 'create') {
      setActiveTab('create');
    }
  }, [tabParam]);

  const handleToggleSidebar = () => {
    if (typeof window !== 'undefined' && window.innerWidth < 1024) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsDesktopSidebarCollapsed((prev) => {
        const next = !prev;
        try {
          localStorage.setItem('slipeai_sidebar_collapsed', String(next));
        } catch {}
        return next;
      });
    }
  };

  const handleToggleDesktopCollapse = () => {
    setIsDesktopSidebarCollapsed((prev) => {
      const next = !prev;
      try {
        localStorage.setItem('slipeai_sidebar_collapsed', String(next));
      } catch {}
      return next;
    });
  };

  const handleExpandDesktopSidebar = () => {
    setIsDesktopSidebarCollapsed(false);
    try {
      localStorage.setItem('slipeai_sidebar_collapsed', 'false');
    } catch {}
  };

  const handleSelectSection = (sectionId: string) => {
    if (sectionId === 'enhance' || sectionId === 'enhancer') {
      setActiveTab('enhance');
    } else if (sectionId === 'video') {
      setActiveTab('video');
    } else if (sectionId === 'audio') {
      setActiveTab('audio');
    } else if (sectionId === 'gif') {
      setActiveTab('gif');
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
        onToggleCollapse={handleToggleDesktopCollapse}
        onExpand={handleExpandDesktopSidebar}
        onOpenPricing={() => setIsPricingOpen(true)}
        activeItem={activeTab}
        onSelectSection={handleSelectSection}
      />

      {/* Main Content Canvas (Right Side) */}
      <div
        className={`flex-1 min-w-0 flex flex-col justify-between transition-all duration-300 ${
          isDesktopSidebarCollapsed ? 'lg:pl-16' : 'lg:pl-64 xl:pl-72'
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

          {activeTab === 'audio' && (
            <AudioEnhanceSection onExploreGif={() => setActiveTab('gif')} />
          )}

          {activeTab === 'gif' && (
            <AIGifStudio onOpenPricing={() => setIsPricingOpen(true)} />
          )}
        </main>
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
