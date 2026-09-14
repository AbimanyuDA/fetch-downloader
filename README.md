# MediaFetch for macOS

MediaFetch is a native macOS desktop application designed for media downloading and conversion from YouTube and web URLs. Built with Swift and SwiftUI, it integrates yt-dlp and FFmpeg through an asynchronous process execution engine, multi-task download queue, custom trimming, format transcoding, persistence, and native macOS design patterns.

## Overview

MediaFetch provides a fast, uncluttered workflow:
1. Paste a media link or let clipboard detection identify it.
2. Inspect metadata (thumbnail, resolution, fps, codecs, duration, estimated file size).
3. Choose mode (Video or Audio), quality, and target format.
4. Optionally specify a custom start and end time to trim media.
5. Select destination folder and filename pattern.
6. Monitor download progress, speed, and ETA in real time.
7. Open downloaded media or reveal it in Finder with a single click.

## Architecture

The project adheres to a modular MVVM architecture:

```
MediaFetch/
├── Package.swift               # Swift Package Manager manifest
├── project.yml                 # XcodeGen configuration
├── MediaFetch.xcodeproj        # Native Xcode project
├── Resources/                  # Entitlements, Info.plist, and Asset catalog
├── Sources/
│   ├── App/                    # Application entry point, AppState, menus, shortcuts
│   ├── Core/                   # Subprocess runner, dependency manager, power management
│   ├── Models/                 # MediaInfo, MediaFormat, OutputSettings, DownloadTask, HistoryEntry
│   ├── Services/
│   │   ├── DownloadEngine/     # yt-dlp wrapper and realtime progress parser
│   │   ├── ConversionEngine/   # FFmpeg wrapper (stream copy, VideoToolbox transcoding, trimming)
│   │   ├── MetadataEngine/     # yt-dlp JSON metadata parser and playlist extractor
│   │   ├── Queue/              # Concurrency-controlled task coordinator
│   │   ├── Persistence/        # JSON history storage and UserDefaults settings
│   │   └── Logging/            # Activity logger with sanitized diagnostic output
│   ├── ViewModels/             # MVVM view models for Download, Queue, History, Settings
│   ├── Views/                  # Native SwiftUI views and components
│   └── Utilities/              # Time, file size, filename sanitization, and URL utilities
└── Tests/                      # Unit test suites covering parsing, formatting, and validation
```

## Requirements

- macOS 14.0 (Sonoma) or newer.
- Apple Silicon (M1, M2, M3, M4, or later) or Intel Mac.
- Xcode 15.0 or newer (or Swift 5.10+ command-line tools).
- yt-dlp and FFmpeg.

## Dependency Management

MediaFetch automatically searches for `yt-dlp`, `ffmpeg`, and `ffprobe` across multiple locations:
1. Application Support: `~/Library/Application Support/MediaFetch/bin/`
2. App Bundle Resources: `Contents/Resources/bin/` (if distributed bundled)
3. Homebrew: `/opt/homebrew/bin/` and `/usr/local/bin/`
4. System PATH: `/usr/bin/`, `/bin/`
5. User overrides configured in Settings

### In-App One-Click Installation

If `yt-dlp` is missing, users can download the official macOS standalone binary directly from within the application (Settings > Advanced > Install Component) without opening the Terminal.

If using Homebrew, dependencies can also be installed with:
```bash
brew install ffmpeg yt-dlp
```

## How yt-dlp Integration Works

- Subprocesses are spawned safely through `ProcessRunner` using explicit argument arrays rather than shell string concatenation to eliminate injection risks.
- Output streams are read line-by-line using non-blocking asynchronous file handles. Both `\n` and carriage return `\r` updates are captured to provide smooth real-time progress percentages, speeds, and ETAs.
- The engine dynamically crafts optimal format selectors (e.g. `bv*[height<=1080]+ba/b` for 1080p, or `-x --audio-format mp3` for audio extraction).
- Trimming requests during download use yt-dlp `--download-sections` to download only the specified time range, saving bandwidth and disk space.

## How FFmpeg Integration Works

- **Stream Copy (Remuxing):** When converting between compatible containers (e.g. WebM to MKV, or MP4 container changes without codec conversion), FFmpeg uses `-c copy` for instant output without re-encoding.
- **Hardware Acceleration:** When transcoding is required on macOS, MediaFetch utilizes `h264_videotoolbox` and `hevc_videotoolbox` to leverage Apple Silicon hardware media engines for high-speed encoding.
- **Audio Extraction:** Supports high-quality transcoding to MP3 (libmp3lame up to 320 kbps), AAC, M4A, WAV, FLAC, and OGG.
- **Trimming:** Trims media with sample accuracy using `-ss` and `-t` flags.

## Permissions and Security

- **Sandboxing and Hardened Runtime:** Configured with network client access, user-selected file read/write, and Downloads folder access.
- **Privacy First:**
  - Zero analytics, telemetry, or user tracking.
  - Zero cloud dependencies for metadata or processing.
  - All processing and history storage remains 100% local on the user Mac.
- **System Sleep Prevention:** Utilizes `IOPMAssertionCreateWithName` with `kIOPMAssertionTypePreventUserIdleSystemSleep` to ensure the Mac does not go to sleep during active downloads or long conversions, releasing assertions automatically upon completion.

## How to Build and Run

### Option 1: Open in Xcode
1. Open the project in Xcode:
   ```bash
   open MediaFetch.xcodeproj
   ```
2. Select the `MediaFetch` scheme and target destination `My Mac`.
3. Press `Cmd + R` to build and run.

### Option 2: Build via Terminal
To build using `xcodebuild`:
```bash
xcodebuild -project MediaFetch.xcodeproj -scheme MediaFetch -destination 'platform=macOS' build CODE_SIGNING_ALLOWED=NO
```

### Option 3: Run Unit Tests
To run the full unit test suite:
```bash
swift test
```

## Known Limitations

- Private or age-restricted videos that require authentication cannot be downloaded unless browser cookies are exported and supplied.
- Stream copy trimming on certain container formats may align to the nearest keyframe; when exact millisecond cuts are required, re-encoding is applied automatically.

## Future Roadmap

- Browser extension for sending links directly to MediaFetch with a single click.
- Native AVPlayer preview sheet to watch clips directly before starting downloads.
- Drag and drop audio track replacement.
