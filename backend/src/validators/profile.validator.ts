import { z } from "zod";

const GenderEnum = z.enum(["MALE", "FEMALE", "OTHER"]);
const MaritalStatusEnum = z.enum(["NEVER_MARRIED", "AWATING_DIVORCE", "DIVORCED", "WIDOWED", "ANNULLED", "LEGALLY_SEPARATED"]);

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
      languages: z.array(z.string()).nullish(),
      childrenStatus: z.enum(["LIVING_WITH_ME", "NOT_LIVING_WITH_ME", "NO_CHILDREN"]).nullish(),
      emotionalReadiness: z.enum(["YES", "MOSTLY", "NOT_SURE"]).nullish(),
      lookingFor: z.enum(["MARRIAGE", "LONG_TERM_RELATIONSHIP", "SERIOUS_COMPANIONSHIP"]).nullish(),
      relationshipTimeline: z.enum(["ZERO_TO_SIX_MONTHS", "SIX_TO_TWELVE_MONTHS", "NO_FIXED_TIMELINE"]).nullish(),
      smokingHabit: z.enum(["NO", "OCCASIONALLY", "YES"]).nullish(),
      drinkingHabit: z.enum(["NO", "SOCIALLY", "YES"]).nullish(),
   }),
});

export const partnerPreferenceSchema = z.object({
   body: z
      .object({
         ageFrom: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100"),
         ageTo: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100"),
         heightFrom: z.number().int().min(50, "Minimum height is 50cm").max(300, "Maximum height is 300cm"),
         heightTo: z.number().int().min(50, "Minimum height is 50cm").max(300, "Maximum height is 300cm"),
         maritalStatus: z.array(MaritalStatusEnum).min(1, "Select at least one marital status"),
         religion: z.array(z.string()).min(1, "Select at least one religion").nullish(),
         motherTongue: z.array(z.string()).min(1, "Select at least one language"),
         highestEducation: z.array(z.string()).min(1, "Select at least one education level"),
         occupation: z.array(z.string()).min(1, "Select at least one occupation"),
         annualIncomeFrom: z.number().int().min(0, "Income cannot be negative").nullish(),
         annualIncomeTo: z.number().int().min(0, "Income cannot be negative").nullish(),
      })
      .refine(
         (data) => {
            return data.ageFrom <= data.ageTo;
         },
         {
            message: "ageFrom must be less than or equal to ageTo",
            path: ["ageFrom"],
         }
      )
      .refine(
         (data) => {
            return data.heightFrom <= data.heightTo;
         },
         {
            message: "heightFrom must be less than or equal to heightTo",
            path: ["heightFrom"],
         }
      )
      .refine(
         (data) => {
            if (data.annualIncomeFrom !== null && 
                data.annualIncomeFrom !== undefined && 
                data.annualIncomeTo !== null && 
                data.annualIncomeTo !== undefined) {
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
