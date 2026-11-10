'use client';

import React, { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import {
  Upload,
  Sparkles,
  Film,
  Image as ImageIcon,
  Wand2,
  Download,
  RotateCcw,
  Plus,
  Check,
  AlertCircle,
  Clock,
  Zap,
  Sliders,
  Eye,
  Trash2,
  RefreshCw,
  Layers,
  ArrowRight,
  Wind,
  Smile,
  ZoomIn,
  ZoomOut,
  Palette,
  Sun,
  Repeat,
  ChevronRight,
  Play,
  Share2,
} from 'lucide-react';
import {
  GifMode,
  AnimationStyleId,
  ANIMATION_STYLES,
  GifGenerationSettings,
  GifJobResult,
  GifJobStage,
  GifHistoryItem,
} from '@/lib/gifStudioTypes';

interface AIGifStudioProps {
  onOpenPricing?: () => void;
  onNavigateHome?: () => void;
}

const STYLE_ICON_MAP: Record<string, any> = {
  Wind,
  Film,
  Smile,
  Sparkles,
  ZoomIn,
  ZoomOut,
  Layers,
  Palette,
  Sun,
  Repeat,
  Sliders,
};

const PROMPT_SUGGESTIONS = [
  'A woman slowly turning towards the camera with natural hair movement',
  'A beautiful butterfly gently flapping its wings on a flower',
  'A cinematic portrait with moving hair and subtle camera zoom',
  'A person smiling naturally and blinking at golden hour',
  'A sunset with moving clouds and flowing ocean water',
  'A cute animated cat waving its paw and blinking',
];

export function AIGifStudio({ onOpenPricing, onNavigateHome }: AIGifStudioProps) {
  // Mode Selection: 'image-to-gif' | 'text-to-gif'
  const [mode, setMode] = useState<GifMode>('image-to-gif');

  // Input States
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [prompt, setPrompt] = useState('');
  const [selectedStyle, setSelectedStyle] = useState<AnimationStyleId>('natural_motion');

  // Customization Settings
  const [duration, setDuration] = useState<2 | 3 | 4 | 5>(3);
  const [fps, setFps] = useState<8 | 12 | 15>(12);
  const [quality, setQuality] = useState<'standard' | 'high'>('high');
  const [aspectRatio, setAspectRatio] = useState<'original' | '1:1' | '4:5' | '9:16' | '16:9'>('original');

  // Progress & Execution States
  const [isGenerating, setIsGenerating] = useState(false);
  const [jobId, setJobId] = useState<string | null>(null);
  const [jobStage, setJobStage] = useState<GifJobStage>('queued');
  const [jobProgress, setJobProgress] = useState(0);
  const [jobStepLabel, setJobStepLabel] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Result States
  const [result, setResult] = useState<GifJobResult | null>(null);
  const [showOriginalComparison, setShowOriginalComparison] = useState(false);

  // Generation History
  const [history, setHistory] = useState<GifHistoryItem[]>([]);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);

  // Drag and drop reference
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const resultRef = useRef<HTMLDivElement>(null);

  // Credit calculation: 1 credit for standard <=3s, 2 credits for high or 4-5s
  const creditCost = quality === 'high' || duration > 3 ? 2 : 1;

  // Load user GIF history
  const loadHistory = async () => {
    try {
      setIsHistoryLoading(true);
      const res = await fetch('/api/gif/history');
      if (res.ok) {
        const data = await res.json();
        if (data.history) {
          setHistory(data.history);
        }
      }
    } catch (err) {
      console.warn('Failed to fetch history:', err);
    } finally {
      setIsHistoryLoading(false);
    }
  };

  useEffect(() => {
    loadHistory();
  }, []);

  // Poll job status while generating
  useEffect(() => {
    if (!jobId || !isGenerating) return;

    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/gif/status?jobId=${jobId}`);
        if (!res.ok) return;

        const data = await res.json();
        if (data.success && data.job) {
          const { status, progress, stepLabel, error, result: jobRes } = data.job;

          setJobStage(status);
          setJobProgress(progress || 0);
          setJobStepLabel(stepLabel || 'Processing...');

          if (status === 'completed' && jobRes) {
            setResult(jobRes);
            setIsGenerating(false);
            clearInterval(interval);
            loadHistory();
            setTimeout(() => {
              resultRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }, 250);
          } else if (status === 'failed') {
            setErrorMessage(error || 'Generation failed. Please try again.');
            setIsGenerating(false);
            clearInterval(interval);
          }
        }
      } catch (err) {
        console.warn('Error polling status:', err);
      }
    }, 1200);

    return () => clearInterval(interval);
  }, [jobId, isGenerating]);

  // Image Upload Handling
  const handleFileSelect = (file: File) => {
    if (!file.type.match(/^image\/(jpeg|png|webp|jpg)$/i)) {
      alert('Please upload a valid JPG, PNG, or WebP image.');
      return;
    }
    if (file.size > 20 * 1024 * 1024) {
      alert('Image file size must be under 20 MB.');
      return;
    }

    setSelectedImage(file);
    const objectUrl = URL.createObjectURL(file);
    setImagePreview(objectUrl);
    setErrorMessage(null);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileSelect(e.dataTransfer.files[0]);
    }
  };

  const handleClearImage = () => {
    setSelectedImage(null);
    if (imagePreview) {
      URL.revokeObjectURL(imagePreview);
      setImagePreview(null);
    }
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  // Trigger Generation
  const handleGenerate = async () => {
    // Credit check
    const currentUses = parseInt(localStorage.getItem('slipeai_free_uses') || '0', 10);
    if (currentUses >= 10 && onOpenPricing) {
      onOpenPricing();
      return;
    }

    // Input validation
    if (mode === 'image-to-gif' && !selectedImage && !imagePreview) {
      setErrorMessage('Please upload a photograph to animate into a GIF.');
      return;
    }

    if (mode === 'text-to-gif' && !prompt.trim()) {
      setErrorMessage('Please enter an animation description prompt.');
      return;
    }

    setErrorMessage(null);
    setIsGenerating(true);
    setJobStage('uploading');
    setJobProgress(10);
    setJobStepLabel('Uploading assets and validating generation parameters...');

    try {
      const formData = new FormData();
      formData.append('mode', mode);
      formData.append('style', selectedStyle);
      formData.append('prompt', prompt.trim());
      formData.append('duration', duration.toString());
      formData.append('fps', fps.toString());
      formData.append('quality', quality);
      formData.append('aspectRatio', aspectRatio);

      if (selectedImage) {
        formData.append('image', selectedImage);
      }

      const res = await fetch('/api/gif/generate', {
        method: 'POST',
        body: formData,
      });

      const data = await res.json();

      if (!res.ok || !data.success) {
        throw new Error(data.error || 'Failed to initiate GIF generation.');
      }

      setJobId(data.jobId);
      setJobStage('preparing');
      setJobProgress(20);
      setJobStepLabel('Job enqueued. Initializing neural frame sequencing...');

      // Update local free uses
      try {
        localStorage.setItem('slipeai_free_uses', (currentUses + creditCost).toString());
      } catch {}
    } catch (err: any) {
      setErrorMessage(err.message || 'Network error initiating generation.');
      setIsGenerating(false);
    }
  };

  const handleDownload = (downloadJobId: string) => {
    window.location.href = `/api/gif/download?jobId=${downloadJobId}`;
  };

  const handleResetForNew = () => {
    setResult(null);
    setJobId(null);
    setJobStage('queued');
    setJobProgress(0);
    setErrorMessage(null);
  };

  const currentStyleObj = ANIMATION_STYLES.find((s) => s.id === selectedStyle) || ANIMATION_STYLES[0];

  return (
    <div className="min-h-screen bg-[#F8FAFC] pb-24 font-sans text-slate-900">
      {/* Studio Header Bar */}
      <section className="bg-white border-b border-slate-200/90 pt-8 sm:pt-10 pb-8 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="space-y-1.5 font-display">
              <div className="flex items-center gap-2">
                <span className="inline-flex items-center gap-1.5 text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full uppercase tracking-wider">
                  <Sparkles className="w-3.5 h-3.5" />
                  AI Production Studio
                </span>
                <span className="text-xs font-semibold text-slate-500">
                  Version 2.5
                </span>
              </div>
              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-slate-950 tracking-tight">
                AI GIF Studio
              </h1>
              <p className="text-base sm:text-lg text-slate-600 font-medium">
                Turn your photos and ideas into high-definition living moments.
              </p>
            </div>

            {/* Quick Action Badges */}
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2 px-3.5 py-2 rounded-2xl bg-slate-100/80 border border-slate-200/80 text-xs font-semibold text-slate-700">
                <Zap className="w-4 h-4 text-amber-500 fill-amber-500" />
                <span>{creditCost} Credit{creditCost > 1 ? 's' : ''} / gen</span>
              </div>
              {onOpenPricing && (
                <button
                  type="button"
                  onClick={onOpenPricing}
                  className="px-4 py-2 rounded-2xl bg-blue-600 text-white hover:bg-blue-700 text-xs font-bold transition-all shadow-sm active:scale-95 cursor-pointer"
                >
                  Upgrade Plan
                </button>
              )}
            </div>
          </div>

          {/* Mode Switcher Tabs */}
          <div className="inline-flex p-1.5 rounded-2xl bg-slate-100 border border-slate-200/90 font-display">
            <button
              type="button"
              onClick={() => {
                setMode('image-to-gif');
                setErrorMessage(null);
              }}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all cursor-pointer ${
                mode === 'image-to-gif'
                  ? 'bg-white text-slate-950 shadow-md scale-[1.01]'
                  : 'text-slate-600 hover:text-slate-950'
              }`}
            >
              <ImageIcon className="w-4 h-4 text-blue-600" />
              <span>Mode A: Image to GIF</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setMode('text-to-gif');
                setErrorMessage(null);
              }}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all cursor-pointer ${
                mode === 'text-to-gif'
                  ? 'bg-white text-slate-950 shadow-md scale-[1.01]'
                  : 'text-slate-600 hover:text-slate-950'
              }`}
            >
              <Wand2 className="w-4 h-4 text-purple-600" />
              <span>Mode B: AI GIF Creator</span>
            </button>
          </div>
        </div>
      </section>

      {/* Main Studio Canvas */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 space-y-10">
        {/* Error Alert Banner */}
        {errorMessage && (
          <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-800 flex items-start gap-3 shadow-xs">
            <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div className="space-y-1 text-xs sm:text-sm font-medium">
              <p className="font-bold">Generation Notice</p>
              <p>{errorMessage}</p>
            </div>
          </div>
        )}

        {/* Studio Workspace Layout: 2-Column Responsive */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left Column: Visual Upload / Source Canvas (5 Cols) */}
          <div className="lg:col-span-5 space-y-6">
            <div className="p-6 rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-5">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-bold font-display text-slate-950 flex items-center gap-2">
                  <ImageIcon className="w-4 h-4 text-blue-600" />
                  <span>
                    {mode === 'image-to-gif' ? 'Upload Source Photograph' : 'Reference Photograph (Optional)'}
                  </span>
                </h2>
                {imagePreview && (
                  <button
                    type="button"
                    onClick={handleClearImage}
                    className="text-xs font-semibold text-rose-600 hover:text-rose-700 flex items-center gap-1 cursor-pointer"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Remove</span>
                  </button>
                )}
              </div>

              {/* Upload Dropzone */}
              <input
                ref={fileInputRef}
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    handleFileSelect(e.target.files[0]);
                  }
                }}
                className="hidden"
              />

              {imagePreview ? (
                <div className="space-y-4">
                  <div className="relative aspect-square rounded-2xl overflow-hidden bg-slate-900 border border-slate-200/80 shadow-inner group">
                    <img
                      src={imagePreview}
                      alt="Selected preview"
                      className="w-full h-full object-contain"
                    />
                    <div className="absolute inset-0 bg-slate-950/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                      <button
                        type="button"
                        onClick={() => fileInputRef.current?.click()}
                        className="px-4 py-2 rounded-xl bg-white text-slate-900 text-xs font-bold shadow-md hover:bg-slate-100 transition-all cursor-pointer"
                      >
                        Replace Image
                      </button>
                    </div>
                  </div>

                  <div className="flex items-center justify-between text-xs text-slate-500 font-medium px-1">
                    <span>{selectedImage?.name || 'Uploaded image'}</span>
                    <span>
                      {selectedImage ? `${(selectedImage.size / (1024 * 1024)).toFixed(2)} MB` : ''}
                    </span>
                  </div>
                </div>
              ) : (
                <div
                  onDragOver={handleDragOver}
                  onDragLeave={handleDragLeave}
                  onDrop={handleDrop}
                  onClick={() => fileInputRef.current?.click()}
                  className={`aspect-square rounded-2xl border-2 border-dashed flex flex-col items-center justify-center p-6 text-center cursor-pointer transition-all ${
                    isDragging
                      ? 'border-blue-600 bg-blue-50/50 scale-[0.99]'
                      : 'border-slate-300 hover:border-slate-400 bg-slate-50/50 hover:bg-slate-50'
                  }`}
                >
                  <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center mb-4 shadow-xs group-hover:scale-105 transition-transform">
                    <Upload className="w-7 h-7" />
                  </div>
                  <h3 className="text-sm sm:text-base font-bold font-display text-slate-900 mb-1">
                    Click to upload or drag & drop
                  </h3>
                  <p className="text-xs text-slate-500 font-medium max-w-[240px] mb-4">
                    JPG, PNG, or WebP up to 20 MB. High-resolution portrait or subject images recommended.
                  </p>
                  <span className="px-4 py-2 rounded-xl bg-white border border-slate-200 text-xs font-bold text-slate-800 shadow-xs hover:bg-slate-50 transition-colors">
                    Browse Files
                  </span>
                </div>
              )}

              {/* Mode Specific Guidance Note */}
              <div className="p-3.5 rounded-xl bg-blue-50/60 border border-blue-100 text-[11px] sm:text-xs text-blue-900 space-y-1">
                <span className="font-bold flex items-center gap-1.5 text-blue-700">
                  <Check className="w-3.5 h-3.5" />
                  Identity Preservation Engine
                </span>
                <p className="text-slate-600 leading-relaxed">
                  Facial bone structure, eye shape, skin tone, hair, clothing, and background are strictly locked across every animated frame.
                </p>
              </div>
            </div>

            {/* Prompt Input Area */}
            <div className="p-6 rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-4">
              <div className="flex items-center justify-between">
                <label className="text-sm font-bold font-display text-slate-950 flex items-center gap-2">
                  <Wand2 className="w-4 h-4 text-purple-600" />
                  <span>
                    {mode === 'image-to-gif' ? 'Custom Animation Directions (Optional)' : 'Prompt Description'}
                  </span>
                </label>
                <span className="text-[11px] font-semibold text-slate-400">
                  {prompt.length}/280
                </span>
              </div>

              <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value.slice(0, 280))}
                placeholder={
                  mode === 'image-to-gif'
                    ? 'e.g., gentle breeze flowing through hair, natural smile transition and blinking...'
                    : 'Describe the scene to generate into an animated GIF (e.g., A cute animated cat waving its paw...)'
                }
                rows={3}
                className="w-full p-3.5 rounded-2xl bg-slate-50 border border-slate-200/90 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-600 transition-all resize-none"
              />

              {/* Prompt Suggestions for Mode B */}
              {mode === 'text-to-gif' && (
                <div className="space-y-2">
                  <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block font-display">
                    Prompt Inspirations
                  </span>
                  <div className="flex flex-wrap gap-1.5">
                    {PROMPT_SUGGESTIONS.map((item, idx) => (
                      <button
                        key={idx}
                        type="button"
                        onClick={() => setPrompt(item)}
                        className="text-[11px] font-medium text-slate-600 hover:text-slate-950 bg-slate-100 hover:bg-slate-200/80 px-2.5 py-1.5 rounded-lg transition-colors text-left"
                      >
                        {item}
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Column: Style Selection, Settings, & Generation (7 Cols) */}
          <div className="lg:col-span-7 space-y-6">
            {/* Animation Style Selector Cards */}
            <div className="p-6 rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-lg font-bold font-display text-slate-950">
                    Animation Styles
                  </h2>
                  <p className="text-xs text-slate-500 font-medium">
                    Select the motion behavior and temporal dynamics.
                  </p>
                </div>
                <span className="text-xs font-bold text-blue-600 bg-blue-50 px-3 py-1 rounded-full">
                  {currentStyleObj.label}
                </span>
              </div>

              {/* Styles Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5 max-h-[380px] overflow-y-auto pr-1">
                {ANIMATION_STYLES.map((style) => {
                  const Icon = STYLE_ICON_MAP[style.iconName] || Sparkles;
                  const isSelected = selectedStyle === style.id;

                  return (
                    <button
                      key={style.id}
                      type="button"
                      onClick={() => setSelectedStyle(style.id)}
                      className={`flex flex-col text-left p-3.5 rounded-2xl border transition-all duration-200 relative group cursor-pointer ${
                        isSelected
                          ? 'border-blue-600 ring-2 ring-blue-500/20 bg-blue-50/40 shadow-xs'
                          : 'border-slate-200/90 bg-white hover:border-slate-300 hover:bg-slate-50/70'
                      }`}
                    >
                      {style.badge && (
                        <span className="absolute top-2 right-2 text-[9px] font-extrabold uppercase px-1.5 py-0.5 rounded-md bg-blue-600 text-white">
                          {style.badge}
                        </span>
                      )}

                      <div
                        className={`w-8 h-8 rounded-xl flex items-center justify-center mb-2.5 transition-colors ${
                          isSelected
                            ? 'bg-blue-600 text-white'
                            : 'bg-slate-100 text-slate-700 group-hover:bg-slate-200'
                        }`}
                      >
                        <Icon className="w-4 h-4" />
                      </div>

                      <h4 className="text-xs sm:text-sm font-bold text-slate-950 font-display line-clamp-1">
                        {style.label}
                      </h4>
                      <p className="text-[11px] text-slate-500 font-medium line-clamp-2 mt-0.5">
                        {style.tagline}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Customization Parameters (Duration, FPS, Quality, Aspect Ratio) */}
            <div className="p-6 rounded-[28px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-5 font-display">
              <h2 className="text-base font-bold text-slate-950 flex items-center gap-2">
                <Sliders className="w-4 h-4 text-blue-600" />
                <span>GIF Customization & Output Parameters</span>
              </h2>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Duration */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
                    <span>Duration</span>
                    <span className="text-blue-600">{duration} Seconds</span>
                  </label>
                  <div className="grid grid-cols-4 gap-1.5">
                    {([2, 3, 4, 5] as const).map((sec) => (
                      <button
                        key={sec}
                        type="button"
                        onClick={() => setDuration(sec)}
                        className={`py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                          duration === sec
                            ? 'bg-slate-950 text-white shadow-xs'
                            : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        {sec}s
                      </button>
                    ))}
                  </div>
                </div>

                {/* Frame Rate (FPS) */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
                    <span>Frame Rate</span>
                    <span className="text-blue-600">{fps} FPS</span>
                  </label>
                  <div className="grid grid-cols-3 gap-1.5">
                    {([8, 12, 15] as const).map((rate) => (
                      <button
                        key={rate}
                        type="button"
                        onClick={() => setFps(rate)}
                        className={`py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                          fps === rate
                            ? 'bg-slate-950 text-white shadow-xs'
                            : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        {rate} FPS
                      </button>
                    ))}
                  </div>
                </div>

                {/* Quality */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
                    <span>Palette Quality</span>
                    <span className="text-blue-600 capitalize">{quality}</span>
                  </label>
                  <div className="grid grid-cols-2 gap-1.5">
                    {(['standard', 'high'] as const).map((q) => (
                      <button
                        key={q}
                        type="button"
                        onClick={() => setQuality(q)}
                        className={`py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                          quality === q
                            ? 'bg-slate-950 text-white shadow-xs'
                            : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        {q === 'high' ? 'High (600px)' : 'Standard (420px)'}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Aspect Ratio */}
                <div className="space-y-2">
                  <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
                    <span>Aspect Ratio</span>
                    <span className="text-blue-600 uppercase">{aspectRatio}</span>
                  </label>
                  <div className="grid grid-cols-5 gap-1">
                    {(['original', '1:1', '4:5', '9:16', '16:9'] as const).map((ar) => (
                      <button
                        key={ar}
                        type="button"
                        onClick={() => setAspectRatio(ar)}
                        className={`py-2 rounded-xl text-[11px] font-bold transition-all cursor-pointer ${
                          aspectRatio === ar
                            ? 'bg-slate-950 text-white shadow-xs'
                            : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                        }`}
                      >
                        {ar === 'original' ? 'Auto' : ar}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Loop Setting info */}
              <div className="flex items-center justify-between pt-1 border-t border-slate-100 text-xs text-slate-500 font-medium">
                <span className="flex items-center gap-1.5">
                  <Repeat className="w-3.5 h-3.5 text-blue-600" />
                  <span>Playback Looping: Infinite Loop</span>
                </span>
                <span>Output Format: Animated GIF (GIF89a)</span>
              </div>
            </div>

            {/* Generate Action Button & Progress Indicator */}
            <div className="space-y-4">
              {isGenerating ? (
                <div className="p-6 rounded-[28px] bg-white border border-blue-200 shadow-md space-y-4 font-display">
                  <div className="flex items-center justify-between">
                    <span className="text-xs sm:text-sm font-bold text-blue-600 flex items-center gap-2">
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span>{jobStepLabel || 'Synthesizing living animated GIF...'}</span>
                    </span>
                    <span className="text-xs font-black text-slate-900 bg-blue-50 px-2.5 py-1 rounded-lg">
                      {jobProgress}%
                    </span>
                  </div>

                  {/* Progress Bar */}
                  <div className="w-full h-2.5 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-blue-600 to-indigo-600 rounded-full transition-all duration-500 ease-out"
                      style={{ width: `${Math.max(jobProgress, 8)}%` }}
                    />
                  </div>

                  {/* Progress Step Pills */}
                  <div className="grid grid-cols-4 sm:grid-cols-7 gap-1 text-center">
                    {[
                      { id: 'uploading', label: 'Upload' },
                      { id: 'preparing', label: 'Prepare' },
                      { id: 'generating_frames', label: 'Frames' },
                      { id: 'processing_frames', label: 'Tween' },
                      { id: 'encoding_gif', label: 'FFmpeg' },
                      { id: 'optimizing', label: 'Palette' },
                      { id: 'completed', label: 'Done' },
                    ].map((step, idx) => (
                      <div
                        key={idx}
                        className={`py-1 rounded-md text-[10px] font-bold ${
                          jobStage === step.id
                            ? 'bg-blue-600 text-white'
                            : 'bg-slate-100 text-slate-400'
                        }`}
                      >
                        {step.label}
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={handleGenerate}
                  disabled={isGenerating || (mode === 'image-to-gif' && !selectedImage && !imagePreview) || (mode === 'text-to-gif' && !prompt.trim())}
                  className="w-full py-4 sm:py-4.5 rounded-[24px] bg-slate-950 hover:bg-slate-900 text-white font-bold text-base sm:text-lg font-display tracking-tight shadow-lg hover:shadow-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-3 cursor-pointer active:scale-[0.99]"
                >
                  <Sparkles className="w-5 h-5 text-amber-400 fill-amber-400" />
                  <span>Generate Animated GIF</span>
                  <span className="text-xs font-medium bg-white/20 px-2.5 py-1 rounded-full text-white/90">
                    {creditCost} Credit{creditCost > 1 ? 's' : ''}
                  </span>
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Result Showcase Canvas */}
        {result && (
          <div
            ref={resultRef}
            className="p-6 sm:p-8 rounded-[32px] bg-white border border-slate-200/90 shadow-[0_16px_40px_rgba(0,0,0,0.06)] space-y-6"
          >
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100 font-display">
              <div className="space-y-1">
                <span className="text-xs font-extrabold text-emerald-600 bg-emerald-50 px-3 py-1 rounded-full uppercase tracking-wider">
                  Generation Successful
                </span>
                <h3 className="text-2xl font-black text-slate-950 tracking-tight">
                  Animated GIF Preview
                </h3>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2.5">
                <button
                  type="button"
                  onClick={() => handleDownload(result.jobId)}
                  className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs sm:text-sm font-bold shadow-md hover:shadow-lg transition-all flex items-center gap-2 cursor-pointer active:scale-95"
                >
                  <Download className="w-4 h-4" />
                  <span>Download GIF</span>
                </button>

                <button
                  type="button"
                  onClick={handleResetForNew}
                  className="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs sm:text-sm font-bold transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>Create Another</span>
                </button>
              </div>
            </div>

            {/* Display Media Canvas */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-6 items-center">
              {/* Media Container (7 cols) */}
              <div className="md:col-span-7 flex flex-col items-center">
                <div className="relative max-h-[500px] rounded-2xl overflow-hidden bg-slate-950 border border-slate-200 shadow-lg flex items-center justify-center">
                  <img
                    src={showOriginalComparison && result.originalImageUrl ? result.originalImageUrl : result.gifUrl}
                    alt="Animated GIF Result"
                    className="max-h-[500px] w-auto object-contain"
                  />
                  {showOriginalComparison && (
                    <div className="absolute top-3 left-3 bg-slate-900/80 backdrop-blur-xs text-white text-[11px] font-bold px-2.5 py-1 rounded-md">
                      Original Photograph
                    </div>
                  )}
                </div>

                {/* Before/After Toggle if Original Exists */}
                {result.originalImageUrl && (
                  <div className="mt-3 flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setShowOriginalComparison((prev) => !prev)}
                      className="text-xs font-bold text-slate-700 hover:text-slate-950 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors cursor-pointer flex items-center gap-1.5 font-display"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      <span>{showOriginalComparison ? 'View Animated GIF' : 'Compare with Original Photo'}</span>
                    </button>
                  </div>
                )}
              </div>

              {/* Technical Specifications & Details (5 cols) */}
              <div className="md:col-span-5 space-y-4 font-display">
                <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-3">
                  <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                    File Specifications
                  </h4>

                  <div className="grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <span className="text-slate-500 block">Resolution</span>
                      <span className="font-bold text-slate-950">
                        {result.width} × {result.height} px
                      </span>
                    </div>

                    <div>
                      <span className="text-slate-500 block">File Size</span>
                      <span className="font-bold text-slate-950">
                        {result.fileSizeFormatted}
                      </span>
                    </div>

                    <div>
                      <span className="text-slate-500 block">Duration</span>
                      <span className="font-bold text-slate-950">
                        {result.duration} Seconds
                      </span>
                    </div>

                    <div>
                      <span className="text-slate-500 block">Frame Rate</span>
                      <span className="font-bold text-slate-950">
                        {result.fps} FPS ({result.frameCount} frames)
                      </span>
                    </div>

                    <div>
                      <span className="text-slate-500 block">Style</span>
                      <span className="font-bold text-slate-950 capitalize">
                        {result.style.replace('_', ' ')}
                      </span>
                    </div>

                    <div>
                      <span className="text-slate-500 block">Looping</span>
                      <span className="font-bold text-emerald-600">
                        Infinite Loop
                      </span>
                    </div>
                  </div>
                </div>

                {result.prompt && (
                  <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 text-xs">
                    <span className="text-slate-500 block font-bold mb-1">Animation Prompt</span>
                    <p className="text-slate-800 italic">"{result.prompt}"</p>
                  </div>
                )}

                <button
                  type="button"
                  onClick={handleGenerate}
                  className="w-full py-3 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>Regenerate Animation</span>
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Generation History Gallery */}
        {history.length > 0 && (
          <div className="p-6 sm:p-8 rounded-[32px] bg-white border border-slate-200/90 shadow-[0_4px_20px_rgba(0,0,0,0.05)] space-y-6">
            <div className="flex items-center justify-between font-display">
              <div>
                <h3 className="text-xl font-black text-slate-950 tracking-tight">
                  Your Recent GIF Creations
                </h3>
                <p className="text-xs text-slate-500 font-medium">
                  Previous animated GIFs stored and ready to download.
                </p>
              </div>
              <span className="text-xs font-bold text-slate-600 bg-slate-100 px-3 py-1 rounded-full">
                {history.length} Creations
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
              {history.map((item) => (
                <div
                  key={item.id}
                  className="rounded-2xl border border-slate-200/90 overflow-hidden bg-slate-950 flex flex-col group hover:shadow-md transition-all relative"
                >
                  <div className="aspect-square relative overflow-hidden bg-slate-900">
                    <img
                      src={item.gifUrl}
                      alt={item.prompt || 'Animated GIF'}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />

                    {/* Download Overlay on Hover */}
                    <button
                      type="button"
                      onClick={() => handleDownload(item.id)}
                      className="absolute inset-0 bg-slate-950/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1.5 text-white text-xs font-bold cursor-pointer"
                    >
                      <Download className="w-5 h-5" />
                      <span>Download</span>
                    </button>
                  </div>

                  <div className="p-2.5 bg-white text-slate-900 space-y-1 font-display">
                    <div className="flex items-center justify-between text-[10px] text-slate-500 font-medium">
                      <span className="capitalize">{item.style.replace('_', ' ')}</span>
                      <span>{item.duration}s • {item.fps}fps</span>
                    </div>
                    <p className="text-xs font-bold line-clamp-1 text-slate-950">
                      {item.prompt || 'Animated Image'}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
