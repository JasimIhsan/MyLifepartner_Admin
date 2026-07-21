export interface UpdateProfileDto {
   name?: string;
   dob?: Date | string;
   gender?: string;
   religion?: string;
   motherTongue?: string;
   maritalStatus?: string;
   weight?: number;
   about?: string;
   city?: string;
   state?: string;
   country?: string;
   education?: string;
   occupation?: string;
   jobId?: number;
   income?: string;
   caste?: string;
   subCaste?: string;
   diet?: string;
   smoke?: string;
   drink?: string;
   bloodGroup?: string;
   familyType?: string;
   familyStatus?: string;
   familyValues?: string;
   fathersOccupation?: string;
   mothersOccupation?: string;
   brothers?: number;
   sisters?: number;
   marriedBrothers?: number;
   marriedSisters?: number;
   hobbies?: string[];
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
   ageMin?: number;
   ageMax?: number;
   ageFrom?: number;
   ageTo?: number;
   maritalStatus?: string | string[];
   religion?: string;
   caste?: string;
   motherTongue?: string | string[];
   education?: string;
   highestEducation?: string | string[];
   occupation?: string | string[];
   income?: string;
   country?: string;
   state?: string;
   city?: string;
   diet?: string;
   smoke?: string;
   drink?: string;
}

