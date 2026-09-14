import { NextRequest, NextResponse } from 'next/server';
import { detectPlatform } from '@/lib/utils';
import { extractYouTube } from '@/lib/extractors/youtube';
import { extractTikTok } from '@/lib/extractors/tiktok';
import { extractTwitter } from '@/lib/extractors/twitter';
import { extractGenericOrSocial } from '@/lib/extractors/generic';
import { MediaInfo } from '@/lib/types';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const url = body?.url?.trim();

    if (!url) {
      return NextResponse.json(
        { success: false, error: 'URL cannot be empty' },
        { status: 400 }
      );
    }

    try {
      new URL(url);
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid URL format. Please paste a valid web link.' },
        { status: 400 }
      );
    }

    const { platform } = detectPlatform(url);
    let mediaInfo: MediaInfo;

    switch (platform) {
      case 'tiktok':
        mediaInfo = await extractTikTok(url);
        break;

      case 'youtube':
        mediaInfo = await extractYouTube(url);
        break;

      case 'twitter':
        mediaInfo = await extractTwitter(url);
        break;

      default:
        mediaInfo = await extractGenericOrSocial(url, platform);
        break;
    }

    return NextResponse.json({
      success: true,
      data: mediaInfo,
    });
  } catch (error: any) {
    console.error('API /api/info error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message || 'Failed to extract media details. Please check the URL and try again.',
      },
      { status: 500 }
    );
  }
}
