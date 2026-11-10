'use client';

import React from 'react';
import { Download } from 'lucide-react';

interface NavbarProps {
  onOpenPricing?: () => void;
  activeTab?: string;
  setActiveTab?: (tab: string) => void;
  onToggleSidebar?: () => void;
  isSidebarOpen?: boolean;
}

export function Navbar({
  onOpenPricing,
}: NavbarProps) {
  return (
    <header className="sticky top-0 z-40 w-full bg-transparent font-display pointer-events-none">
      <div className="flex items-center justify-end px-4 sm:px-6 lg:px-8 py-3.5 sm:py-4">
        {/* Right Actions: Upgrade Now & Get App in Shaded Pill Container */}
        <div className="flex items-center gap-2 p-1.5 rounded-2xl bg-white/95 backdrop-blur-md border border-slate-200/90 shadow-[0_8px_30px_rgba(0,0,0,0.08)] hover:shadow-[0_12px_36px_rgba(0,0,0,0.12)] transition-shadow pointer-events-auto">
          <button
            type="button"
            onClick={onOpenPricing}
            className="text-xs sm:text-sm font-bold px-3.5 sm:px-4 py-2 rounded-xl text-slate-800 hover:text-slate-950 hover:bg-slate-100/90 transition-all active:scale-95 cursor-pointer"
          >
            Upgrade Now
          </button>

          <a
            href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 text-xs sm:text-sm font-bold px-3.5 sm:px-4 py-2 rounded-xl bg-slate-950 text-white hover:bg-slate-800 transition-all shadow-sm hover:shadow-md group active:scale-95 cursor-pointer"
          >
            <Download className="h-3.5 w-3.5 transition-transform group-hover:translate-y-0.5" />
            <span className="hidden xs:inline">Get App</span>
            <span className="xs:hidden">App</span>
          </a>
        </div>
      </div>
    </header>
  );
}
