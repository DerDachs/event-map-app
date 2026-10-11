import Anthropic from "@anthropic-ai/sdk";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { geocodeLandmarks } from "./geocode.js";
import { analyzePlanImage, PlanAnalysisError, SUPPORTED_TYPES, type SupportedType } from "./analyze.js";

initializeApp();

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");
const geocodingApiKey = defineSecret("GOOGLE_GEOCODING_API_KEY");

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

interface AnalyzeRequest {
  storagePath: string;
  locationHint?: string | null;
}

/**
 * Reads an uploaded market plan from Cloud Storage, lets Claude extract all
 * stands and landmarks, and geocodes the landmarks so the app can place the
 * plan on the map. Admin only.
 */
export const analyzeMarketPlan = onCall(
  {
    region: "europe-west3",
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [anthropicApiKey, geocodingApiKey],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Bitte zuerst anmelden.");

    const profile = await getFirestore().collection("profiles").doc(uid).get();
    if (profile.get("role") !== "admin") {
      throw new HttpsError("permission-denied", "Nur Admins können Märkte anlegen.");
    }

    const { storagePath, locationHint = null } = (request.data ?? {}) as AnalyzeRequest;
    if (typeof storagePath !== "string" || !storagePath.startsWith(`market-plans/${uid}/`)) {
      throw new HttpsError("invalid-argument", "Ungültiger Speicherpfad für den Lageplan.");
    }

    const file = getStorage().bucket().file(storagePath);
    const [metadata] = await file.getMetadata();
    const mediaType = metadata.contentType as SupportedType;
    if (!SUPPORTED_TYPES.includes(mediaType)) {
      throw new HttpsError("invalid-argument", "Bitte den Lageplan als PNG, JPG oder WebP hochladen.");
    }
    if (Number(metadata.size) > MAX_IMAGE_BYTES) {
      throw new HttpsError("invalid-argument", "Das Bild ist größer als 5 MB.");
    }
    const [bytes] = await file.download();

    let analysis;
    try {
      analysis = await analyzePlanImage(
        new Anthropic({ apiKey: anthropicApiKey.value() }),
        bytes,
        mediaType,
        locationHint,
      );
    } catch (err) {
      if (err instanceof PlanAnalysisError) {
        throw new HttpsError(err.code, err.message);
      }
      if (err instanceof Anthropic.RateLimitError) {
        throw new HttpsError("resource-exhausted", "Die KI ist gerade ausgelastet. Bitte gleich nochmal versuchen.");
      }
      if (err instanceof Anthropic.APIError) {
        logger.error("Claude API error", { status: err.status, message: err.message });
        throw new HttpsError("internal", "Die KI-Analyse ist fehlgeschlagen.");
      }
      throw err;
    }

    let geo = null;
    try {
      geo = await geocodeLandmarks(analysis, locationHint, geocodingApiKey.value());
    } catch (err) {
      // The organiser can still place the plan manually.
      logger.warn("Geocoding failed", err);
    }

    logger.info("Plan analysed", {
      uid,
      stands: analysis.stands.length,
      landmarks: analysis.landmarks.length,
      controlPoints: geo?.controlPoints.length ?? 0,
    });

    return {
      analysis,
      center: geo?.center ?? null,
      controlPoints: geo?.controlPoints ?? [],
    };
  },
);
