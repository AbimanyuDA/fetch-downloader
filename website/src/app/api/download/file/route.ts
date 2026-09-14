import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const targetUrl = searchParams.get('url');
  let filename = searchParams.get('filename') || 'media_download';

  if (!targetUrl) {
    return new NextResponse('Missing url parameter', { status: 400 });
  }

  // Safety check: JANGAN PERNAH download langsung link youtube.com
  if (targetUrl.includes('youtube.com/watch') || targetUrl.includes('youtu.be/')) {
    return new NextResponse('Cannot download direct YouTube webpage URL. Please use conversion stream.', { status: 400 });
  }

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

    const contentType = upstreamRes.headers.get('content-type') || 'application/octet-stream';
    const contentLength = upstreamRes.headers.get('content-length');

    // Clean and sanitize filename
    filename = filename.replace(/[/\\?%*:|"<>]/g, '_').trim();
    if (!filename) filename = 'media_download';

    const headers = new Headers();
    headers.set('Content-Disposition', `attachment; filename="${encodeURIComponent(filename)}"; filename*=UTF-8''${encodeURIComponent(filename)}`);
    headers.set('Content-Type', contentType);
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Cache-Control', 'public, max-age=3600');

    if (contentLength) {
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
