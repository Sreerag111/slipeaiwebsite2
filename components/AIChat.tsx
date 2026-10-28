'use client';

import React, { useState } from 'react';
import { Sparkles, Bot, User, CornerDownLeft, MessageSquare } from 'lucide-react';

export function AIChat() {
  const [messages, setMessages] = useState<Array<{ role: 'user' | 'assistant'; text: string }>>([
    {
      role: 'assistant',
      text: 'Hello! I am Slipe AI, your neural restoration & creative assistant. Ask me anything about photo enhancement, vintage photo scanning techniques, prompt generation, or 4K video remastering.',
    },
  ]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  const presets = [
    'How do I restore old damaged faces?',
    'What is the best scan DPI for vintage photos?',
    'How does Slipe AI preserve original skin texture?',
    'What video frame rate can I upscale to?',
  ];

  const handleSend = (textToSend?: string) => {
    const text = textToSend || input;
    if (!text.trim()) return;

    const userMsg = { role: 'user' as const, text };
    setMessages((prev) => [...prev, userMsg]);
    if (!textToSend) setInput('');
    setIsTyping(true);

    // Contextual responses based on knowledge
    setTimeout(() => {
      let reply =
        "Slipe AI uses deep neural texture synthesis to repair tears, dust, and scratches while preserving your photo's authentic pixel histogram. Unlike generic filters that blur faces into plastic cartoons, Slipe AI guarantees the subject retains their authentic facial identity and skin micro-pores.";

      const lower = text.toLowerCase();
      if (lower.includes('dpi') || lower.includes('scan')) {
        reply =
          'For vintage paper photos, scan at 600 DPI (or 1200 DPI for wallet-sized prints) as an uncompressed TIFF or PNG. This provides our AI models with sufficient raw granular sensor data to recover micro-textures without compression artifacts.';
      } else if (lower.includes('skin') || lower.includes('texture') || lower.includes('face')) {
        reply =
          'Slipe AI features our proprietary natural face recovery model. Instead of applying a flat blur or plastic caricature, it isolates human skin pores and micro-contrasts, enhancing sharpness while preserving genuine facial marks, freckles, and expressions.';
      } else if (lower.includes('video') || lower.includes('fps') || lower.includes('frame')) {
        reply =
          'Slipe AI Video Remaster uses optical flow neural networks to interpolate mobile and archival clips up to smooth 60 FPS or 120 FPS, while upscaling resolution up to 4K or 8K Ultra-HD with motion deblur and cinema HDR tone mapping.';
      } else if (lower.includes('prompt')) {
        reply =
          'Recommended Portrait Prompt: "Hyper-realistic vintage 1950s portrait, authentic Hasselblad 500C lens, 85mm f/1.4, subtle chiaroscuro side lighting, rich archival depth, unedited texture, 8k resolution."';
      }

      setMessages((prev) => [...prev, { role: 'assistant', text: reply }]);
      setIsTyping(false);
    }, 850);
  };

  return (
    <section id="chat" className="py-14 sm:py-20 md:py-28 border-t border-slate-200/80 bg-[#F8FAFC]">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-12 space-y-3">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border border-blue-200 bg-blue-50 text-[11px] font-bold text-blue-900">
            <MessageSquare className="h-3 w-3 text-blue-600" />
            <span>AI Restoration Assistant</span>
          </div>
          <h2 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
            Ask Slipe AI
          </h2>
          {/* Subheading: Semi Bold */}
          <p className="text-xs sm:text-sm md:text-base text-slate-600 font-semibold px-2">
            Get instant expert guidance on photo restoration techniques, scan parameters, and video remastering workflows.
          </p>
        </div>

        {/* Chat Card */}
        <div className="rounded-3xl border border-slate-200/90 bg-white container-shade-xl flex flex-col h-[540px] sm:h-[580px] overflow-hidden">
          {/* Header */}
          <div className="px-5 sm:px-6 py-3.5 border-b border-slate-100 bg-slate-50/70 flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <span className="h-2.5 w-2.5 rounded-full bg-blue-600 shadow-[0_0_8px_rgba(37,99,235,0.4)]" />
              <span className="text-xs sm:text-sm font-black text-slate-950">
                Slipe AI Assistant
              </span>
            </div>
            <span className="text-[11px] text-slate-500 font-semibold">Model: Slipe Neural v4</span>
          </div>

          {/* Messages Stream */}
          <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4 bg-slate-50/30">
            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={`flex items-start gap-3 ${
                  msg.role === 'user' ? 'justify-end' : 'justify-start'
                }`}
              >
                {msg.role === 'assistant' && (
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl border border-blue-200 bg-blue-50 text-blue-600 shadow-sm">
                    <Sparkles className="h-4 w-4" />
                  </div>
                )}
                <div
                  className={`max-w-[85%] sm:max-w-md p-3.5 sm:p-4 text-xs sm:text-sm leading-relaxed ${
                    msg.role === 'user'
                      ? 'bg-blue-600 text-white font-semibold rounded-2xl rounded-tr-sm shadow-md'
                      : 'bg-white border border-slate-200/90 text-slate-800 font-medium rounded-2xl rounded-tl-sm container-shade-sm'
                  }`}
                >
                  {msg.text}
                </div>
                {msg.role === 'user' && (
                  <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-slate-200 text-slate-700 shadow-sm">
                    <User className="h-4 w-4" />
                  </div>
                )}
              </div>
            ))}
            {isTyping && (
              <div className="flex items-center gap-2 text-xs font-semibold text-slate-500 italic pl-11">
                <span className="h-2 w-2 rounded-full bg-blue-600 animate-pulse" />
                <span>Slipe AI is writing...</span>
              </div>
            )}
          </div>

          {/* Preset Chips */}
          <div className="px-4 sm:px-6 py-2.5 bg-white border-t border-slate-100 overflow-x-auto flex gap-2 no-scrollbar">
            {presets.map((p, i) => (
              <button
                key={i}
                onClick={() => handleSend(p)}
                className="whitespace-nowrap px-3 py-1.5 rounded-xl border border-slate-200 bg-slate-50 text-[11px] font-semibold text-slate-600 hover:text-blue-600 hover:border-blue-300 hover:bg-blue-50/50 transition-colors shrink-0"
              >
                {p}
              </button>
            ))}
          </div>

          {/* Input Bar */}
          <div className="p-3 sm:p-4 bg-white border-t border-slate-100 flex gap-2.5 items-center">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Ask Slipe AI about photo restoration or video enhancement..."
              className="flex-1 bg-slate-50 border border-slate-200 focus:bg-white focus:border-blue-600 focus:ring-2 focus:ring-blue-500/15 px-4 py-2.5 sm:py-3 rounded-xl text-xs sm:text-sm text-slate-900 placeholder-slate-400 outline-none transition-all font-medium"
            />
            <button
              onClick={() => handleSend()}
              className="px-5 py-2.5 sm:py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs sm:text-sm rounded-xl transition-all shadow-md active:scale-95 flex items-center gap-1.5 shrink-0"
            >
              <span>Send</span>
              <CornerDownLeft className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
