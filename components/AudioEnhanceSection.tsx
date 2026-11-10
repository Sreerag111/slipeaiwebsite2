'use client';

import React from 'react';
import {
  AudioWaveform,
  Mic,
  Volume2,
  Sliders,
  Sparkles,
  ArrowRight,
  ImagePlay,
} from 'lucide-react';

interface AudioEnhanceSectionProps {
  onExploreGif?: () => void;
}

export function AudioEnhanceSection({ onExploreGif }: AudioEnhanceSectionProps) {
  const previewFeatures = [
    {
      title: 'Vocal Isolation & Speech Clarity',
      desc: 'Separate crisp, clear speech from heavy background noise, wind, traffic, and crowd chatter.',
      icon: Mic,
    },
    {
      title: 'Studio De-Reverb & Echo Removal',
      desc: 'Eliminate room reflections, hollow hall reverberation, and room acoustics for a direct studio sound.',
      icon: AudioWaveform,
    },
    {
      title: 'Hiss, Hum & Denoise Cleanup',
      desc: 'Remove electrical 50/60Hz hum, air conditioner noise, and microphone preamp hiss without artifacting.',
      icon: Volume2,
    },
    {
      title: 'Broadcast Loudness & Mastering',
      desc: 'Balance dynamic range, apply multi-band compression, and master to broadcast LUFS standards.',
      icon: Sliders,
    },
  ];

  return (
    <section id="audio" className="py-8 sm:py-12 md:py-16 bg-[#F8FAFC]">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 space-y-8 sm:space-y-12">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-2.5 font-display">
          <span className="text-xs sm:text-sm font-bold text-blue-600 uppercase tracking-widest block">
            Coming Soon
          </span>

          <h2 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-slate-950 tracking-tight leading-tight">
            Enhance Audios
          </h2>

          <p className="text-sm sm:text-base md:text-lg text-slate-600 font-medium max-w-2xl mx-auto px-2 leading-relaxed">
            AI-powered vocal isolation, speech clarity restoration, background noise removal, and studio acoustic enhancement.
          </p>
        </div>

        {/* Feature Preview Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 font-display">
          {previewFeatures.map((feat, idx) => {
            const Icon = feat.icon;
            return (
              <div
                key={idx}
                className="flex flex-col justify-between p-5 sm:p-6 rounded-[24px] sm:rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-3"
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center shadow-xs">
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className="text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full bg-slate-100 text-slate-500">
                      Preview
                    </span>
                  </div>

                  <h3 className="text-base sm:text-lg font-bold text-slate-950 tracking-tight">
                    {feat.title}
                  </h3>

                  <p className="text-xs sm:text-[13px] text-slate-600 font-medium leading-relaxed">
                    {feat.desc}
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {/* AI GIF Studio Feature Banner Below Audio Enhance */}
        <div className="rounded-[28px] sm:rounded-[32px] bg-gradient-to-br from-slate-950 via-slate-900 to-indigo-950 p-6 sm:p-8 md:p-10 text-white shadow-xl border border-slate-800/80 font-display relative overflow-hidden">
          <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />
          <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div className="space-y-2.5 max-w-2xl">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-400/30 text-xs font-bold uppercase tracking-wider">
                <Sparkles className="w-3.5 h-3.5" />
                <span>New AI Feature Available</span>
              </div>
              <h3 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
                AI GIF Studio
              </h3>
              <p className="text-sm sm:text-base text-slate-300 font-medium leading-relaxed">
                Turn your still photos and creative text prompts into smooth, looped animated GIFs with identity preservation and cinematic camera motion.
              </p>
            </div>

            <button
              type="button"
              onClick={onExploreGif || (() => { window.location.href = '/?tab=gif'; })}
              className="inline-flex items-center gap-2.5 px-6 py-3.5 rounded-2xl bg-white text-slate-950 hover:bg-slate-100 font-bold text-sm shadow-md transition-all active:scale-95 shrink-0 cursor-pointer group"
            >
              <ImagePlay className="w-4 h-4 text-indigo-600" />
              <span>Launch AI GIF Studio</span>
              <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
