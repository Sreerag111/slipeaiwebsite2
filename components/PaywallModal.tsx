'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { X, Check, Crown, ShieldCheck } from 'lucide-react';

interface PaywallModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type BillingCycle = 'yearly' | 'monthly' | 'weekly';

export function PaywallModal({ isOpen, onClose }: PaywallModalProps) {
  const [billingCycle, setBillingCycle] = useState<BillingCycle>('yearly');
  const [loadingPayment, setLoadingPayment] = useState(false);

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
      alert('Razorpay gateway is loading. Please try again.');
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-900/60 backdrop-blur-md overflow-y-auto">
      <div className="relative w-full max-w-4xl max-h-[94vh] flex flex-col bg-white border border-slate-200/90 rounded-3xl container-shade-xl text-slate-900 overflow-y-auto my-auto p-5 sm:p-8 space-y-6">
        {/* Top bar with close button */}
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 shrink-0">
          <div className="flex items-center gap-2">
            <span className="text-sm font-black text-slate-950 tracking-tight">
              SlipeAI Plans & Pricing
            </span>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full bg-slate-100 text-slate-500 hover:text-slate-950 hover:bg-slate-200 transition-colors"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Modal Header */}
        <div className="text-center max-w-2xl mx-auto space-y-2">
          <h2 className="text-2xl sm:text-3xl font-black text-slate-950 tracking-tight">
            Plans Built for Creators, Studios & Pros
          </h2>
          <p className="text-xs sm:text-sm text-slate-600 font-semibold leading-relaxed">
            Upgrade anytime, restore unlimited photos, and remaster videos in 4K 60FPS clarity.
          </p>

          {/* Billing Cycle Toggle */}
          <div className="pt-3 flex justify-center">
            <div className="inline-flex items-center p-1 rounded-2xl bg-slate-100 border border-slate-200">
              <button
                type="button"
                onClick={() => setBillingCycle('yearly')}
                className={`flex items-center gap-1.5 px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all ${
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
                className={`px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all ${
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
                className={`px-3.5 sm:px-4 py-1.5 rounded-xl text-xs font-bold transition-all ${
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

        {/* 2-Column Cards Grid: Slipe AI Lite & Slipe AI Pro */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5 sm:gap-6 items-stretch">
          {/* TIER: Slipe AI Lite */}
          <div className="flex flex-col justify-between rounded-3xl border border-slate-200/90 bg-white p-5 sm:p-7 container-shade hover:container-shade-lg transition-all">
            <div className="space-y-4">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                    Photo Suite
                  </span>
                  <span className="text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full bg-blue-600 text-white shadow-sm">
                    Popular for Photos
                  </span>
                </div>
                <h3 className="text-xl font-black text-slate-950">Slipe AI Lite</h3>
                <p className="text-xs text-slate-500 font-semibold leading-relaxed">
                  Unlimited photo restoration, portrait facial clarity, and archival colorization.
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

              {/* 10 Lite Features */}
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
                  <span>Upscale Photos</span>
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
                  <span>Refine Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Brightens Dark Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Unblur Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Sharpen Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Balance Colour</span>
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
                disabled={loadingPayment}
                className="w-full flex items-center justify-center py-3 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs shadow-md transition-all active:scale-[0.98]"
              >
                {loadingPayment ? 'Connecting...' : `Upgrade to Lite (${litePrice.price})`}
              </button>
            </div>
          </div>

          {/* TIER: Slipe AI Pro */}
          <div className="relative flex flex-col justify-between rounded-3xl border-2 border-blue-600 bg-white p-5 sm:p-7 container-shade-xl ring-4 ring-blue-500/15 transition-all">
            {/* Top pill */}
            <div className="absolute -top-3 left-1/2 -translate-x-1/2">
              <span className="flex items-center gap-1.5 px-3 py-0.5 rounded-full bg-blue-600 text-white text-[10px] font-black uppercase tracking-wider shadow-md">
                <Crown className="h-3 w-3" />
                <span>Most Popular • Complete Suite</span>
              </span>
            </div>

            <div className="space-y-4 pt-1">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-600">
                    Full AI Powerhouse
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
                  {billingCycle === 'weekly' ? (
                    <span className="text-amber-800 font-bold bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-md inline-block">
                      Pro only available in Monthly & Yearly
                    </span>
                  ) : (
                    proPrice.subtext
                  )}
                </span>
              </div>

              {/* 12 Pro Features */}
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
                  <span>Upscale Photos</span>
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
                  <span>Refine Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Brightens Dark Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Unblur Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Sharpen Photos</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span>Balance Colour</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span className="font-bold text-blue-900">Full Video enhancement features</span>
                </li>
                <li className="flex items-start gap-2">
                  <Check className="h-4 w-4 text-blue-600 shrink-0 mt-0.5" />
                  <span className="font-bold text-blue-900">Video Creations(Coming Soon)</span>
                </li>
              </ul>
            </div>

            <div className="pt-6">
              {billingCycle === 'weekly' ? (
                <button
                  type="button"
                  onClick={() => setBillingCycle('monthly')}
                  className="w-full flex items-center justify-center py-3 rounded-2xl border-2 border-dashed border-blue-400 bg-blue-50/70 text-blue-800 font-bold text-xs transition-all hover:bg-blue-100"
                >
                  Switch to Monthly for Pro
                </button>
              ) : (
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
                  disabled={loadingPayment}
                  className="w-full flex items-center justify-center py-3 rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-black text-xs shadow-md hover:shadow-lg transition-all active:scale-[0.98]"
                >
                  {loadingPayment ? 'Connecting...' : `Upgrade to Pro (${proPrice.price})`}
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div className="pt-2 flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-slate-100 text-xs">
          <Link
            href="/pricing"
            onClick={onClose}
            className="font-bold text-blue-600 hover:text-blue-800 hover:underline flex items-center gap-1"
          >
            <span>View Full Website Pricing & Compare Plans →</span>
          </Link>
          <div className="flex items-center gap-1.5 text-slate-400 text-[11px] font-semibold">
            <ShieldCheck className="h-3.5 w-3.5 text-emerald-600" />
            <span>Cancel anytime • Secured by Razorpay 256-bit SSL</span>
          </div>
        </div>
      </div>
    </div>
  );
}