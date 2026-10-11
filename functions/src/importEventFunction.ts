import Anthropic from "@anthropic-ai/sdk";
import { randomUUID } from "node:crypto";
import { getStorage } from "firebase-admin/storage";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { requireAdmin } from "./auth.js";
import { extractEventInfo } from "./eventImport.js";
import { fetchImage, fetchPage, WebpageError } from "./webpage.js";

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

/**
 * Reads an event's web page and returns listing details plus copies of the
 * most fitting images in our own Storage, so the app never hotlinks them.
 * Admin only.
 */
export const importEventFromUrl = onCall(
  { region: "europe-west3", timeoutSeconds: 300, memory: "512MiB", secrets: [anthropicApiKey] },
  async (request) => {
    const uid = await requireAdmin(request);
    const { url } = (request.data ?? {}) as { url?: string };
    if (typeof url !== "string" || url.length > 2000) {
      throw new HttpsError("invalid-argument", "Bitte eine Webadresse angeben.");
    }

    let page;
    try {
      page = await fetchPage(/^https?:\/\//i.test(url.trim()) ? url.trim() : `https://${url.trim()}`);
    } catch (err) {
      if (err instanceof WebpageError) throw new HttpsError("failed-precondition", err.message);
      logger.warn("Page fetch failed", err);
      throw new HttpsError("unavailable", "Die Webseite konnte nicht geladen werden.");
    }
    if (page.text.length < 200 && page.jsonLd.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Auf der Seite steht kaum Text – sie lädt ihre Inhalte vermutlich erst im Browser. Bitte eine andere Seite des Marktes versuchen.",
      );
    }

    let info;
    try {
      info = await extractEventInfo(new Anthropic({ apiKey: anthropicApiKey.value() }), page);
    } catch (err) {
      if (err instanceof Anthropic.RateLimitError) {
        throw new HttpsError("resource-exhausted", "Die KI ist gerade ausgelastet. Bitte gleich nochmal versuchen.");
      }
      logger.error("Event extraction failed", err);
      throw new HttpsError("internal", "Die Seite konnte nicht ausgewertet werden.");
    }
    if (!info.isEventPage) {
      throw new HttpsError("failed-precondition", "Auf dieser Seite wurde kein Markt oder Event gefunden.");
    }

    const bucket = getStorage().bucket();
    const images: { url: string; sourceUrl: string }[] = [];
    for (const index of info.imageIndices) {
      const source = page.images[index].url;
      const image = await fetchImage(source);
      if (!image) continue;
      const token = randomUUID();
      const ext = image.contentType.split("/")[1].replace("jpeg", "jpg");
      const path = `event-images/${uid}/${Date.now()}-${index}.${ext}`;
      await bucket.file(path).save(image.body, {
        contentType: image.contentType,
        metadata: { metadata: { firebaseStorageDownloadTokens: token, sourceUrl: source } },
      });
      images.push({
        url: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`,
        sourceUrl: source,
      });
    }

    logger.info("Event imported", { uid, url: page.url, images: images.length });
    const { imageIndices: _ignored, isEventPage: _alsoIgnored, ...details } = info;
    return { ...details, sourceUrl: page.url, images };
  },
);
