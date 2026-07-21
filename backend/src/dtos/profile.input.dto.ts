export interface UpdateProfileDto {
   name?: string;
   gender?: string;
   motherTongue?: string;
   maritalStatus?: string;
   city?: string;
   state?: string;
   country?: string;
   occupation?: string;
   jobId?: number;
   dateOfBirth?: Date | string;
   bio?: string;
   highestEducation?: string;
   smokingHabit?: string;
   drinkingHabit?: string;
   languages?: string[];
   childrenStatus?: string;
   emotionalReadiness?: string;
   lookingFor?: string;
   relationshipTimeline?: string;
}

export interface CreatePartnerPreferenceDto {
   ageFrom?: number;
   ageTo?: number;
   maritalStatus?: string | string[];
   motherTongue?: string | string[];
}
