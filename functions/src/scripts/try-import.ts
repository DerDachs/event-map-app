/**
 * Runs the URL import locally, without Firebase:
 *
 *   ANTHROPIC_API_KEY=... npm run try-import -- https://example.org/weihnachtsmarkt
 */
import Anthropic from "@anthropic-ai/sdk";
import { extractEventInfo } from "../eventImport.js";
import { fetchPage } from "../webpage.js";

async function main() {
  const url = process.argv[2];
  if (!url) {
    console.error("Usage: npm run try-import -- <url>");
    process.exit(1);
  }
  const page = await fetchPage(url);
  console.error(`${page.text.length} chars, ${page.jsonLd.length} JSON-LD blocks, ${page.images.length} images`);
  const info = await extractEventInfo(new Anthropic(), page);
  console.log(JSON.stringify({ ...info, images: info.imageIndices.map((i) => page.images[i].url) }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
