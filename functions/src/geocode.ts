import type { PlanAnalysis } from "./schema.js";

export interface ControlPointCandidate {
  label: string;
  x: number;
  y: number;
  latitude: number;
  longitude: number;
  source: "geocoded";
}

export interface GeoResult {
  center: { latitude: number; longitude: number } | null;
  controlPoints: ControlPointCandidate[];
}

const GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json";

// Results that only resolve to a city or postcode are useless as control points.
const COARSE_TYPES = new Set([
  "locality",
  "political",
  "postal_code",
  "administrative_area_level_1",
  "administrative_area_level_2",
  "administrative_area_level_3",
  "country",
]);

async function geocode(
  query: string,
  apiKey: string,
  language: string,
): Promise<{ latitude: number; longitude: number; precise: boolean } | null> {
  const url = `${GEOCODE_URL}?address=${encodeURIComponent(query)}&language=${language}&key=${apiKey}`;
  const res = await fetch(url);
  if (!res.ok) return null;
  const body = (await res.json()) as {
    status: string;
    results: Array<{
      types: string[];
      geometry: { location: { lat: number; lng: number } };
    }>;
  };
  if (body.status !== "OK" || body.results.length === 0) return null;
  const best = body.results[0];
  return {
    latitude: best.geometry.location.lat,
    longitude: best.geometry.location.lng,
    precise: !best.types.every((t) => COARSE_TYPES.has(t)),
  };
}

/**
 * Geocodes the landmarks the model found so the app can place the plan
 * without manual input. Outlier filtering happens in the app, which owns
 * the transform math.
 */
export async function geocodeLandmarks(
  analysis: PlanAnalysis,
  locationHint: string | null,
  apiKey: string,
): Promise<GeoResult> {
  const hint = locationHint || analysis.locationHint || "";
  const center = hint ? await geocode(hint, apiKey, "de") : null;

  const results = await Promise.all(
    analysis.landmarks.slice(0, 12).map(async (landmark) => {
      const query = hint ? `${landmark.name}, ${hint}` : landmark.name;
      const hit = await geocode(query, apiKey, "de");
      if (!hit || !hit.precise) return null;
      return {
        label: landmark.name,
        x: landmark.x,
        y: landmark.y,
        latitude: hit.latitude,
        longitude: hit.longitude,
        source: "geocoded" as const,
      };
    }),
  );

  return {
    center: center ? { latitude: center.latitude, longitude: center.longitude } : null,
    controlPoints: results.filter((r): r is ControlPointCandidate => r !== null),
  };
}
