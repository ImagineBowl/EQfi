# EQfi

AI-powered system-wide equalizer for macOS. EQfi lives in your menu bar, detects what you're listening to, looks up genre metadata, generates an EQ profile with a local LLM (Ollama), and applies it to all system audio.

## Features

- **AI mode** — Detects now playing → Spotify genre lookup (with MusicBrainz fallback) → Ollama EQ generation → system-wide 8-band EQ
- **Manual mode** — 8-band sliders, built-in presets, custom preset save/load
- **Native system EQ** — Core Audio tap + aggregate device (macOS 14.2+), no third-party audio drivers
- **Local-first** — Ollama runs on your Mac; no cloud AI required for EQ generation

## Requirements

- macOS 14.2 or later
- Xcode 16+ (to build)
- [Ollama](https://ollama.com) with a Llama 3.2 model (e.g. `ollama pull llama3.2:3b`)
- **Spotify Developer app** (optional) — for genre lookup via Spotify Web API; MusicBrainz is used automatically if Spotify is unavailable
- **System Audio Recording** permission (prompted on first enable)

## Supported now-playing sources

EQfi reads track metadata via AppleScript from:

- Spotify
- Apple Music
- Overcast
- Pocket Casts
- Apple Podcasts

Browser playback (e.g. YouTube in Chrome) is **not** supported yet.

## Setup

### 1. Clone and build

```bash
git clone https://github.com/ImagineBowl/EQfi.git
cd EQfi
open EQfi.xcodeproj
```

Build and run from Xcode (⌘R).

### 2. Spotify (optional)

1. Create an app at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Add redirect URI: `http://127.0.0.1:8888/callback` (do **not** use `localhost`)
3. Development Mode requires **Premium** on the account that owns the app
4. Enter **Client ID** and **Client Secret** in EQfi → **Spotify Settings**

If Spotify fails, EQfi falls back to **MusicBrainz** for genre tags.

### 3. Ollama

```bash
ollama serve
ollama pull llama3.2:3b
```

EQfi auto-detects installed models matching `llama3.2`, `llama3`, or `llama`.

### 4. Enable EQ

1. Open EQfi from the menu bar
2. Toggle **Enable EQfi**
3. Allow **System Audio Recording** when macOS prompts

## Architecture

```
Now Playing (AppleScript) → Genre (Spotify / MusicBrainz) → EQ (Ollama) → System Audio EQ Engine
```

| Layer | Technology |
|-------|------------|
| UI | SwiftUI menu bar extra |
| AI pipeline | Spotify API, MusicBrainz, Ollama |
| Audio | Core Audio tap, AVAudioEngine, AVAudioUnitEQ |

## Project structure

```
EQfi/
├── App/              App entry, dependency injection
├── Audio/            System-wide EQ engine and tap
├── Orchestrator/     AI pipeline coordination
├── Services/         Spotify, Ollama, now playing, etc.
├── UI/               Menu bar and manual EQ views
└── ViewModels/       SwiftUI state
```

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and pull requests welcome at [github.com/ImagineBowl/EQfi](https://github.com/ImagineBowl/EQfi).
