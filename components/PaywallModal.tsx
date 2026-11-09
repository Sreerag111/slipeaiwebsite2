'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  X,
  Check,
  Crown,
  ShieldCheck,
  ChevronDown,
} from 'lucide-react';

interface PaywallModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type BillingCycle = 'yearly' | 'monthly' | 'weekly';

export function PaywallModal({ isOpen, onClose }: PaywallModalProps) {
  const [billingCycle, setBillingCycle] = useState<BillingCycle>('yearly');
  const [loadingPayment, setLoadingPayment] = useState(false);
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  if (!isOpen) return null;

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
          onClose();
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
      alert('Razorpay gateway is initializing. Please try again in a few seconds.');
    }
  };

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
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/70 backdrop-blur-md overflow-y-auto animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-5xl max-h-[92vh] flex flex-col bg-white border border-slate-200/90 rounded-[32px] shadow-2xl text-slate-900 overflow-y-auto my-auto p-5 sm:p-8 md:p-10 space-y-8 font-display animate-in zoom-in-95 duration-200"
      >
        {/* Top bar with close button */}
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 shrink-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-black text-slate-950 tracking-tight">
              SlipeAI Plans & Pricing
            </span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-full bg-slate-100 text-slate-500 hover:text-slate-950 hover:bg-slate-200 transition-colors cursor-pointer"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Header & Billing Cycle Toggle */}
        <div className="text-center max-w-2xl mx-auto space-y-3">
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-black text-slate-950 tracking-tight leading-tight">
            Plans Built for Creators, Studios & Pros
          </h2>
          <p className="text-xs sm:text-sm text-slate-600 font-semibold leading-relaxed">
            Experience state-of-the-art neural restoration. Upgrade anytime, restore unlimited photos, and remaster videos in 4K 60FPS clarity.
          </p>

          {/* Billing Cycle Toggle */}
          <div className="pt-2 flex justify-center">
            <div className="inline-flex items-center p-1 rounded-2xl bg-slate-100 border border-slate-200">
              <button
                type="button"
                onClick={() => setBillingCycle('yearly')}
                className={`flex items-center gap-1.5 px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  billingCycle === 'yearly'
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-slate-600 hover:text-slate-950'
                }`}
              >
                <span>Yearly</span>
                <span
                  className={`text-[9px] font-black uppercase px-1.5 py-0.5 rounded-full ${
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
                className={`px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
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
                className={`px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                  billingCycle === 'weekly'
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'text-slate-600 hover:text-slate-950'
                }`}
              >
                Weekly Pass
              </button>
            </div>
          </div>
        </div>

        {/* 3-Column Pricing Cards Grid: Free Starter, Slipe AI Lite, Slipe AI Pro */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5 sm:gap-6 items-stretch">
          {/* TIER 1: Free Starter */}
          <div className="flex flex-col justify-between rounded-3xl border border-slate-200/90 bg-white p-5 sm:p-7 shadow-xs hover:shadow-md transition-all">
            <div className="space-y-5">
              <div className="space-y-1">
                <span className="text-xs font-black uppercase tracking-wider text-slate-500">
                  Starter
                </span>
                <h3 className="text-xl font-black text-slate-950">Free</h3>
              </div>

              <div className="pb-3 border-b border-slate-100">
                <div className="flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-slate-950">₹0</span>
                </div>
                <span className="text-[11px] font-semibold text-slate-400 mt-0.5 block">
                  No credit card or payment needed
                </span>
              </div>

              <ul className="space-y-2.5 text-xs font-semibold text-slate-700">
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                  <span>2 Free lifetime photo restorations</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                  <span>Up to 1080p output resolution</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                  <span>Access to all 10 photo model previews</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-emerald-600 shrink-0 mt-0.5" />
                  <span>Interactive comparison viewer</span>
                </li>
                <li className="flex items-start gap-2 text-slate-400">
                  <Check className="h-4 w-4 text-slate-300 shrink-0 mt-0.5" />
                  <span>Standard cloud inference queue</span>
                </li>
              </ul>
            </div>

            <div className="pt-6">
              <button
                type="button"
                onClick={onClose}
                className="w-full flex items-center justify-center py-3 rounded-2xl border-2 border-slate-200 bg-slate-50 hover:bg-slate-100 text-slate-900 font-bold text-xs transition-all cursor-pointer"
              >
                Current Plan
              </button>
            </div>
          </div>

          {/* TIER 2: Slipe AI Lite */}
          <div className="flex flex-col justify-between rounded-3xl border border-slate-200/90 bg-white p-5 sm:p-7 shadow-xs hover:shadow-md transition-all">
            <div className="space-y-5">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                    Photo Suite
                  </span>
                  <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-blue-600 text-white shadow-xs">
                    Photos
                  </span>
                </div>
                <h3 className="text-xl font-black text-slate-950">Slipe AI Lite</h3>
                <p className="text-xs text-slate-500 font-semibold leading-relaxed">
                  Unlimited photo restoration, portrait facial clarity, and colorization.
                </p>
              </div>

              <div className="pb-3 border-b border-slate-100">
                <div className="flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-slate-950">
                    {litePrice.price}
                  </span>
                  <span className="text-xs font-bold text-slate-500">{litePrice.period}</span>
                </div>
                <span className="text-[11px] font-semibold text-blue-600 mt-0.5 block">
                  {litePrice.subtext}
                </span>
              </div>

              <ul className="space-y-2 text-xs font-semibold text-slate-700">
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span className="font-bold text-slate-900">AI Image creation</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>B&W photo to colour</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Upscale Photos 4K</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Enhance Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Remove Background</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Unblur & Sharpen</span>
                </li>
              </ul>
            </div>

            <div className="pt-6">
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
                className="w-full flex items-center justify-center py-3 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-md transition-all active:scale-98 cursor-pointer"
              >
                Upgrade to Lite ({litePrice.price})
              </button>
            </div>
          </div>

          {/* TIER 3: Slipe AI Pro */}
          <div className="relative flex flex-col justify-between rounded-3xl border-2 border-blue-600 bg-white p-5 sm:p-7 shadow-xl ring-4 ring-blue-500/15 transition-all">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2">
              <span className="flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-blue-600 text-white text-[10px] font-black uppercase tracking-wider shadow-md whitespace-nowrap">
                <Crown className="h-3 w-3" />
                <span>Complete Suite</span>
              </span>
            </div>

            <div className="space-y-5 pt-1">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                    Full AI Suite
                  </span>
                  <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
                    Photos + Videos
                  </span>
                </div>
                <h3 className="text-xl font-black text-slate-950">Slipe AI Pro</h3>
                <p className="text-xs text-slate-500 font-semibold leading-relaxed">
                  The complete photo suite plus 60FPS 4K video upscaling & frame interpolation.
                </p>
              </div>

              <div className="pb-3 border-b border-slate-100">
                <div className="flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-slate-950">
                    {proPrice.price}
                  </span>
                  <span className="text-xs font-bold text-slate-500">{proPrice.period}</span>
                </div>
                <span className="text-[11px] font-semibold text-blue-600 mt-0.5 block">
                  {billingCycle === 'weekly' ? 'Pro available in Monthly & Yearly' : proPrice.subtext}
                </span>
              </div>

              <ul className="space-y-2 text-xs font-semibold text-slate-700">
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span className="font-bold text-slate-900">Everything in Lite Included</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span className="font-bold text-blue-950">Full Video enhancement features</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>4K 60FPS Video Upscaling</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Camera Shake Stabilization</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Optical Flow Frame Interpolation</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>High-Priority GPU Node Queue</span>
                </li>
              </ul>
            </div>

            <div className="pt-6">
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
                className="w-full flex items-center justify-center py-3.5 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-black text-xs uppercase tracking-wider shadow-lg transition-all active:scale-98 cursor-pointer"
              >
                {billingCycle === 'weekly'
                  ? 'Get Pro Monthly (₹599)'
                  : `Unlock Slipe AI Pro (${proPrice.price})`}
              </button>
            </div>
          </div>
        </div>

        {/* Full Feature Comparison Matrix Section */}
        <div className="space-y-4 pt-4 border-t border-slate-100">
          <div className="text-center max-w-xl mx-auto space-y-1">
            <h3 className="text-xl sm:text-2xl font-black text-slate-950 tracking-tight">
              Compare Plan Capabilities
            </h3>
            <p className="text-xs text-slate-600 font-semibold">
              Detailed breakdown of restoration models, resolution limits, and cloud compute.
            </p>
          </div>

          <div className="overflow-x-auto rounded-2xl border border-slate-200/90 bg-white shadow-xs">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50/80">
                  <th className="py-3 px-3 sm:px-5 font-black text-slate-900 w-2/5">Features</th>
                  <th className="py-3 px-3 sm:px-5 font-bold text-slate-600 text-center w-1/5">Free</th>
                  <th className="py-3 px-3 sm:px-5 font-bold text-blue-700 text-center w-1/5 bg-blue-50/50">Lite</th>
                  <th className="py-3 px-3 sm:px-5 font-black text-slate-950 text-center w-1/5 bg-blue-50/70">Pro</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-semibold text-slate-700">
                <tr className="bg-slate-50/40">
                  <td colSpan={4} className="py-2 px-3 sm:px-5 text-[10px] font-black uppercase tracking-wider text-slate-500">
                    Photo Restoration & Clarity
                  </td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">Photo Enhancements</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-500">2 Free Uses</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-blue-700 font-bold bg-blue-50/30">Unlimited</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-950 font-black bg-blue-50/50">Unlimited</td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">Maximum Export Resolution</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-500">1080p</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-900 bg-blue-50/30">4K Ultra</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-950 font-black bg-blue-50/50">8K Neural</td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">All 10 Specialized Photo Models</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center">Preview</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-bold bg-blue-50/30">✓ Included</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-bold bg-blue-50/50">✓ Included</td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">B&W Archival Colorization</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center">✓</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-bold bg-blue-50/30">✓ Included</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-bold bg-blue-50/50">✓ Included</td>
                </tr>

                <tr className="bg-slate-50/40">
                  <td colSpan={4} className="py-2 px-3 sm:px-5 text-[10px] font-black uppercase tracking-wider text-slate-500">
                    Video Remastering Suite
                  </td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">AI Video Upscaling (4K/8K)</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">60 FPS / 120 FPS Frame Interpolation</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
                <tr>
                  <td className="py-2.5 px-3 sm:px-5">Camera Motion Deblur & HDR</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-slate-400 bg-blue-50/30">—</td>
                  <td className="py-2.5 px-3 sm:px-5 text-center text-emerald-600 font-black bg-blue-50/50">✓ Full Access</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Security & Payment Methods */}
        <div className="rounded-2xl border border-slate-200/90 bg-slate-50 p-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 border border-blue-200 text-blue-600 shadow-xs shrink-0">
              <ShieldCheck className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <h4 className="text-xs sm:text-sm font-black text-slate-950">
                Bank-Grade 256-Bit SSL Security
              </h4>
              <p className="text-[11px] text-slate-500 font-medium">
                Official billing via Razorpay • UPI, Cards, NetBanking.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-1.5 text-[11px] font-bold text-slate-600">
            <span className="px-2.5 py-1 rounded-lg border border-slate-200 bg-white">UPI / GPay</span>
            <span className="px-2.5 py-1 rounded-lg border border-slate-200 bg-white">Cards</span>
            <span className="px-2.5 py-1 rounded-lg border border-slate-200 bg-white">NetBanking</span>
          </div>
        </div>

        {/* FAQ Accordion Section */}
        <div className="space-y-3 pt-2">
          <div className="text-center space-y-1">
            <h3 className="text-xl font-black text-slate-950 tracking-tight">
              Frequently Asked Questions
            </h3>
            <p className="text-xs text-slate-600 font-semibold">
              Everything you need to know about Slipe AI plans and billing.
            </p>
          </div>

          <div className="space-y-2">
            {faqs.map((faq, index) => {
              const isOpen = openFaq === index;
              return (
                <div
                  key={index}
                  className="rounded-xl border border-slate-200/90 bg-white overflow-hidden shadow-2xs transition-all"
                >
                  <button
                    type="button"
                    onClick={() => setOpenFaq(isOpen ? null : index)}
                    className="w-full flex items-center justify-between p-3.5 text-left font-bold text-slate-950 text-xs sm:text-sm hover:text-blue-600 transition-colors cursor-pointer"
                  >
                    <span>{faq.q}</span>
                    <ChevronDown
                      className={`h-4 w-4 text-slate-400 shrink-0 transition-transform duration-200 ${
                        isOpen ? 'rotate-180 text-blue-600' : ''
                      }`}
                    />
                  </button>
                  {isOpen && (
                    <div className="px-3.5 pb-4 text-xs font-semibold text-slate-600 leading-relaxed border-t border-slate-100 pt-2.5">
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
