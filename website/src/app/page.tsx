'use client';

import React, { useState, useEffect } from 'react';
import { Sparkles, AlertCircle, ArrowDown, ShieldCheck, Zap } from 'lucide-react';
import UrlInput from '@/components/UrlInput';
import MediaInspector from '@/components/MediaInspector';
import HistoryList from '@/components/HistoryList';
import SupportedPlatforms from '@/components/SupportedPlatforms';
import FeaturesGrid from '@/components/FeaturesGrid';
import FaqSection from '@/components/FaqSection';
import { MediaInfo, HistoryItem } from '@/lib/types';

export default function HomePage() {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [mediaInfo, setMediaInfo] = useState<MediaInfo | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [history, setHistory] = useState<HistoryItem[]>([]);
  const [currentUrl, setCurrentUrl] = useState<string>('');

  // Load history from localStorage
  useEffect(() => {
    try {
      const saved = localStorage.getItem('mediafetch_history');
      if (saved) {
        setHistory(JSON.parse(saved));
      }
    } catch (e) {
      console.warn('Failed to load history:', e);
    }
  }, []);

  // Save history helper
  const handleSaveHistory = (item: HistoryItem) => {
    setHistory((prev) => {
      const filtered = prev.filter((i) => i.url !== item.url);
      const updated = [item, ...filtered].slice(0, 12);
      try {
        localStorage.setItem('mediafetch_history', JSON.stringify(updated));
      } catch (e) {
        // ignore
      }
      return updated;
    });
  };

  const handleClearHistory = () => {
    setHistory([]);
    try {
      localStorage.removeItem('mediafetch_history');
    } catch (e) {}
  };

  const handleRemoveHistoryItem = (id: string) => {
    setHistory((prev) => {
      const updated = prev.filter((i) => i.id !== id);
      try {
        localStorage.setItem('mediafetch_history', JSON.stringify(updated));
      } catch (e) {}
      return updated;
    });
  };

  const handleFetchMedia = async (url: string) => {
    setIsLoading(true);
    setError(null);
    setCurrentUrl(url);

    try {
      const res = await fetch('/api/info', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url }),
      });

      const json = await res.json();

      if (!json.success || !json.data) {
        throw new Error(json.error || 'Failed to fetch media details');
      }

      setMediaInfo(json.data);
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred. Please try again.');
      setMediaInfo(null);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen bg-radial-gradient">
      {/* Hero Container */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-16 pb-12 text-center">
        {/* Release / Status Pill */}
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white/5 border border-white/10 text-xs font-medium text-gray-300 mb-6 shadow-inner">
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
          <span>Vercel Serverless Ready • Free & Fast</span>
        </div>

        {/* Title */}
        <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight text-white max-w-3xl mx-auto leading-tight sm:leading-tight">
          Download Web Media{' '}
          <span className="bg-gradient-to-r from-indigo-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
            Without Limits.
          </span>
        </h1>

        <p className="text-base sm:text-lg text-gray-400 max-w-2xl mx-auto mt-4 leading-relaxed">
          The web companion to MediaFetch for macOS. Paste links from YouTube, TikTok,
          Instagram, X, and more to inspect metadata and download high-quality MP4 or MP3 instantly.
        </p>

        {/* Input Bar */}
        <div className="mt-8">
          <UrlInput
            onFetch={handleFetchMedia}
            isLoading={isLoading}
            initialUrl={currentUrl}
          />
        </div>

        {/* Error Alert */}
        {error && (
          <div className="max-w-2xl mx-auto mt-6 p-4 rounded-2xl bg-red-500/10 border border-red-500/20 text-red-400 text-sm flex items-start gap-3 text-left">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
            <div>
              <p className="font-medium">Fetch Failed</p>
              <p className="text-xs text-red-400/80 mt-0.5">{error}</p>
            </div>
          </div>
        )}

        {/* Media Inspector Preview */}
        {mediaInfo && (
          <MediaInspector
            media={mediaInfo}
            onDownloaded={handleSaveHistory}
          />
        )}

        {/* Download History */}
        <HistoryList
          history={history}
          onSelectUrl={handleFetchMedia}
          onClear={handleClearHistory}
          onRemoveItem={handleRemoveHistoryItem}
        />
      </div>

      {/* Supported Platforms Grid */}
      <SupportedPlatforms />

      {/* Features Grid */}
      <FeaturesGrid />

      {/* FAQ Section */}
      <FaqSection />
    </div>
  );
}
