'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { X, Check, ShieldCheck, Sparkles, Lock } from 'lucide-react';

interface PaywallModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function PaywallModal({ isOpen, onClose }: PaywallModalProps) {
  const [tier, setTier] = useState<'lite' | 'pro'>('lite');
  const [selectedPlanId, setSelectedPlanId] = useState<string>('lite_monthly');
  const [loadingPayment, setLoadingPayment] = useState(false);

  if (!isOpen) return null;

  const litePlans = [
    { id: 'lite_weekly', title: 'Weekly', price: '₹49', period: 'week', badge: null, amountPaise: 4900 },
    { id: 'lite_monthly', title: 'Monthly', price: '₹99', period: 'month', badge: '24% OFF', amountPaise: 9900 },
    { id: 'lite_yearly', title: 'Yearly', price: '₹899', period: 'year', badge: '75% OFF', amountPaise: 89900 },
  ];

  const proPlans = [
    { id: 'pro_monthly', title: 'Monthly', price: '₹599', period: 'month', badge: null, amountPaise: 59900 },
    { id: 'pro_yearly', title: 'Yearly', price: '₹1,799', period: 'year', badge: '75% OFF', amountPaise: 179900 },
  ];

  const currentPlans = tier === 'lite' ? litePlans : proPlans;

  const handleCheckout = () => {
    setLoadingPayment(true);
    const plan = currentPlans.find((p) => p.id === selectedPlanId) || currentPlans[0];

    if (typeof window !== 'undefined' && (window as any).Razorpay) {
      const options = {
        key: 'rzp_live_TsvRRjJbFwaKbD',
        amount: plan.amountPaise,
        currency: 'INR',
        name: 'Pace AI Technologies (OPC) Private Limited',
        description: `Slipe AI ${tier.toUpperCase()} Subscription - ${plan.title}`,
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
          color: '#000000',
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
      alert('Razorpay gateway is loading. Please try again in 2 seconds.');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/90 backdrop-blur-md overflow-y-auto">
      <div className="relative w-full max-w-lg bg-black border border-neutral-800 rounded-none halo-shadow-active overflow-hidden my-6">
        {/* Top bar with close button */}
        <div className="flex items-center justify-between px-5 pt-4 pb-2">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-neutral-400 tracking-wider uppercase">
              Subscription
            </span>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full bg-neutral-900 text-neutral-400 hover:text-white hover:bg-neutral-800 transition-colors"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* 2x2 Showcase Images Grid (matching mobile app exact layout) */}
        <div className="px-5 py-2">
          <div className="grid grid-cols-2 gap-2.5">
            {[1, 2, 3, 4].map((num) => (
              <div
                key={num}
                className="relative aspect-square w-full overflow-hidden border-2 border-white rounded-none bg-neutral-950 halo-shadow-sm"
              >
                <Image
                  src={`/assets/images/premium_showcase_${num}.jpg`}
                  alt={`Slipe AI Showcase ${num}`}
                  fill
                  className="object-cover"
                />
              </div>
            ))}
          </div>
        </div>

        {/* Headlines */}
        <div className="px-5 pt-3 pb-2 text-center">
          <h2 className="text-xl sm:text-2xl font-black text-white tracking-tight leading-snug">
            Bring your photos back to life{' '}
            <span className="block">without losing original look!</span>
          </h2>
          <p className="text-xs sm:text-sm text-neutral-300 font-medium mt-1">
            These enhancements are done in SlipeAI not fake
          </p>
        </div>

        {/* Segmented Switcher: [ Lite ] [ Pro ] */}
        <div className="px-5 py-3">
          <div className="flex rounded-lg border border-neutral-800 bg-neutral-950 p-1">
            <button
              onClick={() => {
                setTier('lite');
                setSelectedPlanId('lite_monthly');
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-md transition-all ${
                tier === 'lite'
                  ? 'bg-white text-black shadow-md halo-shadow-sm'
                  : 'text-neutral-400 hover:text-white'
              }`}
            >
              Lite Tier
            </button>
            <button
              onClick={() => {
                setTier('pro');
                setSelectedPlanId('pro_yearly');
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-md transition-all ${
                tier === 'pro'
                  ? 'bg-white text-black shadow-md halo-shadow-sm'
                  : 'text-neutral-400 hover:text-white'
              }`}
            >
              Pro Tier (4K & Video)
            </button>
          </div>
        </div>

        {/* Horizontal Docked Plan Cards (Ascending order) */}
        <div className="px-5 py-2">
          <div className={`grid gap-2 ${tier === 'lite' ? 'grid-cols-3' : 'grid-cols-2'}`}>
            {currentPlans.map((plan) => {
              const isSelected = selectedPlanId === plan.id;
              return (
                <button
                  key={plan.id}
                  onClick={() => setSelectedPlanId(plan.id)}
                  className={`relative flex flex-col justify-between p-3 rounded-none border text-left transition-all ${
                    isSelected
                      ? 'border-white bg-neutral-900 halo-shadow'
                      : 'border-neutral-800 bg-neutral-950/70 hover:border-neutral-700'
                  }`}
                >
                  {plan.badge && (
                    <span className="inline-block text-[9px] font-black uppercase tracking-wider text-black bg-white px-1.5 py-0.5 rounded-none mb-1.5 w-fit">
                      {plan.badge}
                    </span>
                  )}
                  <div>
                    <span className="text-[11px] font-bold text-neutral-400 block uppercase">
                      {plan.title}
                    </span>
                    <div className="mt-1 flex items-baseline gap-1">
                      <span className="text-lg font-black text-white">{plan.price}</span>
                      <span className="text-[10px] text-neutral-400">/{plan.period}</span>
                    </div>
                  </div>
                  {isSelected && (
                    <div className="mt-2 flex items-center gap-1 text-[10px] font-bold text-white">
                      <Check className="h-3 w-3 text-white" />
                      <span>Selected</span>
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Continue Button */}
        <div className="px-5 pt-3 pb-5 space-y-2">
          <button
            onClick={handleCheckout}
            disabled={loadingPayment}
            className="w-full py-3.5 rounded-none bg-white text-black font-black text-sm uppercase tracking-wider hover:bg-neutral-200 transition-all shadow-xl halo-shadow hover:scale-[1.01] active:scale-[0.99]"
          >
            {loadingPayment ? 'Connecting Gateway...' : 'Continue to Upgrade'}
          </button>
          <p className="text-center text-[11px] text-neutral-500 font-medium">
            Cancel anytime. Secured by Razorpay 256-bit SSL.
          </p>
        </div>
      </div>
    </div>
  );
}
