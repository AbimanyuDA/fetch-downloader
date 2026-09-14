import { NextRequest, NextResponse } from 'next/server';
import { extractYouTubeId } from '@/lib/extractors/youtube';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function getTargetFormat(format?: string, resolution?: string, extension?: string): string {
  const ext = (extension || '').toLowerCase();
  const fmt = (format || '').toLowerCase();
  const res = (resolution || '').toLowerCase();

  // Audio formats
  if (ext === 'mp3' || fmt === 'mp3' || fmt.includes('mp3')) return 'mp3';
  if (ext === 'wav' || fmt === 'wav' || fmt.includes('wav')) return 'wav';
  if (ext === 'flac' || fmt === 'flac' || fmt.includes('flac')) return 'flac';
  if (ext === 'm4a' || fmt === 'm4a' || ext === 'aac' || fmt === 'aac' || fmt.includes('m4a') || fmt.includes('aac')) return 'm4a';
  if (ext === 'opus' || fmt === 'opus' || fmt.includes('opus')) return 'opus';
  if (ext === 'ogg' || fmt === 'ogg' || fmt.includes('ogg')) return 'ogg';

  // Video formats & resolutions
  if (res.includes('4k') || res.includes('2160') || fmt.includes('4k') || fmt.includes('2160')) return '4k';
  if (res.includes('1440') || fmt.includes('1440')) return '1440';
  if (res.includes('1080') || fmt.includes('1080')) return '1080';
  if (res.includes('720') || fmt.includes('720')) return '720';
  if (res.includes('480') || fmt.includes('480')) return '480';
  if (res.includes('360') || fmt.includes('360')) return '360';
  if (ext === 'webm' || fmt === 'webm') return 'webm';

  return '720';
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { action, url, progressUrl, format, resolution, extension, trimStartSec, trimEndSec } = body;

    // Action 1: Poll progress of an existing conversion job
    if (action === 'progress') {
      if (!progressUrl) {
        return NextResponse.json({ success: false, error: 'Missing progressUrl' }, { status: 400 });
      }

      const progRes = await fetch(progressUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)',
        },
        cache: 'no-store',
      });

      if (!progRes.ok) {
        return NextResponse.json({ success: false, error: 'Failed to poll conversion progress' }, { status: 502 });
      }

      const progData = await progRes.json();
      const isFinished = !!progData.download_url || progData.progress === 1000;

      return NextResponse.json({
        success: true,
        progress: typeof progData.progress === 'number' ? Math.min(100, Math.round(progData.progress / 10)) : 50,
        text: progData.text || 'Processing media...',
        downloadUrl: progData.download_url || null,
        finished: isFinished,
      });
    }

    // Action 2: Initialize conversion job
    if (!url) {
      return NextResponse.json({ success: false, error: 'Missing URL' }, { status: 400 });
    }

    const ytId = extractYouTubeId(url);
    if (ytId) {
      const targetFmt = getTargetFormat(format, resolution, extension);

      // Use trim range if provided, otherwise download full (start=1&end=1 means full)
      const startParam = (typeof trimStartSec === 'number' && trimStartSec > 0) ? trimStartSec : 1;
      const endParam = (typeof trimEndSec === 'number' && trimEndSec > 0) ? trimEndSec : 1;

      const initUrl = `https://loader.to/ajax/download.php?button=1&start=${startParam}&end=${endParam}&format=${targetFmt}&url=${encodeURIComponent(url)}`;

      const initRes = await fetch(initUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)',
        },
        cache: 'no-store',
      });

      if (!initRes.ok) {
        throw new Error('Failed to contact conversion service. Please try again.');
      }

      const initData = await initRes.json();
      if (!initData || !initData.progress_url) {
        throw new Error('Conversion service did not return a valid task tracker.');
      }

      return NextResponse.json({
        success: true,
        jobId: initData.id,
        progressUrl: initData.progress_url,
        isAsync: true,
      });
    }

    // For direct non-YouTube streams (TikTok, Twitter, etc.), return immediately
    return NextResponse.json({
      success: true,
      downloadUrl: url,
      finished: true,
      isAsync: false,
    });
  } catch (error: any) {
    console.error('/api/download error:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Failed to process download' },
      { status: 500 }
    );
  }
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const mediaUrl = searchParams.get('url');

  if (!mediaUrl) {
    return new NextResponse('Missing url parameter', { status: 400 });
  }

  // Fast redirect for streaming downloads
  return NextResponse.redirect(mediaUrl);
}
