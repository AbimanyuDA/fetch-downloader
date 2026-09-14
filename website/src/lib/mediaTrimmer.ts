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
  onStatus?.('Fetching audio stream for trimming...');

  let res: Response;
  try {
    res = await fetch(audioUrl);
    if (!res.ok) throw new Error('Direct fetch failed');
  } catch {
    res = await fetch(`/api/download?url=${encodeURIComponent(audioUrl)}`);
  }

  if (!res.ok) {
    throw new Error('Could not download audio stream to perform trim');
  }

  onStatus?.('Decoding audio data...');
  const arrayBuffer = await res.arrayBuffer();

  const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
  const audioCtx = new AudioContextClass();
  const decodedBuffer = await audioCtx.decodeAudioData(arrayBuffer);

  const duration = decodedBuffer.duration;
  const actualStart = Math.max(0, Math.min(startSec, duration));
  const actualEnd = endSec > actualStart ? Math.min(endSec, duration) : duration;

  if (actualEnd <= actualStart) {
    throw new Error('End time must be greater than start time');
  }

  onStatus?.('Trimming audio buffer...');
  const sampleRate = decodedBuffer.sampleRate;
  const startSample = Math.floor(actualStart * sampleRate);
  const endSample = Math.floor(actualEnd * sampleRate);
  const frameCount = endSample - startSample;

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

  onStatus?.('Encoding trimmed audio file...');
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
  onStatus?.('Preparing video for trimming...');

  return new Promise((resolve, reject) => {
    const video = document.createElement('video');
    video.crossOrigin = 'anonymous';
    video.preload = 'auto';
    video.muted = false;

    video.src = videoUrl;

    const timeout = setTimeout(() => {
      reject(new Error('Video trimming timed out.'));
    }, 60000);

    video.onloadedmetadata = () => {
      video.currentTime = startSec;
    };

    video.onseeked = () => {
      try {
        const stream = (video as any).captureStream
          ? (video as any).captureStream()
          : (video as any).mozCaptureStream
          ? (video as any).mozCaptureStream()
          : null;

        if (!stream) {
          throw new Error('Browser does not support video stream capture');
        }

        const isMp4Supported = MediaRecorder.isTypeSupported('video/mp4');
        const mimeType = isMp4Supported ? 'video/mp4' : 'video/webm';
        const extension = isMp4Supported ? 'mp4' : 'webm';
        const recorder = new MediaRecorder(stream, { mimeType });
        const chunks: BlobPart[] = [];

        recorder.ondataavailable = (e) => {
          if (e.data.size > 0) chunks.push(e.data);
        };

        recorder.onstop = () => {
          clearTimeout(timeout);
          const blob = new Blob(chunks, { type: mimeType });
          resolve({ blob, extension });
        };

        video.ontimeupdate = () => {
          onStatus?.(`Capturing video clip (${Math.floor(video.currentTime)}s / ${Math.floor(endSec)}s)...`);
          if (video.currentTime >= endSec) {
            video.pause();
            recorder.stop();
          }
        };

        recorder.start();
        video.play().catch(reject);
      } catch (err) {
        clearTimeout(timeout);
        reject(err);
      }
    };

    video.onerror = () => {
      clearTimeout(timeout);
      reject(new Error('Failed to load video stream for trimming.'));
    };
  });
}
