import axiosInstance from "./api.config";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface PlanFeature {
   id: number;
   planId: number;
   key: string;
   value: string;
   createdAt: string;
}

export interface SubscriptionPlan {
   id: number;
   name: string;
   price: number; // in paise
   durationDays: number;
   isActive: boolean;
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

export const createPlan = async (data: { name: string; price: number; durationDays: number }) => {
   const res = await axiosInstance.post("/admin/plans", data);
   return res.data;
};

export const updatePlan = async (planId: number, data: { price?: number; durationDays?: number; isActive?: boolean }) => {
   const res = await axiosInstance.patch(`/admin/plans/${planId}`, data);
   return res.data;
};

export const deletePlan = async (planId: number) => {
   const res = await axiosInstance.delete(`/admin/plans/${planId}`);
   return res.data;
};

// ─── Feature APIs ─────────────────────────────────────────────────────────────

export const addFeatures = async (planId: number, features: { key: string; value: string }[]) => {
   const res = await axiosInstance.post(`/admin/plans/${planId}/features`, features);
   return res.data;
};

export const updateFeature = async (featureId: number, value: string) => {
   const res = await axiosInstance.patch(`/admin/features/${featureId}`, { value });
   return res.data;
};

export const deleteFeature = async (featureId: number) => {
   const res = await axiosInstance.delete(`/admin/features/${featureId}`);
   return res.data;
};
