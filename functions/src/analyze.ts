import Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import { SYSTEM_PROMPT } from "./prompt.js";
import { type PlanAnalysis, PlanAnalysisSchema } from "./schema.js";

export const SUPPORTED_TYPES = ["image/png", "image/jpeg", "image/webp"] as const;
export type SupportedType = (typeof SUPPORTED_TYPES)[number];

export class PlanAnalysisError extends Error {
  constructor(
    readonly code: "failed-precondition" | "internal",
    message: string,
  ) {
    super(message);
  }
}

const clamp = (v: number) => Math.min(1000, Math.max(0, v));

/** Lets Claude read every stand and landmark off a market plan image. */
export async function analyzePlanImage(
  client: Anthropic,
  image: Buffer,
  mediaType: SupportedType,
  locationHint: string | null,
): Promise<PlanAnalysis> {
  const message = await client.beta.messages
    .stream({
      model: "claude-opus-5-5",
      max_tokens: 64000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      output_config: {
        effort: "high",
        format: betaZodOutputFormat(PlanAnalysisSchema),
      },
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: { type: "base64", media_type: mediaType, data: image.toString("base64") },
            },
            {
              type: "text",
              text: locationHint
                ? `Lageplan des Marktes. Ort laut Veranstalter: ${locationHint}`
                : "Lageplan des Marktes.",
            },
          ],
        },
      ],
    })
    .finalMessage();

  if (message.stop_reason === "refusal") {
    throw new PlanAnalysisError("failed-precondition", "Die KI konnte diesen Plan nicht verarbeiten.");
  }
  if (message.stop_reason === "max_tokens" || !message.parsed_output) {
    throw new PlanAnalysisError("internal", "Die KI-Antwort war unvollständig. Bitte erneut versuchen.");
  }

  const analysis = message.parsed_output;
  for (const item of [...analysis.stands, ...analysis.landmarks]) {
    item.x = clamp(item.x);
    item.y = clamp(item.y);
  }
  return analysis;
}
