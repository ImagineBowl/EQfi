import { fetchMusicBrainzGenres } from "./musicbrainz";
import { fetchSpotifyGenres } from "./spotify";
import {
  badRequest,
  cacheKey,
  jsonResponse,
  readCachedGenres,
  unauthorized,
  verifyApiKey,
  writeCachedGenres,
  type Env,
  type GenreResponse,
} from "./types";

async function resolveGenres(
  title: string,
  artist: string,
  env: Env,
): Promise<GenreResponse> {
  const key = cacheKey(title, artist);
  const cached = await readCachedGenres(env.GENRE_CACHE, key);
  if (cached) return cached;

  const market = env.SPOTIFY_MARKET?.trim() || "US";

  try {
    const genres = await fetchSpotifyGenres(
      title,
      artist,
      env.SPOTIFY_CLIENT_ID,
      env.SPOTIFY_CLIENT_SECRET,
      market,
    );
    await writeCachedGenres(env.GENRE_CACHE, key, genres, "spotify");
    return { genres, source: "spotify" };
  } catch {
    // Spotify unavailable — try MusicBrainz.
  }

  const genres = await fetchMusicBrainzGenres(title, artist);
  await writeCachedGenres(env.GENRE_CACHE, key, genres, "musicbrainz");
  return { genres, source: "musicbrainz" };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return new Response("ok");
    }

    if (url.pathname !== "/v1/genre" || request.method !== "GET") {
      return jsonResponse({ error: "Not found" }, 404);
    }

    if (!verifyApiKey(request, env)) {
      return unauthorized();
    }

    const title = url.searchParams.get("title")?.trim() ?? "";
    const artist = url.searchParams.get("artist")?.trim() ?? "";

    if (!title || !artist) {
      return badRequest("Query parameters 'title' and 'artist' are required.");
    }

    try {
      const result = await resolveGenres(title, artist, env);
      return jsonResponse(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Genre lookup failed";
      return jsonResponse({ error: message }, 502);
    }
  },
};
