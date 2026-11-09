'use client';

import React from 'react';
import { Download, PanelLeft } from 'lucide-react';

interface NavbarProps {
  onOpenPricing?: () => void;
  activeTab?: string;
  setActiveTab?: (tab: string) => void;
  onToggleSidebar?: () => void;
  isSidebarOpen?: boolean;
}

export function Navbar({
  onOpenPricing,
  onToggleSidebar,
}: NavbarProps) {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/85 backdrop-blur-md transition-colors font-display">
      <div className="mx-auto flex h-16 sm:h-18 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-3">
          {/* Sidebar Toggle Button */}
          {onToggleSidebar && (
            <button
              type="button"
              onClick={onToggleSidebar}
              className="p-2 rounded-xl text-slate-600 hover:text-slate-950 hover:bg-slate-100 transition-colors focus:outline-none cursor-pointer"
              aria-label="Toggle Sidebar"
              title="Toggle Sidebar"
            >
              <PanelLeft className="w-5 h-5 text-slate-800" />
            </button>
          )}
        </div>

        {/* Right Actions: Upgrade Pro & Get App */}
        <div className="flex items-center gap-2 sm:gap-3">
          <button
            type="button"
            onClick={onOpenPricing}
            className="text-xs sm:text-sm font-bold px-3.5 sm:px-4 py-2 rounded-xl border border-slate-200 bg-white text-slate-900 hover:bg-slate-50 hover:border-slate-300 transition-all shadow-sm active:scale-95 cursor-pointer"
          >
            Upgrade Pro
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
