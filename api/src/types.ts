export interface Env {
  SPOTIFY_CLIENT_ID: string;
  SPOTIFY_CLIENT_SECRET: string;
  EQFI_API_KEY: string;
  SPOTIFY_MARKET?: string;
  GENRE_CACHE?: KVNamespace;
}

export type GenreSource = "cache" | "spotify" | "musicbrainz";

export interface GenreResponse {
  genres: string[];
  source: GenreSource;
}

const memoryCache = new Map<string, { payload: GenreResponse; expiresAt: number }>();
const MEMORY_TTL_MS = 60 * 60 * 24 * 30 * 1000;

export function cacheKey(title: string, artist: string): string {
  return `${artist}|${title}`.toLowerCase().trim();
}

export function primaryArtist(artist: string): string {
  return artist.split(/[,&;]/)[0]?.trim() ?? artist;
}

export function sanitizeSearchText(value: string): string {
  return value.replace(/"/g, "").trim();
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

export function unauthorized(): Response {
  return jsonResponse({ error: "Unauthorized" }, 401);
}

export function badRequest(message: string): Response {
  return jsonResponse({ error: message }, 400);
}

export function verifyApiKey(request: Request, env: Env): boolean {
  const expected = env.EQFI_API_KEY?.trim();
  if (!expected) return false;
  const header = request.headers.get("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  return token.length > 0 && token === expected;
}

function readMemoryCache(key: string): GenreResponse | null {
  const entry = memoryCache.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return { genres: entry.payload.genres, source: "cache" };
}

function writeMemoryCache(
  key: string,
  genres: string[],
  source: Exclude<GenreSource, "cache">,
): void {
  memoryCache.set(key, {
    payload: { genres, source },
    expiresAt: Date.now() + MEMORY_TTL_MS,
  });
}

export async function readCachedGenres(
  kv: KVNamespace | undefined,
  key: string,
): Promise<GenreResponse | null> {
  const fromMemory = readMemoryCache(key);
  if (fromMemory) return fromMemory;
  if (!kv) return null;

  const raw = await kv.get(key);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as GenreResponse;
    if (!Array.isArray(parsed.genres) || parsed.genres.length === 0) return null;
    return { genres: parsed.genres, source: "cache" };
  } catch {
    return null;
  }
}

export async function writeCachedGenres(
  kv: KVNamespace | undefined,
  key: string,
  genres: string[],
  source: Exclude<GenreSource, "cache">,
): Promise<void> {
  writeMemoryCache(key, genres, source);
  if (!kv) return;

  const payload: GenreResponse = { genres, source };
  await kv.put(key, JSON.stringify(payload), { expirationTtl: 60 * 60 * 24 * 30 });
}
