'use client';

import React from 'react';
import Link from 'next/link';
import { Sparkles, Shield, Heart, ExternalLink } from 'lucide-react';

export function Footer() {
  return (
    <footer className="border-t border-neutral-900 bg-black pt-16 pb-12 text-neutral-400">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10 pb-12 border-b border-neutral-900">
          {/* Col 1: Brand */}
          <div className="space-y-4 md:col-span-2">
            <div className="flex items-center gap-2.5">
              <div className="flex h-8 w-8 items-center justify-center rounded border border-white/20 bg-neutral-950 text-white">
                <Sparkles className="h-4 w-4" />
              </div>
              <span className="text-lg font-black tracking-tight text-white">
                Slipe<span className="text-neutral-400 font-light">AI</span>
              </span>
            </div>
            <p className="text-xs text-neutral-400 max-w-sm leading-relaxed">
              World-class AI photo restoration, super-resolution enhancement, video remastering, and creative assistance. Built with genuine neural texture recovery so your photos never lose their original look.
            </p>
            <div className="pt-1">
              <span className="text-[11px] text-neutral-500 font-medium">
                Pace AI Technologies (OPC) Private Limited • Kerala, India
              </span>
            </div>
          </div>

          {/* Col 2: Product */}
          <div className="space-y-3">
            <h4 className="text-xs font-black uppercase tracking-wider text-white">Features</h4>
            <ul className="space-y-2 text-xs">
              <li>
                <a href="#enhancer" className="hover:text-white transition-colors">
                  Photo Enhancer
                </a>
              </li>
              <li>
                <a href="#video" className="hover:text-white transition-colors">
                  Video Remaster
                </a>
              </li>
              <li>
                <a href="#chat" className="hover:text-white transition-colors">
                  Slipe AI Assistant
                </a>
              </li>
              <li>
                <Link href="/pricing" className="hover:text-white transition-colors">
                  Pricing Plans (Lite & Pro)
                </Link>
              </li>
            </ul>
          </div>

          {/* Col 3: Legal & Store */}
          <div className="space-y-3">
            <h4 className="text-xs font-black uppercase tracking-wider text-white">Legal & Mobile</h4>
            <ul className="space-y-2 text-xs">
              <li>
                <Link href="/privacy" className="hover:text-white transition-colors">
                  Privacy Policy
                </Link>
              </li>
              <li>
                <Link href="/terms" className="hover:text-white transition-colors">
                  Terms & Conditions
                </Link>
              </li>
              <li>
                <a
                  href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 text-neutral-300 hover:text-white transition-colors"
                >
                  <span>Google Play Store</span>
                  <ExternalLink className="h-3 w-3" />
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-neutral-500 gap-4">
          <p>© {new Date().getFullYear()} Pace AI Technologies (OPC) Private Limited. All rights reserved.</p>
          <div className="flex items-center gap-4 text-[11px]">
            <span>Payments powered by Razorpay</span>
            <span>•</span>
            <span>256-bit SSL Encryption</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
