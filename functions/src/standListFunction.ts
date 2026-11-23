import Anthropic from "@anthropic-ai/sdk";
import { getStorage } from "firebase-admin/storage";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { requireAdmin } from "./auth.js";
import { extractStandList, type StandListSource } from "./standList.js";
import { fetchPage, WebpageError } from "./webpage.js";

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

interface StandListRequest {
  /** Pasted text of the list. */
  text?: string;
  /** Web page with the exhibitor list. */
  url?: string;
  /** Photo or PDF of the list, uploaded to market-plans/<uid>/. */
  storagePath?: string;
}

/**
 * Reads a stand/exhibitor list (pasted text, photo, PDF or web page) and
 * returns names, numbers, descriptions and offers, so the organiser doesn't
 * type them stand by stand. The app matches entries to the plan. Admin only.
 */
export const parseStandList = onCall(
  { region: "europe-west3", timeoutSeconds: 300, memory: "512MiB", secrets: [anthropicApiKey] },
  async (request) => {
    const uid = await requireAdmin(request);
    const { text, url, storagePath } = (request.data ?? {}) as StandListRequest;

    let source: StandListSource;
    if (typeof text === "string" && text.trim().length > 0) {
      source = { kind: "text", text };
    } else if (typeof url === "string" && url.trim().length > 0) {
      try {
        const page = await fetchPage(/^https?:\/\//i.test(url.trim()) ? url.trim() : `https://${url.trim()}`);
        source = { kind: "text", text: `Webseite ${page.url} – ${page.title}\n\n${page.text}` };
      } catch (err) {
        if (err instanceof WebpageError) throw new HttpsError("failed-precondition", err.message);
        throw new HttpsError("unavailable", "Die Webseite konnte nicht geladen werden.");
      }
    } else if (typeof storagePath === "string" && storagePath.startsWith(`market-plans/${uid}/`)) {
      const file = getStorage().bucket().file(storagePath);
      const [meta] = await file.getMetadata();
      const [data] = await file.download();
      const type = String(meta.contentType);
      if (type === "application/pdf") source = { kind: "pdf", data };
      else if (type === "image/png" || type === "image/jpeg" || type === "image/webp") {
        source = { kind: "image", data, mediaType: type };
      } else throw new HttpsError("invalid-argument", "Bitte ein Bild oder PDF der Standliste wählen.");
    } else {
      throw new HttpsError("invalid-argument", "Bitte Text, eine Webadresse oder ein Bild/PDF der Standliste angeben.");
    }

    try {
      const list = await extractStandList(new Anthropic({ apiKey: anthropicApiKey.value() }), source);
      logger.info("Stand list parsed", { uid, kind: source.kind, entries: list.entries.length });
      return list;
    } catch (err) {
      if (err instanceof Anthropic.RateLimitError) {
        throw new HttpsError("resource-exhausted", "Die KI ist gerade ausgelastet. Bitte gleich nochmal versuchen.");
      }
      logger.error("Stand list failed", err);
      throw new HttpsError("internal", "Die Standliste konnte nicht ausgewertet werden.");
    }
  },
);
