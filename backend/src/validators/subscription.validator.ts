import { z } from "zod";

// ── Create Plan ──────────────────────────────────────────────────────────────
export const createPlanSchema = z.object({
   name: z
      .string()
      .min(1, "Plan name is required")
      .max(50, "Plan name must be at most 50 characters")
      .regex(/^[A-Za-z0-9_]+$/, "Plan name can only contain letters, numbers, and underscores"),
   price: z
      .number({ message: "Price must be a non-negative integer (in paise)" })
      .int("Price must be an integer (in paise)")
      .min(0, "Price must be non-negative"),
   durationDays: z
      .number({ message: "Duration must be a positive integer (days)" })
      .int("Duration must be an integer")
      .min(1, "Duration must be at least 1 day"),
   identifier: z.string().min(1, "Identifier is required"),
});

// ── Update Plan ──────────────────────────────────────────────────────────────
export const updatePlanSchema = z
   .object({
      price: z.number().int("Price must be an integer (in paise)").min(0, "Price must be non-negative").optional(),
      durationDays: z.number().int("Duration must be an integer").min(1, "Duration must be at least 1 day").optional(),
      isActive: z.boolean().optional(),
      isMostPopular: z.boolean().optional(),
      identifier: z.string().min(1, "Identifier is required").optional(),
   })
   .refine((v) => Object.keys(v).length > 0, { message: "At least one field must be provided for update" });

// ── Add Features ─────────────────────────────────────────────────────────────
export const addFeaturesSchema = z
   .array(
      z.object({
         featureKey: z
            .string()
            .min(1, "Feature key is required")
            .max(100, "Feature key must be at most 100 characters")
            .regex(/^[a-z0-9_]+$/, "Feature key must be lowercase letters, numbers, or underscores"),
         limit: z.string().min(1, "Feature limit is required").max(255, "Feature limit must be at most 255 characters"),
      })
   )
   .min(1, "At least one feature is required");


// ── Update Feature ────────────────────────────────────────────────────────────
export const updateFeatureSchema = z.object({
   limit: z.string().min(1, "Feature limit is required").max(255, "Feature limit must be at most 255 characters"),
});

export type CreatePlanInput = z.infer<typeof createPlanSchema>;
export type UpdatePlanInput = z.infer<typeof updatePlanSchema>;
export type AddFeaturesInput = z.infer<typeof addFeaturesSchema>;
export type UpdateFeatureInput = z.infer<typeof updateFeatureSchema>;
