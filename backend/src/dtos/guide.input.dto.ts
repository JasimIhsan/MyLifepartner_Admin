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
