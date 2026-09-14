'use client';

import React, { useState, useEffect } from 'react';
import {
  Search,
  Clipboard,
  X,
  ArrowRight,
  Loader2,
  Video,
} from 'lucide-react';
import {
  YouTubeIcon,
  TikTokIcon,
  XTwitterIcon,
  InstagramIcon,
} from './PlatformIcons';
import { detectPlatform } from '@/lib/utils';
import { MediaPlatform } from '@/lib/types';

interface UrlInputProps {
  onFetch: (url: string) => void;
  isLoading: boolean;
  initialUrl?: string;
}

export default function UrlInput({ onFetch, isLoading, initialUrl = '' }: UrlInputProps) {
  const [url, setUrl] = useState(initialUrl);
  const [detected, setDetected] = useState<{ platform: MediaPlatform; platformName: string }>({
    platform: 'generic',
    platformName: '',
  });

  useEffect(() => {
    if (url.trim()) {
      setDetected(detectPlatform(url));
    } else {
      setDetected({ platform: 'generic', platformName: '' });
    }
  }, [url]);

  const handlePaste = async () => {
    try {
      if (navigator.clipboard) {
        const text = await navigator.clipboard.readText();
        if (text) {
          setUrl(text);
          onFetch(text);
        }
      }
    } catch (err) {
      console.warn('Clipboard read error:', err);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (url.trim()) {
      onFetch(url.trim());
    }
  };

  const handleClear = () => {
    setUrl('');
  };

  const renderPlatformBadge = () => {
    if (!detected.platformName || !url.trim()) return null;

    let icon = <Video className="w-3.5 h-3.5" />;
    let color = 'text-indigo-400 bg-indigo-500/10 border-indigo-500/20';

    if (detected.platform === 'youtube') {
      icon = <YouTubeIcon className="w-3.5 h-3.5 text-red-500" />;
      color = 'text-red-400 bg-red-500/10 border-red-500/20';
    } else if (detected.platform === 'tiktok') {
      icon = <TikTokIcon className="w-3.5 h-3.5 text-cyan-400" />;
      color = 'text-cyan-400 bg-cyan-500/10 border-cyan-500/20';
    } else if (detected.platform === 'twitter') {
      icon = <XTwitterIcon className="w-3.5 h-3.5 text-sky-400" />;
      color = 'text-sky-400 bg-sky-500/10 border-sky-500/20';
    } else if (detected.platform === 'instagram') {
      icon = <InstagramIcon className="w-3.5 h-3.5 text-pink-400" />;
      color = 'text-pink-400 bg-pink-500/10 border-pink-500/20';
    }

    return (
      <span
        className={`hidden sm:inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-lg border ${color} transition-all`}
      >
        {icon}
        {detected.platformName}
      </span>
    );
  };

  return (
    <form onSubmit={handleSubmit} className="w-full max-w-3xl mx-auto">
      <div className="relative group">
        {/* Glow ambient background effect */}
        <div className="absolute -inset-1 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 rounded-3xl blur-xl opacity-25 group-hover:opacity-40 transition duration-500 group-focus-within:opacity-60" />

        <div className="relative flex flex-col sm:flex-row items-center bg-[#131622]/90 backdrop-blur-2xl border border-white/10 group-focus-within:border-indigo-500/50 rounded-2xl p-2 shadow-2xl transition-all">
          <div className="flex items-center w-full pl-3 pr-2 py-1.5 sm:py-0">
            <Search className="w-5 h-5 text-gray-500 group-focus-within:text-indigo-400 transition-colors shrink-0 mr-3" />

            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="Paste media link from YouTube, TikTok, Instagram, X..."
              className="w-full bg-transparent text-sm sm:text-base text-white placeholder-gray-500 focus:outline-none focus:ring-0"
              disabled={isLoading}
            />

            {renderPlatformBadge()}

            {url && (
              <button
                type="button"
                onClick={handleClear}
                className="p-1.5 text-gray-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors ml-1 shrink-0"
                title="Clear input"
              >
                <X className="w-4 h-4" />
              </button>
            )}

            <button
              type="button"
              onClick={handlePaste}
              className="hidden sm:inline-flex items-center gap-1.5 text-xs font-medium text-gray-300 hover:text-white bg-white/5 hover:bg-white/10 border border-white/10 px-2.5 py-1.5 rounded-xl ml-2 shrink-0 transition-all cursor-pointer active:scale-95"
              title="Paste from clipboard"
            >
              <Clipboard className="w-3.5 h-3.5 text-indigo-400" />
              Paste
            </button>
          </div>

          <div className="w-full sm:w-auto mt-2 sm:mt-0">
            <button
              type="submit"
              disabled={isLoading || !url.trim()}
              className="w-full sm:w-auto flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-600 via-indigo-500 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white font-semibold text-sm px-6 py-3 rounded-xl shadow-lg shadow-indigo-600/25 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-95 cursor-pointer"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>Fetching...</span>
                </>
              ) : (
                <>
                  <span>Fetch Media</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Quick helper hints */}
      <div className="mt-3 flex items-center justify-center gap-2 text-xs text-gray-500">
        <span>Supported:</span>
        <span className="text-gray-400">YouTube</span>
        <span>•</span>
        <span className="text-gray-400">TikTok</span>
        <span>•</span>
        <span className="text-gray-400">Instagram</span>
        <span>•</span>
        <span className="text-gray-400">X (Twitter)</span>
        <span>•</span>
        <span className="text-gray-400">Reddit</span>
        <span>•</span>
        <span className="text-gray-400">Direct MP4/MP3</span>
      </div>
    </form>
  );
}
