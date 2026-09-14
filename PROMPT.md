Saya ingin Anda bertindak sebagai Senior macOS Engineer, Product Designer, UX Engineer, dan Software Architect.

Buatkan saya aplikasi desktop native untuk macOS yang berfungsi sebagai media downloader dan converter berbasis URL, terutama untuk mengambil media dari URL YouTube yang pengguna memang memiliki hak atau izin untuk mengunduhnya.

Saya ingin aplikasi ini benar-benar usable, bukan sekadar mockup atau prototype UI.

Nama sementara aplikasi:
MediaFetch

Target platform:

- macOS
- Fokus utama Apple Silicon M1, M2, M3, M4 dan generasi setelahnya
- Tetap pertimbangkan kompatibilitas Intel Mac jika memungkinkan

Teknologi utama:

- Swift
- SwiftUI
- Gunakan arsitektur yang bersih dan modular
- Gunakan yt-dlp sebagai download engine jika memang menjadi pilihan terbaik
- Gunakan FFmpeg untuk conversion, trimming, audio extraction, remuxing, transcoding, metadata processing, dan operasi media lainnya
- Semua dependency management harus dibuat semudah mungkin bagi pengguna
- Jika memungkinkan, aplikasi dapat mendeteksi atau mengelola dependency secara otomatis tanpa pengguna harus membuka Terminal

Saya ingin Anda mengerjakan project ini secara menyeluruh.

TUJUAN UTAMA

Pengguna cukup:

1. Membuka aplikasi
2. Paste link YouTube
3. Aplikasi melakukan fetch metadata
4. Menampilkan informasi media
5. Memilih video atau audio
6. Memilih kualitas
7. Memilih format output
8. Opsional memilih bagian tertentu dari video
9. Memilih folder output
10. Klik Download
11. Melihat progress secara realtime
12. Mendapatkan hasil akhir secara otomatis

FITUR UTAMA

1. URL Input

Buat input URL yang besar dan mudah ditemukan.

Fitur:

- Paste URL
- Auto detect URL dari clipboard
- Tombol Paste
- Tombol Clear
- Validasi URL
- Detect platform
- Tombol Fetch
- Fetch otomatis opsional setelah URL valid
- Dukungan drag and drop URL jika memungkinkan

Contoh URL:
YouTube video
YouTube Shorts
YouTube playlist

Arsitektur sebaiknya dibuat extensible agar nantinya bisa mendukung platform lain tanpa merombak keseluruhan aplikasi.

2. Media Information

Setelah URL berhasil di-fetch, tampilkan:

- Thumbnail
- Judul
- Channel
- Durasi
- Tanggal upload jika tersedia
- Resolusi maksimum
- FPS maksimum
- Codec
- Audio codec
- Estimasi ukuran file
- URL source
- Informasi playlist jika link merupakan playlist

Gunakan card yang modern dan bersih.

Thumbnail harus memiliki aspect ratio yang benar.

3. Mode Download

Berikan segmented control:

Video
Audio

VIDEO MODE

Pengguna dapat memilih quality seperti:

- Best Available
- 2160p / 4K
- 1440p
- 1080p
- 720p
- 480p
- 360p

Jangan menampilkan pilihan resolusi yang tidak tersedia untuk video tersebut.

Jika memungkinkan tampilkan:

Resolution
FPS
Video codec
Audio codec
Estimated file size

Contoh:

1080p
60 FPS
H.264 + AAC
145 MB

Jika stream video dan audio terpisah, download keduanya lalu merge menggunakan FFmpeg.

AUDIO MODE

Pilihan kualitas:

- Best
- 320 kbps
- 256 kbps
- 192 kbps
- 128 kbps

Tampilkan bitrate asli jika diketahui.

4. Output Format

Video format:

MP4
MOV
MKV
WEBM
M4V

Audio format:

MP3
M4A
AAC
WAV
FLAC
OGG

