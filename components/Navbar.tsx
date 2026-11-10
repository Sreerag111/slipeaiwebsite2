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
    <header className="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/85 backdrop-blur-md transition-colors font-display">
      <div className="mx-auto flex h-16 sm:h-18 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-3">
          {/* Left spacer / branding placeholder */}
        </div>

        {/* Right Actions: Upgrade Now & Get App */}
        <div className="flex items-center gap-2 sm:gap-3">
          <button
            type="button"
            onClick={onOpenPricing}
            className="text-xs sm:text-sm font-bold px-3.5 sm:px-4 py-2 rounded-xl border border-slate-200 bg-white text-slate-900 hover:bg-slate-50 hover:border-slate-300 transition-all shadow-sm active:scale-95 cursor-pointer"
          >
            Upgrade Now
          </button>

          <a
            href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-xs sm:text-sm font-bold px-3.5 sm:px-4 py-2 rounded-xl bg-slate-950 text-white hover:bg-slate-800 transition-all shadow-md group active:scale-95"
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
