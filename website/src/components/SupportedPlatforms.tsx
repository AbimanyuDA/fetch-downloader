import React from 'react';
import { Radio, Video, Globe } from 'lucide-react';
import {
  YouTubeIcon,
  TikTokIcon,
  XTwitterIcon,
  InstagramIcon,
  FacebookIcon,
  RedditIcon,
} from './PlatformIcons';

const platforms = [
  {
    name: 'YouTube',
    icon: <YouTubeIcon className="w-5 h-5 text-red-500" />,
    badge: '1080p / MP3',
    desc: 'Videos, Shorts, and Audio extraction',
  },
  {
    name: 'TikTok',
    icon: <TikTokIcon className="w-5 h-5 text-cyan-400" />,
    badge: 'No Watermark HD',
    desc: 'Clean MP4 and original audio sound',
  },
  {
    name: 'Instagram',
    icon: <InstagramIcon className="w-5 h-5 text-pink-500" />,
    badge: 'Reels & Videos',
    desc: 'High-definition video reels and clips',
  },
  {
    name: 'X (Twitter)',
    icon: <XTwitterIcon className="w-5 h-5 text-sky-400" />,
    badge: 'HD Clips & GIF',
    desc: 'Instant video downloads from tweets',
  },
  {
    name: 'Facebook',
    icon: <FacebookIcon className="w-5 h-5 text-blue-500" />,
    badge: 'Watch & Reels',
    desc: 'Public video posts and reels',
  },
  {
    name: 'Reddit',
    icon: <RedditIcon className="w-5 h-5 text-orange-500" />,
    badge: 'Video & Audio',
    desc: 'Reddit hosted video posts',
  },
  {
    name: 'SoundCloud',
    icon: <Radio className="w-5 h-5 text-amber-500" />,
    badge: '320kbps Audio',
    desc: 'Lossless audio stream extraction',
  },
  {
    name: 'Direct Web Media',
    icon: <Video className="w-5 h-5 text-indigo-400" />,
    badge: 'MP4 / MP3 / WebM',
    desc: 'Direct media files from any website',
  },
];

export default function SupportedPlatforms() {
  return (
    <section id="platforms" className="w-full max-w-5xl mx-auto mt-20 px-4">
      <div className="text-center mb-10">
        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
          Supported Platforms
        </h2>
        <p className="text-sm text-gray-400 mt-2 max-w-lg mx-auto">
          MediaFetch Web automatically parses media from the world's most popular platforms in pristine quality.
        </p>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
        {platforms.map((p) => (
          <div
            key={p.name}
            className="glass-panel glass-panel-hover rounded-2xl p-4 flex flex-col justify-between border border-white/5"
          >
            <div className="flex items-center justify-between mb-3">
              <div className="w-9 h-9 rounded-xl bg-white/5 flex items-center justify-center">
                {p.icon}
              </div>
              <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
                {p.badge}
              </span>
            </div>
            <div>
              <h3 className="text-sm font-semibold text-white">{p.name}</h3>
              <p className="text-xs text-gray-400 mt-1 line-clamp-2">{p.desc}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