Format yang tidak masuk akal terhadap sumber atau membutuhkan transcoding berat sebaiknya diberi penjelasan.

Jika hanya membutuhkan remuxing, jangan lakukan encoding ulang supaya proses lebih cepat dan tidak menurunkan kualitas.

Contoh:

WebM to MKV
Use remux

WebM to MP4 jika codec tidak kompatibel:
Transcoding required

Beri indikator:

Fast
Remux only

atau

Slower
Requires transcoding

5. Custom Time Range

Saya ingin fitur untuk hanya mengambil bagian tertentu dari video.

Berikan toggle:

Trim Media

Kemudian input:

Start Time
End Time

Format:
HH:MM:SS

Contoh:
Start
00:02:15

End
00:05:45

Tambahkan alternatif:

Start + Duration

Contoh:
Start
00:02:15

Duration
00:03:30

Tambahkan slider timeline jika memungkinkan.

Timeline harus menunjukkan:

Start marker
End marker
Total duration

Pengguna dapat drag marker untuk menentukan bagian yang ingin disimpan.

Tambahkan tombol:

Reset Range

Sistem harus memastikan:

- Start tidak boleh negatif
- End tidak boleh lebih panjang dari durasi video
- Start harus lebih kecil dari End

Gunakan FFmpeg atau metode paling efisien untuk memotong media.

Jika memungkinkan, gunakan stream copy ketika codec memungkinkan supaya tidak perlu re-encode.

6. Output Settings

Berikan section:

Output

Isi:

Save to:
Folder path

Tombol:
Choose Folder

Pilihan default:
Downloads

Tambahkan filename template.

Contoh default:

%(title)s

Pilihan template:

Title
Title + Channel
Title + Resolution
Custom

Contoh custom:

%(channel)s - %(title)s - %(resolution)s

Pastikan karakter yang tidak valid untuk filename otomatis dibersihkan.

7. Download Queue

Aplikasi harus bisa menjalankan beberapa download.

Buat Download Queue.

Setiap item menunjukkan:

Thumbnail
Title
Quality
Format
File size
Progress
Download speed
ETA
Status

Status:

Waiting
Fetching
Downloading
Processing
Merging
Converting
Completed
Failed
Cancelled

Controls:

Pause jika memang memungkinkan
Resume
Cancel
Retry
Remove

Tambahkan:

Pause All
Resume All
Clear Completed

Pengguna dapat mengatur:

Maximum concurrent downloads

Pilihan:
1
2
3
4

Default:
2

8. Download Progress

Progress harus realtime.

Contoh:

68%
34.2 MB / 50.1 MB
8.4 MB/s
ETA 00:02

Setelah download selesai dan FFmpeg sedang melakukan processing:

Processing Media

atau:

Merging Video and Audio

atau:

Converting to MP3

Jangan membuat progress terlihat stuck.

Gunakan animated progress indicator untuk proses yang tidak memiliki percentage.

9. Completed Download

Jika berhasil:

Status:
Completed

Berikan action:

Open File
Show in Finder
Play
Copy File Path
Remove from History

Tampilkan notifikasi macOS:

Download Completed
filename.mp4

10. Playlist Support

Jika URL berupa playlist:

Tampilkan list video.

Berikan checkbox:

Select All

Pengguna dapat memilih video mana yang ingin di-download.

Tambahkan informasi:

Video count
Total estimated size
Estimated duration

Pengaturan quality bisa:

Apply same settings to all

atau:

Customize individually

11. Subtitle Support

Tambahkan opsi:

Download Subtitles

Language:
Auto
English
Indonesian
dan bahasa lain yang tersedia

Format:
SRT
VTT

Tambahkan:

Embed subtitles

Jika format output mendukung.

12. Thumbnail

Opsi:

Download Thumbnail

Pilihan:
JPG
PNG
WEBP

Opsi:
Embed thumbnail as cover art

Terutama untuk MP3, M4A, dan audio file.

13. Metadata

Toggle:

