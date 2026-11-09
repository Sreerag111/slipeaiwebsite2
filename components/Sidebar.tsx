'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Wand2,
  Film,
  Sparkles,
  Plus,
  Shield,
  Download,
  CreditCard,
  ChevronUp,
  Search,
  PanelLeftClose,
} from 'lucide-react';
import { AboutModal } from '@/components/AboutModal';

interface SidebarProps {
  isOpen: boolean;
  isCollapsed?: boolean;
  onClose: () => void;
  onToggleCollapse?: () => void;
  onOpenPricing: () => void;
  activeItem?: 'create' | 'enhance' | 'video' | string;
  onSelectSection?: (sectionId: string) => void;
}

export function Sidebar({
  isOpen,
  isCollapsed = false,
  onClose,
  onToggleCollapse,
  onOpenPricing,
  activeItem = 'create',
  onSelectSection,
}: SidebarProps) {
  const [freeUses, setFreeUses] = useState(0);
  const [isAboutOpen, setIsAboutOpen] = useState(false);

  useEffect(() => {
    try {
      const uses = parseInt(localStorage.getItem('slipeai_free_uses') || '0', 10);
      setFreeUses(isNaN(uses) ? 0 : Math.min(uses, 10));
    } catch {
      // Ignore
    }
  }, []);

  const handleNavClick = (sectionId: string) => {
    onClose();
    if (onSelectSection) {
      onSelectSection(sectionId);
    } else {
      if (sectionId === 'create') {
        window.location.href = '/';
      } else {
        window.location.href = `/?tab=${sectionId}`;
      }
    }
  };

  const navItems = [
    {
      id: 'create',
      label: 'AI Image Creation',
      icon: Sparkles,
      isCurrent: activeItem === 'create',
      action: () => handleNavClick('create'),
    },
    {
      id: 'enhance',
      label: 'Enhance Photos',
      icon: Wand2,
      isCurrent: activeItem === 'enhance' || activeItem === 'enhancer',
      action: () => handleNavClick('enhance'),
    },
    {
      id: 'video',
      label: 'Remaster Videos',
      icon: Film,
      isCurrent: activeItem === 'video',
      action: () => handleNavClick('video'),
    },
  ];

  return (
    <>
      {/* Mobile Backdrop Overlay */}
      {isOpen && (
        <div
          onClick={onClose}
          className="fixed inset-0 z-40 bg-slate-950/40 backdrop-blur-xs lg:hidden transition-opacity"
          aria-hidden="true"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 w-64 xl:w-72 bg-white/98 backdrop-blur-md border-r border-slate-200/90 flex flex-col justify-between transition-transform duration-300 ease-in-out ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        } ${isCollapsed ? 'lg:-translate-x-full' : 'lg:translate-x-0'}`}
      >
        {/* Top Area: Brand, Header icons & New Creation Button */}
        <div className="p-4 sm:p-5 space-y-4">
          <div className="flex items-center justify-between pb-1">
            <button
              type="button"
              onClick={() => handleNavClick('create')}
              className="flex items-center gap-2 group text-left cursor-pointer"
            >
              <span className="text-2xl font-black tracking-tight text-slate-950 group-hover:text-slate-700 transition-colors">
                SlipeAI
              </span>
            </button>

            {/* Header Tool Icons (matching chat.v2.aifiesta.ai) */}
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => {
                  handleNavClick('create');
                  setTimeout(() => {
                    const input = document.querySelector<HTMLInputElement>('input[type="text"]');
                    input?.focus();
                  }, 100);
                }}
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
                title="Search / Prompt"
                aria-label="Search or Prompt"
              >
                <Search className="w-4 h-4" />
              </button>

              <button
                type="button"
                onClick={() => {
                  if (onToggleCollapse) {
                    onToggleCollapse();
                  } else {
                    onClose();
                  }
                }}
                className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors"
                title="Close / Collapse Sidebar"
                aria-label="Toggle Sidebar"
              >
                <PanelLeftClose className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* New Creation Action Button */}
          <button
            type="button"
            onClick={() => {
              handleNavClick('create');
              setTimeout(() => {
                const input = document.querySelector<HTMLInputElement>('input[type="text"]');
                if (input) {
                  input.value = '';
                  input.focus();
                }
              }, 100);
            }}
            className="w-full flex items-center gap-2.5 px-3.5 py-2.5 rounded-2xl bg-slate-100/90 hover:bg-slate-200/80 text-slate-950 font-extrabold text-xs sm:text-sm transition-all shadow-xs group font-display text-left cursor-pointer"
          >
            <div className="w-6 h-6 rounded-lg bg-white flex items-center justify-center text-slate-900 shadow-2xs group-hover:scale-105 transition-transform shrink-0">
              <Plus className="w-3.5 h-3.5" />
            </div>
            <span>New Creation</span>
          </button>

          {/* Main Navigation Links: Enhance Photos, Remaster Videos, AI Image Creation */}
          <nav className="space-y-1.5 pt-1 font-display">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={item.action}
                  className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs sm:text-[13px] font-bold transition-all text-left cursor-pointer ${
                    item.isCurrent
                      ? 'bg-slate-950 text-white shadow-sm'
                      : 'text-slate-600 hover:text-slate-950 hover:bg-slate-100/80'
                  }`}
                >
                  <Icon className={`w-4 h-4 shrink-0 ${item.isCurrent ? 'text-white' : 'text-slate-500'}`} />
                  <span className="truncate">{item.label}</span>
                </button>
              );
            })}
          </nav>

          {/* Secondary Quick Links */}
          <div className="pt-2 border-t border-slate-100 space-y-1 font-display">
            <button
              type="button"
              onClick={() => {
                onClose();
                onOpenPricing();
              }}
              className="w-full flex items-center gap-3 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-slate-100/80 transition-colors text-left cursor-pointer"
            >
              <CreditCard className="w-4 h-4 text-slate-400" />
              <span>Web Pricing Plans</span>
            </button>

            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full flex items-center gap-3 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-slate-100/80 transition-colors"
            >
              <Download className="w-4 h-4 text-slate-400" />
              <span>Download Android App</span>
            </a>
          </div>
        </div>

        {/* Bottom Area: Plan Card & Profile (With About Section on Arrow Click) */}
        <div className="p-4 sm:p-5 space-y-3 border-t border-slate-100 font-display">
          {/* Plan Status Card */}
          <div className="rounded-2xl border border-slate-200/90 bg-[#F8FAFC] p-3.5 shadow-2xs space-y-2.5">
            <div className="flex items-center gap-2">
              <Shield className="w-4 h-4 text-slate-700" />
              <span className="text-xs font-bold text-slate-950">Free Plan</span>
            </div>

            <p className="text-[11px] text-slate-500 font-medium leading-tight">
              {freeUses} out of 10 free uses used
            </p>

            <button
              type="button"
              onClick={() => {
                onClose();
                onOpenPricing();
              }}
              className="w-full flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl bg-slate-950 text-white font-black text-xs uppercase tracking-wider hover:bg-slate-800 transition-all shadow-sm active:scale-95 cursor-pointer"
            >
              <Sparkles className="w-3.5 h-3.5" />
              <span>Upgrade Now</span>
            </button>
          </div>

          {/* User Profile Pill Row: Opens the About section when Sreerag Jotish / arrow is clicked */}
          <button
            type="button"
            onClick={() => setIsAboutOpen(true)}
            className="w-full flex items-center justify-between p-2 rounded-2xl hover:bg-slate-100/80 transition-colors cursor-pointer group text-left"
            title="About SlipeAI & Account Details"
            aria-label="About SlipeAI and Account Details"
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-full bg-emerald-600 text-white font-black text-xs flex items-center justify-center shadow-xs shrink-0">
                S
              </div>
              <div className="min-w-0">
                <p className="text-xs font-bold text-slate-950 truncate group-hover:text-blue-700 transition-colors">
                  Sreerag Jotish
                </p>
                <p className="text-[10px] font-medium text-slate-500">Free</p>
              </div>
            </div>

            <ChevronUp className="w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors shrink-0" />
          </button>
        </div>
      </aside>

      {/* About Section Modal */}
      <AboutModal
        isOpen={isAboutOpen}
        onClose={() => setIsAboutOpen(false)}
        onOpenPricing={onOpenPricing}
      />
    </>
  );
}
