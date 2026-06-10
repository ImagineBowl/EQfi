# EQfi Genre API

Cloudflare Worker that proxies Spotify genre lookups for the EQfi macOS app. Spotify credentials stay on the server; the app sends only track title and artist.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Liveness check (no auth) |
| GET | `/v1/genre?title=…&artist=…` | Genre lookup (requires API key) |

### Auth

```
Authorization: Bearer <EQFI_API_KEY>
```

### Success response

```json
{
  "genres": ["rock", "alternative rock"],
  "source": "spotify"
}
```

`source` is one of: `cache`, `spotify`, `musicbrainz`.

## Setup

### 1. Install dependencies

Requires **Node.js 18+** (Node 20 works with Wrangler 3; Node 22+ if you prefer Wrangler 4).

```bash
cd api
npm install
```

### 2. Create a KV namespace

```bash
npx wrangler kv namespace create GENRE_CACHE
npx wrangler kv namespace create GENRE_CACHE --preview
```

Copy the returned IDs into `wrangler.toml` (`id` and `preview_id`).

### 3. Set secrets

```bash
npx wrangler secret put SPOTIFY_CLIENT_ID
npx wrangler secret put SPOTIFY_CLIENT_SECRET
npx wrangler secret put EQFI_API_KEY
```

For local dev, copy `.dev.vars.example` to `.dev.vars` and fill in values.

### 4. Deploy

```bash
npm run deploy
```

Note the worker URL (e.g. `https://eqfi-genre-api.<account>.workers.dev`).

### 5. Configure the macOS app

In `EQfi/Config/Constants.swift`, set:

- `Constants.GenreProxy.baseURL` → your worker URL
- `Constants.GenreProxy.apiKey` → same value as `EQFI_API_KEY`

## Local development

```bash
cp .dev.vars.example .dev.vars
# edit .dev.vars
npm run dev
```

Test:

```bash
curl -s -H "Authorization: Bearer YOUR_KEY" \
  "http://localhost:8787/v1/genre?title=Locked%20Out%20of%20Heaven&artist=Bruno%20Mars"
```

## Spotify quota

Apply for **Extended Quota Mode** in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) before wide public distribution.

## Security notes

- `EQFI_API_KEY` is a **client key** embedded in the app — it limits casual abuse but is not fully secret. Rotate it if leaked.
- Never commit `.dev.vars` or Spotify credentials to git.
