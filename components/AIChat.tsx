'use client';

import React, { useState } from 'react';
import { Sparkles, Send, Bot, User, CornerDownLeft } from 'lucide-react';

export function AIChat() {
  const [messages, setMessages] = useState<Array<{ role: 'user' | 'assistant'; text: string }>>([
    {
      role: 'assistant',
      text: 'Hello! I am Slipe AI, your creative & image restoration assistant. Ask me anything about photo enhancement, vintage photo scanning techniques, or prompt generation.',
    },
  ]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  const presets = [
    'How do I restore old damaged faces?',
    'What is the best scan DPI for vintage photos?',
    'How does Slipe AI preserve original skin texture?',
    'Generate a prompt for black & white photography',
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
        "Slipe AI uses deep neural texture synthesis to repair tears and scratches while anchoring to your photo's original pixel histogram. Unlike other apps that replace faces with synthetic caricatures, Slipe AI guarantees the subject retains their authentic facial identity.";

      if (text.toLowerCase().includes('dpi') || text.toLowerCase().includes('scan')) {
        reply =
          'For vintage paper photos, always scan at 600 DPI (or 1200 DPI for wallet-sized prints) as uncompressed TIFF or PNG. This provides our AI models with sufficient raw granular sensor data to recover micro-textures without compression artifacts.';
      } else if (text.toLowerCase().includes('skin') || text.toLowerCase().includes('texture')) {
        reply =
          'Slipe AI features our proprietary natural face recovery model. Instead of applying a flat blur or plastic filter, it isolates human skin pores and micro-contrasts, enhancing sharpness while preserving genuine facial marks and texture.';
      } else if (text.toLowerCase().includes('prompt')) {
        reply =
          'Prompt: "Hyper-realistic vintage 1940s portrait, natural film grain, authentic Hasselblad 500C lens, 85mm f/1.4, subtle chiaroscuro side lighting, rich archival depth, unedited texture."';
      }

      setMessages((prev) => [...prev, { role: 'assistant', text: reply }]);
      setIsTyping(false);
    }, 900);
  };

  return (
    <section id="chat" className="py-16 md:py-24 border-t border-neutral-900 bg-neutral-950">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-xl mx-auto mb-10 space-y-2">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border border-neutral-800 bg-black text-[11px] font-bold text-neutral-300">
            <Bot className="h-3 w-3 text-white" />
            <span>Slipe AI Interactive Assistant</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
            Ask Slipe AI
          </h2>
          <p className="text-xs sm:text-sm text-neutral-400">
            Get instant expert advice on restoration techniques, scan parameters, and creative workflows.
          </p>
        </div>

        {/* Chat Box */}
        <div className="rounded-none border-2 border-white bg-black halo-shadow flex flex-col h-[520px] overflow-hidden">
          {/* Header */}
          <div className="px-5 py-3 border-b border-neutral-800 bg-neutral-950 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="h-2 w-2 rounded-full bg-white shadow-[0_0_8px_white]" />
              <span className="text-xs font-black uppercase tracking-wider text-white">
                Slipe AI Assistant
              </span>
            </div>
            <span className="text-[11px] text-neutral-500 font-medium">Model: Slipe Neural v4</span>
          </div>

          {/* Messages Stream */}
          <div className="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
            {messages.map((msg, idx) => (
              <div
                key={idx}
                className={`flex items-start gap-3 ${
                  msg.role === 'user' ? 'justify-end' : 'justify-start'
                }`}
              >
                {msg.role === 'assistant' && (
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded border border-white/20 bg-neutral-900 text-white text-xs">
                    <Sparkles className="h-3.5 w-3.5" />
                  </div>
                )}
                <div
                  className={`max-w-[85%] sm:max-w-md p-3.5 rounded-none text-xs leading-relaxed ${
                    msg.role === 'user'
                      ? 'bg-white text-black font-semibold'
                      : 'bg-neutral-950 border border-neutral-800 text-neutral-200'
                  }`}
                >
                  {msg.text}
                </div>
                {msg.role === 'user' && (
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded bg-neutral-800 text-neutral-400 text-xs">
                    <User className="h-3.5 w-3.5" />
                  </div>
                )}
              </div>
            ))}
            {isTyping && (
              <div className="flex items-center gap-2 text-xs text-neutral-500 italic">
                <span className="h-1.5 w-1.5 rounded-full bg-white animate-pulse" />
                <span>Slipe AI is thinking...</span>
              </div>
            )}
          </div>

          {/* Preset Chips */}
          <div className="px-4 py-2 bg-neutral-950 border-t border-neutral-900 overflow-x-auto flex gap-2 no-scrollbar">
            {presets.map((p, i) => (
              <button
                key={i}
                onClick={() => handleSend(p)}
                className="whitespace-nowrap px-2.5 py-1 rounded-none border border-neutral-800 bg-black text-[11px] text-neutral-400 hover:text-white hover:border-neutral-600 transition-colors"
              >
                {p}
              </button>
            ))}
          </div>

          {/* Input Bar */}
          <div className="p-3 bg-neutral-950 border-t border-neutral-800 flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
              placeholder="Ask Slipe AI about photo enhancement or creative prompts..."
              className="flex-1 bg-black border border-neutral-800 px-4 py-2.5 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-white transition-colors"
            />
            <button
              onClick={() => handleSend()}
              className="px-4 py-2.5 bg-white text-black font-bold text-xs hover:bg-neutral-200 transition-colors flex items-center gap-1.5"
            >
              <span>Send</span>
              <CornerDownLeft className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
