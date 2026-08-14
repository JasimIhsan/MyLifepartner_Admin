import axiosInstance from "./api.config";
import type { UserInterface } from "@/interface/user.interface";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface GlobalFeature {
   id: number;
   key: string;
   name: string;
   boolean: boolean;
   description?: string;
   createdAt: string;
}

export interface PlanFeature {
   id: number;
   planId: number;
   featureKey: string;
   description?: string;
   limit: string;
   createdAt: string;
}

export interface SubscriptionPlan {
   id: number;
   name: string;
   description?: string;
   price: number; // in paise
   durationDays: number;
   isActive: boolean;
   isMostPopular: boolean;
   identifier?: string;
   features: PlanFeature[];
   createdAt: string;
   updatedAt: string;
}

export type UserSubscriptionStatusFilter = "ALL" | "ACTIVE" | "CANCELLED_PENDING_EXPIRY" | "BILLING_ISSUE" | "GRACE_PERIOD" | "NO_ACTIVE_SUBSCRIPTION";

export type UserSubscriptionsQuery = {
   search?: string;
   page?: number;
   limit?: number;
   status?: UserSubscriptionStatusFilter;
   planId?: number;
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Convert ₹ (rupees) to paise */
export const rupeesToPaise = (rupees: number) => Math.round(rupees * 100);

/** Convert paise to ₹ (readable string) */
export const paiseToRupees = (paise: number) =>
   new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(paise / 100);

// ─── Plan APIs ────────────────────────────────────────────────────────────────

export const getPlans = async () => {
   const res = await axiosInstance.get("/admin/subscriptions");
   return res.data; // { success, data, message }
};

export const createPlan = async (data: { name: string; description?: string; price: number; durationDays: number; identifier: string }) => {
   const res = await axiosInstance.post("/admin/subscriptions", data);
   return res.data;
};

export const updatePlan = async (planId: number, data: { description?: string; price?: number; durationDays?: number; isActive?: boolean; isMostPopular?: boolean; identifier?: string }) => {
   const res = await axiosInstance.patch(`/admin/subscriptions/${planId}`, data);
   return res.data;
};

export const deletePlan = async (planId: number) => {
   const res = await axiosInstance.delete(`/admin/subscriptions/${planId}`);
   return res.data;
};

// ─── User Subscription Management APIs ───────────────────────────────────────

export const getUserSubscriptions = async (query: UserSubscriptionsQuery) => {
   const res = await axiosInstance.get("/admin/subscriptions/users", {
      params: query,
   });
   return res.data as { data: { data: UserInterface[]; total: number }; message: string };
};

export const updateUserSubscriptionPlan = async (userId: number, planId: number) => {
   const res = await axiosInstance.patch(`/admin/subscriptions/users/${userId}/plan`, { planId });
   return res.data;
};

// ─── Plan Feature Mapping APIs ────────────────────────────────────────────────

export const addFeaturesToPlan = async (planId: number, features: { featureKey: string; limit: string; description?: string }[]) => {
   const res = await axiosInstance.post(`/admin/subscriptions/${planId}/features`, features);
   return res.data;
};

export const updatePlanFeature = async (planId: number, planFeatureId: number, data: { limit?: string; description?: string }) => {
   const res = await axiosInstance.patch(`/admin/subscriptions/${planId}/features/${planFeatureId}`, data);
   return res.data;
};

export const deletePlanFeature = async (planId: number, planFeatureId: number) => {
   const res = await axiosInstance.delete(`/admin/subscriptions/${planId}/features/${planFeatureId}`);
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
