'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  X,
  Sparkles,
  Shield,
  FileText,
  Download,
  ExternalLink,
  MapPin,
  Wand2,
  Film,
  CreditCard,
  Info,
} from 'lucide-react';

interface AboutModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenPricing?: () => void;
}

export function AboutModal({ isOpen, onClose, onOpenPricing }: AboutModalProps) {
  const [freeUses, setFreeUses] = useState(0);

  useEffect(() => {
    try {
      const uses = parseInt(localStorage.getItem('slipeai_free_uses') || '0', 10);
      setFreeUses(isNaN(uses) ? 0 : Math.min(uses, 10));
    } catch {
      // Ignore
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-lg rounded-[32px] border border-slate-200/90 bg-white shadow-2xl p-6 sm:p-8 space-y-6 max-h-[90vh] overflow-y-auto scrollbar-none font-display animate-in zoom-in-95 duration-200"
      >
        {/* Header with Close Button */}
        <div className="flex items-start justify-between pb-2 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl bg-slate-950 text-white flex items-center justify-center font-black text-lg shadow-md">
              S
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-xl font-extrabold text-slate-950 tracking-tight">
                  About SlipeAI
                </h3>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-50 text-blue-800 border border-blue-200">
                  v2.4.0
                </span>
              </div>
              <p className="text-xs text-slate-500 font-semibold flex items-center gap-1 mt-0.5">
                <MapPin className="w-3 h-3 text-slate-400" />
                <span>Pace AI Technologies (OPC) Private Limited • Kerala, India</span>
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-900 hover:bg-slate-100 transition-colors cursor-pointer"
            aria-label="Close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Company & Technology Description */}
        <div className="rounded-2xl border border-slate-200/80 bg-slate-50/80 p-4 space-y-2">
          <div className="flex items-center gap-1.5 text-xs font-bold text-slate-900">
            <Info className="w-4 h-4 text-blue-600" />
            <span>Neural Restoration & Super-Resolution</span>
          </div>
          <p className="text-xs text-slate-600 leading-relaxed font-medium">
            World-class AI photo restoration, super-resolution enhancement, video remastering, and creative assistance. Built with genuine neural texture recovery so your photos and videos never lose their original look.
          </p>
        </div>

        {/* User Account / Plan Details */}
        <div className="rounded-2xl border border-slate-200/80 bg-[#F8FAFC] p-4 flex items-center justify-between gap-3 shadow-2xs">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-full bg-emerald-600 text-white font-black text-sm flex items-center justify-center shadow-xs shrink-0">
              S
            </div>
            <div className="min-w-0">
              <p className="text-sm font-bold text-slate-950 truncate">
                Sreerag Jotish
              </p>
              <p className="text-xs text-slate-500 font-medium">
                Free Plan &bull; {freeUses} out of 10 free uses used
              </p>
            </div>
          </div>

          {onOpenPricing && (
            <button
              type="button"
              onClick={() => {
                onClose();
                onOpenPricing();
              }}
              className="px-3.5 py-1.5 rounded-xl bg-slate-950 text-white font-bold text-xs uppercase tracking-wider hover:bg-slate-800 transition-all shadow-sm active:scale-95 shrink-0"
            >
              Upgrade
            </button>
          )}
        </div>

        {/* Features & Links */}
        <div className="space-y-3 pt-1">
          <h4 className="text-xs font-black uppercase tracking-wider text-slate-500">
            Quick Navigation & Features
          </h4>
          <div className="grid grid-cols-2 gap-2 text-xs font-bold">
            <Link
              href="/#enhancer"
              onClick={onClose}
              className="flex items-center gap-2 p-2.5 rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50 text-slate-800 transition-colors"
            >
              <Wand2 className="w-4 h-4 text-blue-600" />
              <span>Enhance Photos</span>
            </Link>

            <Link
              href="/#video"
              onClick={onClose}
              className="flex items-center gap-2 p-2.5 rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50 text-slate-800 transition-colors"
            >
              <Film className="w-4 h-4 text-blue-600" />
              <span>Remaster Videos</span>
            </Link>

            <Link
              href="/#create"
              onClick={onClose}
              className="flex items-center gap-2 p-2.5 rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50 text-slate-800 transition-colors"
            >
              <Sparkles className="w-4 h-4 text-blue-600" />
              <span>AI Image Creation</span>
            </Link>

            <Link
              href="/pricing"
              onClick={onClose}
              className="flex items-center gap-2 p-2.5 rounded-xl border border-slate-200 hover:border-slate-300 hover:bg-slate-50 text-slate-800 transition-colors"
            >
              <CreditCard className="w-4 h-4 text-blue-600" />
              <span>Pricing Plans</span>
            </Link>
          </div>
        </div>

        {/* Legal & Mobile Store Links */}
        <div className="space-y-2 pt-1 border-t border-slate-100">
          <h4 className="text-xs font-black uppercase tracking-wider text-slate-500 pt-2">
            Legal & Mobile Store
          </h4>
          <div className="flex flex-col gap-1 text-xs font-semibold text-slate-700">
            <Link
              href="/privacy"
              onClick={onClose}
              className="flex items-center justify-between p-2 rounded-xl hover:bg-slate-100 transition-colors"
            >
              <span className="flex items-center gap-2">
                <Shield className="w-3.5 h-3.5 text-slate-500" />
                <span>Privacy Policy</span>
              </span>
              <span className="text-[11px] text-slate-400">View</span>
            </Link>

            <Link
              href="/terms"
              onClick={onClose}
              className="flex items-center justify-between p-2 rounded-xl hover:bg-slate-100 transition-colors"
            >
              <span className="flex items-center gap-2">
                <FileText className="w-3.5 h-3.5 text-slate-500" />
                <span>Terms & Conditions</span>
              </span>
              <span className="text-[11px] text-slate-400">View</span>
            </Link>

            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-between p-2 rounded-xl hover:bg-slate-100 transition-colors"
            >
              <span className="flex items-center gap-2">
                <Download className="w-3.5 h-3.5 text-slate-500" />
                <span>Google Play Store App</span>
              </span>
              <ExternalLink className="w-3.5 h-3.5 text-slate-400" />
            </a>
          </div>
        </div>

        {/* Modal Bottom Copyright */}
        <div className="pt-3 border-t border-slate-100 text-center">
          <p className="text-[11px] text-slate-500 font-medium">
            &copy; {new Date().getFullYear()} Pace AI Technologies (OPC) Private Limited. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  );
}
