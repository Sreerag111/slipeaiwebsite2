'use client';

import React from 'react';
import Link from 'next/link';
import { ExternalLink } from 'lucide-react';

export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white pt-12 sm:pt-16 pb-8 sm:pb-12 text-slate-600">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-8 sm:gap-10 pb-8 sm:pb-12 border-b border-slate-100">
          {/* Col 1: Brand */}
          <div className="space-y-3 sm:space-y-4 sm:col-span-2">
            <Link href="/" className="inline-block">
              <span className="text-2xl font-black tracking-tight text-slate-950">
                SlipeAI
              </span>
            </Link>
            <p className="text-xs text-slate-600 max-w-sm leading-relaxed font-medium">
              World-class AI photo restoration, super-resolution enhancement, video remastering, and creative assistance. Built with genuine neural texture recovery so your photos never lose their original look.
            </p>
            <div className="pt-1">
              <span className="text-[11px] text-slate-400 font-semibold">
                Pace AI Technologies (OPC) Private Limited • Kerala, India
              </span>
            </div>
          </div>

          {/* Col 2: Product */}
          <div className="space-y-2.5 sm:space-y-3">
            <h4 className="text-xs font-black uppercase tracking-wider text-slate-900">Features</h4>
            <ul className="space-y-2 text-xs font-semibold">
              <li>
                <a href="#enhancer" className="hover:text-slate-950 transition-colors">
                  Enhance Photos
                </a>
              </li>
              <li>
                <a href="#video" className="hover:text-slate-950 transition-colors">
                  Remaster Videos
                </a>
              </li>
              <li>
                <a href="#create" className="hover:text-slate-950 transition-colors">
                  AI Image Creation
                </a>
              </li>
              <li>
                <Link href="/pricing" className="hover:text-slate-950 transition-colors">
                  Pricing Plans (Lite & Pro)
                </Link>
              </li>
            </ul>
          </div>

          {/* Col 3: Legal & Store */}
          <div className="space-y-2.5 sm:space-y-3">
            <h4 className="text-xs font-black uppercase tracking-wider text-slate-900">Legal & Mobile</h4>
            <ul className="space-y-2 text-xs font-semibold">
              <li>
                <Link href="/privacy" className="hover:text-slate-950 transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="hover:text-slate-950 transition-colors">
                  Terms & Conditions
                </Link>
              </li>
              <li>
                <a
                  href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 text-slate-700 hover:text-slate-950 transition-colors"
                >
                  <span>Google Play Store</span>
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-6 sm:pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-3 sm:gap-4 text-center sm:text-left">
          <p className="font-semibold">© {new Date().getFullYear()} Pace AI Technologies (OPC) Private Limited. All rights reserved.</p>
          <div className="flex items-center gap-3 sm:gap-4 text-[11px] font-semibold">
            <span>Payments powered by Razorpay</span>
            <span>•</span>
            <span>256-bit SSL Encryption</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
