'use client';

import React, { useState } from 'react';
import { ChevronDown } from 'lucide-react';

const faqs = [
  {
    q: 'Can this website be deployed on Vercel for free?',
    a: 'Yes! MediaFetch Web is built with Next.js App Router and serverless route handlers. It has zero heavy operating-system binary requirements, making it 100% compliant with Vercel Hobby Free Tier.',
  },
  {
    q: 'Does it download TikTok videos without watermarks?',
    a: 'Yes. TikTok links are parsed through high-definition watermark-free resolvers, giving you pristine MP4 video and separate MP3 audio files.',
  },
  {
    q: 'Where do the downloaded files go?',
    a: 'Files are saved directly to your device default Downloads folder via your browser download manager, without saving any copies on our servers.',
  },
  {
    q: 'What is the difference between this Web version and the macOS Desktop app?',
    a: 'The Web version runs instantly in any browser without installation. The native macOS desktop app utilizes your Mac hardware VideoToolbox encoder, local yt-dlp & FFmpeg, multi-task download queue, and sample-accurate trimming.',
  },
  {
    q: 'Is there a download limit or registration needed?',
    a: 'No. MediaFetch Web is free to use with no account registration, login, or subscriptions needed.',
  },
];

export default function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (i: number) => {
    setOpenIndex(openIndex === i ? null : i);
  };

  return (
    <section id="faq" className="w-full max-w-3xl mx-auto mt-24 px-4">
      <div className="text-center mb-10">
        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
          Frequently Asked Questions
        </h2>
        <p className="text-sm text-gray-400 mt-2">
          Everything you need to know about using MediaFetch Web.
        </p>
      </div>

      <div className="space-y-3">
        {faqs.map((faq, i) => {
          const isOpen = openIndex === i;
          return (
            <div
              key={i}
              className="glass-panel rounded-2xl border border-white/5 overflow-hidden transition-all"
            >
              <button
                onClick={() => toggle(i)}
                className="w-full flex items-center justify-between p-4 text-left font-medium text-sm text-white hover:text-indigo-300 transition-colors cursor-pointer"
              >
                <span>{faq.q}</span>
                <ChevronDown
                  className={`w-4 h-4 text-gray-400 transition-transform duration-200 shrink-0 ml-2 ${
                    isOpen ? 'rotate-180 text-indigo-400' : ''
                  }`}
                />
              </button>

              {isOpen && (
                <div className="px-4 pb-4 text-xs sm:text-sm text-gray-400 leading-relaxed border-t border-white/5 pt-3 animate-fadeIn">
                  {faq.a}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
