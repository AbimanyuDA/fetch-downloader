import { MediaPlatform } from './types';
import { trimAudioFromUrl, trimVideoFromUrl } from './mediaTrimmer';

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

/**
 * Helper: save a Blob as a file download in the browser
 */
function saveBlobAsFile(blob: Blob, filename: string) {
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
}

/**
 * Determine if a filename represents an audio format
 */
function isAudioFile(filename: string): boolean {
  return /\.(mp3|wav|m4a|flac|aac|ogg|wma)$/i.test(filename);
}

export async function triggerBrowserDownload(
  downloadUrl: string,
  filename: string,
  trimParams?: { trimStart?: number; trimEnd?: number },
  onStatusUpdate?: (status: string) => void
): Promise<void> {
  if (typeof window === 'undefined') return;

  // Blob or data URLs — direct download
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

  const hasTrim =
    trimParams &&
    typeof trimParams.trimStart === 'number' &&
    typeof trimParams.trimEnd === 'number' &&
    trimParams.trimEnd > trimParams.trimStart;

  // Build server endpoint URL
  let secureEndpoint = `/api/download/file?url=${encodeURIComponent(downloadUrl)}&filename=${encodeURIComponent(filename)}`;
  if (hasTrim) {
    secureEndpoint += `&trimStart=${trimParams.trimStart}&trimEnd=${trimParams.trimEnd}`;
  }

  const isTrimmedOrAudio = hasTrim || isAudioFile(filename);

  if (isTrimmedOrAudio) {
    onStatusUpdate?.('Downloading media stream...');

    // Attempt server-side download/trim first
    const res = await fetch(secureEndpoint);

    if (res.ok) {
      // Server succeeded (ffmpeg available or no trim needed)
      onStatusUpdate?.('Saving file to your device...');
      const blob = await res.blob();
      saveBlobAsFile(blob, filename);
      return;
    }

    // Server returned error (503 = no ffmpeg, 500 = ffmpeg crashed, etc.)
    console.warn(`Server-side download failed (HTTP ${res.status}), falling back to client-side processing...`);

    if (hasTrim) {
      // Client-side trimming fallback
      // First, get the untrimmed stream from the server (without trim params)
      const isAudio = isAudioFile(filename);

      if (isAudio) {
        onStatusUpdate?.('Using browser audio trimmer (server trim unavailable)...');
        // trimAudioFromUrl handles fetching internally (direct + proxy fallback)
        const trimmedBlob = await trimAudioFromUrl(
          downloadUrl,
          trimParams.trimStart!,
          trimParams.trimEnd!,
          onStatusUpdate
        );
        // trimAudioFromUrl always returns WAV format
        const wavFilename = filename.replace(/\.[^.]+$/, '.wav');
        saveBlobAsFile(trimmedBlob, wavFilename);
        return;
      } else {
        // Video trim fallback
        onStatusUpdate?.('Using browser video trimmer (server trim unavailable)...');
        const result = await trimVideoFromUrl(
          downloadUrl,
          trimParams.trimStart!,
          trimParams.trimEnd!,
          onStatusUpdate
        );
        const videoFilename = filename.replace(/\.[^.]+$/, `.${result.extension}`);
        saveBlobAsFile(result.blob, videoFilename);
        return;
      }
    }

    // No trim needed but server still failed — retry without trim params
    onStatusUpdate?.('Retrying direct download...');
    const directEndpoint = `/api/download/file?url=${encodeURIComponent(downloadUrl)}&filename=${encodeURIComponent(filename)}`;
    const retryRes = await fetch(directEndpoint);
    if (!retryRes.ok) {
      throw new Error(`Download failed (HTTP ${retryRes.status}). The media source may be unavailable.`);
    }
    const blob = await retryRes.blob();
    saveBlobAsFile(blob, filename);
    return;
  }

  // Non-audio, non-trimmed: use iframe for direct streaming download
  const iframe = document.createElement('iframe');
  iframe.style.display = 'none';
  iframe.src = secureEndpoint;
  document.body.appendChild(iframe);
  setTimeout(() => {
    document.body.removeChild(iframe);
  }, 30000);
}
