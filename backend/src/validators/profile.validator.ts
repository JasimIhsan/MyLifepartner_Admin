import { z } from "zod";

const GenderEnum = z.enum(["MALE", "FEMALE", "OTHER"]);
const MaritalStatusEnum = z.enum(["AWAITING_DIVORCE", "DIVORCED", "WIDOWED", "SEPARATED"]);

export const basicProfileSchema = z.object({
   body: z.object({
      name: z.string().min(1, "Name is required").optional(),
      gender: GenderEnum.nullish(),
      dateOfBirth: z
         .string()
         .datetime({ message: "Invalid date format" })
         .nullish()
         .refine(
            (val) => {
               if (!val) return true;
               const dob = new Date(val);
               const today = new Date();
               let age = today.getFullYear() - dob.getFullYear();
               const m = today.getMonth() - dob.getMonth();
               if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
                  age--;
               }
               return age >= 18;
            },
            { message: "Members must be aged 18 or over" }
         ),
      maritalStatus: MaritalStatusEnum.nullish(),
      motherTongue: z.string().nullish(),
      city: z.string().nullish(),
      state: z.string().nullish(),
      country: z.string().nullish(),
      highestEducation: z.string().nullish(),
      occupation: z.string().nullish(),
      bio: z.string().min(50, "Bio must be at least 50 characters").max(1000, "Bio cannot exceed 1000 characters").nullish(),
      languages: z.array(z.string()).nullish(),
      childrenStatus: z.enum(["LIVING_WITH_ME", "NOT_LIVING_WITH_ME", "NO_CHILDREN"]).nullish(),
      emotionalReadiness: z.enum(["YES", "MOSTLY", "NOT_SURE"]).nullish(),
      lookingFor: z.enum(["MARRIAGE", "LONG_TERM_RELATIONSHIP", "SERIOUS_COMPANIONSHIP"]).nullish(),
      relationshipTimeline: z.enum(["ZERO_TO_SIX_MONTHS", "SIX_TO_TWELVE_MONTHS", "NO_FIXED_TIMELINE"]).nullish(),
      smokingHabit: z.enum(["NEVER", "OCCASIONALLY", "SOCIALLY", "REGULARLY"]).nullish(),
      drinkingHabit: z.enum(["NEVER", "OCCASIONALLY", "SOCIALLY", "REGULARLY"]).nullish(),
   }),
});

const arrayOrSingle = <T extends z.ZodTypeAny>(schema: T, minMessage?: string) => {
   let arraySchema = z.array(schema);
   if (minMessage) {
      arraySchema = arraySchema.min(1, minMessage);
   }
   return z.preprocess((val) => {
      if (val === undefined || val === null) return undefined;
      return Array.isArray(val) ? val : [val];
   }, arraySchema);
};

export const partnerPreferenceSchema = z.object({
   body: z
      .object({
         ageFrom: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100"),
         ageTo: z.number().int().min(18, "Minimum age is 18").max(100, "Maximum age is 100"),
         maritalStatus: arrayOrSingle(MaritalStatusEnum, "Select at least one marital status"),
         motherTongue: arrayOrSingle(z.string(), "Select at least one language"),
         highestEducation: arrayOrSingle(z.string(), "Select at least one education level"),
         occupation: arrayOrSingle(z.string(), "Select at least one occupation"),
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
});
