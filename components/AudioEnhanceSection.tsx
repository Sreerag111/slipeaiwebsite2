'use client';

import React from 'react';
import {
  AudioWaveform,
  Mic,
  Volume2,
  Sliders,
  Sparkles,
  Lock,
  Radio,
  Clock,
} from 'lucide-react';

export function AudioEnhanceSection() {
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
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 border border-blue-200 text-blue-900 text-xs font-bold shadow-2xs">
            <Clock className="w-3.5 h-3.5 text-blue-600" />
            <span>Coming Soon</span>
          </div>

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

        {/* Disabled Upload Dropzone Workspace (Coming Soon notice) */}
        <div className="rounded-[28px] sm:rounded-[36px] border border-slate-200/90 bg-white p-8 sm:p-14 md:p-16 text-center shadow-[0_8px_30px_rgba(0,0,0,0.06)] flex flex-col items-center justify-center space-y-5 font-display">
          <div className="flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center rounded-3xl bg-blue-50/80 border border-blue-200 text-blue-600 shadow-md">
            <AudioWaveform className="h-8 w-8 sm:h-10 sm:w-10 text-blue-600" />
          </div>

          <div className="space-y-2 max-w-lg mx-auto">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 text-slate-700 text-xs font-bold">
              <Lock className="w-3.5 h-3.5 text-slate-500" />
              <span>In Neural Model Training</span>
            </div>
            <h3 className="text-xl sm:text-2xl font-black text-slate-950 tracking-tight">
              Audio Enhancement Engine Coming Soon
            </h3>
            <p className="text-xs sm:text-sm text-slate-600 font-medium leading-relaxed">
              Our 48kHz audio super-resolution and real-time speech de-noising models are undergoing final GPU optimization. This section will be unlocked in an upcoming update.
            </p>
          </div>

          <button
            type="button"
            disabled
            className="flex items-center justify-center gap-2 px-8 py-3.5 rounded-2xl bg-slate-200 text-slate-500 font-bold text-xs uppercase tracking-wider cursor-not-allowed shadow-none"
          >
            <Clock className="w-4 h-4" />
            <span>Coming Soon</span>
          </button>
        </div>
      </div>
    </section>
  );
}