Embed Metadata

Metadata dapat meliputi:

Title
Artist / Channel
Album jika tersedia
Upload date
Description
Thumbnail
Source URL

Untuk MP3 atau M4A, tuliskan metadata menggunakan FFmpeg atau library yang sesuai.

14. Advanced Video Settings

Buat Advanced Settings yang collapsed secara default.

Video codec:

Auto
Copy
H.264
H.265 / HEVC
AV1
VP9

Audio codec:

Auto
Copy
AAC
MP3
Opus
FLAC

Frame rate:

Original
60
30
24

Jangan melakukan transcoding kecuali pengguna memang meminta format atau codec yang membutuhkan transcoding.

15. Quality Strategy

Tambahkan pilihan sederhana:

Quality Preference

Best Quality
Balanced
Small File

Best Quality:
Prioritaskan quality tertinggi.

Balanced:
Prioritaskan codec kompatibel dan ukuran moderat.

Small File:
Prioritaskan codec efisien dan bitrate lebih kecil.

16. File Size Estimator

Sebelum download, jika memungkinkan tampilkan estimasi ukuran.

Contoh:

Estimated Size
184 MB

Setelah pengguna mengganti:

Resolution
Codec
Audio bitrate
Format

Estimasi diperbarui.

Tidak perlu berpura-pura presisi jika metadata tidak cukup.

Gunakan tanda:

Approx. 184 MB

17. Clipboard Detection

Jika aplikasi mendeteksi clipboard berisi URL media yang valid:

Tampilkan notification kecil di aplikasi:

Media URL detected

dengan tombol:

Paste URL

Jangan melakukan download otomatis.

18. Drag and Drop

Pengguna dapat drag URL ke window.

Jika memungkinkan juga dukung:

Drag text containing URL

19. Download History

Buat halaman History.

Informasi:

Thumbnail
Filename
Source title
Source URL
Format
Quality
Date downloaded
File path

Action:

Open
Show in Finder
Copy Link
Download Again
Delete History Entry

History disimpan secara lokal.

20. Search dan Filter History

Search:

Search downloads

Filter:

All
Video
Audio
Completed
Failed

Sort:

Newest
Oldest
Name
File size

21. Preferences

Buat halaman Settings.

Sections:

General
Downloads
Conversion
Appearance
Advanced

GENERAL

Default output folder

Remember last settings

Clipboard detection

Notification

Keep download history

DOWNLOADS

Concurrent downloads

Default video quality

Default audio quality

Default format

Retry failed downloads

CONVERSION

Default video codec

Default audio codec

Prefer remux over transcode

Hardware acceleration jika tersedia

APPEARANCE

System
Light
Dark

ADVANCED

Path yt-dlp

Path FFmpeg

Check dependency

Update yt-dlp

Reset Settings

22. Dependency Management

Ini sangat penting.

Aplikasi harus mendeteksi:

yt-dlp
FFmpeg
FFprobe

Jika dependency belum tersedia:

Jangan langsung error teknis.

Tampilkan onboarding:

Required Components

yt-dlp
FFmpeg

Berikan solusi paling user friendly.

Idealnya aplikasi mengelola bundled binary atau mekanisme instalasi sendiri dengan tetap mempertimbangkan lisensi, code signing, sandboxing, dan distribusi macOS.

Jika memilih menggunakan binary eksternal, jelaskan implementasi yang realistis.

Jangan mengharuskan pengguna teknis menjalankan command Terminal hanya untuk menggunakan aplikasi.

23. yt-dlp Update

Karena extractor website dapat berubah:

Buat fitur:

Check yt-dlp Update

Current version
Latest version

Update

Jangan melakukan update tanpa persetujuan pengguna.

24. Error Handling

Error harus human friendly.

Jangan hanya tampilkan:

Process exited with code 1

Contoh:

Video unavailable

This video may be private, deleted, region restricted, or require authentication.

Contoh lain:

FFmpeg not found

