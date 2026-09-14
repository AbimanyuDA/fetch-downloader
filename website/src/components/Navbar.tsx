'use client';

import React from 'react';
import { Download, Sparkles, Laptop } from 'lucide-react';
import { GithubIcon } from './PlatformIcons';

export default function Navbar() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-white/5 bg-[#090a0f]/80 backdrop-blur-xl">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 via-violet-600 to-pink-500 p-0.5 shadow-lg shadow-indigo-500/20 flex items-center justify-center">
            <div className="w-full h-full bg-[#0d0f17] rounded-[10px] flex items-center justify-center">
              <Download className="w-5 h-5 text-indigo-400" />
            </div>
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <span className="font-bold text-lg tracking-tight bg-gradient-to-r from-white via-gray-200 to-gray-400 bg-clip-text text-transparent">
                MediaFetch
              </span>
              <span className="text-[10px] uppercase font-semibold tracking-wider px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 flex items-center gap-1">
                <Sparkles className="w-2.5 h-2.5" />
                Web
              </span>
            </div>
            <p className="text-[11px] text-gray-500 hidden sm:block">Universal High-Speed Media Downloader</p>
          </div>
        </div>

        {/* Action / Links */}
        <div className="flex items-center space-x-3">
          <a
            href="#platforms"
            className="text-xs font-medium text-gray-400 hover:text-white transition-colors hidden md:inline-block px-3 py-1.5"
          >
            Platforms
          </a>
          <a
            href="#features"
            className="text-xs font-medium text-gray-400 hover:text-white transition-colors hidden md:inline-block px-3 py-1.5"
          >
            Features
          </a>
          <a
            href="#faq"
            className="text-xs font-medium text-gray-400 hover:text-white transition-colors hidden md:inline-block px-3 py-1.5"
          >
            FAQ
          </a>

          <a
            href="https://github.com"
            target="_blank"
            rel="noreferrer"
            className="flex items-center space-x-2 text-xs font-semibold px-3.5 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-gray-300 hover:text-white border border-white/10 transition-all"
          >
            <Laptop className="w-3.5 h-3.5 text-indigo-400" />
            <span className="hidden sm:inline">macOS App</span>
          </a>
        </div>
      </div>
    </header>
  );
}
