'use client';

import React, { Suspense, useState } from 'react';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { PaywallModal } from '@/components/PaywallModal';
import { PhotoEnhanceStudio } from '@/components/PhotoEnhanceStudio';
import { Loader2 } from 'lucide-react';

function StudioLoading() {
  return (
    <div className="min-h-[600px] flex flex-col items-center justify-center p-8 space-y-4">
      <Loader2 className="w-8 h-8 text-blue-600 animate-spin" />
      <p className="text-sm font-bold text-slate-600">Loading Photo Enhancement Studio...</p>
    </div>
  );
}

export default function EnhancePage() {
  const [isPricingOpen, setIsPricingOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('enhancer');

  return (
    <main className="min-h-screen bg-[#F8FAFC] text-slate-900 selection:bg-slate-900 selection:text-white flex flex-col justify-between">
      <div>
        {/* Navigation */}
        <Navbar
          onOpenPricing={() => setIsPricingOpen(true)}
          activeTab={activeTab}
          setActiveTab={setActiveTab}
        />

        {/* Dedicated Photo Enhancement Studio */}
        <Suspense fallback={<StudioLoading />}>
          <PhotoEnhanceStudio onOpenPricing={() => setIsPricingOpen(true)} />
        </Suspense>
      </div>

      {/* Footer */}
      <Footer />

      {/* Paywall Modal */}
      <PaywallModal isOpen={isPricingOpen} onClose={() => setIsPricingOpen(false)} />
    </main>
  );
}
