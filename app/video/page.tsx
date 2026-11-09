'use client';

import React, { Suspense, useState } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { PaywallModal } from '@/components/PaywallModal';
import { VideoEnhanceStudio } from '@/components/VideoEnhanceStudio';
import { Loader2 } from 'lucide-react';

function StudioLoading() {
  return (
    <div className="min-h-[600px] flex flex-col items-center justify-center p-8 space-y-4">
      <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
      <p className="text-sm font-bold text-slate-600">Loading Video Remaster Studio...</p>
    </div>
  );
}

export default function VideoPage() {
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('video');
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
            activeTab={activeTab}
            setActiveTab={setActiveTab}
            onToggleSidebar={handleToggleSidebar}
          />

          {/* Dedicated Video Remaster Studio */}
          <Suspense fallback={<StudioLoading />}>
            <VideoEnhanceStudio onOpenPricing={() => setIsPricingOpen(true)} />
          </Suspense>
        </div>

        {/* Footer */}
        <Footer />
      </div>

      {/* Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </div>
  );
}
