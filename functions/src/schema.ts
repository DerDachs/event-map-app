import { z } from "zod";

/**
 * Fixed stand categories. Keys are stable and shared with the Flutter app
 * (lib/features/market_builder/models/stand_categories.dart).
 */
export const STAND_CATEGORIES = [
  "gluehwein",
  "food_savory",
  "food_sweet",
  "crafts",
  "decoration",
  "kids",
  "stage",
  "service",
  "other",
] as const;

export const LANDMARK_KINDS = [
  "church",
  "town_hall",
  "square",
  "building",
  "station",
  "intersection",
  "street",
  "other",
] as const;

/** Coordinates are on a 0..1000 grid, origin top-left of the plan image. */
export const PlanAnalysisSchema = z.object({
  marketName: z.string().nullable(),
  locationHint: z
    .string()
    .nullable()
    .describe("City and square/area of the market as far as readable on the plan"),
  northArrowDegrees: z
    .number()
    .nullable()
    .describe(
      "Clockwise angle from image-up to the north arrow, null if the plan has no north arrow",
    ),
  stands: z.array(
    z.object({
      label: z.string().describe("Name of the stand as written, or a short description"),
      number: z.string().nullable().describe("Stand number from the plan/legend, if any"),
      category: z.enum(STAND_CATEGORIES),
      x: z.number(),
      y: z.number(),
      confidence: z.enum(["low", "medium", "high"]),
    }),
  ),
  landmarks: z.array(
    z.object({
      name: z
        .string()
        .describe(
          "Searchable name, e.g. 'Frauenkirche' or 'Kaufingerstraße & Augustinerstraße'",
        ),
      kind: z.enum(LANDMARK_KINDS),
      x: z.number(),
      y: z.number(),
    }),
  ),
  warnings: z.array(z.string()),
});

export type PlanAnalysis = z.infer<typeof PlanAnalysisSchema>;
