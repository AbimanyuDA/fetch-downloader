import { NextRequest, NextResponse } from 'next/server';
import { sanitizeFilename } from '@/lib/utils';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const mediaUrl = searchParams.get('url');
  const rawFilename = searchParams.get('filename') || 'media_download';
  const ext = searchParams.get('ext') || 'mp4';

  if (!mediaUrl) {
    return new NextResponse('Missing url parameter', { status: 400 });
  }

  const safeFilename = `${sanitizeFilename(rawFilename)}.${ext}`;

  try {
    const upstreamRes = await fetch(mediaUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': new URL(mediaUrl).origin,
      },
    });

    if (!upstreamRes.ok || !upstreamRes.body) {
      // If direct proxy fails (e.g. CORS/hotlinking restriction), redirect directly
      return NextResponse.redirect(mediaUrl);
    }

    const contentType = upstreamRes.headers.get('content-type') || (ext === 'mp3' ? 'audio/mpeg' : 'video/mp4');
    const contentLength = upstreamRes.headers.get('content-length');

    const headers = new Headers();
    headers.set('Content-Disposition', `attachment; filename="${safeFilename}"`);
    headers.set('Content-Type', contentType);
    if (contentLength) {
      headers.set('Content-Length', contentLength);
    }

    return new NextResponse(upstreamRes.body as any, {
      status: 200,
      headers,
    });
  } catch (error) {
    console.error('Download stream error:', error);
    // Fallback redirect
    return NextResponse.redirect(mediaUrl);
  }
}
