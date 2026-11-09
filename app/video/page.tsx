'use client';

import React, { Suspense, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { PaywallModal } from '@/components/PaywallModal';
import { VideoEnhancer } from '@/components/VideoEnhancer';

export default function VideoPage() {
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [isDesktopSidebarCollapsed, setIsDesktopSidebarCollapsed] = useState(false);

  const handleToggleSidebar = () => {
    if (typeof window !== 'undefined' && window.innerWidth < 1024) {
      setIsMobileSidebarOpen((prev) => !prev);
    } else {
      setIsDesktopSidebarCollapsed((prev) => !prev);
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 selection:bg-slate-900 selection:text-white flex">
      {/* Sidebar */}
      <Sidebar
        isOpen={isMobileSidebarOpen}
        isCollapsed={isDesktopSidebarCollapsed}
        onClose={() => setIsMobileSidebarOpen(false)}
        onToggleCollapse={() => setIsDesktopSidebarCollapsed(!isDesktopSidebarCollapsed)}
        onOpenPricing={() => setIsPricingOpen(true)}
        activeItem="video"
      />

      {/* Main Content Area */}
      <div
        className={`flex-1 min-w-0 flex flex-col justify-between transition-all duration-300 ${
          isDesktopSidebarCollapsed ? 'lg:pl-0' : 'lg:pl-64 xl:pl-72'
        }`}
      >
        <div>
          {/* Navigation */}
          <Navbar
            onOpenPricing={() => setIsPricingOpen(true)}
            activeTab="video"
            setActiveTab={(tab) => {
              if (tab === 'create') window.location.href = '/';
              else if (tab === 'enhance') window.location.href = '/enhance';
            }}
            onToggleSidebar={handleToggleSidebar}
          />

          {/* Remaster Videos with video showing containers + studio */}
          <VideoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
        </div>
      </div>

      {/* Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </div>
  );
}
