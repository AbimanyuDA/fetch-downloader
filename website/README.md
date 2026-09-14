# MediaFetch Web 🚀

Web-based universal media downloader companion to **MediaFetch for macOS**. Built with Next.js 16 (App Router), TypeScript, and Tailwind CSS. Designed to be 100% free and ready to deploy on **Vercel Serverless (Hobby Tier)**.

## ✨ Features

- ⚡ **Zero Setup & Free:** Deploys seamlessly to Vercel without heavy native binaries (no OS ffmpeg or yt-dlp dependencies needed).
- 🎬 **Multi-Platform Support:**
  - **YouTube:** High-quality videos (1080p, 720p, 480p) & MP3 audio streams.
  - **TikTok:** No-watermark HD MP4 video & original MP3 audio.
  - **Instagram:** Reels, video posts, and stories.
  - **X (Twitter):** Instant video & GIF downloads from tweets.
  - **Facebook, Reddit, Vimeo, SoundCloud:** Multi-engine stream extraction.
  - **Direct Links:** Direct web media links (MP4, MP3, WebM).
- ✂️ **Trim Range Simulator:** Preview custom start & end trim times (inspired by the macOS native app).
- 💾 **Local History:** Automatically saves recent downloads in your browser's `localStorage` for fast re-access.
- 🎨 **Modern macOS-Inspired UI:** Sleek dark mode, glassmorphism, responsive mobile/desktop layout, and micro-interactions.

---

## 🛠️ Local Development

1. Navigate to the website directory:
   ```bash
   cd website
   ```

2. Install dependencies (if not already installed):
   ```bash
   npm install
   ```

3. Run the development server:
   ```bash
   npm run dev
   ```

4. Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 🌐 Deploy to Vercel (Free Tier)

### Method 1: Vercel CLI
```bash
npm i -g vercel
vercel
```

### Method 2: GitHub Integration
1. Push this repository to GitHub.
2. Go to [Vercel Dashboard](https://vercel.com/new).
3. Import your repository.
4. Set **Root Directory** to `website`.
5. Click **Deploy**. Done!
