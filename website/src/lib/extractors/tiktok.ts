import { MediaInfo, MediaFormat } from '../types';
import { formatDuration } from '../utils';

export async function extractTikTok(url: string): Promise<MediaInfo> {
  const apiUrl = `https://www.tikwm.com/api/?url=${encodeURIComponent(url)}`;
  const res = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
    next: { revalidate: 60 },
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch TikTok data: HTTP ${res.status}`);
  }

  const data = await res.json();
  if (data.code !== 0 || !data.data) {
    throw new Error(data.msg || 'TikTok video not found or private');
  }

  const item = data.data;
  const formats: MediaFormat[] = [];

  // Video Watermark-Free HD
  if (item.hdplay) {
    formats.push({
      id: 'hd-video',
      label: 'HD Video (No Watermark)',
      type: 'video',
      resolution: '1080p',
      quality: 'HD 1080p',
      extension: 'mp4',
      url: item.hdplay,
      isDirect: true,
    });
  }

  // Video Standard No Watermark
  if (item.play) {
    formats.push({
      id: 'sd-video',
      label: 'Standard Video (No Watermark)',
      type: 'video',
      resolution: '720p',
      quality: 'SD 720p',
      extension: 'mp4',
      url: item.play,
      isDirect: true,
    });
  }

  // Audio MP3
  if (item.music) {
    formats.push({
      id: 'audio-mp3',
      label: 'Original Audio (MP3)',
      type: 'audio',
      quality: 'High Quality MP3',
      extension: 'mp3',
      url: item.music,
      isDirect: true,
    });
  }

  return {
    url,
    platform: 'tiktok',
    platformName: 'TikTok',
    title: item.title || `TikTok by @${item.author?.unique_id || 'user'}`,
    author: item.author?.nickname || item.author?.unique_id || 'TikTok Creator',
    authorUrl: item.author?.unique_id ? `https://www.tiktok.com/@${item.author.unique_id}` : undefined,
    thumbnail: item.cover || item.origin_cover || '',
    duration: item.duration || 0,
    durationFormatted: formatDuration(item.duration || 0),
    formats,
  };
}
