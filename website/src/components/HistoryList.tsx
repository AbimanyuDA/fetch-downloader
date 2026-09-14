'use client';

import React from 'react';
import { History, Trash2, ArrowUpRight, Clock, Video } from 'lucide-react';
import { HistoryItem } from '@/lib/types';

interface HistoryListProps {
  history: HistoryItem[];
  onSelectUrl: (url: string) => void;
  onClear: () => void;
  onRemoveItem: (id: string) => void;
}

export default function HistoryList({
  history,
  onSelectUrl,
  onClear,
  onRemoveItem,
}: HistoryListProps) {
  if (history.length === 0) return null;

  return (
    <div className="w-full max-w-4xl mx-auto mt-12">
      <div className="flex items-center justify-between mb-4 px-1">
        <div className="flex items-center gap-2">
          <History className="w-4 h-4 text-indigo-400" />
          <h3 className="text-sm font-semibold text-white">Recent Downloads</h3>
          <span className="text-[11px] px-2 py-0.5 rounded-full bg-white/10 text-gray-400 font-mono">
            {history.length}
          </span>
        </div>

        <button
          onClick={onClear}
          className="text-xs text-gray-500 hover:text-red-400 flex items-center gap-1 transition-colors cursor-pointer"
        >
          <Trash2 className="w-3.5 h-3.5" />
          Clear All
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
        {history.slice(0, 6).map((item) => (
          <div
            key={item.id}
            className="group relative glass-panel rounded-2xl p-3 border border-white/5 hover:border-indigo-500/30 transition-all flex flex-col justify-between"
          >
            <div className="flex items-start gap-3">
              <div className="w-14 h-14 rounded-xl overflow-hidden bg-black/50 border border-white/10 shrink-0 relative">
                {item.thumbnail ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={item.thumbnail}
                    alt={item.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-gray-600">
                    <Video className="w-5 h-5" />
                  </div>
                )}
              </div>

              <div className="min-w-0 flex-1">
                <h4 className="text-xs font-semibold text-white line-clamp-1 group-hover:text-indigo-300 transition-colors">
                  {item.title}
                </h4>
                <p className="text-[11px] text-gray-400 truncate mt-0.5">{item.author}</p>
                <div className="flex items-center gap-1.5 mt-1.5">
                  <span className="text-[10px] px-1.5 py-0.2 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase font-medium">
                    {item.platform}
                  </span>
                  <span className="text-[10px] text-gray-500 font-mono">
                    {new Date(item.downloadedAt).toLocaleDateString()}
                  </span>
                </div>
              </div>
            </div>

            <div className="mt-3 pt-2 border-t border-white/5 flex items-center justify-between">
              <button
                onClick={() => onSelectUrl(item.url)}
                className="text-[11px] text-indigo-400 hover:text-indigo-300 flex items-center gap-1 font-medium transition-colors cursor-pointer"
              >
                Re-fetch Link
                <ArrowUpRight className="w-3 h-3" />
              </button>

              <button
                onClick={() => onRemoveItem(item.id)}
                className="text-gray-500 hover:text-red-400 p-1 rounded transition-colors cursor-pointer"
                title="Remove"
              >
                <Trash2 className="w-3 h-3" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
