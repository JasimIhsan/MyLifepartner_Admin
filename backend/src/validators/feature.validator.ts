import { z } from "zod";

export const createFeatureSchema = z.object({
   key: z
      .string()
      .min(1, "Feature key is required")
      .max(100, "Feature key must be at most 100 characters")
      .regex(/^[a-z0-9_]+$/, "Feature key must be lowercase letters, numbers, or underscores"),
   name: z.string().min(1, "Feature name is required").max(100, "Feature name must be at most 100 characters"),
   description: z.string().max(500, "Feature description must be at most 500 characters").optional(),
});

export const updateFeatureSchema = z
   .object({
      name: z.string().min(1, "Feature name is required").max(100, "Feature name must be at most 100 characters").optional(),
      description: z.string().max(500, "Feature description must be at most 500 characters").optional(),
   })
   .refine((v) => Object.keys(v).length > 0, { message: "At least one field must be provided for update" });

export type CreateFeatureInput = z.infer<typeof createFeatureSchema>;
export type UpdateFeatureInput = z.infer<typeof updateFeatureSchema>;
