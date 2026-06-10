import { primaryArtist, sanitizeSearchText } from "./types";

const TOKEN_URL = "https://accounts.spotify.com/api/token";
const API_BASE = "https://api.spotify.com/v1";

interface SpotifyTokenResponse {
  access_token: string;
  expires_in: number;
}

interface SpotifySearchTrackResponse {
  tracks: { items: Array<{ artists: Array<{ id: string }> }> };
}

interface SpotifySearchArtistResponse {
  artists: { items: Array<{ id: string }> };
}

interface SpotifyArtistResponse {
  genres: string[];
}

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getAccessToken(clientId: string, clientSecret: string): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 30_000) {
    return cachedToken.value;
  }

  const credentials = btoa(`${clientId}:${clientSecret}`);
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });

  if (!response.ok) {
    throw new Error(`Spotify token request failed (${response.status})`);
  }

  const data = (await response.json()) as SpotifyTokenResponse;
  cachedToken = {
    value: data.access_token,
    expiresAt: Date.now() + data.expires_in * 1000,
  };
  return data.access_token;
}

async function spotifyGET<T>(url: string, token: string): Promise<T> {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (response.status === 429) {
    throw new Error("Spotify rate limited");
  }
  if (!response.ok) {
    throw new Error(`Spotify request failed (${response.status})`);
  }

  return (await response.json()) as T;
}

async function searchTrackArtistID(
  query: string,
  token: string,
  market: string,
): Promise<string> {
  const params = new URLSearchParams({
    q: query,
    type: "track",
    limit: "1",
    market,
  });
  const data = await spotifyGET<SpotifySearchTrackResponse>(
    `${API_BASE}/search?${params}`,
    token,
  );
  const artistId = data.tracks.items[0]?.artists[0]?.id;
  if (!artistId) throw new Error("Track not found on Spotify");
  return artistId;
}

async function searchArtistID(name: string, token: string, market: string): Promise<string> {
  const params = new URLSearchParams({
    q: name,
    type: "artist",
    limit: "1",
    market,
  });
  const data = await spotifyGET<SpotifySearchArtistResponse>(
    `${API_BASE}/search?${params}`,
    token,
  );
  const artistId = data.artists.items[0]?.id;
  if (!artistId) throw new Error("Artist not found on Spotify");
  return artistId;
}

async function fetchArtistGenres(artistId: string, token: string): Promise<string[]> {
  const data = await spotifyGET<SpotifyArtistResponse>(`${API_BASE}/artists/${artistId}`, token);
  if (!data.genres.length) throw new Error("Artist has no genres on Spotify");
  return data.genres;
}

async function resolveArtistID(
  title: string,
  artist: string,
  token: string,
  market: string,
): Promise<string> {
  const cleanedTitle = sanitizeSearchText(title);
  const cleanedArtist = sanitizeSearchText(primaryArtist(artist));

  try {
    return await searchTrackArtistID(
      `track:${cleanedTitle} artist:${cleanedArtist}`,
      token,
      market,
    );
  } catch {
    // fall through
  }

  try {
    return await searchArtistID(cleanedArtist, token, market);
  } catch {
    // fall through
  }

  return searchTrackArtistID(`track:${cleanedTitle}`, token, market);
}

export async function fetchSpotifyGenres(
  title: string,
  artist: string,
  clientId: string,
  clientSecret: string,
  market: string,
): Promise<string[]> {
  const token = await getAccessToken(clientId, clientSecret);
  const artistId = await resolveArtistID(title, artist, token, market);
  return fetchArtistGenres(artistId, token);
}
