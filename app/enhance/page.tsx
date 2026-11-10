'use client';

import React, { Suspense, useState, useEffect } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { Navbar } from '@/components/Navbar';
import { PaywallModal } from '@/components/PaywallModal';
import { PhotoEnhancer } from '@/components/PhotoEnhancer';

export default function EnhancePage() {
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

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 selection:bg-slate-900 selection:text-white flex">
      {/* Sidebar */}
      <Sidebar
        isOpen={isMobileSidebarOpen}
        isCollapsed={isDesktopSidebarCollapsed}
        onClose={() => setIsMobileSidebarOpen(false)}
        onToggleCollapse={handleToggleDesktopCollapse}
        onExpand={handleExpandDesktopSidebar}
        onOpenPricing={() => setIsPricingOpen(true)}
        activeItem="enhance"
      />

      {/* Main Content Area */}
      <div
        className={`flex-1 min-w-0 flex flex-col justify-between transition-all duration-300 ${
          isDesktopSidebarCollapsed ? 'lg:pl-16' : 'lg:pl-64 xl:pl-72'
        }`}
      >
        <div>
          {/* Navigation */}
          <Navbar
            onOpenPricing={() => setIsPricingOpen(true)}
            activeTab="enhance"
            setActiveTab={(tab) => {
              if (tab === 'create') window.location.href = '/';
              else if (tab === 'video') window.location.href = '/video';
            }}
            onToggleSidebar={handleToggleSidebar}
          />

          {/* Enhance Photos with video showing containers + studio */}
          <PhotoEnhancer onOpenPricing={() => setIsPricingOpen(true)} />
        </div>
      </div>

      {/* Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </div>
  );
}
