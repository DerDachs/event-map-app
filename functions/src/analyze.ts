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
  pdf?: { data: Buffer; page: number } | null,
): Promise<PlanAnalysis> {
  const hint = locationHint ? ` Ort laut Veranstalter: ${locationHint}` : "";
  const pdfNote = pdf
    ? ` Zusätzlich liegt das Original-PDF bei; das Bild ist Seite ${pdf.page} daraus. Nutze das PDF, um Beschriftungen, Standnamen und die Legende (auch auf anderen Seiten) exakt zu lesen. Alle Koordinaten beziehen sich ausschließlich auf das Bild.`
    : "";
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
            ...(pdf
              ? [
                  {
                    type: "document" as const,
                    source: {
                      type: "base64" as const,
                      media_type: "application/pdf" as const,
                      data: pdf.data.toString("base64"),
                    },
                    title: "Lageplan (PDF)",
                  },
                ]
              : []),
            {
              type: "image",
              source: { type: "base64", media_type: mediaType, data: image.toString("base64") },
            },
            {
              type: "text",
              text: `Lageplan des Marktes.${hint}${pdfNote}`,
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
