import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: 'MediaFetch Web - Fast Universal Video & Audio Downloader',
  description:
    'Download media from YouTube, TikTok (no watermark), Instagram, X/Twitter, and more in pristine HD quality. Free, fast, and serverless on Vercel.',
  keywords: [
    'video downloader',
    'tiktok downloader',
    'youtube downloader',
    'instagram reels download',
    'mp3 converter',
    'mediafetch',
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased dark`}
    >
      <body
        suppressHydrationWarning
        className="min-h-full flex flex-col bg-[#090a0f] text-gray-100 selection:bg-indigo-600 selection:text-white"
      >
        {children}
      </body>
    </html>
  );
}
