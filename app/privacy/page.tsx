'use client';

import React from 'react';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { Footer } from '@/components/Footer';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900">
      <header className="border-b border-slate-200/80 bg-white/80 backdrop-blur-md sticky top-0 z-40">
        <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-4 sm:px-6">
          <Link href="/" className="flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-slate-950 transition-colors">
            <ArrowLeft className="h-4 w-4" />
            <span>Back to Slipe AI</span>
          </Link>
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Privacy Policy
          </span>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-4 sm:px-6 py-10 sm:py-14 space-y-8">
        <div className="bg-white rounded-3xl border border-slate-200/90 container-shade-md p-6 sm:p-10 space-y-6">
          <div className="space-y-2 pb-6 border-b border-slate-100">
            <span className="inline-block text-[11px] font-bold text-slate-400 uppercase tracking-wider">
              Effective Date: October 2026
            </span>
            <h1 className="text-3xl sm:text-4xl font-black text-slate-950 tracking-tight">
              Privacy Policy
            </h1>
            <p className="text-sm text-slate-600">
              Pace AI Technologies (OPC) Private Limited (&quot;Pace AI&quot;, &quot;we&quot;, &quot;us&quot;, or &quot;our&quot;) is committed to protecting your personal information and privacy rights.
            </p>
          </div>

          <section className="space-y-5 text-xs sm:text-sm text-slate-700 leading-relaxed">
            <h2 className="text-base sm:text-lg font-black text-slate-950">1. Scope and Overview</h2>
            <p>
              This Privacy Policy governs the collection, use, disclosure, and handling of information when you use our website, mobile application (&quot;Slipe AI&quot;), services, tools, and platforms. By accessing or using Slipe AI, you consent to the data practices described in this policy.
            </p>

            <h2 className="text-base sm:text-lg font-black text-slate-950">2. Photo and Media Processing</h2>
            <p>
              When you upload photos or videos for AI enhancement, remastering, or colorization, these media files are transmitted securely over 256-bit encrypted channels to our processing infrastructure. We do not sell, rent, or lease your images or biometric information to third parties. Media files are automatically purged from our caching servers after processing.
            </p>

            <h2 className="text-base sm:text-lg font-black text-slate-950">3. Information We Collect</h2>
            <ul className="list-disc pl-5 space-y-2 text-slate-600">
              <li><strong>Account Information:</strong> If you register or purchase a subscription, we store your email address, user ID, and subscription tier.</li>
              <li><strong>Payment Information:</strong> All payment transactions are processed securely by Razorpay. We do not store complete credit card or debit card credentials on our servers.</li>
              <li><strong>Device & Usage Data:</strong> Anonymized diagnostic telemetry, operating system version, browser details, and feature usage timestamps to optimize performance and prevent abuse.</li>
            </ul>

            <h2 className="text-base sm:text-lg font-black text-slate-950">4. Data Security</h2>
            <p>
              We implement industry-standard organizational and technical safeguards, including strict access controls and encrypted storage buckets. While we take comprehensive precautions, no transmission over the internet is completely infallible.
            </p>

            <h2 className="text-base sm:text-lg font-black text-slate-950">5. Grievance Officer & Contact</h2>
            <p>
              For privacy inquiries, data deletion requests, or grievances, please contact:<br />
              <strong className="text-slate-900">Pace AI Technologies (OPC) Private Limited</strong><br />
              Attn: Grievance Officer<br />
              Registered Office: Kerala, India<br />
              Email: <span className="text-slate-900 underline font-semibold">support@paceai.tech</span>
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
