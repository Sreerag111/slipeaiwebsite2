'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Wand2,
  Film,
  Sparkles,
  Shield,
  Download,
  ChevronUp,
  Search,
  PanelLeftClose,
  AudioWaveform,
} from 'lucide-react';
import { AboutModal } from '@/components/AboutModal';

interface SidebarProps {
  isOpen: boolean;
  isCollapsed?: boolean;
  onClose: () => void;
  onToggleCollapse?: () => void;
  onExpand?: () => void;
  onOpenPricing: () => void;
  activeItem?: 'create' | 'enhance' | 'video' | 'audio' | string;
  onSelectSection?: (sectionId: string) => void;
}

export function Sidebar({
  isOpen,
  isCollapsed = false,
  onClose,
  onToggleCollapse,
  onExpand,
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

  const handleRailIconClick = (sectionId: string) => {
    if (onExpand) {
      onExpand();
    } else if (onToggleCollapse && isCollapsed) {
      onToggleCollapse();
    }
    handleNavClick(sectionId);
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
    {
      id: 'audio',
      label: 'Enhance Audios',
      suffix: '(Coming Soon)',
      icon: AudioWaveform,
      isCurrent: activeItem === 'audio',
      action: () => handleNavClick('audio'),
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
        className={`fixed top-0 bottom-0 left-0 z-50 bg-white/98 backdrop-blur-md border-r border-slate-200/90 flex flex-col justify-between transition-all duration-300 ease-in-out ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0 ${isCollapsed ? 'w-64 lg:w-16' : 'w-64 xl:w-72'}`}
      >
        {/* Mini Icon Rail - Visible on Desktop when isCollapsed is true */}
        {isCollapsed && (
          <div className="hidden lg:flex flex-col justify-between h-full w-full py-4 px-2 items-center">
            {/* Top Brand Logo & Navigation Stack */}
            <div className="w-full flex flex-col items-center space-y-2.5">
              {/* SlipeAI Brand Logo / Expand Trigger */}
              <button
                type="button"
                onClick={() => {
                  if (onExpand) onExpand();
                  else if (onToggleCollapse) onToggleCollapse();
                }}
                className="w-9 h-9 rounded-xl hover:bg-slate-100 text-slate-900 flex items-center justify-center p-1 transition-all cursor-pointer group relative"
                title="Expand Sidebar (SlipeAI)"
                aria-label="Expand Sidebar"
              >
                <img
                  src="/slipe-logo.png"
                  alt="SlipeAI"
                  className="w-6 h-6 object-contain group-hover:scale-105 transition-transform"
                />
                <span className="pointer-events-none absolute left-full ml-3 hidden group-hover:flex items-center px-2.5 py-1.5 rounded-lg bg-slate-900 text-white text-[11px] font-semibold whitespace-nowrap shadow-xl z-50 border border-slate-700">
                  Expand Sidebar
                </span>
              </button>

              <div className="w-7 h-px bg-slate-200/90 my-0.5" />

              {/* Nav Items Stack */}
              <nav className="w-full flex flex-col items-center space-y-1.5">
                {navItems.map((item) => {
                  const Icon = item.icon;
                  return (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => handleRailIconClick(item.id)}
                      className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all cursor-pointer relative group ${
                        item.isCurrent
                          ? 'bg-slate-950 text-white shadow-sm'
                          : 'text-slate-600 hover:text-slate-950 hover:bg-slate-100'
                      }`}
                      title={`${item.label}${item.suffix ? ' ' + item.suffix : ''}`}
                      aria-label={item.label}
                    >
                      <Icon
                        className={`w-4 h-4 shrink-0 ${
                          item.isCurrent ? 'text-white' : 'text-slate-600 group-hover:text-slate-950'
                        }`}
                      />

                      {/* Floating Tooltip on Hover */}
                      <span className="pointer-events-none absolute left-full ml-3 hidden group-hover:flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-slate-900 text-white text-[11px] font-semibold whitespace-nowrap shadow-xl z-50 border border-slate-700">
                        <span>{item.label}</span>
                        {item.suffix && (
                          <span className="text-[10px] text-emerald-400 font-normal">
                            {item.suffix}
                          </span>
                        )}
                      </span>
                    </button>
                  );
                })}
              </nav>

              <div className="w-7 h-px bg-slate-200/90 my-0.5" />

              {/* Android App Link */}
              <a
                href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                target="_blank"
                rel="noopener noreferrer"
                className="w-9 h-9 rounded-xl flex items-center justify-center text-slate-600 hover:text-slate-950 hover:bg-slate-100 transition-all relative group cursor-pointer"
                title="Download Android App"
                aria-label="Download Android App"
              >
                <Download className="w-4 h-4 text-slate-500 group-hover:text-slate-950" />
                <span className="pointer-events-none absolute left-full ml-3 hidden group-hover:flex items-center px-2.5 py-1.5 rounded-lg bg-slate-900 text-white text-[11px] font-semibold whitespace-nowrap shadow-xl z-50 border border-slate-700">
                  Download Android App
                </span>
              </a>
            </div>

            {/* Bottom: Upgrade Shield + Avatar S */}
            <div className="w-full flex flex-col items-center space-y-2.5 pt-2.5 pb-2 border-t border-slate-200/80 shrink-0">
              {/* Free Plan / Upgrade Shield */}
              <button
                type="button"
                onClick={() => {
                  if (onExpand) onExpand();
                  else if (onToggleCollapse) onToggleCollapse();
                  onOpenPricing();
                }}
                className="w-9 h-9 rounded-xl flex items-center justify-center text-slate-600 hover:text-slate-950 hover:bg-slate-100 transition-all relative group cursor-pointer"
                title="Upgrade Plan"
                aria-label="Upgrade Plan"
              >
                <Shield className="w-4 h-4 text-slate-600 group-hover:text-slate-950" />
                <span className="pointer-events-none absolute left-full ml-3 hidden group-hover:flex flex-col px-2.5 py-1.5 rounded-lg bg-slate-900 text-white text-[11px] whitespace-nowrap shadow-xl z-50 border border-slate-700">
                  <span className="font-bold text-white">Free Plan</span>
                  <span className="text-[10px] text-slate-300">{freeUses}/10 free uses used</span>
                  <span className="text-[10px] text-emerald-400 font-semibold mt-0.5">Click to Upgrade</span>
                </span>
              </button>

              {/* Green circular avatar with S (matching chat.v2.aifiesta.ai style) */}
              <button
                type="button"
                onClick={() => {
                  if (onExpand) onExpand();
                  else if (onToggleCollapse) onToggleCollapse();
                  setIsAboutOpen(true);
                }}
                className="w-8 h-8 rounded-full bg-emerald-600 text-white font-black text-xs flex items-center justify-center shrink-0 shadow-sm cursor-pointer hover:ring-2 hover:ring-emerald-400 hover:ring-offset-2 transition-all relative group"
                title="Sreerag Jotish (Free Plan)"
                aria-label="About & Profile"
              >
                S
                <span className="pointer-events-none absolute left-full ml-3 hidden group-hover:flex flex-col px-2.5 py-1.5 rounded-lg bg-slate-900 text-white text-[11px] whitespace-nowrap shadow-xl z-50 border border-slate-700">
                  <span className="font-bold text-white">Sreerag Jotish</span>
                  <span className="text-[10px] text-slate-300">Free Plan • Click for About</span>
                </span>
              </button>
            </div>
          </div>
        )}

        {/* Full Expanded Sidebar Content */}
        <div className={`h-full w-full flex flex-col justify-between ${isCollapsed ? 'flex lg:hidden' : 'flex'}`}>
          {/* Top Area: Brand, Header icons & New Creation Button */}
          <div className="p-4 sm:p-5 space-y-4">
            <div className="flex items-center justify-between pb-1">
              <button
                type="button"
                onClick={() => handleNavClick('create')}
                className="flex items-center gap-2.5 group text-left cursor-pointer"
              >
                <img
                  src="/slipe-logo.png"
                  alt="SlipeAI"
                  className="w-6 h-6 object-contain"
                />
                <span className="text-xl font-black tracking-tight text-slate-950 group-hover:text-slate-700 transition-colors">
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
                  className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer"
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
                  className="p-1.5 rounded-lg text-slate-500 hover:text-slate-950 hover:bg-slate-100 transition-colors cursor-pointer"
                  title="Close / Collapse Sidebar"
                  aria-label="Toggle Sidebar"
                >
                  <PanelLeftClose className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Main Navigation Links: Enhance Photos, Remaster Videos, Enhance Audios, AI Image Creation */}
            <nav className="space-y-1.5 pt-1 font-display">
              {navItems.map((item) => {
                const Icon = item.icon;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={item.action}
                    className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs sm:text-[13px] font-bold transition-all text-left cursor-pointer ${
                      item.isCurrent
                        ? 'bg-slate-950 text-white shadow-md'
                        : 'text-slate-600 hover:text-slate-950 hover:bg-slate-100/70 font-medium'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <Icon className={`w-4 h-4 shrink-0 ${item.isCurrent ? 'text-white' : 'text-slate-500'}`} />
                      <span className="truncate">
                        {item.label}
                        {item.suffix && (
                          <span
                            className={`ml-1 text-[11px] font-medium tracking-normal ${
                              item.isCurrent ? 'text-white/80' : 'text-slate-400'
                            }`}
                          >
                            {item.suffix}
                          </span>
                        )}
                      </span>
                    </div>
                  </button>
                );
              })}
            </nav>

            {/* Secondary Quick Links */}
            <div className="pt-2 border-t border-slate-100 space-y-1 font-display">
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
                className="w-full flex items-center justify-center py-2 px-3 rounded-xl bg-slate-950 text-white font-black text-xs uppercase tracking-wider hover:bg-slate-800 transition-all shadow-sm active:scale-95 cursor-pointer"
              >
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
