'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowLeft,
  Check,
  Video,
  ShieldCheck,
  ChevronDown,
  Crown,
  Download,
} from 'lucide-react';
import { Footer } from '@/components/Footer';

type BillingCycle = 'yearly' | 'monthly' | 'weekly';

export default function PricingPage() {
  const [billingCycle, setBillingCycle] = useState<BillingCycle>('yearly');
  const [loadingPayment, setLoadingPayment] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const handleCheckout = (
    planId: string,
    amountPaise: number,
    title: string,
    tierName: string
  ) => {
    setLoadingPayment(true);

    if (typeof window !== 'undefined' && (window as any).Razorpay) {
      const options = {
        key: 'rzp_live_TsvRRjJbFwaKbD',
        amount: amountPaise,
        currency: 'INR',
        name: 'Pace AI Technologies (OPC) Private Limited',
        description: `Slipe AI ${tierName} - ${title}`,
        image: '/assets/logo/logo.png',
        handler: function (response: any) {
          alert(`Payment successful! Payment ID: ${response.razorpay_payment_id}`);
          setLoadingPayment(false);
        },
        prefill: {
          name: '',
          email: '',
          contact: '',
        },
        theme: {
          color: '#0F172A',
        },
        modal: {
          ondismiss: function () {
            setLoadingPayment(false);
          },
        },
      };

      try {
        const rzp = new (window as any).Razorpay(options);
        rzp.open();
      } catch (e) {
        console.error(e);
        setLoadingPayment(false);
        alert('Could not initialize Razorpay checkout. Please verify connection.');
      }
    } else {
      setLoadingPayment(false);
      alert('Razorpay gateway is initializing. Please try again.');
    }
  };

  // Pricing configuration based on billingCycle
  const getLitePrice = () => {
    if (billingCycle === 'yearly') {
      return {
        price: '₹899',
        period: '/ year',
        subtext: 'Billed annually (~₹75/mo) • Save 75%',
        amountPaise: 89900,
        id: 'lite_yearly',
        title: 'Yearly Plan',
      };
    }
    if (billingCycle === 'weekly') {
      return {
        price: '₹49',
        period: '/ week',
        subtext: 'Billed weekly • Instant access',
        amountPaise: 4900,
        id: 'lite_weekly',
        title: 'Weekly Pass',
      };
    }
    return {
      price: '₹99',
      period: '/ month',
      subtext: 'Billed monthly • Cancel anytime',
      amountPaise: 9900,
      id: 'lite_monthly',
      title: 'Monthly Plan',
    };
  };

  const getProPrice = () => {
    if (billingCycle === 'yearly') {
      return {
        price: '₹1,799',
        period: '/ year',
        subtext: 'Billed annually (~₹149/mo) • Save 75%',
        amountPaise: 179900,
        id: 'pro_yearly',
        title: 'Yearly Plan',
      };
    }
    // Pro only available in Monthly & Yearly (no weekly)
    return {
      price: '₹599',
      period: '/ month',
      subtext: 'Billed monthly • Cancel anytime',
      amountPaise: 59900,
      id: 'pro_monthly',
      title: 'Monthly Plan',
    };
  };

  const litePrice = getLitePrice();
  const proPrice = getProPrice();

  const faqs = [
    {
      q: 'What is the main difference between Slipe AI Lite and Pro?',
      a: 'Slipe AI Lite is dedicated to unlimited, high-resolution photo restoration, colorization, and facial refinement. Slipe AI Pro includes everything in Lite plus the entire AI Video Remastering suite (60fps optical flow frame interpolation, 4K video upscaling, motion deblur, HDR cinema color mapping, video denoise, and video colorization) powered by high-priority dedicated GPU cloud nodes.',
    },
    {
      q: 'How does payment and subscription work?',
      a: 'All transactions are 100% secure and processed by Razorpay. We support UPI (Google Pay, PhonePe, Paytm), Visa, MasterCard, RuPay debit/credit cards, and Net Banking. You receive instant access immediately after payment.',
    },
    {
      q: 'Can I cancel my subscription anytime?',
      a: 'Yes, absolutely. You can cancel your subscription at any time with zero cancellation fees. Your plan remains active until the end of your prepaid period.',
    },
    {
      q: 'Can I use enhanced photos and videos for commercial purposes?',
      a: 'Yes! Both Lite and Pro plans include full commercial rights to all output photos and videos with zero attribution required.',
    },
    {
      q: 'How fast is the processing time?',
      a: 'Photo restoration typically completes in 3 to 8 seconds. Video remastering utilizes high-throughput cloud GPU nodes with instant queue priority for Pro members.',
    },
  ];

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 flex flex-col antialiased">
      {/* Website Sticky Header */}
      <header className="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/85 backdrop-blur-md transition-colors">
        <div className="mx-auto flex h-16 sm:h-18 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/" className="flex items-center group py-1">
            <span className="text-2xl sm:text-3xl font-black tracking-tight text-slate-950 group-hover:text-slate-700 transition-colors">
              SlipeAI
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-1 bg-slate-100/80 p-1 rounded-full border border-slate-200/80 shadow-inner">
            <Link
              href="/#enhancer"
              className="px-4 py-1.5 rounded-full text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-white/60 transition-colors"
            >
              Enhance Photos
            </Link>
            <Link
              href="/#video"
              className="px-4 py-1.5 rounded-full text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-white/60 transition-colors"
            >
              Remaster Videos
            </Link>
            <a
              href="#comparison"
              className="px-4 py-1.5 rounded-full text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-white/60 transition-colors"
            >
              Compare Plans
            </a>
            <a
              href="#faq"
              className="px-4 py-1.5 rounded-full text-xs font-semibold text-slate-600 hover:text-slate-950 hover:bg-white/60 transition-colors"
            >
              FAQ
            </a>
          </nav>

          <div className="flex items-center gap-2.5 sm:gap-3">
            <Link
              href="/"
              className="flex items-center gap-1.5 text-xs font-bold px-3.5 py-2 rounded-xl border border-slate-200 bg-white text-slate-900 hover:bg-slate-50 transition-all shadow-sm container-shade-sm"
            >
              <ArrowLeft className="h-3.5 w-3.5" />
              <span>Back to App</span>
            </Link>
            <a
              href="https://play.google.com/store/apps/details?id=com.paceai.paceai"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:flex items-center gap-2 text-xs font-bold px-3.5 py-2 rounded-xl bg-slate-950 text-white hover:bg-slate-800 transition-all shadow-md group active:scale-95"
            >
              <Download className="h-3.5 w-3.5 transition-transform group-hover:translate-y-0.5" />
              <span>Get Android App</span>
            </a>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        {/* Hero Section */}
        <section className="pt-12 sm:pt-16 md:pt-20 pb-8 sm:pb-12 px-4 sm:px-6 lg:px-8 text-center max-w-4xl mx-auto space-y-4">
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-black text-slate-950 tracking-tight leading-tight">
            Plans Built for Creators, Studios & Pros
          </h1>

          <p className="text-sm sm:text-base md:text-lg text-slate-600 font-semibold max-w-2xl mx-auto">
            Experience state-of-the-art neural restoration. Upgrade anytime, restore unlimited photos, and remaster videos in 4K 60FPS clarity.
          </p>

          {/* Billing Cycle Toggle */}
          <div className="pt-4 sm:pt-6 flex justify-center">
            <div className="inline-flex items-center p-1.5 rounded-2xl bg-white border border-slate-200 container-shade-sm">
              <button
                type="button"
                onClick={() => setBillingCycle('yearly')}
                className={`flex items-center gap-1.5 px-4 sm:px-5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                  billingCycle === 'yearly'
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-slate-600 hover:text-slate-950'
                }`}
              >
                <span>Yearly</span>
                <span
                  className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${
                    billingCycle === 'yearly'
                      ? 'bg-white text-blue-700'
                      : 'bg-emerald-100 text-emerald-800'
                  }`}
                >
                  Save 75%
                </span>
              </button>

              <button
                type="button"
                onClick={() => setBillingCycle('monthly')}
                className={`px-4 sm:px-5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                  billingCycle === 'monthly'
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-slate-600 hover:text-slate-950'
                }`}
              >
                Monthly
              </button>

              <button
                type="button"
                onClick={() => setBillingCycle('weekly')}
                className={`px-4 sm:px-5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all ${
                  billingCycle === 'weekly'
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-slate-600 hover:text-slate-950'
                }`}
              >
                Weekly Pass
              </button>
            </div>
          </div>
        </section>

        {/* 3-Column Pricing Cards Grid */}
        <section className="py-6 sm:py-10 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8 items-stretch">
            {/* TIER 1: Free Starter */}
            <div className="flex flex-col justify-between rounded-3xl border border-slate-200/90 bg-white p-6 sm:p-8 container-shade hover:container-shade-lg transition-all duration-300">
              <div className="space-y-6">
                <div className="space-y-2">
                  <span className="text-xs font-black uppercase tracking-wider text-slate-500">
                    Starter
                  </span>
                  <h3 className="text-2xl font-black text-slate-950">Free</h3>
                </div>

                <div className="pb-4 border-b border-slate-100">
                  <div className="flex items-baseline gap-1">
                    <span className="text-4xl sm:text-5xl font-black text-slate-950">₹0</span>
                  </div>
                  <span className="text-[11px] font-semibold text-slate-400 mt-1 block">
                    No credit card or payment needed
                  </span>
                </div>

                {/* Features list */}
                <ul className="space-y-3 text-xs sm:text-sm font-semibold text-slate-700">
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>2 Free lifetime photo restorations</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Up to 1080p output resolution</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Access to all 10 photo model previews</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>Interactive split-screen comparison viewer</span>
                  </li>
                  <li className="flex items-start gap-2.5 text-slate-400">
                    <Check className="h-4 w-4 text-slate-300 shrink-0 mt-0.5" />
                    <span>Standard cloud inference queue</span>
                  </li>
                  <li className="flex items-start gap-2.5 text-slate-400">
                    <Check className="h-4 w-4 text-slate-300 shrink-0 mt-0.5" />
                    <span>Personal non-commercial use</span>
                  </li>
                </ul>
              </div>

              <div className="pt-8">
                <Link
                  href="/#enhancer"
                  className="w-full flex items-center justify-center py-3.5 rounded-2xl border-2 border-slate-200 bg-slate-50 hover:bg-slate-100 hover:border-slate-300 text-slate-900 font-bold text-sm transition-all"
                >
                  Start Free
                </Link>
              </div>
            </div>

            {/* TIER 2: Slipe AI Lite */}
            <div className="flex flex-col justify-between rounded-3xl border border-slate-200/90 bg-white p-6 sm:p-8 container-shade hover:container-shade-lg transition-all duration-300">
              <div className="space-y-6">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                      Photo Suite
                    </span>
                    <span className="text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full bg-blue-600 text-white shadow-sm">
                      Popular for Photos
                    </span>
                  </div>
                  <h3 className="text-2xl font-black text-slate-950">Slipe AI Lite</h3>
                  <p className="text-xs sm:text-sm text-slate-500 font-semibold leading-relaxed">
                    Unlimited photo restoration, portrait facial clarity, and archival colorization.
                  </p>
                </div>

                <div className="pb-4 border-b border-slate-100">
                  <div className="flex items-baseline gap-1">
                    <span className="text-4xl sm:text-5xl font-black text-slate-950">
                      {litePrice.price}
                    </span>
                    <span className="text-xs font-bold text-slate-500">{litePrice.period}</span>
                  </div>
                  <span className="text-[11px] font-semibold text-blue-600 mt-1 block">
                    {litePrice.subtext}
                  </span>
                </div>

                {/* Features list */}
                <ul className="space-y-2.5 text-xs sm:text-sm font-semibold text-slate-700">
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span className="font-bold text-slate-900">AI Image creation</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>B&W photo to colour</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Upscale Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Enhance Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Remove Background</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Refine Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Brightens Dark Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Unblur Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Sharpen Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Balance Colour</span>
                  </li>
                </ul>
              </div>

              <div className="pt-8">
                <button
                  type="button"
                  onClick={() =>
                    handleCheckout(
                      litePrice.id,
                      litePrice.amountPaise,
                      litePrice.title,
                      'Lite Tier'
                    )
                  }
                  className="w-full flex items-center justify-center py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-sm shadow-md transition-all active:scale-98"
                >
                  Upgrade to Lite ({litePrice.price})
                </button>
              </div>
            </div>

            {/* TIER 3: Slipe AI Pro (Flagship highlighted tier) */}
            <div className="relative flex flex-col justify-between rounded-3xl border-2 border-blue-600 bg-white p-6 sm:p-8 container-shade-xl ring-4 ring-blue-500/15 transition-all duration-300 lg:-translate-y-2">
              {/* Highlight pill */}
              <div className="absolute -top-3.5 left-1/2 -translate-x-1/2">
                <span className="flex items-center gap-1.5 px-4 py-1 rounded-full bg-blue-600 text-white text-[11px] font-black uppercase tracking-wider shadow-md">
                  <Crown className="h-3 w-3" />
                  <span>Most Popular • Complete Suite</span>
                </span>
              </div>

              <div className="space-y-6 pt-2">
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                      Full AI Powerhouse
                    </span>
                    <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
                      Photos + Videos
                    </span>
                  </div>
                  <h3 className="text-2xl font-black text-slate-950">Slipe AI Pro</h3>
                  <p className="text-xs sm:text-sm text-slate-500 font-semibold leading-relaxed">
                    The complete photo suite plus 60FPS 4K video upscaling & frame interpolation.
                  </p>
                </div>

                <div className="pb-4 border-b border-slate-100">
                  <div className="flex items-baseline gap-1">
                    <span className="text-4xl sm:text-5xl font-black text-slate-950">
                      {proPrice.price}
                    </span>
                    <span className="text-xs font-bold text-slate-500">{proPrice.period}</span>
                  </div>
                  <span className="text-[11px] font-semibold text-blue-600 mt-1 block">
                    {billingCycle === 'weekly' ? (
                      <span className="text-amber-800 font-bold bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-md inline-block">
                        Pro only available in Monthly & Yearly
                      </span>
                    ) : (
                      proPrice.subtext
                    )}
                  </span>
                </div>

                {/* Features list */}
                <ul className="space-y-2.5 text-xs sm:text-sm font-semibold text-slate-700">
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span className="font-bold text-slate-900">AI Image creation</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>B&W photo to colour</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Upscale Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Enhance Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Remove Background</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Refine Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Brightens Dark Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Unblur Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Sharpen Photos</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span>Balance Colour</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <span className="font-bold text-blue-950">Full Video enhancement features</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <span className="font-bold text-slate-900">Video Creations</span>
                      <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                        Coming Soon
                      </span>
                    </div>
                  </li>
                </ul>
              </div>

              <div className="pt-8">
                <button
                  type="button"
                  onClick={() =>
                    handleCheckout(
                      proPrice.id,
                      proPrice.amountPaise,
                      proPrice.title,
                      'Pro Tier'
                    )
                  }
                  className="w-full flex items-center justify-center py-4 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-black text-sm uppercase tracking-wider shadow-lg hover:shadow-xl transition-all active:scale-98"
                >
                  {billingCycle === 'weekly'
                    ? 'Get Pro Monthly (₹599)'
                    : `Unlock Slipe AI Pro (${proPrice.price})`}
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* Feature Comparison Matrix Section */}
        <section id="comparison" className="py-12 sm:py-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
          <div className="text-center max-w-3xl mx-auto mb-10 sm:mb-14 space-y-2">
            <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-slate-950 tracking-tight">
              Compare Plan Capabilities
            </h2>
            <p className="text-xs sm:text-sm text-slate-600 font-semibold">
              Detailed breakdown of restoration models, resolution limits, and cloud compute.
            </p>
          </div>

          <div className="overflow-x-auto rounded-3xl border border-slate-200/90 bg-white container-shade-lg">
            <table className="w-full text-left text-xs sm:text-sm">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50/80">
                  <th className="py-4 px-4 sm:px-6 font-black text-slate-900 w-2/5">Features</th>
                  <th className="py-4 px-4 sm:px-6 font-bold text-slate-600 text-center w-1/5">Free</th>
                  <th className="py-4 px-4 sm:px-6 font-bold text-blue-700 text-center w-1/5 bg-blue-50/50">Lite</th>
                  <th className="py-4 px-4 sm:px-6 font-black text-slate-950 text-center w-1/5 bg-blue-50/70">Pro</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-semibold text-slate-700">
                {/* Photo Restoration */}
                <tr className="bg-slate-50/40">
                  <td colSpan={4} className="py-2.5 px-4 sm:px-6 text-[11px] font-black uppercase tracking-wider text-slate-500">
                    Photo Restoration & Clarity
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">Photo Enhancements</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-500">2 Free Uses</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-blue-700 font-bold bg-blue-50/30">Unlimited</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-950 font-black bg-blue-50/50">Unlimited</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">Maximum Export Resolution</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-500">1080p</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-900 bg-blue-50/30">4K Ultra</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-950 font-black bg-blue-50/50">8K Neural</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">All 10 Specialized Photo Models</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center">Preview</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/30">✓ Included</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/50">✓ Included</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">B&W Archival Colorization</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center">✓</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/30">✓ Included</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/50">✓ Included</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">Scratch & Dust Removal</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center">✓</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/30">✓ Included</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-bold bg-blue-50/50">✓ Included</td>
                </tr>

                {/* Video Remastering */}
                <tr className="bg-slate-50/40">
                  <td colSpan={4} className="py-2.5 px-4 sm:px-6 text-[11px] font-black uppercase tracking-wider text-slate-500">
                    Video Remastering Suite
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">AI Video Upscaling (4K/8K)</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">60 FPS / 120 FPS Frame Interpolation</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">Camera Motion Deblur & HDR</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 sm:px-6">Video Colorize & Denoise</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-3.5 px-4 sm:px-6 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        {/* Security & Payment Methods */}
        <section className="py-8 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto">
          <div className="rounded-3xl border border-slate-200/90 bg-white p-6 sm:p-8 container-shade flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-4">
              <div className="flex h-12 w-12 sm:h-14 sm:w-14 items-center justify-center rounded-2xl bg-blue-50 border border-blue-200 text-blue-600 shadow-sm shrink-0">
                <ShieldCheck className="h-6 w-6 sm:h-7 sm:w-7 text-blue-600" />
              </div>
              <div className="space-y-0.5">
                <h4 className="text-sm sm:text-base font-black text-slate-950">
                  Bank-Grade 256-Bit SSL Security
                </h4>
                <p className="text-xs sm:text-sm text-slate-500 font-semibold">
                  Official billing operated by Pace AI Technologies (OPC) Private Limited via Razorpay.
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-center gap-2 text-xs font-bold text-slate-600">
              <span className="px-3 py-1.5 rounded-lg border border-slate-200 bg-slate-50">UPI / GPay / PhonePe</span>
              <span className="px-3 py-1.5 rounded-lg border border-slate-200 bg-slate-50">Credit / Debit Card</span>
              <span className="px-3 py-1.5 rounded-lg border border-slate-200 bg-slate-50">NetBanking</span>
            </div>
          </div>
        </section>

        {/* FAQ Section */}
        <section id="faq" className="py-12 sm:py-16 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
          <div className="text-center mb-10 sm:mb-12 space-y-2">
            <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-slate-950 tracking-tight">
              Frequently Asked Questions
            </h2>
            <p className="text-xs sm:text-sm text-slate-600 font-semibold">
              Everything you need to know about Slipe AI plans and billing.
            </p>
          </div>

          <div className="space-y-3">
            {faqs.map((faq, index) => {
              const isOpen = openFaq === index;
              return (
                <div
                  key={index}
                  className="rounded-2xl border border-slate-200/90 bg-white overflow-hidden container-shade-sm transition-all"
                >
                  <button
                    type="button"
                    onClick={() => setOpenFaq(isOpen ? null : index)}
                    className="w-full flex items-center justify-between p-4 sm:p-5 text-left font-bold text-slate-950 text-xs sm:text-sm hover:text-blue-600 transition-colors"
                  >
                    <span>{faq.q}</span>
                    <ChevronDown
                      className={`h-4 w-4 text-slate-400 shrink-0 transition-transform duration-200 ${
                        isOpen ? 'rotate-180 text-blue-600' : ''
                      }`}
                    />
                  </button>
                  {isOpen && (
                    <div className="px-4 sm:px-5 pb-5 text-xs sm:text-sm font-semibold text-slate-600 leading-relaxed border-t border-slate-100 pt-3">
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </section>
      </main>

      {/* Website Footer */}
      <Footer />
    </div>
  );
}
