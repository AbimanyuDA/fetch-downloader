export type MediaPlatform =
  | 'youtube'
  | 'tiktok'
  | 'instagram'
  | 'twitter'
  | 'facebook'
  | 'reddit'
  | 'soundcloud'
  | 'vimeo'
  | 'generic';

export interface MediaFormat {
  id: string;
  label: string;
  type: 'video' | 'audio';
  resolution?: string;
  quality?: string;
  extension: string;
  filesize?: number;
  filesizeFormatted?: string;
  url: string;
  isDirect?: boolean;
}

export interface MediaInfo {
  url: string;
  platform: MediaPlatform;
  platformName: string;
  title: string;
  author: string;
  authorUrl?: string;
  thumbnail: string;
  duration: number;
  durationFormatted: string;
  formats: MediaFormat[];
  description?: string;
}

export interface HistoryItem {
  id: string;
  title: string;
  author: string;
  thumbnail: string;
  platform: MediaPlatform;
  url: string;
  downloadedAt: number;
  formatLabel: string;
}

export interface ParseResponse {
  success: boolean;
  data?: MediaInfo;
  error?: string;
}
