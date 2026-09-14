import React from 'react';
import { Download, Shield } from 'lucide-react';
import { GithubIcon } from './PlatformIcons';

export default function Footer() {
  return (
    <footer className="w-full border-t border-white/5 bg-[#07080c] mt-28 py-12 px-4 sm:px-6">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 rounded-lg bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center">
            <Download className="w-4 h-4 text-indigo-400" />
          </div>
          <div>
            <span className="font-bold text-white text-sm">MediaFetch</span>
            <span className="text-gray-500 text-xs ml-2">Web Edition</span>
          </div>
        </div>

        <div className="text-xs text-gray-500 text-center md:text-left">
          Crafted for high-speed web media extraction. 100% Free & Open-Architecture.
        </div>

        <div className="flex items-center space-x-4 text-xs text-gray-400">
          <a
            href="https://github.com"
            target="_blank"
            rel="noreferrer"
            className="hover:text-white transition-colors flex items-center gap-1.5"
          >
            <GithubIcon className="w-4 h-4" />
            GitHub
          </a>
          <span>•</span>
          <span className="flex items-center gap-1 text-gray-500">
            <Shield className="w-3.5 h-3.5" />
            Vercel Ready
          </span>
        </div>
      </div>
    </footer>
  );
}
