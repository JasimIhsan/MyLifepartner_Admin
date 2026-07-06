export interface UpdateProfileDto {
   name?: string;
   dob?: Date | string;
   gender?: string;
   religion?: string;
   motherTongue?: string;
   maritalStatus?: string;
   height?: number;
   weight?: number;
   about?: string;
   city?: string;
   state?: string;
   country?: string;
   education?: string;
   occupation?: string;
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
   interests?: string[];
}

export interface CreatePartnerPreferenceDto {
   ageMin?: number;
   ageMax?: number;
   heightMin?: number;
   heightMax?: number;
   maritalStatus?: string;
   religion?: string;
   caste?: string;
   motherTongue?: string;
   education?: string;
   occupation?: string;
   income?: string;
   country?: string;
   state?: string;
   city?: string;
   diet?: string;
   smoke?: string;
   drink?: string;
}