MediaFetch needs FFmpeg to process this format.

Action:
Install Component

Tetap sediakan:

Show Technical Details

agar developer atau advanced user dapat melihat stdout, stderr, exit code dan command.

25. Log Viewer

Advanced users dapat membuka:

Activity Log

Isi:

Timestamp
Process
Message
Status

Berikan tombol:

Copy Log
Export Log
Clear Log

Jangan membocorkan credential atau cookie pada log.

26. Authentication

Jika suatu media membutuhkan login, jangan mencoba membypass DRM atau proteksi.

Buat arsitektur agar nantinya memungkinkan penggunaan browser cookies pengguna secara sah jika memang diperlukan dan pengguna memiliki akses terhadap kontennya.

Jangan menyimpan credential plaintext.

27. Privacy

Saya ingin aplikasi privacy-first.

- Tidak ada analytics secara default
- Tidak ada tracking
- Tidak upload URL pengguna ke server aplikasi sendiri
- Semua media processing dilakukan lokal di Mac
- History hanya disimpan lokal
- Tidak ada telemetry kecuali pengguna secara eksplisit opt-in

Tambahkan Privacy section pada About atau Settings.

28. Keyboard Shortcuts

Tambahkan shortcut:

Command + V
Paste URL

Command + Return
Fetch

Command + D
Download

Command + ,
Settings

Command + K
Clear URL jika tidak konflik dengan convention macOS

Gunakan shortcut yang mengikuti Human Interface Guidelines macOS.

29. Native macOS Integration

Gunakan:

NSOpenPanel untuk memilih folder

Finder integration

macOS notifications

Menu Commands

Keyboard shortcuts

Dock progress jika realistis

Open in Finder

Quick Look jika memungkinkan

30. Hardware Acceleration

Untuk proses encoding yang kompatibel, pertimbangkan penggunaan:

VideoToolbox

Contoh:
H.264 VideoToolbox
HEVC VideoToolbox

Agar transcoding di Apple Silicon lebih cepat.

Tetapi jangan mengorbankan kualitas tanpa alasan.

31. Theme dan Design

Ini sangat penting.

Saya tidak ingin tampilan yang terlihat seperti aplikasi hasil generate AI.

Hindari:

- Gradient berlebihan
- Neon
- Glassmorphism berlebihan
- Card di dalam card di dalam card
- Border di semua komponen
- Shadow berlebihan
- Rounded corner terlalu besar
- Emoji sebagai icon UI
- Terlalu banyak warna
- Hero text seperti landing page
- Dashboard yang terasa seperti website SaaS
- Purple gradient generik
- Layout dengan terlalu banyak whitespace
- Teks marketing yang tidak diperlukan
- Icon random
- UI terlalu ramai

Gunakan desain seperti aplikasi macOS modern.

Referensi filosofi desain:

Finder
Safari
Arc
Raycast
Things
Craft
Linear
CleanShot X
IINA

Jangan menyalin aplikasi tersebut, cukup gunakan sebagai referensi tingkat kualitas.

Gunakan SF Symbols.

Gunakan hierarchy yang jelas.

Design direction:

Minimal
Professional
Native
Calm
Premium
Functional

32. Main Window

Layout yang saya bayangkan:

Sidebar kiri:

Download
Queue
History
Settings

Main content:

URL input pada bagian atas

Setelah fetch:

Media Preview

Kemudian:

Mode
Quality
Format
Trim
Output

Bagian bawah:

Primary button:
Download

Ketika belum ada URL:

Empty state sederhana.

Contoh:

Drop or paste a media link

Paste a URL to inspect available formats.

Tombol:

Paste URL

Jangan menggunakan kalimat marketing.

33. Window Size

Initial window sekitar:

1050 x 720

Tetapi responsive terhadap resize.

Minimum window size harus masuk akal.

Sidebar dapat collapse jika diperlukan.

34. Typography

Gunakan system font San Francisco.

Hierarchy:

