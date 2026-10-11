/**
 * Runs the plan analysis locally on an image file, without Firebase:
 *
 *   ANTHROPIC_API_KEY=... [GOOGLE_GEOCODING_API_KEY=...] \
 *     npm run try-plan -- ./plan.jpg "Marienplatz, München"
 */
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "node:fs";
import { extname } from "node:path";
import { analyzePlanImage, type SupportedType } from "../analyze.js";
import { geocodeLandmarks } from "../geocode.js";

const [file, locationHint = null] = process.argv.slice(2);
if (!file) {
  console.error("Usage: npm run try-plan -- <plan.png|jpg|webp> [location hint]");
  process.exit(1);
}

const types: Record<string, SupportedType> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
};
const mediaType = types[extname(file).toLowerCase()];
if (!mediaType) {
  console.error("Only PNG, JPG and WebP are supported.");
  process.exit(1);
}

async function main() {
  const started = Date.now();
  const analysis = await analyzePlanImage(new Anthropic(), readFileSync(file), mediaType, locationHint);
  console.log(JSON.stringify(analysis, null, 2));
  console.error(
    `\n${analysis.stands.length} stands, ${analysis.landmarks.length} landmarks in ${Math.round((Date.now() - started) / 1000)} s`,
  );

  const geocodingKey = process.env.GOOGLE_GEOCODING_API_KEY;
  if (geocodingKey) {
    const geo = await geocodeLandmarks(analysis, locationHint, geocodingKey);
    console.error(`Geocoded ${geo.controlPoints.length} landmarks:`);
    for (const p of geo.controlPoints) {
      console.error(`  ${p.label}: ${p.latitude.toFixed(6)}, ${p.longitude.toFixed(6)}`);
    }
}
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
