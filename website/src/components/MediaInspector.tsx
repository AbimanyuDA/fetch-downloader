'use client';

import React, { useState, useEffect } from 'react';
import {
  Video,
  Music,
  Download,
  Scissors,
  ExternalLink,
  CheckCircle2,
  Clock,
  AlertCircle,
  Loader2,
  RotateCcw,
} from 'lucide-react';
import confetti from 'canvas-confetti';
import { MediaInfo, MediaFormat, HistoryItem } from '@/lib/types';
import { sanitizeFilename, triggerBrowserDownload } from '@/lib/utils';
import {
  parseTimeToSeconds,
  secondsToTimeString,
  trimAudioFromUrl,
  trimVideoFromUrl,
} from '@/lib/mediaTrimmer';

interface MediaInspectorProps {
  media: MediaInfo;
  onDownloaded: (item: HistoryItem) => void;
}

export default function MediaInspector({ media, onDownloaded }: MediaInspectorProps) {
  const [activeTab, setActiveTab] = useState<'video' | 'audio'>('video');
  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [downloadProgress, setDownloadProgress] = useState<number>(0);
  const [downloadStatusText, setDownloadStatusText] = useState<string>('');
  const [downloadSuccess, setDownloadSuccess] = useState<string | null>(null);
  const [downloadError, setDownloadError] = useState<string | null>(null);

  // Total duration in seconds
  const totalDuration = media.duration && media.duration > 0 ? media.duration : 180;

  // Trim range states
  const [enableTrim, setEnableTrim] = useState<boolean>(false);
  const [startSeconds, setStartSeconds] = useState<number>(0);
  const [endSeconds, setEndSeconds] = useState<number>(totalDuration);
  const [trimStartText, setTrimStartText] = useState<string>('00:00');
  const [trimEndText, setTrimEndText] = useState<string>(secondsToTimeString(totalDuration));

  // Sync initial end time when media changes
  useEffect(() => {
    const dur = media.duration && media.duration > 0 ? media.duration : 180;
    setStartSeconds(0);
    setEndSeconds(dur);
    setTrimStartText('00:00');
    setTrimEndText(secondsToTimeString(dur));
  }, [media]);

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

  // Adjust time helpers
  const handleAdjustStart = (delta: number) => {
    const next = Math.max(0, Math.min(endSeconds - 1, startSeconds + delta));
    setStartSeconds(next);
    setTrimStartText(secondsToTimeString(next));
  };

  const handleAdjustEnd = (delta: number) => {
    const next = Math.max(startSeconds + 1, Math.min(totalDuration, endSeconds + delta));
    setEndSeconds(next);
    setTrimEndText(secondsToTimeString(next));
  };

  const handleStartTextBlur = () => {
    const parsed = parseTimeToSeconds(trimStartText);
    const clamped = Math.max(0, Math.min(endSeconds - 1, parsed));
    setStartSeconds(clamped);
    setTrimStartText(secondsToTimeString(clamped));
  };

  const handleEndTextBlur = () => {
    const parsed = parseTimeToSeconds(trimEndText);
    const clamped = Math.max(startSeconds + 1, Math.min(totalDuration, parsed));
    setEndSeconds(clamped);
    setTrimEndText(secondsToTimeString(clamped));
  };

  const handleResetTrim = () => {
    setStartSeconds(0);
    setEndSeconds(totalDuration);
    setTrimStartText('00:00');
    setTrimEndText(secondsToTimeString(totalDuration));
  };

  const clipDurationSec = Math.max(0, endSeconds - startSeconds);

  const handleDownload = async (format: MediaFormat) => {
    setDownloadingId(format.id);
    setDownloadProgress(5);
    setDownloadStatusText('Connecting to stream engine...');
    setDownloadSuccess(null);
    setDownloadError(null);

    try {
      const filename = `${sanitizeFilename(media.title)}_${format.resolution || format.quality || 'media'}`;
      let finalDownloadUrl = '';

      // Validate trim bounds if enabled
      let startSec = startSeconds;
      let endSec = endSeconds;
      if (enableTrim) {
        startSec = parseTimeToSeconds(trimStartText);
        endSec = parseTimeToSeconds(trimEndText);
        if (endSec <= startSec) {
          throw new Error('End Time must be greater than Start Time.');
        }
      }

      // If direct stream URL is already known and doesn't require backend conversion
      if (format.isDirect && format.url.startsWith('http') && !format.url.includes('youtube.com')) {
        finalDownloadUrl = format.url;
      } else {
        // Step 1: Initialize serverless conversion task
        setDownloadStatusText('Preparing high-speed media stream...');
        const initRes = await fetch('/api/download', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            action: 'init',
            url: media.url,
            resolution: format.resolution || (format.type === 'audio' ? 'mp3' : '720p'),
            format: format.type === 'audio' ? 'mp3' : (format.resolution || '720'),
            extension: format.extension,
          }),
        });

        const initJson = await initRes.json();
        if (!initJson.success) {
          throw new Error(initJson.error || 'Could not initialize download. Please try another quality.');
        }

        if (initJson.downloadUrl) {
          finalDownloadUrl = initJson.downloadUrl;
        } else if (initJson.progressUrl) {
          // Step 2: Poll progress without blocking Vercel serverless execution
          let resolved = false;
          let attempts = 0;
          const maxAttempts = 60;

          while (!resolved && attempts < maxAttempts) {
            attempts++;
            await new Promise((r) => setTimeout(r, 1500));

            try {
              const pollRes = await fetch('/api/download', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  action: 'progress',
                  progressUrl: initJson.progressUrl,
                }),
              });

              if (pollRes.ok) {
                const pollJson = await pollRes.json();
                if (pollJson.success) {
                  if (typeof pollJson.progress === 'number' && pollJson.progress > 0) {
                    setDownloadProgress(Math.min(95, pollJson.progress));
                  }
                  if (pollJson.text) {
                    setDownloadStatusText(`${pollJson.text} (${pollJson.progress || 0}%)`);
                  }

                  if (pollJson.finished && pollJson.downloadUrl) {
                    finalDownloadUrl = pollJson.downloadUrl;
                    resolved = true;
                    break;
                  }
                }
              }
            } catch (pollErr) {
              // Retry on next interval
            }
          }

          if (!resolved || !finalDownloadUrl) {
            throw new Error('Conversion took longer than expected. Please select another quality or try again.');
          }
        }
      }

      // Safety check: JANGAN PERNAH gunakan link youtube.com sebagai final download
      if (finalDownloadUrl.includes('youtube.com/watch') || finalDownloadUrl.includes('youtu.be/')) {
        throw new Error('Stream URL is not direct. Please choose another format option.');
      }

      // Step 3: Handle Trim Range if enabled
      if (enableTrim) {
        setDownloadProgress(95);

        if (format.type === 'audio') {
          setDownloadStatusText(`Trimming audio (${trimStartText} to ${trimEndText})...`);
          const trimmedBlob = await trimAudioFromUrl(finalDownloadUrl, startSec, endSec, (msg) => {
            setDownloadStatusText(msg);
          });

          const blobUrl = URL.createObjectURL(trimmedBlob);
          const safeTrimFilename = `${filename}_trimmed_${trimStartText.replace(':', '-')}_to_${trimEndText.replace(':', '-')}.wav`;

          triggerBrowserDownload(blobUrl, safeTrimFilename);

          setDownloadProgress(100);
          setDownloadSuccess(`Downloaded trimmed audio (${trimStartText} to ${trimEndText})!`);
          triggerConfetti();

          onDownloaded({
            id: `${media.url}_${Date.now()}`,
            title: `${media.title} [Trimmed ${trimStartText}-${trimEndText}]`,
            author: media.author,
            thumbnail: media.thumbnail,
            platform: media.platform,
            url: media.url,
            downloadedAt: Date.now(),
            formatLabel: `Trimmed Audio (${trimStartText}-${trimEndText})`,
          });

          setTimeout(() => {
            setDownloadingId(null);
            setDownloadProgress(0);
            setDownloadStatusText('');
          }, 3500);
          return;
        } else {
          // Video trimming
          setDownloadStatusText(`Trimming video (${trimStartText} to ${trimEndText})...`);
          try {
            const { blob: trimmedVideoBlob, extension: vidExt } = await trimVideoFromUrl(
              finalDownloadUrl,
              startSec,
              endSec,
              (msg) => setDownloadStatusText(msg)
            );

            const blobUrl = URL.createObjectURL(trimmedVideoBlob);
            const safeTrimFilename = `${filename}_trimmed_${trimStartText.replace(':', '-')}_to_${trimEndText.replace(':', '-')}.${vidExt}`;

            triggerBrowserDownload(blobUrl, safeTrimFilename);

            setDownloadProgress(100);
            setDownloadSuccess(`Downloaded trimmed video (${trimStartText} to ${trimEndText})!`);
            triggerConfetti();

            onDownloaded({
              id: `${media.url}_${Date.now()}`,
              title: `${media.title} [Trimmed ${trimStartText}-${trimEndText}]`,
              author: media.author,
              thumbnail: media.thumbnail,
              platform: media.platform,
              url: media.url,
              downloadedAt: Date.now(),
              formatLabel: `Trimmed Video (${trimStartText}-${trimEndText})`,
            });

            setTimeout(() => {
              setDownloadingId(null);
              setDownloadProgress(0);
              setDownloadStatusText('');
            }, 3500);
            return;
          } catch (vidErr: any) {
            // DO NOT silently download full video! Report error to user
            throw new Error(`Video trimming failed: ${vidErr.message || 'Stream format could not be trimmed'}. You can disable "Custom Trim Range" to download the full video, or switch to Audio to trim MP3/WAV.`);
          }
        }
      }

      // Step 4: Standard Full Download directly to Mac Downloads folder
      setDownloadProgress(100);
      setDownloadStatusText('Starting download to your Mac...');

      triggerBrowserDownload(finalDownloadUrl, `${filename}.${format.extension}`);

      setDownloadSuccess(`Downloaded ${format.label}! Check your Mac Downloads folder.`);
      triggerConfetti();

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
        setDownloadStatusText('');
      }, 3500);
    } catch (err: any) {
      setDownloadingId(null);
      setDownloadProgress(0);
      setDownloadStatusText('');
      setDownloadError(err.message || 'Could not complete download. Please try another quality or format.');
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
        <div className="flex-1 min-w-0 flex flex-col justify-between w-full">
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

          {/* Trim Range Simulator (Enhanced with Sliders & Quick Step) */}
          <div className={`mt-4 p-4 rounded-2xl border transition-all ${
            enableTrim ? 'bg-indigo-500/10 border-indigo-500/40 shadow-lg shadow-indigo-500/10' : 'bg-white/[0.03] border-white/5'
          }`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs font-semibold text-gray-200">
                <Scissors className={`w-4 h-4 ${enableTrim ? 'text-indigo-400' : 'text-gray-400'}`} />
                <span>Custom Trim Range</span>
                <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${
                  enableTrim ? 'bg-indigo-500 text-white' : 'bg-white/10 text-gray-400'
                }`}>
                  {enableTrim ? 'Active' : 'Disabled'}
                </span>
              </div>
              <div className="flex items-center gap-3">
                {enableTrim && (
                  <button
                    onClick={handleResetTrim}
                    className="text-[11px] text-gray-400 hover:text-white flex items-center gap-1 hover:underline cursor-pointer"
                  >
                    <RotateCcw className="w-3 h-3" />
                    Reset
                  </button>
                )}
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={enableTrim}
                    onChange={(e) => setEnableTrim(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-9 h-5 bg-gray-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-indigo-600"></div>
                </label>
              </div>
            </div>

            {enableTrim && (
              <div className="mt-3.5 pt-3 border-t border-white/10 space-y-3.5 text-xs animate-fadeIn">
                {/* Visual Timeline Bar */}
                <div className="space-y-1.5">
                  <div className="flex justify-between text-[11px] text-gray-400 font-mono">
                    <span>Start: {trimStartText}</span>
                    <span className="text-indigo-300 font-semibold">
                      Clip: {secondsToTimeString(clipDurationSec)} ({Math.round((clipDurationSec / totalDuration) * 100)}%)
                    </span>
                    <span>End: {trimEndText}</span>
                  </div>

                  {/* Dual Slider Timeline */}
                  <div className="relative w-full h-3 bg-black/60 rounded-full overflow-hidden border border-white/10">
                    <div
                      className="absolute top-0 bottom-0 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full opacity-80"
                      style={{
                        left: `${(startSeconds / totalDuration) * 100}%`,
                        width: `${Math.max(2, ((endSeconds - startSeconds) / totalDuration) * 100)}%`,
                      }}
                    />
                  </div>
                </div>

                {/* Pickers with Stepper Buttons */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {/* Start Time Section */}
                  <div className="p-3 rounded-xl bg-black/40 border border-white/10">
                    <label className="text-gray-300 font-medium block mb-1.5 text-[11px]">
                      Start Time (MM:SS)
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        value={trimStartText}
                        onChange={(e) => setTrimStartText(e.target.value)}
                        onBlur={handleStartTextBlur}
                        placeholder="00:00"
                        className="w-24 px-2.5 py-1.5 rounded-lg bg-black/80 border border-indigo-500/40 text-white font-mono text-center text-xs focus:outline-none focus:border-indigo-400 transition-all"
                      />
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => handleAdjustStart(-10)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          -10s
                        </button>
                        <button
                          onClick={() => handleAdjustStart(10)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          +10s
                        </button>
                        <button
                          onClick={() => handleAdjustStart(60)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          +1m
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* End Time Section */}
                  <div className="p-3 rounded-xl bg-black/40 border border-white/10">
                    <label className="text-gray-300 font-medium block mb-1.5 text-[11px]">
                      End Time (MM:SS)
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        value={trimEndText}
                        onChange={(e) => setTrimEndText(e.target.value)}
                        onBlur={handleEndTextBlur}
                        placeholder="03:00"
                        className="w-24 px-2.5 py-1.5 rounded-lg bg-black/80 border border-indigo-500/40 text-white font-mono text-center text-xs focus:outline-none focus:border-indigo-400 transition-all"
                      />
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => handleAdjustEnd(-60)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          -1m
                        </button>
                        <button
                          onClick={() => handleAdjustEnd(-10)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          -10s
                        </button>
                        <button
                          onClick={() => handleAdjustEnd(10)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-[10px] text-gray-300 transition-all cursor-pointer"
                        >
                          +10s
                        </button>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="text-[11px] text-indigo-300/90 flex items-center gap-1.5 bg-indigo-500/10 p-2 rounded-lg border border-indigo-500/20">
                  <Scissors className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                  <span>Only the {secondsToTimeString(clipDurationSec)} segment ({trimStartText} to {trimEndText}) will be downloaded.</span>
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
            {enableTrim ? '✂️ Custom Trim Range Active' : 'Direct Serverless CDN Streams'}
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
                      disabled={!!downloadingId}
                      className="w-full sm:w-auto flex items-center justify-center gap-2 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white font-medium text-xs sm:text-sm px-5 py-2.5 rounded-xl shadow-md shadow-indigo-600/20 hover:shadow-indigo-600/40 transition-all cursor-pointer disabled:opacity-50 active:scale-95"
                    >
                      {isCurrentDownloading ? (
                        <>
                          <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          <span>Preparing ({downloadProgress}%)</span>
                        </>
                      ) : (
                        <>
                          {enableTrim ? <Scissors className="w-3.5 h-3.5 text-indigo-200" /> : <Download className="w-3.5 h-3.5" />}
                          <span>{enableTrim ? `Download Trimmed (${trimStartText}-${trimEndText})` : `Download ${format.extension.toUpperCase()}`}</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Progress bar if active */}
        {downloadingId && (
          <div className="mt-4 p-3.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 animate-fadeIn">
            <div className="flex justify-between text-xs text-indigo-300 mb-2 font-medium">
              <span className="flex items-center gap-1.5">
                <Loader2 className="w-3.5 h-3.5 animate-spin text-indigo-400" />
                {downloadStatusText || 'Preparing stream...'}
              </span>
              <span className="font-mono">{downloadProgress}%</span>
            </div>
            <div className="w-full h-1.5 bg-black/40 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 transition-all duration-300"
                style={{ width: `${downloadProgress}%` }}
              />
            </div>
          </div>
        )}

        {/* Error notification */}
        {downloadError && (
          <div className="mt-4 p-3.5 rounded-xl bg-red-500/10 border border-red-500/25 text-red-400 text-xs flex items-start gap-2.5 animate-fadeIn">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="font-semibold">Download Failed</p>
              <p className="text-red-400/90 mt-0.5 leading-relaxed">{downloadError}</p>
            </div>
          </div>
        )}

        {/* Success toast notification */}
        {downloadSuccess && (
          <div className="mt-4 p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/25 text-emerald-400 text-xs flex items-center gap-2.5 animate-fadeIn">
            <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-400" />
            <span className="font-medium">{downloadSuccess}</span>
          </div>
        )}
      </div>
    </div>
  );
}
