'use client';

import React, { useState } from 'react';
import {
  Video,
  Music,
  Download,
  Scissors,
  ExternalLink,
  CheckCircle2,
  Clock,
  Sparkles,
  Play,
  FileCheck,
  Share2,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { MediaInfo, MediaFormat, HistoryItem } from '@/lib/types';
import { sanitizeFilename } from '@/lib/utils';

interface MediaInspectorProps {
  media: MediaInfo;
  onDownloaded: (item: HistoryItem) => void;
}

export default function MediaInspector({ media, onDownloaded }: MediaInspectorProps) {
  const [activeTab, setActiveTab] = useState<'video' | 'audio'>('video');
  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [downloadProgress, setDownloadProgress] = useState<number>(0);
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);

  // Trim range states (matching macOS MediaFetch desktop trim feature)
  const [enableTrim, setEnableTrim] = useState<boolean>(false);
  const [trimStart, setTrimStart] = useState<string>('00:00');
  const [trimEnd, setTrimEnd] = useState<string>(media.durationFormatted || '00:00');

  const videoFormats = media.formats.filter((f) => f.type === 'video');
  const audioFormats = media.formats.filter((f) => f.type === 'audio');

  const currentFormats = activeTab === 'video' ? videoFormats : audioFormats;

  const triggerConfetti = () => {
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 },
      colors: ['#6366f1', '#a855f7', '#ec4899', '#3b82f6'],
    });
  };

  const handleDownload = async (format: MediaFormat) => {
    setDownloadingId(format.id);
    setDownloadProgress(10);
    setDownloadSuccess(null);

    // Smooth simulated progress indicator for user feedback
    const interval = setInterval(() => {
      setDownloadProgress((prev) => {
        if (prev >= 90) {
          clearInterval(interval);
          return 90;
        }
        return prev + 25;
      });
    }, 150);

    try {
      const filename = `${sanitizeFilename(media.title)}_${format.resolution || format.quality || 'media'}`;
      let downloadUrl = '';

      if (format.isDirect && format.url.startsWith('http')) {
        // Stream directly through download API route with proper attachment header
        downloadUrl = `/api/download?url=${encodeURIComponent(format.url)}&filename=${encodeURIComponent(filename)}&ext=${format.extension}`;
      } else {
        // Fallback or external link
        downloadUrl = format.url;
      }

      // Trigger browser download via invisible link
      const a = document.createElement('a');
      a.href = downloadUrl;
      a.download = `${filename}.${format.extension}`;
      a.target = '_blank';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);

      clearInterval(interval);
      setDownloadProgress(100);
      setDownloadSuccess(`Downloaded ${format.label}!`);
      triggerConfetti();

      // Save to download history
      onDownloaded({
        id: `${media.url}_${Date.now()}`,
        title: media.title,
        author: media.author,
        thumbnail: media.thumbnail,
        platform: media.platform,
        url: media.url,
        downloadedAt: Date.now(),
        formatLabel: `${format.label} (${format.extension.toUpperCase()})`,
      });

      setTimeout(() => {
        setDownloadingId(null);
        setDownloadProgress(0);
      }, 2500);
    } catch (err) {
      clearInterval(interval);
      setDownloadingId(null);
      setDownloadProgress(0);
      alert('Could not start download. Please try another quality.');
    }
  };

  return (
    <div className="w-full max-w-4xl mx-auto mt-8 glass-panel rounded-3xl p-5 sm:p-7 shadow-2xl border border-white/10 animate-fadeIn">
      {/* Top Media Info Header */}
      <div className="flex flex-col md:flex-row gap-6 items-start">
        {/* Thumbnail Preview */}
        <div className="relative w-full md:w-80 aspect-video rounded-2xl overflow-hidden bg-black/50 border border-white/10 shrink-0 group">
          {media.thumbnail ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={media.thumbnail}
              alt={media.title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
          ) : (
            <div className="w-full h-full flex flex-col items-center justify-center text-gray-500">
              <Video className="w-12 h-12 mb-2 opacity-50" />
              <span className="text-xs">Preview Media</span>
            </div>
          )}

          {/* Duration Badge */}
          {media.durationFormatted && (
            <div className="absolute bottom-2 right-2 px-2 py-0.5 rounded-md bg-black/80 backdrop-blur-md text-white text-[11px] font-mono font-medium flex items-center gap-1 border border-white/10">
              <Clock className="w-3 h-3 text-indigo-400" />
              {media.durationFormatted}
            </div>
          )}

          {/* Platform Watermark Badge */}
          <div className="absolute top-2 left-2 px-2.5 py-1 rounded-lg bg-black/70 backdrop-blur-md text-white text-xs font-semibold uppercase tracking-wider border border-white/10">
            {media.platformName}
          </div>
        </div>

        {/* Video Title & Meta details */}
        <div className="flex-1 min-w-0 flex flex-col justify-between">
          <div>
            <h2 className="text-lg sm:text-xl font-bold text-white leading-snug line-clamp-2 tracking-tight">
              {media.title}
            </h2>

            <div className="flex items-center gap-3 mt-2 text-sm text-gray-400">
              <span className="font-medium text-gray-300 truncate">
                {media.author}
              </span>
              {media.authorUrl && (
                <a
                  href={media.authorUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="text-xs text-indigo-400 hover:text-indigo-300 flex items-center gap-1 hover:underline shrink-0"
                >
                  Visit Channel
                  <ExternalLink className="w-3 h-3" />
                </a>
              )}
            </div>
          </div>

          {/* Trim Range Simulator (Matching macOS desktop feature) */}
          <div className="mt-4 p-3 rounded-2xl bg-white/[0.03] border border-white/5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs font-medium text-gray-300">
                <Scissors className="w-3.5 h-3.5 text-indigo-400" />
                <span>Custom Trim Range</span>
                <span className="text-[10px] text-indigo-400/80 bg-indigo-500/10 px-1.5 py-0.5 rounded">
                  Desktop Feature
                </span>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input
                  type="checkbox"
                  checked={enableTrim}
                  onChange={(e) => setEnableTrim(e.target.checked)}
                  className="sr-only peer"
                />
                <div className="w-8 h-4.5 bg-gray-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-3.5 after:w-3.5 after:transition-all peer-checked:bg-indigo-600"></div>
              </label>
            </div>

            {enableTrim && (
              <div className="mt-3 grid grid-cols-2 gap-3 text-xs animate-fadeIn">
                <div>
                  <label className="text-gray-400 block mb-1">Start Time</label>
                  <input
                    type="text"
                    value={trimStart}
                    onChange={(e) => setTrimStart(e.target.value)}
                    placeholder="00:00"
                    className="w-full px-3 py-1.5 rounded-lg bg-black/40 border border-white/10 text-white font-mono text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="text-gray-400 block mb-1">End Time</label>
                  <input
                    type="text"
                    value={trimEnd}
                    onChange={(e) => setTrimEnd(e.target.value)}
                    placeholder="00:00"
                    className="w-full px-3 py-1.5 rounded-lg bg-black/40 border border-white/10 text-white font-mono text-xs focus:outline-none focus:border-indigo-500"
                  />
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Mode Switcher Tabs (Video vs Audio) */}
      <div className="mt-8 border-t border-white/10 pt-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2 p-1 rounded-xl bg-black/40 border border-white/10">
            <button
              onClick={() => setActiveTab('video')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === 'video'
                  ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <Video className="w-3.5 h-3.5" />
              Video (MP4)
              <span className="px-1.5 py-0.2 rounded-full bg-white/20 text-[10px]">
                {videoFormats.length}
              </span>
            </button>

            <button
              onClick={() => setActiveTab('audio')}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === 'audio'
                  ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              <Music className="w-3.5 h-3.5" />
              Audio (MP3 / M4A)
              <span className="px-1.5 py-0.2 rounded-full bg-white/20 text-[10px]">
                {audioFormats.length}
              </span>
            </button>
          </div>

          <span className="text-xs text-gray-500 hidden sm:inline">
            Direct Serverless CDN Streams
          </span>
        </div>

        {/* Formats Grid / List */}
        <div className="space-y-2.5">
          {currentFormats.length === 0 ? (
            <div className="text-center py-8 text-gray-500 text-sm">
              No direct {activeTab} streams found. Switch to the other tab or check source URL.
            </div>
          ) : (
            currentFormats.map((format) => {
              const isCurrentDownloading = downloadingId === format.id;

              return (
                <div
                  key={format.id}
                  className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-3.5 sm:p-4 rounded-2xl bg-white/[0.03] hover:bg-white/[0.06] border border-white/5 hover:border-white/15 transition-all group"
                >
                  <div className="flex items-center space-x-3 min-w-0">
                    <div className="w-9 h-9 rounded-xl bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 flex items-center justify-center shrink-0">
                      {format.type === 'video' ? (
                        <Video className="w-4 h-4" />
                      ) : (
                        <Music className="w-4 h-4" />
                      )}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-sm text-white truncate">
                          {format.label}
                        </span>
                        <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-white/10 text-gray-300 font-medium">
                          {format.extension}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-xs text-gray-400 mt-0.5">
                        {format.resolution && <span>Resolution: {format.resolution}</span>}
                        {format.filesizeFormatted && (
                          <>
                            <span>•</span>
                            <span>{format.filesizeFormatted}</span>
                          </>
                        )}
                        <span>•</span>
                        <span className="text-emerald-400">Ready</span>
                      </div>
                    </div>
                  </div>

                  {/* Download Trigger */}
                  <div className="flex items-center gap-2 sm:self-center">
                    <button
                      onClick={() => handleDownload(format)}
                      disabled={isCurrentDownloading}
                      className="w-full sm:w-auto flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white font-medium text-xs sm:text-sm px-5 py-2.5 rounded-xl shadow-md shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all cursor-pointer disabled:opacity-50 active:scale-95"
                    >
                      {isCurrentDownloading ? (
                        <>
                          <div className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                          <span>Preparing ({downloadProgress}%)</span>
                        </>
                      ) : (
                        <>
                          <Download className="w-3.5 h-3.5" />
                          <span>Download {format.extension.toUpperCase()}</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Simulated Progress bar if active */}
        {downloadingId && (
          <div className="mt-4 p-3 rounded-xl bg-indigo-500/10 border border-indigo-500/20 animate-fadeIn">
            <div className="flex justify-between text-xs text-indigo-300 mb-1.5 font-medium">
              <span>Streaming file from CDN...</span>
              <span>{downloadProgress}%</span>
            </div>
            <div className="w-full h-1.5 bg-black/40 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-indigo-500 to-pink-500 transition-all duration-300"
                style={{ width: `${downloadProgress}%` }}
              />
            </div>
          </div>
        )}

        {/* Success toast notification */}
        {downloadSuccess && (
          <div className="mt-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs flex items-center gap-2 animate-fadeIn">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{downloadSuccess} Check your browser Downloads folder.</span>
          </div>
        )}
      </div>
    </div>
  );
}
