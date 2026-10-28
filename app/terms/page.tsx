'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Footer } from '@/components/Footer';

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      <header className="border-b border-neutral-900 bg-black/80 backdrop-blur-md sticky top-0 z-40">
        <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-4 sm:px-6">
          <Link href="/" className="flex items-center gap-2 text-xs font-bold text-neutral-300 hover:text-white">
            <ArrowLeft className="h-4 w-4" />
            <span>Back to Slipe AI</span>
          </Link>
          <span className="text-xs font-black uppercase tracking-wider text-neutral-400">
            Terms & Conditions
          </span>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-4 sm:px-6 py-12 space-y-8">
        <div className="space-y-3 pb-6 border-b border-neutral-900">
          <span className="inline-block text-[11px] font-bold text-neutral-500 uppercase tracking-wider">
            Last Updated: October 2026
          </span>
          <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
            Terms & Conditions
          </h1>
          <p className="text-sm text-neutral-400">
            Please read these terms carefully before using Slipe AI website and mobile services operated by Pace AI Technologies (OPC) Private Limited.
          </p>
        </div>

        <section className="space-y-4 text-xs sm:text-sm text-neutral-300 leading-relaxed">
          <h2 className="text-lg font-black text-white">1. Agreement to Terms</h2>
          <p>
            By accessing or using Slipe AI, you agree to be bound by these Terms and Conditions. If you disagree with any part of the terms, you must discontinue using our services immediately.
          </p>

          <h2 className="text-lg font-black text-white">2. Acceptable Use</h2>
          <p>
            You agree not to upload, process, or distribute any media containing unlawful, obscene, defamatory, violent, or non-consensual imagery. You retain all copyright and ownership of the images you submit for processing.
          </p>

          <h2 className="text-lg font-black text-white">3. Subscriptions & Billing</h2>
          <p>
            Subscriptions (Lite and Pro tiers) are billed on a recurring or fixed period (Weekly, Monthly, Yearly) as selected at checkout. Payments are processed securely via Razorpay. You may cancel your subscription at any time prior to the next renewal period.
          </p>

          <h2 className="text-lg font-black text-white">4. Limitation of Liability</h2>
          <p>
            Slipe AI and Pace AI Technologies (OPC) Private Limited provide all neural processing and creative tools &quot;as is&quot; without warranties of any kind, whether express or implied.
          </p>

          <h2 className="text-lg font-black text-white">5. Governing Law</h2>
          <p>
            These Terms shall be governed and construed in accordance with the laws of the Republic of India. Any disputes arising out of these terms shall be subject to the exclusive jurisdiction of the competent courts in Kerala, India.
          </p>
        </section>
      </main>

      <Footer />
    </div>
  );
}
