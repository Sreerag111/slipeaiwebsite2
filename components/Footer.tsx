'use client';

import React from 'react';

export function Footer() {
  return (
    <footer className="border-t border-slate-200/80 bg-white py-4 text-slate-500 font-display text-xs">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-2 text-center sm:text-left">
        <p className="font-semibold text-slate-500">
          &copy; {new Date().getFullYear()} Pace AI Technologies (OPC) Private Limited. All rights reserved.
        </p>
        <div className="flex items-center gap-3 text-[11px] font-semibold text-slate-400">
          <span>Razorpay Verified</span>
          <span>&bull;</span>
          <span>256-bit SSL</span>
        </div>
      </div>
    </footer>
  );
}
