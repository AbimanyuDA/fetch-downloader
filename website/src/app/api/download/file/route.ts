import { NextRequest, NextResponse } from 'next/server';
import { spawn } from 'child_process';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const targetUrl = searchParams.get('url');
  let filename = searchParams.get('filename') || 'media_download';
  const trimStart = searchParams.get('trimStart');
  const trimEnd = searchParams.get('trimEnd');

  if (!targetUrl) {
    return new NextResponse('Missing url parameter', { status: 400 });
  }

  // Safety check: JANGAN PERNAH download langsung link youtube.com
  if (targetUrl.includes('youtube.com/watch') || targetUrl.includes('youtu.be/')) {
    return new NextResponse('Cannot download direct YouTube webpage URL. Please use conversion stream.', { status: 400 });
  }

  // Clean and sanitize filename
  filename = filename.replace(/[/\\?%*:|"<>]/g, '_').trim();
  if (!filename) filename = 'media_download';

  const extMatch = filename.match(/\.([a-zA-Z0-9]+)$/);
  const ext = extMatch ? extMatch[1].toLowerCase() : 'mp4';

  const startSec = trimStart !== null ? parseFloat(trimStart) : NaN;
  const endSec = trimEnd !== null ? parseFloat(trimEnd) : NaN;
  const hasTrim = !isNaN(startSec) && !isNaN(endSec) && endSec > startSec;

  // Trim mode using ffmpeg
  if (hasTrim) {
    try {
      const ffmpegArgs: string[] = ['-ss', startSec.toString(), '-to', endSec.toString(), '-i', targetUrl];
      let contentType = 'application/octet-stream';

      if (ext === 'mp3') {
        ffmpegArgs.push('-vn', '-c:a', 'libmp3lame', '-b:a', '320k', '-f', 'mp3', 'pipe:1');
        contentType = 'audio/mpeg';
      } else if (ext === 'wav') {
        ffmpegArgs.push('-vn', '-c:a', 'pcm_s16le', '-f', 'wav', 'pipe:1');
        contentType = 'audio/wav';
      } else if (ext === 'flac') {
        ffmpegArgs.push('-vn', '-c:a', 'flac', '-f', 'flac', 'pipe:1');
        contentType = 'audio/flac';
      } else if (ext === 'm4a' || ext === 'aac') {
        ffmpegArgs.push('-vn', '-c:a', 'aac', '-b:a', '256k', '-f', 'adts', 'pipe:1');
        contentType = 'audio/aac';
      } else if (ext === 'webm') {
        ffmpegArgs.push('-c:v', 'copy', '-c:a', 'copy', '-f', 'webm', 'pipe:1');
        contentType = 'video/webm';
      } else {
        // MP4 video
        ffmpegArgs.push('-c', 'copy', '-movflags', 'frag_keyframe+empty_moov', '-f', 'mp4', 'pipe:1');
        contentType = 'video/mp4';
      }

      const ff = spawn('ffmpeg', ffmpegArgs);

      const stream = new ReadableStream({
        start(controller) {
          ff.stdout.on('data', (chunk) => controller.enqueue(chunk));
          ff.stdout.on('end', () => controller.close());
          ff.stdout.on('error', (err) => controller.error(err));
          ff.on('error', (err) => controller.error(err));
        },
        cancel() {
          ff.kill();
        },
      });

      const headers = new Headers();
      headers.set('Content-Disposition', `attachment; filename="${encodeURIComponent(filename)}"; filename*=UTF-8''${encodeURIComponent(filename)}`);
      headers.set('Content-Type', contentType);
      headers.set('Access-Control-Allow-Origin', '*');
      headers.set('Cache-Control', 'no-cache');

      return new NextResponse(stream as any, {
        status: 200,
        headers,
      });
    } catch (trimErr) {
      console.warn('FFmpeg trim error, falling back to full stream:', trimErr);
    }
  }

  // Standard direct download
  try {
    const upstreamRes = await fetch(targetUrl, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      },
    });

    if (!upstreamRes.ok || !upstreamRes.body) {
      return new NextResponse(`Failed to fetch media from upstream (HTTP ${upstreamRes.status})`, {
        status: upstreamRes.status,
      });
    }

    let contentType = upstreamRes.headers.get('content-type') || 'application/octet-stream';
    if (contentType.includes('text/html')) {
      if (ext === 'mp3') contentType = 'audio/mpeg';
      else if (ext === 'wav') contentType = 'audio/wav';
      else if (ext === 'm4a') contentType = 'audio/mp4';
      else if (ext === 'mp4') contentType = 'video/mp4';
    }
    const contentLength = upstreamRes.headers.get('content-length');

    const headers = new Headers();
    headers.set('Content-Disposition', `attachment; filename="${encodeURIComponent(filename)}"; filename*=UTF-8''${encodeURIComponent(filename)}`);
    headers.set('Content-Type', contentType);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Cache-Control', 'public, max-age=3600');

    if (contentLength && !contentType.includes('text/html')) {
      headers.set('Content-Length', contentLength);
    }

    return new NextResponse(upstreamRes.body as any, {
      status: 200,
      headers,
    });
  } catch (err: any) {
    console.error('Download stream error:', err);
    return new NextResponse(err.message || 'Failed to stream media download', { status: 500 });
  }
}
