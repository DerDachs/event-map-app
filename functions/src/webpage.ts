import { lookup } from "node:dns/promises";
import { isIP } from "node:net";

const MAX_PAGE_BYTES = 3 * 1024 * 1024;
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_TEXT_CHARS = 60_000;
const MAX_REDIRECTS = 4;
const USER_AGENT = "MarketMateBot/1.0 (+https://event-map-app-aab7b.web.app)";

export class WebpageError extends Error {}

/** True for loopback, private, link-local and other non-public addresses. */
export function isPrivateAddress(ip: string): boolean {
  if (isIP(ip) === 4) {
    const [a, b] = ip.split(".").map(Number);
    return (
      a === 0 ||
      a === 10 ||
      a === 127 ||
      (a === 100 && b >= 64 && b <= 127) ||
      (a === 169 && b === 254) ||
      (a === 172 && b >= 16 && b <= 31) ||
      (a === 192 && b === 168) ||
      a >= 224
    );
  }
  const v6 = ip.toLowerCase();
  if (v6.startsWith("::ffff:")) return isPrivateAddress(v6.slice(7));
  return v6 === "::" || v6 === "::1" || v6.startsWith("fc") || v6.startsWith("fd") || v6.startsWith("fe8") ||
    v6.startsWith("fe9") || v6.startsWith("fea") || v6.startsWith("feb");
}

/**
 * Rejects URLs that could reach the function's own infrastructure (the
 * metadata server, internal IPs). Checked again for every redirect.
 */
async function assertPublicUrl(raw: string): Promise<URL> {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new WebpageError("Das ist keine gültige Adresse.");
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") {
    throw new WebpageError("Nur http- und https-Adressen sind erlaubt.");
  }
  if (url.username || url.password || (url.port && !["80", "443"].includes(url.port))) {
    throw new WebpageError("Diese Adresse wird nicht unterstützt.");
  }
  const host = url.hostname.replace(/^\[|\]$/g, "");
  if (host === "localhost" || host.endsWith(".internal") || host.endsWith(".local")) {
    throw new WebpageError("Diese Adresse ist nicht öffentlich erreichbar.");
  }
  const addresses = isIP(host) ? [{ address: host }] : await lookup(host, { all: true }).catch(() => []);
  if (addresses.length === 0) throw new WebpageError("Die Webseite wurde nicht gefunden.");
  if (addresses.some((a) => isPrivateAddress(a.address))) {
    throw new WebpageError("Diese Adresse ist nicht öffentlich erreichbar.");
  }
  return url;
}

/** GET with redirect, size and time limits. */
export async function safeFetch(
  raw: string,
  { maxBytes, accept }: { maxBytes: number; accept: string },
): Promise<{ url: URL; body: Buffer; contentType: string }> {
  let url = await assertPublicUrl(raw);
  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    const res = await fetch(url, {
      redirect: "manual",
      headers: { "user-agent": USER_AGENT, accept, "accept-language": "de,en;q=0.5" },
      signal: AbortSignal.timeout(15_000),
    });
    if (res.status >= 300 && res.status < 400 && res.headers.get("location")) {
      url = await assertPublicUrl(new URL(res.headers.get("location")!, url).toString());
      continue;
    }
    if (!res.ok) throw new WebpageError(`Die Webseite antwortet mit Fehler ${res.status}.`);
    const declared = Number(res.headers.get("content-length") ?? 0);
    if (declared > maxBytes) throw new WebpageError("Die Datei ist zu groß.");
    const chunks: Buffer[] = [];
    let size = 0;
    for await (const chunk of res.body as unknown as AsyncIterable<Uint8Array>) {
      size += chunk.length;
      if (size > maxBytes) throw new WebpageError("Die Datei ist zu groß.");
      chunks.push(Buffer.from(chunk));
    }
    return { url, body: Buffer.concat(chunks), contentType: res.headers.get("content-type") ?? "" };
  }
  throw new WebpageError("Zu viele Weiterleitungen.");
}

export interface ImageCandidate {
  url: string;
  alt: string;
  source: "og" | "jsonld" | "img";
}

export interface ExtractedPage {
  url: string;
  title: string;
  text: string;
  jsonLd: string[];
  images: ImageCandidate[];
}

const ENTITIES: Record<string, string> = {
  amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ",
  auml: "ä", ouml: "ö", uuml: "ü", Auml: "Ä", Ouml: "Ö", Uuml: "Ü", szlig: "ß", euro: "€", ndash: "–", mdash: "—",
};

