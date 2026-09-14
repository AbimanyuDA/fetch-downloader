import { MediaInfo, MediaFormat, MediaPlatform } from '../types';
import { detectPlatform, formatDuration } from '../utils';

// Public Cobalt instances for Instagram, Reddit, Facebook, Vimeo, SoundCloud
const COBALT_INSTANCES = [
  'https://cobalt.kwiatekm.tokyo',
  'https://api.cobalt.tools',
  'https://cobalt.xy2401.com',
  'https://cobalt-api.hyper.lol',
];

export async function extractGenericOrSocial(url: string, platform: MediaPlatform): Promise<MediaInfo> {
  const { platformName } = detectPlatform(url);

  // 1. Direct file link check (.mp4, .mp3, .webm, .m4a, .mov, etc.)
  const cleanPath = new URL(url).pathname.toLowerCase();
  if (
    cleanPath.endsWith('.mp4') ||
    cleanPath.endsWith('.webm') ||
    cleanPath.endsWith('.mov') ||
    cleanPath.endsWith('.mkv')
  ) {
    const filename = url.split('/').pop()?.split('?')[0] || 'Media Video';
    return {
      url,
      platform: 'generic',
      platformName: 'Direct Media',
      title: decodeURIComponent(filename),
      author: new URL(url).hostname,
      thumbnail: '',
      duration: 0,
      durationFormatted: 'Direct MP4',
      formats: [
        {
          id: 'direct-file-mp4',
          label: 'Original Media Stream (MP4)',
          type: 'video',
          resolution: 'Original',
          quality: 'Original Quality',
          extension: 'mp4',
          url: url,
          isDirect: true,
        },
      ],
    };
  }

  if (
    cleanPath.endsWith('.mp3') ||
    cleanPath.endsWith('.m4a') ||
    cleanPath.endsWith('.wav') ||
    cleanPath.endsWith('.ogg')
  ) {
    const filename = url.split('/').pop()?.split('?')[0] || 'Audio Track';
    return {
      url,
      platform: 'generic',
      platformName: 'Direct Audio',
      title: decodeURIComponent(filename),
      author: new URL(url).hostname,
      thumbnail: '',
      duration: 0,
      durationFormatted: 'Direct Audio',
      formats: [
        {
          id: 'direct-file-audio',
          label: 'Original Audio Stream',
          type: 'audio',
          quality: 'Original Quality',
          extension: cleanPath.split('.').pop() || 'mp3',
          url: url,
          isDirect: true,
        },
      ],
    };
  }

  // 2. Attempt Cobalt instance extraction for supported platforms
  for (const instance of COBALT_INSTANCES) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      const res = await fetch(instance, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'MediaFetch-Web/1.0',
        },
        body: JSON.stringify({
          url,
          videoQuality: '1080',
        }),
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const data = await res.json();
        if (data.url || (data.status === 'stream' && data.url)) {
          const directUrl = data.url;
          return {
            url,
            platform,
            platformName,
            title: `${platformName} Media Download`,
            author: platformName,
            thumbnail: '',
            duration: 0,
            durationFormatted: 'Media',
            formats: [
              {
                id: 'media-direct-hd',
                label: 'High Quality (MP4/Media)',
                type: 'video',
                resolution: '1080p',
                quality: 'HD',
                extension: 'mp4',
                url: directUrl,
                isDirect: true,
              },
            ],
          };
        }
      }
    } catch (e) {
      // Continue to next instance
    }
  }

  // 3. Fallback: OpenGraph HTML metadata scraper
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      next: { revalidate: 60 },
    });

    if (res.ok) {
      const html = await res.text();

      // Extract title
      const titleMatch = html.match(/<meta\s+property=["']og:title["']\s+content=["'](.*?)["']/i) ||
                         html.match(/<title>(.*?)<\/title>/i);
      const title = titleMatch ? titleMatch[1].trim() : `${platformName} Content`;

      // Extract image
      const imgMatch = html.match(/<meta\s+property=["']og:image["']\s+content=["'](.*?)["']/i);
      const thumbnail = imgMatch ? imgMatch[1] : '';

      // Extract video stream if available
      const videoMatch = html.match(/<meta\s+property=["']og:video(?::secure_url)?["']\s+content=["'](.*?)["']/i) ||
                          html.match(/<meta\s+name=["']twitter:player:stream["']\s+content=["'](.*?)["']/i);

      if (videoMatch && videoMatch[1]) {
        return {
          url,
          platform,
          platformName,
          title,
          author: platformName,
          thumbnail,
          duration: 0,
          durationFormatted: 'Media',
          formats: [
            {
              id: 'og-video-stream',
              label: 'Direct Video Stream (MP4)',
              type: 'video',
              resolution: 'Original',
              quality: 'Original',
              extension: 'mp4',
              url: videoMatch[1],
              isDirect: true,
            },
          ],
        };
      }
    }
  } catch (err) {
    console.warn('OpenGraph parsing error:', err);
  }

  throw new Error(`Could not automatically resolve downloadable media for this ${platformName} link.`);
}
