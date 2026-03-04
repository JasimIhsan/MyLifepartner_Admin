import axiosInstance from "./api.config";

export interface ProfileSection {
   id: number;
   key: string;
   title: string;
   orderNo: number;
   isPrimary: boolean;
   questions?: ProfileQuestion[];
}

export interface ProfileQuestion {
   id: number;
   sectionId: number;
   question: string;
   answerType: "TEXT" | "SINGLE_CHOICE" | "MULTI_CHOICE" | "RATING" | "BOOLEAN";
   options: Record<string, string> | null;
   minWords?: number;
   weight: number;
   isRequired: boolean;
   orderNo: number;
   isActive: boolean;
}

// ==========================================
// Sections
// ==========================================

export const getSections = async () => {
   const response = await axiosInstance.get("/admin/questionnaire/sections");
   return response.data; // { statusCode, data, message, success }
};

export const createSection = async (data: Partial<ProfileSection>) => {
   const response = await axiosInstance.post("/admin/questionnaire/sections", data);
   return response.data;
};

export const updateSection = async (id: number, data: Partial<ProfileSection>) => {
   const response = await axiosInstance.put(`/admin/questionnaire/sections/${id}`, data);
   return response.data;
};

export const deleteSection = async (id: number) => {
   const response = await axiosInstance.delete(`/admin/questionnaire/sections/${id}`);
   return response.data;
};

export const reorderSections = async (orderedIds: number[]) => {
   const response = await axiosInstance.put("/admin/questionnaire/sections/reorder", { orderedIds });
   return response.data;
};

// ==========================================
// Questions
// ==========================================

export const createQuestion = async (sectionId: number, data: Partial<ProfileQuestion>) => {
   const response = await axiosInstance.post(`/admin/questionnaire/sections/${sectionId}/questions`, data);
   return response.data;
};

export const updateQuestion = async (id: number, data: Partial<ProfileQuestion>) => {
   const response = await axiosInstance.put(`/admin/questionnaire/questions/${id}`, data);
   return response.data;
};

export const toggleQuestionActive = async (id: number) => {
   const response = await axiosInstance.patch(`/admin/questionnaire/questions/${id}/toggle-active`);
   return response.data;
};

export const deleteQuestion = async (id: number) => {
   const response = await axiosInstance.delete(`/admin/questionnaire/questions/${id}`);
   return response.data;
};

export const reorderQuestions = async (sectionId: number, orderedIds: number[]) => {
   const response = await axiosInstance.put(`/admin/questionnaire/sections/${sectionId}/questions/reorder`, { orderedIds });
   return response.data;
};