function decodeEntities(s: string): string {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e: string) => {
    if (e[0] === "#") {
      const code = e[1] === "x" || e[1] === "X" ? parseInt(e.slice(2), 16) : parseInt(e.slice(1), 10);
      return Number.isFinite(code) ? String.fromCodePoint(code) : m;
    }
    return ENTITIES[e] ?? m;
  });
}

function attr(tag: string, name: string): string | null {
  const m = tag.match(new RegExp(`\\b${name}\\s*=\\s*("([^"]*)"|'([^']*)'|([^\\s>]+))`, "i"));
  return m ? decodeEntities(m[2] ?? m[3] ?? m[4] ?? "") : null;
}

/** Pulls readable text, schema.org data and image candidates out of HTML. */
export function extractPage(html: string, pageUrl: URL): ExtractedPage {
  const jsonLd = [...html.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
    .map((m) => m[1].trim())
    .filter(Boolean)
    .slice(0, 10);

  const resolve = (src: string | null) => {
    if (!src || src.startsWith("data:")) return null;
    try {
      const u = new URL(src, pageUrl);
      return u.protocol === "http:" || u.protocol === "https:" ? u.toString() : null;
    } catch {
      return null;
    }
  };

  const images: ImageCandidate[] = [];
  const seen = new Set<string>();
  const add = (src: string | null, alt: string, source: ImageCandidate["source"]) => {
    const url = resolve(src);
    if (!url || seen.has(url) || /\.(svg|gif|ico)(\?|$)/i.test(url)) return;
    if (/logo|icon|sprite|pixel|tracking|avatar|placeholder/i.test(url)) return;
    seen.add(url);
    images.push({ url, alt: alt.slice(0, 160), source });
  };

  for (const m of html.matchAll(/<meta\b[^>]*>/gi)) {
    const prop = (attr(m[0], "property") ?? attr(m[0], "name") ?? "").toLowerCase();
    if (prop === "og:image" || prop === "og:image:url" || prop === "twitter:image") {
      add(attr(m[0], "content"), "Vorschaubild der Seite", "og");
    }
  }
  for (const block of jsonLd) {
    for (const m of block.matchAll(/"image"\s*:\s*(\[[^\]]*\]|"[^"]+"|\{[^}]*\})/g)) {
      for (const u of m[1].matchAll(/https?:\/\/[^"\s]+/g)) add(u[0], "Bild aus den Event-Daten", "jsonld");
    }
  }
  for (const m of html.matchAll(/<img\b[^>]*>/gi)) {
    const width = Number(attr(m[0], "width") ?? 0);
    if (width && width < 200) continue;
    const srcset = attr(m[0], "srcset");
    const largest = srcset?.split(",").map((s) => s.trim().split(/\s+/)[0]).pop() ?? null;
    add(largest ?? attr(m[0], "data-src") ?? attr(m[0], "src"), attr(m[0], "alt") ?? "", "img");
  }

  const title = decodeEntities(html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "").trim();
  const text = decodeEntities(
    html
      .replace(/<(script|style|noscript|svg|template|iframe)[\s\S]*?<\/\1>/gi, " ")
      .replace(/<!--[\s\S]*?-->/g, " ")
      .replace(/<(br|\/p|\/div|\/li|\/h[1-6]|\/tr|\/section|\/article)\b[^>]*>/gi, "\n")
      .replace(/<[^>]+>/g, " "),
  )
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\s*\n\s*/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim()
    .slice(0, MAX_TEXT_CHARS);

  return { url: pageUrl.toString(), title, text, jsonLd, images: images.slice(0, 30) };
}

export async function fetchPage(raw: string): Promise<ExtractedPage> {
  const { url, body, contentType } = await safeFetch(raw, {
    maxBytes: MAX_PAGE_BYTES,
    accept: "text/html,application/xhtml+xml",
  });
  if (!/html|xml|text\/plain/i.test(contentType)) {
    throw new WebpageError("Unter dieser Adresse liegt keine Webseite.");
  }
  return extractPage(body.toString("utf8"), url);
}

const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];

export async function fetchImage(raw: string): Promise<{ body: Buffer; contentType: string } | null> {
  try {
    const { body, contentType } = await safeFetch(raw, { maxBytes: MAX_IMAGE_BYTES, accept: "image/*" });
    const type = contentType.split(";")[0].trim().toLowerCase();
    if (!IMAGE_TYPES.includes(type) || body.length < 5_000) return null;
    return { body, contentType: type };
  } catch {
    return null;
  }
}
