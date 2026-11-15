import { HttpsError } from "firebase-functions/v2/https";

/**
 * Version of the consent text the app shows when someone uploads a plan.
 * Keep in sync with `planConsentVersion` in
 * lib/features/market_builder/models/plan_consent.dart.
 */
export const MIN_PLAN_CONSENT_VERSION = 1;

/** True if the request carries a consent record for the current text. */
export function hasPlanConsent(data: unknown): boolean {
  if (typeof data !== "object" || data === null) return false;
  const consent = (data as { planConsent?: unknown }).planConsent;
  if (typeof consent !== "object" || consent === null) return false;
  const { granted, version } = consent as { granted?: unknown; version?: unknown };
  return granted === true && typeof version === "number" && version >= MIN_PLAN_CONSENT_VERSION;
}

/** Plans are only read when the uploader confirmed the right to use them. */
export function requirePlanConsent(data: unknown): void {
  if (!hasPlanConsent(data)) {
    throw new HttpsError(
      "failed-precondition",
      "Ohne Einwilligung zur Nutzung des Lageplans kann er nicht analysiert werden.",
    );
  }
}