Large Title secukupnya
Title
Headline
Body
Caption

Jangan menggunakan terlalu banyak font weight.

35. Color

Gunakan macOS semantic colors.

Background:
system background

Secondary background:
secondary system background

Accent:
gunakan satu accent utama.

Harus bekerja dengan benar pada:

Light Mode
Dark Mode

36. Interaction

Gunakan subtle animation hanya jika berguna.

Contoh:

Fetch loading indicator
Progress animation
Expandable advanced settings
Queue transition

Durasi animation pendek.

Jangan membuat UI terasa seperti website.

37. Confirmation

Jangan memberi confirmation dialog untuk hal trivial.

Confirmation hanya untuk:

Cancel active downloads
Delete file
Clear entire history

38. Architecture

Gunakan architecture yang maintainable.

Contoh struktur:

MediaFetch
App
Core
Models
Services
DownloadEngine
ConversionEngine
MetadataEngine
Views
ViewModels
Components
Utilities
Persistence

Pisahkan:

yt-dlp process management
FFmpeg process management
Download queue
Metadata parser
Format selection
File management
Settings
History

Jangan menaruh seluruh kode ke ContentView.swift.

39. Process Management

Buat ProcessRunner yang aman.

Harus mampu:

Run executable
Capture stdout
Capture stderr
Stream stdout realtime
Parse progress
Cancel process
Handle exit status
Avoid blocking UI thread

Gunakan Swift concurrency:

async/await
Task
actors jika relevan

Jangan gunakan architecture concurrency yang berlebihan.

40. Download Engine

Buat abstraction misalnya:

protocol MediaDownloadEngine

Implementasi:

YTDLPDownloadEngine

Sehingga ke depan engine dapat diganti.

41. FFmpeg Engine

Buat abstraction:

MediaProcessingEngine

Fitur:

convert
remux
trim
extract audio
merge
embed metadata
embed thumbnail

42. Model

Buat model seperti:

MediaInfo
MediaFormat
DownloadRequest
DownloadTask
DownloadProgress
DownloadStatus
OutputSettings
TrimRange

43. Persistence

Gunakan SwiftData jika sesuai.

Simpan:

Download history
Settings
Recent folders

Jangan simpan data sensitif sembarangan.

44. State Restoration

Jika aplikasi ditutup:

History tetap ada.

Jika ada incomplete queue, aplikasi dapat menandainya sebagai Interrupted.

Jika realistis, berikan pilihan Resume.

45. Filename Collision

Jika file sudah ada:

Jangan overwrite diam-diam.

Pilihan:

Keep Both
Replace
Cancel

Default:
Keep Both

Contoh:

video.mp4
video 2.mp4

46. Disk Space

Sebelum download file besar:

Periksa free disk space jika memungkinkan.

Jika estimasi file lebih besar dari ruang tersisa:

Tampilkan warning.

47. Power Management

Jangan membuat Mac sleep ketika download atau transcoding besar sedang berlangsung jika memungkinkan.

Setelah semua proses selesai, lepaskan assertion.

48. Network Handling

Jika jaringan terputus:

Tampilkan:

Connection Lost

Retry otomatis dalam batas tertentu.

Contoh:

3 attempts

Kemudian status:

Failed

Dengan tombol Retry.

49. URL History

Boleh tambahkan recent URLs sebagai suggestion, tetapi berikan setting untuk menonaktifkan atau membersihkannya.

50. Batch URL

Tambahkan fitur:

Add Multiple URLs

Pengguna dapat paste beberapa link sekaligus.

Satu URL per baris.

Aplikasi fetch semuanya lalu memasukkan ke queue.

51. Presets

Tambahkan presets.

Contoh:

Best Video
1080p MP4
720p MP4
Audio MP3 320
Audio MP3 192
Original Quality

Pengguna juga dapat membuat Custom Preset.

52. Quick Actions

Jika pengguna sering menggunakan format tertentu:

Download button memiliki dropdown:

