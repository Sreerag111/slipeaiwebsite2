'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Menu, X, Sparkles, Download, ArrowUpRight } from 'lucide-react';

interface NavbarProps {
  onOpenPricing?: () => void;
  activeTab?: string;
  setActiveTab?: (tab: string) => void;
}

export function Navbar({ onOpenPricing, activeTab, setActiveTab }: NavbarProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const navItems = [
    { id: 'enhancer', label: 'Photo Enhancer' },
    { id: 'video', label: 'Video Remaster' },
    { id: 'chat', label: 'Slipe AI Chat' },
    { id: 'showcase', label: 'Showcase' },
  ];

  return (
    <header className="sticky top-0 z-40 w-full border-b border-neutral-900 bg-black/85 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg border border-white/20 bg-neutral-950 text-white shadow-sm transition-transform duration-200 group-hover:scale-105">
            <Sparkles className="h-4 w-4 text-white" />
          </div>
          <div className="flex flex-col">
            <span className="text-lg font-black tracking-tight text-white">
              Slipe<span className="text-neutral-400 font-light">AI</span>
            </span>
            <span className="text-[10px] tracking-wider uppercase text-neutral-500 font-medium">
              Web & Mobile Suite
            </span>
          </div>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden md:flex items-center gap-1 bg-neutral-950/80 p-1 rounded-full border border-neutral-800">
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
                  ? 'bg-white text-black shadow-sm'
                  : 'text-neutral-400 hover:text-white hover:bg-neutral-900'
              }`}
            >
              {item.label}
            </button>
          ))}
          <button
            onClick={onOpenPricing}
            className="px-4 py-1.5 rounded-full text-xs font-semibold text-neutral-300 hover:text-white hover:bg-neutral-900 transition-colors"
          >
            Pricing
          </button>
        </nav>

        {/* Right Actions */}
        <div className="hidden sm:flex items-center gap-3">
          <button
            onClick={onOpenPricing}
            className="text-xs font-bold px-3.5 py-2 rounded-lg border border-neutral-800 bg-neutral-950 text-white hover:border-neutral-600 transition-all halo-shadow-sm"
          >
            Upgrade Pro
          </button>
          <a
            href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-xs font-bold px-3.5 py-2 rounded-lg bg-white text-black hover:bg-neutral-200 transition-all shadow-md group"
          >
            <Download className="h-3.5 w-3.5 transition-transform group-hover:translate-y-0.5" />
            <span>Get App</span>
          </a>
        </div>

        {/* Mobile menu toggle */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden p-2 text-neutral-400 hover:text-white"
          aria-label="Toggle Menu"
        >
          {mobileMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6 text-white" />}
        </button>
      </div>

      {/* Mobile Menu Dropdown */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-neutral-900 bg-black/95 px-4 pt-2 pb-6 space-y-3">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => {
                if (setActiveTab) setActiveTab(item.id);
                setMobileMenuOpen(false);
                const el = document.getElementById(item.id);
                if (el) el.scrollIntoView({ behavior: 'smooth' });
              }}
              className="block w-full text-left py-2 text-sm font-medium text-neutral-300 hover:text-white"
            >
              {item.label}
            </button>
          ))}
          <button
            onClick={() => {
              setMobileMenuOpen(false);
              if (onOpenPricing) onOpenPricing();
            }}
            className="block w-full text-left py-2 text-sm font-medium text-neutral-300 hover:text-white"
          >
            Pricing & Plans
          </button>
          <div className="pt-3 border-t border-neutral-900 flex flex-col gap-2">
            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2 w-full py-2.5 rounded-lg bg-white text-black font-bold text-xs"
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
