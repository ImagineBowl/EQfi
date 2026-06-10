import { primaryArtist } from "./types";

const API_BASE = "https://musicbrainz.org/ws/2";
const USER_AGENT = "EQfi-Genre-API/1.0 (https://github.com/ImagineBowl/EQfi)";

interface ArtistSearchResponse {
  artists: Array<{ id: string }>;
}

interface ArtistDetailResponse {
  tags: Array<{ name: string; count: number }>;
}

async function musicBrainzGET<T>(path: string): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: { "User-Agent": USER_AGENT },
  });
  if (!response.ok) {
    throw new Error(`MusicBrainz request failed (${response.status})`);
  }
  return (await response.json()) as T;
}

async function searchArtistID(name: string): Promise<string> {
  const params = new URLSearchParams({
    query: `artist:"${name}"`,
    fmt: "json",
    limit: "1",
  });
  const data = await musicBrainzGET<ArtistSearchResponse>(`/artist?${params}`);
  const artistId = data.artists[0]?.id;
  if (!artistId) throw new Error("Artist not found on MusicBrainz");
  return artistId;
}

async function fetchArtistTags(artistId: string): Promise<string[]> {
  const params = new URLSearchParams({ inc: "tags", fmt: "json" });
  const data = await musicBrainzGET<ArtistDetailResponse>(`/artist/${artistId}?${params}`);
  const tags = data.tags
    .sort((a, b) => b.count - a.count)
    .slice(0, 5)
    .map((tag) => tag.name);
  if (!tags.length) throw new Error("No tags found on MusicBrainz");
  return tags;
}

export async function fetchMusicBrainzGenres(title: string, artist: string): Promise<string[]> {
  void title;
  const artistName = primaryArtist(artist);
  const artistId = await searchArtistID(artistName);
  return fetchArtistTags(artistId);
}