Download
Download Using Last Settings
Audio Only
Best Video

Tetapi tetap jaga UI sederhana.

53. Media Preview

Jika memungkinkan, tambahkan preview player ringan untuk mengecek video sebelum download atau trimming.

Gunakan AVKit atau AVFoundation jika memungkinkan.

Tidak wajib pada tahap MVP jika kompleks.

54. About

About MediaFetch

Tampilkan:

App version
yt-dlp version
FFmpeg version

Buttons:

GitHub jika nantinya ada
View Licenses
Privacy

55. Accessibility

Pastikan:

VoiceOver labels
Keyboard navigation
Proper contrast
Dynamic type jika relevan
Tooltips untuk icon-only buttons

56. Legal UX

Jangan membuat fitur bypass DRM atau restriction.

Tambahkan catatan kecil pada onboarding atau About:

Only download media you own or have permission to save. Availability and permitted use may depend on the source platform and content rights.

Jangan membuat pop-up berulang yang mengganggu.

57. Code Quality

Saya ingin:

Production-style code
Clear naming
Modular code
Comments hanya ketika memang membantu
No unnecessary abstraction
No giant files
No duplicated logic
Strong error handling
No force unwrap jika tidak perlu
No blocking process pada main thread

58. Testing

Buat unit tests untuk:

URL validation
Time parsing
Filename sanitization
Format selection
Trim validation
Progress parsing

Jika memungkinkan tambahkan test untuk yt-dlp output parser.

59. README

Buat README yang berisi:

Project overview
Architecture
Requirements
How to build
Dependencies
How yt-dlp integration works
How FFmpeg integration works
macOS permissions
Known limitations
Future roadmap

60. Development Priorities

Prioritas pertama:

Aplikasi benar-benar bisa fetch metadata.

Prioritas kedua:

Video download benar-benar bekerja.

Prioritas ketiga:

Audio extraction.

Prioritas keempat:

Quality selection.

Prioritas kelima:

Output format.

Prioritas keenam:

Custom start and end time.

Prioritas ketujuh:

Queue dan progress.

Prioritas kedelapan:

History.

Prioritas kesembilan:

Advanced features.

Jangan mengorbankan core functionality demi terlalu banyak fitur.

61. MVP

Untuk MVP minimum pastikan fitur ini 100 persen berfungsi:

- Paste YouTube URL
- Fetch metadata
- Thumbnail
- Title
- Duration
- Pilih quality
- Pilih MP4
- Pilih MP3
- Pilih MOV
- Trim berdasarkan start dan end time
- Pilih output folder
- Download
- Progress realtime
- Merge audio + video
- Conversion
- Error handling
- Show in Finder
- Download history

62. Development Method

Jangan langsung menulis ribuan baris kode tanpa struktur.

Kerjakan dengan urutan:

STEP 1
Analisis requirements.

STEP 2
Tentukan architecture.

STEP 3
Buat folder structure.

STEP 4
Buat data models.

STEP 5
Buat yt-dlp wrapper.

STEP 6
Buat FFmpeg wrapper.

STEP 7
Buat metadata fetch pipeline.

STEP 8
Buat download pipeline.

STEP 9
Buat progress parser.

STEP 10
Buat download queue.

STEP 11
Buat SwiftUI interface.

STEP 12
Hubungkan UI ke backend.

STEP 13
Implement trimming.

STEP 14
Implement conversion.

STEP 15
Implement history.

STEP 16
Error handling.

STEP 17
Testing.

STEP 18
Polish UI.

STEP 19
Audit seluruh aplikasi.

STEP 20
Berikan final project structure dan instructions untuk menjalankan.

Setelah setiap langkah, lanjutkan mengimplementasikan project. Jangan hanya memberikan penjelasan teori.

63. Coding Rules

Hindari penggunaan em dash dalam seluruh UI copy, dokumentasi, komentar, README, dan teks yang Anda hasilkan.

