import axiosInstance from "./api.config";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface GlobalFeature {
   id: number;
   key: string;
   name: string;
   description?: string;
   createdAt: string;
}

export interface PlanFeature {
   id: number;
   planId: number;
   featureKey: string;
   limit: string;
   createdAt: string;
}

export interface SubscriptionPlan {
   id: number;
   name: string;
   price: number; // in paise
   durationDays: number;
   isActive: boolean;
   isMostPopular: boolean;
   identifier?: string;
   features: PlanFeature[];
   createdAt: string;
   updatedAt: string;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Convert ₹ (rupees) to paise */
export const rupeesToPaise = (rupees: number) => Math.round(rupees * 100);

/** Convert paise to ₹ (readable string) */
export const paiseToRupees = (paise: number) =>
   new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(paise / 100);

// ─── Plan APIs ────────────────────────────────────────────────────────────────

export const getPlans = async () => {
   const res = await axiosInstance.get("/admin/plans");
   return res.data; // { success, data, message }
};

export const createPlan = async (data: { name: string; price: number; durationDays: number; identifier: string }) => {
   const res = await axiosInstance.post("/admin/plans", data);
   return res.data;
};

export const updatePlan = async (planId: number, data: { price?: number; durationDays?: number; isActive?: boolean; isMostPopular?: boolean; identifier?: string }) => {
   const res = await axiosInstance.patch(`/admin/plans/${planId}`, data);
   return res.data;
};

export const deletePlan = async (planId: number) => {
   const res = await axiosInstance.delete(`/admin/plans/${planId}`);
   return res.data;
};

// ─── Plan Feature Mapping APIs ────────────────────────────────────────────────

export const addFeaturesToPlan = async (planId: number, features: { featureKey: string; limit: string }[]) => {
   const res = await axiosInstance.post(`/admin/plans/${planId}/features`, features);
   return res.data;
};

export const updatePlanFeature = async (planId: number, planFeatureId: number, limit: string) => {
   const res = await axiosInstance.patch(`/admin/plans/${planId}/features/${planFeatureId}`, { limit });
   return res.data;
};

export const deletePlanFeature = async (planId: number, planFeatureId: number) => {
   const res = await axiosInstance.delete(`/admin/plans/${planId}/features/${planFeatureId}`);
   return res.data;
};

// ─── Global Feature APIs ──────────────────────────────────────────────────────

export const getGlobalFeatures = async () => {
   const res = await axiosInstance.get("/admin/features");
   return res.data;
};

export const createGlobalFeature = async (data: { key: string; name: string; description?: string }) => {
   const res = await axiosInstance.post("/admin/features", data);
   return res.data;
};

export const updateGlobalFeature = async (featureId: number, data: { name?: string; description?: string }) => {
   const res = await axiosInstance.patch(`/admin/features/${featureId}`, data);
   return res.data;
};

export const deleteGlobalFeature = async (featureId: number) => {
   const res = await axiosInstance.delete(`/admin/features/${featureId}`);
   return res.data;
};
