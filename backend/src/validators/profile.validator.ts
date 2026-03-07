import { z } from "zod";

const GenderEnum = z.enum(["MALE", "FEMALE", "OTHER"]);
const MaritalStatusEnum = z.enum(["NEVER_MARRIED", "AWATING_DIVORCE", "DIVORCED", "WIDOWED", "ANNULLED"]);

export const basicProfileSchema = z.object({
   body: z.object({
      name: z.string().min(1, "Name is required").optional(),
      gender: GenderEnum.nullish(),
      dateOfBirth: z.string().datetime({ message: "Invalid date format" }).nullish(),
      maritalStatus: MaritalStatusEnum.nullish(),
      heightCm: z.number().int().min(50, "Height must be at least 50cm").max(300, "Height cannot exceed 300cm").nullish(),
      religion: z.string().nullish(),
      motherTongue: z.string().nullish(),
      city: z.string().nullish(),
      state: z.string().nullish(),
      country: z.string().nullish(),
      highestEducation: z.string().nullish(),
      occupation: z.string().nullish(),
      annualIncome: z.number().int().min(0, "Income cannot be negative").nullish(),
      bio: z.string().min(50, "Bio must be at least 50 characters").max(1000, "Bio cannot exceed 1000 characters").nullish(),
   }),
});

export const partnerPreferenceSchema = z.object({
   body: z
      .object({
         ageFrom: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100").nullish(),
         ageTo: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100").nullish(),
         heightFrom: z.number().int().min(50, "Minimum height is 50cm").max(300, "Maximum height is 300cm").nullish(),
         heightTo: z.number().int().min(50, "Minimum height is 50cm").max(300, "Maximum height is 300cm").nullish(),
         maritalStatus: z.array(MaritalStatusEnum).nullish(),
         religion: z.array(z.string()).nullish(),
         motherTongue: z.array(z.string()).nullish(),
         highestEducation: z.array(z.string()).nullish(),
         occupation: z.array(z.string()).nullish(),
         annualIncomeFrom: z.number().int().min(0, "Income cannot be negative").nullish(),
         annualIncomeTo: z.number().int().min(0, "Income cannot be negative").nullish(),
      })
      .refine(
         (data) => {
            if (data.ageFrom && data.ageTo) {
               return data.ageFrom <= data.ageTo;
            }
            return true;
         },
         {
            message: "ageFrom must be less than or equal to ageTo",
            path: ["ageFrom"],
         }
      )
      .refine(
         (data) => {
            if (data.heightFrom && data.heightTo) {
               return data.heightFrom <= data.heightTo;
            }
            return true;
         },
         {
            message: "heightFrom must be less than or equal to heightTo",
            path: ["heightFrom"],
         }
      )
      .refine(
         (data) => {
            if (data.annualIncomeFrom && data.annualIncomeTo) {
               return data.annualIncomeFrom <= data.annualIncomeTo;
            }
            return true;
         },
         {
            message: "annualIncomeFrom must be less than or equal to annualIncomeTo",
            path: ["annualIncomeFrom"],
         }
      ),
});
