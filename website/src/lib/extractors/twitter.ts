import { MediaInfo, MediaFormat } from '../types';
import { formatDuration } from '../utils';

export async function extractTwitter(url: string): Promise<MediaInfo> {
  // Convert URL to vxtwitter / fxtwitter API format
  const parsed = new URL(url);
  const path = parsed.pathname; // e.g. /username/status/123456789

  const apiUrl = `https://api.vxtwitter.com${path}`;
  const res = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)',
    },
    next: { revalidate: 60 },
  });

  if (!res.ok) {
    throw new Error(`Failed to resolve Twitter media: HTTP ${res.status}`);
  }

  const data = await res.json();
  const formats: MediaFormat[] = [];

  if (Array.isArray(data.media_extended)) {
    for (const media of data.media_extended) {
      if (media.type === 'video' || media.type === 'gif') {
        formats.push({
          id: `twitter-video-${formats.length}`,
          label: `MP4 Video (${media.size?.width ? `${media.size.width}x${media.size.height}` : 'HD'})`,
          type: 'video',
          resolution: 'HD',
          quality: 'HD',
          extension: 'mp4',
          url: media.url,
          isDirect: true,
        });
      }
    }
  }

  // Fallback to single media_url if extended was empty
  if (formats.length === 0 && data.video_url) {
    formats.push({
      id: 'twitter-video-main',
      label: 'HD Video (MP4)',
      type: 'video',
      resolution: 'HD',
      quality: 'HD',
      extension: 'mp4',
      url: data.video_url,
      isDirect: true,
    });
  }

  if (formats.length === 0) {
    throw new Error('No video found in this tweet');
  }

  return {
    url,
    platform: 'twitter',
    platformName: 'X / Twitter',
    title: data.text ? data.text.slice(0, 100) : `Post by @${data.user_screen_name || 'user'}`,
    author: `${data.user_name || 'User'} (@${data.user_screen_name || 'user'})`,
    authorUrl: `https://x.com/${data.user_screen_name}`,
    thumbnail: data.mediaURLs?.[0] || 'https://abs.twimg.com/icons/apple-touch-icon-192x192.png',
    duration: 0,
    durationFormatted: 'Video',
    formats,
  };
}
