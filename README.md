# EQfi

AI-powered system-wide equalizer for macOS. EQfi lives in your menu bar, detects what you're listening to, looks up genre metadata, generates an EQ profile with a local LLM (Ollama), and applies it to all system audio.

## Features

- **AI mode** — Detects now playing → genre lookup via hosted API (Spotify + MusicBrainz on server) → Ollama EQ generation → system-wide 8-band EQ
- **Manual mode** — 8-band sliders, built-in presets, custom preset save/load
- **Native system EQ** — Core Audio tap + aggregate device (macOS 14.2+), no third-party audio drivers
- **Local-first AI** — Ollama runs on your Mac; no cloud AI required for EQ generation

## Requirements

- macOS 14.2 or later
- Xcode 16+ (to build)
- [Ollama](https://ollama.com) with a Llama 3.2 model (e.g. `ollama pull llama3.2:3b`)
- **System Audio Recording** permission (prompted on first enable)
- **Genre API** — deploy the included Cloudflare Worker (`api/`) for public releases; the app falls back to MusicBrainz client-side if the proxy is unreachable

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

### 2. Genre API (required for public releases)

The macOS app calls a hosted genre proxy — Spotify credentials never ship in the app.

```bash
cd api
npm install
cp .dev.vars.example .dev.vars   # add Spotify + EQFI_API_KEY
npx wrangler kv namespace create GENRE_CACHE
# update wrangler.toml with KV IDs
npm run deploy
```

Then set in `EQfi/Config/Constants.swift`:

- `Constants.GenreProxy.baseURL` → your worker URL
- `Constants.GenreProxy.apiKey` → same value as `EQFI_API_KEY`

See [api/README.md](api/README.md) for full deployment steps.

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
Now Playing (AppleScript) → Genre Proxy API → EQ (Ollama) → System Audio EQ Engine
                                    ↓ (if proxy fails)
                              MusicBrainz (client fallback)
```

| Layer | Technology |
|-------|------------|
| UI | SwiftUI menu bar extra |
| Genre lookup | Cloudflare Worker (Spotify + MusicBrainz), client MusicBrainz fallback |
| AI pipeline | Ollama |
| Audio | Core Audio tap, AVAudioEngine, AVAudioUnitEQ |

## Project structure

```
EQfi/
├── api/              Genre proxy (Cloudflare Worker)
├── App/              App entry, dependency injection
├── Audio/            System-wide EQ engine and tap
├── Orchestrator/     AI pipeline coordination
├── Services/         Genre proxy client, Ollama, now playing, etc.
├── UI/               Menu bar and manual EQ views
└── ViewModels/       SwiftUI state
```

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and pull requests welcome at [github.com/ImagineBowl/EQfi](https://github.com/ImagineBowl/EQfi).
