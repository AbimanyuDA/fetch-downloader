import { MediaPlatform } from './types';

export function formatDuration(seconds: number): string {
  if (!seconds || isNaN(seconds) || seconds < 0) return '00:00';
  const hrs = Math.floor(seconds / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hrs > 0) {
    return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function formatBytes(bytes?: number): string {
  if (!bytes || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  let i = 0;
  let val = bytes;
  while (val >= 1024 && i < units.length - 1) {
    val /= 1024;
    i++;
  }
  return `${val.toFixed(1)} ${units[i]}`;
}

export function sanitizeFilename(name: string): string {
  return name
    .replace(/[/\\?%*:|"<>]/g, '_')
    .replace(/\s+/g, '_')
    .slice(0, 80);
}

export function detectPlatform(url: string): { platform: MediaPlatform; platformName: string } {
  try {
    const parsed = new URL(url.trim());
    const host = parsed.hostname.toLowerCase();

    if (host.includes('youtube.com') || host.includes('youtu.be')) {
      return { platform: 'youtube', platformName: 'YouTube' };
    }
    if (host.includes('tiktok.com')) {
      return { platform: 'tiktok', platformName: 'TikTok' };
    }
    if (host.includes('instagram.com')) {
      return { platform: 'instagram', platformName: 'Instagram' };
    }
    if (host.includes('twitter.com') || host.includes('x.com')) {
      return { platform: 'twitter', platformName: 'X / Twitter' };
    }
    if (host.includes('facebook.com') || host.includes('fb.watch')) {
      return { platform: 'facebook', platformName: 'Facebook' };
    }
    if (host.includes('reddit.com') || host.includes('redd.it')) {
      return { platform: 'reddit', platformName: 'Reddit' };
    }
    if (host.includes('soundcloud.com')) {
      return { platform: 'soundcloud', platformName: 'SoundCloud' };
    }
    if (host.includes('vimeo.com')) {
      return { platform: 'vimeo', platformName: 'Vimeo' };
    }
    return { platform: 'generic', platformName: 'Web Media' };
  } catch {
    return { platform: 'generic', platformName: 'Web Media' };
  }
}

export async function triggerBrowserDownload(
  downloadUrl: string,
  filename: string,
  trimParams?: { trimStart?: number; trimEnd?: number },
  onStatusUpdate?: (status: string) => void
): Promise<void> {
  if (typeof window === 'undefined') return;

  // Blob or data URLs
  if (downloadUrl.startsWith('blob:') || downloadUrl.startsWith('data:')) {
    const a = document.createElement('a');
    a.href = downloadUrl;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
      document.body.removeChild(a);
    }, 1000);
    return;
  }

  // Stream directly through download endpoint with Content-Disposition: attachment
  let secureEndpoint = `/api/download/file?url=${encodeURIComponent(downloadUrl)}&filename=${encodeURIComponent(filename)}`;
  if (
    trimParams &&
    typeof trimParams.trimStart === 'number' &&
    typeof trimParams.trimEnd === 'number' &&
    trimParams.trimEnd > trimParams.trimStart
  ) {
    secureEndpoint += `&trimStart=${trimParams.trimStart}&trimEnd=${trimParams.trimEnd}`;
  }

  // If trimmed or audio, fetch blob so user sees exact progress and success only when file is ready
  const isTrimmedOrAudio = !!trimParams || /\.(mp3|wav|m4a|flac|aac)$/i.test(filename);
  if (isTrimmedOrAudio) {
    if (onStatusUpdate) {
      onStatusUpdate('Downloading and saving file to your Mac...');
    }

    const res = await fetch(secureEndpoint);
    if (!res.ok) {
      throw new Error(`Download stream failed (HTTP ${res.status})`);
    }

    const blob = await res.blob();
    const blobUrl = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(() => {
      document.body.removeChild(a);
      URL.revokeObjectURL(blobUrl);
    }, 5000);
    return;
  }
  
  const iframe = document.createElement('iframe');
  iframe.style.display = 'none';
  iframe.src = secureEndpoint;
  document.body.appendChild(iframe);
  setTimeout(() => {
    document.body.removeChild(iframe);
  }, 30000);
}
