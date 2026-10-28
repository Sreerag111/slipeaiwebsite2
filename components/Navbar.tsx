'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Menu, X, Download } from 'lucide-react';

interface NavbarProps {
  onOpenPricing?: () => void;
  activeTab?: string;
  setActiveTab?: (tab: string) => void;
}

export function Navbar({ onOpenPricing, activeTab, setActiveTab }: NavbarProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navItems = [
    { id: 'enhancer', label: 'Enhance Photos' },
    { id: 'video', label: 'Remaster Videos' },
    { id: 'create', label: 'AI Image Creation' },
  ];

  return (
    <header className="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/85 backdrop-blur-md transition-colors">
      <div className="mx-auto flex h-16 sm:h-18 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Top left SlipeAI with AI bold like Slipe, without Web & Mobile Suite */}
        <Link href="/" className="flex items-center group py-1">
          <span className="text-2xl sm:text-3xl font-black tracking-tight text-slate-950 group-hover:text-slate-700 transition-colors">
            SlipeAI
          </span>
        </Link>

        {/* Desktop / Tablet Nav */}
        <nav className="hidden md:flex items-center gap-1 bg-slate-100/80 p-1 rounded-full border border-slate-200/80 shadow-inner">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => {
                if (setActiveTab) setActiveTab(item.id);
                const el = document.getElementById(item.id);
                if (el) el.scrollIntoView({ behavior: 'smooth' });
              }}
              className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${
                activeTab === item.id
                  ? 'bg-white text-slate-900 shadow-sm'
                  : 'text-slate-600 hover:text-slate-950 hover:bg-white/60'
              }`}
            >
              {item.label}
            </button>
          ))}
          <Link
            href="/pricing"
            className="px-4 py-1.5 rounded-full text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-white/60 transition-colors"
          >
            Pricing
          </Link>
        </nav>

        {/* Right Actions */}
        <div className="hidden sm:flex items-center gap-2.5 sm:gap-3">
          <button
            onClick={onOpenPricing}
            className="text-xs font-bold px-3.5 py-2 rounded-lg border border-slate-200 bg-white text-slate-900 hover:bg-slate-50 hover:border-slate-300 transition-all shadow-sm container-shade-sm active:scale-95"
          >
            Upgrade Pro
          </button>
          <a
            href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-xs font-bold px-3.5 py-2 rounded-lg bg-slate-950 text-white hover:bg-slate-800 transition-all shadow-md group active:scale-95"
          >
            <Download className="h-3.5 w-3.5 transition-transform group-hover:translate-y-0.5" />
            <span>Get App</span>
          </a>
        </div>

        {/* Mobile menu toggle */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden p-2 text-slate-600 hover:text-slate-950 transition-colors focus:outline-none"
          aria-label="Toggle Menu"
        >
          {mobileMenuOpen ? <X className="h-6 w-6 text-slate-900" /> : <Menu className="h-6 w-6 text-slate-900" />}
        </button>
      </div>

      {/* Mobile Menu Dropdown */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-slate-200 bg-white/98 px-4 pt-3 pb-6 space-y-3 shadow-xl animate-in fade-in duration-200">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => {
                if (setActiveTab) setActiveTab(item.id);
                setMobileMenuOpen(false);
                const el = document.getElementById(item.id);
                if (el) el.scrollIntoView({ behavior: 'smooth' });
              }}
              className="block w-full text-left py-2.5 px-3 rounded-lg text-sm font-semibold text-slate-700 hover:text-slate-950 hover:bg-slate-100 transition-colors"
            >
              {item.label}
            </button>
          ))}
          <Link
            href="/pricing"
            onClick={() => setMobileMenuOpen(false)}
            className="block w-full text-left py-2.5 px-3 rounded-lg text-sm font-semibold text-slate-700 hover:text-slate-950 hover:bg-slate-100 transition-colors"
          >
            Pricing & Plans
          </Link>
          <div className="pt-3 border-t border-slate-200 flex flex-col gap-2.5">
            <button
              onClick={() => {
                setMobileMenuOpen(false);
                if (onOpenPricing) onOpenPricing();
              }}
              className="w-full py-2.5 rounded-lg border border-slate-200 bg-white text-slate-900 font-bold text-xs hover:bg-slate-50 transition-colors shadow-sm"
            >
              Upgrade Pro
            </button>
            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 w-full py-2.5 rounded-lg bg-slate-950 text-white font-bold text-xs hover:bg-slate-800 transition-colors shadow-md"
            >
              <Download className="h-4 w-4" />
              Download Android App
            </a>
          </div>
        </div>
      )}
    </header>
  );
}
