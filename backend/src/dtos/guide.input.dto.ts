export interface CreateGuideDto {
   question: string;
   answer: string;
   categoryId: number;
   bullets?: string[];
}

export interface UpdateGuideDto {
   question?: string;
   answer?: string;
   categoryId?: number;
   bullets?: string[];
}

export interface CreateGuideCategoryDto {
   name: string;
   displayOrder?: number;
}

export interface UpdateGuideCategoryDto {
   name?: string;
   displayOrder?: number;
}
