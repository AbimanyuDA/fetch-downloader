import { MediaInfo, MediaFormat } from '../types';
import { formatBytes, formatDuration } from '../utils';

export function extractYouTubeId(url: string): string | null {
  try {
    const parsed = new URL(url.trim());

    // 1. Check standard ?v= param
    const vParam = parsed.searchParams.get('v');
    if (vParam && /^[a-zA-Z0-9_-]{11}$/.test(vParam)) {
      return vParam;
    }

    // 2. Check path segments (youtu.be/ID, /live/ID, /shorts/ID, /embed/ID, /v/ID)
    const pathParts = parsed.pathname.split('/').filter(Boolean);

    if (parsed.hostname.includes('youtu.be') && pathParts[0]) {
      const idCandidate = pathParts[0].slice(0, 11);
      if (/^[a-zA-Z0-9_-]{11}$/.test(idCandidate)) {
        return idCandidate;
      }
    }

    const triggerSegments = ['shorts', 'live', 'embed', 'v'];
    for (let i = 0; i < pathParts.length; i++) {
      if (triggerSegments.includes(pathParts[i]) && pathParts[i + 1]) {
        const potentialId = pathParts[i + 1].slice(0, 11);
        if (/^[a-zA-Z0-9_-]{11}$/.test(potentialId)) {
          return potentialId;
        }
      }
    }
  } catch (e) {
    // If URL parsing fails, continue to regex fallback
  }

  // Fallback regex covering watch, v, embed, shorts, live, youtu.be
  const match = url.match(/(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|shorts\/|live\/|watch\?v=|watch\?.+&v=))([a-zA-Z0-9_-]{11})/);
  return match ? match[1] : null;
}

const INVIDIOUS_INSTANCES = [
  'https://inv.tux.pizza',
  'https://invidious.nerdvpn.de',
  'https://invidious.jing.rocks',
  'https://yt.artemislena.eu',
  'https://invidious.drgns.space',
];

export async function extractYouTube(url: string): Promise<MediaInfo> {
  const id = extractYouTubeId(url);
  if (!id) {
    throw new Error('Invalid YouTube URL: could not extract Video ID. Please ensure the link is a valid YouTube video, shorts, or live stream.');
  }

  // 1. Get metadata as baseline
  let title = 'YouTube Video';
  let author = 'YouTube Creator';
  let authorUrl = `https://www.youtube.com/watch?v=${id}`;
  let thumbnail = `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
  let duration = 0;

  try {
    const [oembedRes, pageRes] = await Promise.allSettled([
      fetch(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${id}&format=json`, {
        next: { revalidate: 300 },
      }),
      fetch(`https://www.youtube.com/watch?v=${id}`, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        next: { revalidate: 300 },
      }),
    ]);

    if (oembedRes.status === 'fulfilled' && oembedRes.value.ok) {
      const oembed = await oembedRes.value.json();
      if (oembed.title) title = oembed.title;
      if (oembed.author_name) author = oembed.author_name;
      if (oembed.author_url) authorUrl = oembed.author_url;
      if (oembed.thumbnail_url) thumbnail = oembed.thumbnail_url;
    }

    if (pageRes.status === 'fulfilled' && pageRes.value.ok) {
      const html = await pageRes.value.text();
      const lengthMatch = html.match(/"lengthSeconds":"(\d+)"/) || html.match(/"approxDurationMs":"(\d+)"/);
      if (lengthMatch && lengthMatch[1]) {
        const val = Number(lengthMatch[1]);
        duration = val > 10000 ? Math.floor(val / 1000) : val;
      }
    }
  } catch (err) {
    console.warn('Metadata fetch error:', err);
  }

  // 2. Fetch streams from Invidious instance pool
  const formats: MediaFormat[] = [];

  for (const instance of INVIDIOUS_INSTANCES) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      const res = await fetch(`${instance}/api/v1/videos/${id}`, {
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const data = await res.json();
        if (data.title) title = data.title;
        if (data.author) author = data.author;
        if (data.lengthSeconds) duration = Number(data.lengthSeconds);

        // Combined audio + video formats (best for direct download)
        if (Array.isArray(data.formatStreams)) {
          for (const s of data.formatStreams) {
            if (s.url && s.container === 'mp4') {
              const quality = s.qualityLabel || s.resolution || '720p';
              formats.push({
                id: `mp4-${quality}`,
                label: `MP4 Video (${quality})`,
                type: 'video',
                resolution: quality,
                quality,
                extension: 'mp4',
                filesize: s.size ? Number(s.size) : undefined,
                filesizeFormatted: s.size ? formatBytes(Number(s.size)) : undefined,
                url: s.url,
                isDirect: true,
              });
            }
          }
        }

        // Adaptive high quality formats (1080p, 1440p)
        if (Array.isArray(data.adaptiveFormats)) {
          for (const s of data.adaptiveFormats) {
            if (s.container === 'mp4' && s.type?.includes('video')) {
              const label = s.qualityLabel || s.resolution || '';
              if (['1080p', '1080p60', '1440p', '2160p', '4K'].some(q => label.includes(q))) {
                if (!formats.some(f => f.resolution === label)) {
                  formats.push({
                    id: `mp4-adaptive-${label}`,
                    label: `MP4 Video (${label})`,
                    type: 'video',
                    resolution: label,
                    quality: label,
                    extension: 'mp4',
                    filesize: s.size ? Number(s.size) : undefined,
                    filesizeFormatted: s.size ? formatBytes(Number(s.size)) : undefined,
                    url: s.url,
                    isDirect: true,
                  });
                }
              }
            }

            // Audio format
            if (s.type?.includes('audio') && (s.container === 'm4a' || s.container === 'mp4')) {
              if (!formats.some(f => f.type === 'audio')) {
                formats.push({
                  id: 'audio-m4a-hq',
                  label: 'HQ Audio (M4A / AAC)',
                  type: 'audio',
                  quality: s.audioQuality || 'High Bitrate',
                  extension: 'm4a',
                  filesize: s.size ? Number(s.size) : undefined,
                  filesizeFormatted: s.size ? formatBytes(Number(s.size)) : undefined,
                  url: s.url,
                  isDirect: true,
                });
              }
            }
          }
        }

        if (formats.length > 0) {
          break; // Found working instance!
        }
      }
    } catch (e) {
      // Continue to next instance
    }
  }

  // Fallback formats if instances are blocked or slow
  if (formats.length === 0) {
    formats.push(
      {
        id: 'yt-1080p',
        label: 'Full HD (1080p MP4)',
        type: 'video',
        resolution: '1080p',
        quality: '1080p',
        extension: 'mp4',
        url: `https://www.youtube.com/watch?v=${id}`,
        isDirect: false,
      },
      {
        id: 'yt-720p',
        label: 'HD (720p MP4)',
        type: 'video',
        resolution: '720p',
        quality: '720p',
        extension: 'mp4',
        url: `https://www.youtube.com/watch?v=${id}`,
        isDirect: false,
      },
      {
        id: 'yt-audio',
        label: 'Audio Only (MP3 320kbps)',
        type: 'audio',
        quality: '320kbps',
        extension: 'mp3',
        url: `https://www.youtube.com/watch?v=${id}`,
        isDirect: false,
      }
    );
  }

  return {
    url,
    platform: 'youtube',
    platformName: 'YouTube',
    title,
    author,
    authorUrl,
    thumbnail,
    duration,
    durationFormatted: duration > 0 ? formatDuration(duration) : 'Video',
    formats,
  };
}