Jangan menggunakan karakter:
—

Gunakan koma, titik, titik dua, atau tanda hubung biasa jika diperlukan.

Hindari gaya tulisan yang terasa seperti AI generated.

Jangan menggunakan pola kalimat marketing seperti:

"Powerful, seamless, and intuitive experience."

Gunakan bahasa UI yang sederhana dan natural.

Contoh:

Paste URL
Fetch Media
Download
Choose Folder
Video Quality
Audio Quality
Output Format
Start Time
End Time

64. UI Copy

Gunakan English untuk UI aplikasi agar tampak universal.

Tetapi seluruh penjelasan kepada saya selama development boleh menggunakan Bahasa Indonesia.

65. Jangan membuat fake functionality

Ini sangat penting.

Jangan membuat button yang hanya mengubah state UI tanpa benar-benar menjalankan fungsi.

Jika fitur belum selesai, tandai sebagai:

Not implemented

dan selesaikan sebelum project dianggap final.

Jangan gunakan mock data untuk final implementation.

66. Command Safety

Ketika menjalankan yt-dlp atau FFmpeg:

Jangan membuat command menggunakan raw string concatenation yang rentan terhadap escaping atau command injection.

Gunakan Process dengan executableURL dan arguments secara terpisah.

Validate semua input.

67. Final Audit

Sebelum menganggap project selesai, lakukan audit:

FUNCTIONAL

- Apakah fetch URL bekerja?
- Apakah quality selection benar-benar diterapkan?
- Apakah MP4 bekerja?
- Apakah MOV bekerja?
- Apakah MP3 bekerja?
- Apakah trimming bekerja?
- Apakah output folder bekerja?
- Apakah progress realtime?
- Apakah cancellation bekerja?
- Apakah queue bekerja?

UX

- Apakah pengguna baru langsung memahami aplikasi?
- Apakah hierarchy jelas?
- Apakah UI terlihat seperti aplikasi macOS?
- Apakah Dark Mode benar?
- Apakah tidak ada overflow?
- Apakah tidak ada layout yang terlihat seperti generated dashboard?

TECHNICAL

- Tidak ada main-thread blocking
- Tidak ada force unwrap berbahaya
- Tidak ada hardcoded path
- Tidak ada dependency silently missing
- Process cleanup benar
- Temporary files dihapus
- Error dapat dibaca pengguna

DESIGN

- Konsisten
- Minimal
- Native
- Professional
- Tidak banyak warna
- Tidak menggunakan emoji untuk icon
- Tidak menggunakan gradient generik
- Tidak menggunakan em dash
- Spacing konsisten
- SF Symbols konsisten

68. Output yang Saya Inginkan dari Anda

Saya tidak hanya ingin tutorial.

Saya ingin Anda membuat project yang benar-benar dapat dibuka di Xcode.

Berikan:

1. Arsitektur final
2. Folder structure
3. Semua source code yang diperlukan
4. File configuration
5. Dependency handling
6. yt-dlp integration
7. FFmpeg integration
8. UI SwiftUI
9. Download engine
10. Conversion engine
11. Trim engine
12. Queue manager
13. History persistence
14. Settings
15. Error handling
16. Unit tests
17. README
18. Build instructions
19. Distribution considerations
20. Final audit

Jika Anda memiliki akses untuk membuat dan mengedit file project secara langsung, jangan berhenti pada penjelasan. Buat file project tersebut secara langsung.

Jika menemukan keputusan teknis yang belum saya tentukan, pilih pendekatan yang menurut Anda paling production-ready dan paling cocok untuk aplikasi native macOS.

Jangan terus meminta konfirmasi untuk keputusan kecil. Ambil keputusan teknis yang masuk akal dan lanjutkan.

Target akhirnya adalah aplikasi macOS downloader dan media converter yang terlihat seperti produk software sungguhan, bukan project demo, bukan template generik, dan bukan aplikasi yang terlihat seperti hasil generate AI.
