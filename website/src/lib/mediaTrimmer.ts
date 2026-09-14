/**
 * Parses time format (HH:MM:SS or MM:SS or SS) into seconds
 */
export function parseTimeToSeconds(timeStr: string): number {
  if (!timeStr || typeof timeStr !== 'string') return 0;
  const parts = timeStr.trim().split(':').map((p) => parseFloat(p) || 0);

  if (parts.length === 3) {
    // HH:MM:SS
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  } else if (parts.length === 2) {
    // MM:SS
    return parts[0] * 60 + parts[1];
  } else if (parts.length === 1) {
    // SS
    return parts[0];
  }
  return 0;
}

/**
 * Converts seconds into MM:SS or HH:MM:SS string
 */
export function secondsToTimeString(totalSeconds: number): string {
  if (isNaN(totalSeconds) || totalSeconds < 0) return '00:00';
  const hrs = Math.floor(totalSeconds / 3600);
  const mins = Math.floor((totalSeconds % 3600) / 60);
  const secs = Math.floor(totalSeconds % 60);

  if (hrs > 0) {
    return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

/**
 * Converts an AudioBuffer into a standard 16-bit PCM WAV Blob
 */
export function audioBufferToWavBlob(buffer: AudioBuffer): Blob {
  const numChannels = buffer.numberOfChannels;
  const sampleRate = buffer.sampleRate;
  const format = 1; // PCM
  const bitDepth = 16;
  const bytesPerSample = bitDepth / 8;
  const blockAlign = numChannels * bytesPerSample;

  const numSamples = buffer.length;
  const dataSize = numSamples * blockAlign;
  const headerSize = 44;
  const totalSize = headerSize + dataSize;

  const arrayBuffer = new ArrayBuffer(totalSize);
  const view = new DataView(arrayBuffer);

  function writeString(offset: number, str: string) {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(offset + i, str.charCodeAt(i));
    }
  }

  // RIFF chunk descriptor
  writeString(0, 'RIFF');
  view.setUint32(4, totalSize - 8, true);
  writeString(8, 'WAVE');

  // fmt sub-chunk
  writeString(12, 'fmt ');
  view.setUint32(16, 16, true); // Subchunk1Size (16 for PCM)
  view.setUint16(20, format, true); // AudioFormat (1 for PCM)
  view.setUint16(22, numChannels, true); // NumChannels
  view.setUint32(24, sampleRate, true); // SampleRate
  view.setUint32(28, sampleRate * blockAlign, true); // ByteRate
  view.setUint16(32, blockAlign, true); // BlockAlign
  view.setUint16(34, bitDepth, true); // BitsPerSample

  // data sub-chunk
  writeString(36, 'data');
  view.setUint32(40, dataSize, true);

  // Write interleaved PCM samples
  let offset = 44;
  const channelData: Float32Array[] = [];
  for (let ch = 0; ch < numChannels; ch++) {
    channelData.push(buffer.getChannelData(ch));
  }

  for (let i = 0; i < numSamples; i++) {
    for (let ch = 0; ch < numChannels; ch++) {
      const sample = Math.max(-1, Math.min(1, channelData[ch][i]));
      const int16 = sample < 0 ? sample * 0x8000 : sample * 0x7fff;
      view.setInt16(offset, int16, true);
      offset += 2;
    }
  }

  return new Blob([arrayBuffer], { type: 'audio/wav' });
}

/**
 * Client-side high-precision audio trimmer using Web Audio API
 */
export async function trimAudioFromUrl(
  audioUrl: string,
  startSec: number,
  endSec: number,
  onStatus?: (msg: string) => void
): Promise<Blob> {
  onStatus?.('Fetching audio stream...');

  let res: Response;
  try {
    // Try direct fetch first for faster transfers
    res = await fetch(audioUrl);
    if (!res.ok) throw new Error('Direct fetch failed');
  } catch {
    // Fallback to proxy
    onStatus?.('Loading via proxy stream...');
    const proxyUrl = `/api/proxy?url=${encodeURIComponent(audioUrl)}`;
    res = await fetch(proxyUrl);
    if (!res.ok) {
      throw new Error(`Failed to download audio stream (HTTP ${res.status})`);
    }
  }

  onStatus?.('Decoding audio data in browser...');
  const arrayBuffer = await res.arrayBuffer();

  const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
  const audioCtx = new AudioContextClass();
  const decodedBuffer = await audioCtx.decodeAudioData(arrayBuffer);

  const duration = decodedBuffer.duration;
  const actualStart = Math.max(0, Math.min(startSec, duration));
  const actualEnd = endSec > actualStart ? Math.min(endSec, duration) : duration;

  if (actualEnd <= actualStart) {
    audioCtx.close();
    throw new Error(`Invalid trim duration: Start (${actualStart.toFixed(1)}s) must be less than End (${actualEnd.toFixed(1)}s).`);
  }

  onStatus?.(`Trimming audio (${secondsToTimeString(actualStart)} to ${secondsToTimeString(actualEnd)})...`);
  const sampleRate = decodedBuffer.sampleRate;
  const startSample = Math.floor(actualStart * sampleRate);
  const endSample = Math.floor(actualEnd * sampleRate);
  const frameCount = Math.max(1, endSample - startSample);

  const trimmedBuffer = audioCtx.createBuffer(
    decodedBuffer.numberOfChannels,
    frameCount,
    sampleRate
  );

  for (let ch = 0; ch < decodedBuffer.numberOfChannels; ch++) {
    const origData = decodedBuffer.getChannelData(ch);
    const trimmedData = trimmedBuffer.getChannelData(ch);
    trimmedData.set(origData.subarray(startSample, endSample));
  }

  onStatus?.('Encoding trimmed audio...');
  const wavBlob = audioBufferToWavBlob(trimmedBuffer);
  audioCtx.close();

  return wavBlob;
}

/**
 * Client-side video trimming using HTML5 video and MediaRecorder
 */
export async function trimVideoFromUrl(
  videoUrl: string,
  startSec: number,
  endSec: number,
  onStatus?: (msg: string) => void
): Promise<{ blob: Blob; extension: string }> {
  onStatus?.('Preparing video trimmer...');

  // Use proxy or direct URL
  const streamUrl = videoUrl.startsWith('http')
    ? `/api/proxy?url=${encodeURIComponent(videoUrl)}`
    : videoUrl;

  return new Promise((resolve, reject) => {
    // Create invisible video attached to DOM so browsers allow rendering & stream capture
    const video = document.createElement('video');
    video.crossOrigin = 'anonymous';
    video.preload = 'auto';
    video.muted = true; // Crucial to prevent autoplay policy rejection
    video.playsInline = true;
    video.style.position = 'fixed';
    video.style.top = '-9999px';
    video.style.left = '-9999px';
    video.style.opacity = '0';
    video.style.pointerEvents = 'none';
    video.style.width = '320px';
    video.style.height = '180px';
    document.body.appendChild(video);

    let recorder: MediaRecorder | null = null;
    let isCompleted = false;

    const cleanup = () => {
      clearTimeout(timeout);
      if (recorder && recorder.state !== 'inactive') {
        try { recorder.stop(); } catch {}
      }
      try {
        video.pause();
        video.removeAttribute('src');
        video.load();
        document.body.removeChild(video);
      } catch {}
    };

    const timeout = setTimeout(() => {
      if (!isCompleted) {
        cleanup();
        reject(new Error('Video trimming timed out. The video file may be too large or the network is slow.'));
      }
    }, 90000);

    video.onerror = () => {
      cleanup();
      reject(new Error('Could not load video stream for trimming. Please try downloading the full video or use audio trim.'));
    };

    video.onloadedmetadata = () => {
      const maxDuration = video.duration || endSec;
      const targetStart = Math.max(0, Math.min(startSec, maxDuration));
      const targetEnd = Math.min(endSec, maxDuration);

      if (targetEnd <= targetStart) {
        cleanup();
        reject(new Error('End time must be greater than start time.'));
        return;
      }

      onStatus?.(`Seeking to start time: ${secondsToTimeString(targetStart)}...`);
      video.currentTime = targetStart;
    };

    video.onseeked = () => {
      if (recorder) return; // Only initialize once

      try {
        const stream = (video as any).captureStream
          ? (video as any).captureStream()
          : (video as any).mozCaptureStream
          ? (video as any).mozCaptureStream()
          : null;

        if (!stream) {
          throw new Error('Your browser does not support video stream capture for trimming.');
        }

        const isMp4Supported = MediaRecorder.isTypeSupported('video/mp4;codecs=avc1');
        const mimeType = isMp4Supported ? 'video/mp4' : 'video/webm';
        const extension = isMp4Supported ? 'mp4' : 'webm';

        recorder = new MediaRecorder(stream, {
          mimeType,
          videoBitsPerSecond: 2500000, // 2.5 Mbps
        });

        const chunks: BlobPart[] = [];
        recorder.ondataavailable = (e) => {
          if (e.data && e.data.size > 0) {
            chunks.push(e.data);
          }
        };

        recorder.onstop = () => {
          isCompleted = true;
          const blob = new Blob(chunks, { type: mimeType });
          cleanup();
          resolve({ blob, extension });
        };

        video.ontimeupdate = () => {
          const current = video.currentTime;
          const progressPct = Math.min(99, Math.round(((current - startSec) / Math.max(1, endSec - startSec)) * 100));
          onStatus?.(`Capturing video clip (${secondsToTimeString(current)} / ${secondsToTimeString(endSec)}) [${progressPct}%]...`);

          if (current >= endSec) {
            video.pause();
            if (recorder && recorder.state === 'recording') {
              recorder.stop();
            }
          }
        };

        recorder.start(250);

        // Attempt slightly accelerated playback if browser permits
        try {
          video.playbackRate = 2.0;
        } catch {}

        video.play().catch((playErr) => {
          cleanup();
          reject(new Error(`Browser prevented video playback: ${playErr.message || playErr}`));
        });
      } catch (err: any) {
        cleanup();
        reject(err);
      }
    };

    video.src = streamUrl;
  });
}
