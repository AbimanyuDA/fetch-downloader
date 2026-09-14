import React from 'react';
import { Zap, ShieldCheck, Cpu, Smartphone, Download, Layers } from 'lucide-react';

const features = [
  {
    icon: <Zap className="w-5 h-5 text-indigo-400" />,
    title: 'Instant Serverless Parsing',
    description:
      'Deployed on Vercel Edge & Serverless functions for low-latency media parsing without heavy servers.',
  },
  {
    icon: <ShieldCheck className="w-5 h-5 text-emerald-400" />,
    title: 'Zero Tracking & 100% Privacy',
    description:
      'No user analytics, no tracking cookies, and no media files stored on our servers. Your downloads stay yours.',
  },
  {
    icon: <Cpu className="w-5 h-5 text-purple-400" />,
    title: 'Direct CDN Stream Redirects',
    description:
      'Files stream directly from the platform origin CDN to your browser at maximum possible bandwidth.',
  },
  {
    icon: <Download className="w-5 h-5 text-pink-400" />,
    title: 'Audio & Video Separation',
    description:
      'Choose between high-resolution MP4 video or pristine MP3 / M4A audio files with one click.',
  },
  {
    icon: <Smartphone className="w-5 h-5 text-cyan-400" />,
    title: 'Universal Device Support',
    description:
      'Works flawlessly across iPhone, iPad, Android, macOS, Windows, and Linux browsers without apps.',
  },
  {
    icon: <Layers className="w-5 h-5 text-amber-400" />,
    title: 'Native macOS Companion',
    description:
      'Need hardware-accelerated transcoding, batch queues, and offline FFmpeg? Download our native Mac app.',
  },
];

export default function FeaturesGrid() {
  return (
    <section id="features" className="w-full max-w-5xl mx-auto mt-24 px-4">
      <div className="text-center mb-12">
        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
          Engineered for Speed & Simplicity
        </h2>
        <p className="text-sm text-gray-400 mt-2 max-w-lg mx-auto">
          Everything you need to fetch, inspect, and save media across the modern web in seconds.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
        {features.map((f, i) => (
          <div
            key={i}
            className="glass-panel glass-panel-hover rounded-2xl p-6 border border-white/5 flex flex-col"
          >
            <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center mb-4 border border-white/10">
              {f.icon}
            </div>
            <h3 className="text-base font-semibold text-white mb-2">{f.title}</h3>
            <p className="text-xs sm:text-sm text-gray-400 leading-relaxed">{f.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
