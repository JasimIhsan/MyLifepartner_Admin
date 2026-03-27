import { ConfirmationModal } from "@/components/confirmation-modal";
import { deletePlan, getPlans, updatePlan, type SubscriptionPlan } from "@/api/subscription.service";
import { Button } from "@/components/ui/button";
import type { AxiosError } from "axios";
import { Plus } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import CreateEditPlanModal from "./components/CreateEditPlanModal";
import FeaturesDrawer from "./components/FeaturesDrawer";
import PlanCard from "./components/PlanCard";

export default function SubscriptionPage() {
   const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
   const [loading, setLoading] = useState(true);

   // Modal state
   const [isPlanModalOpen, setIsPlanModalOpen] = useState(false);
   const [editingPlan, setEditingPlan] = useState<SubscriptionPlan | null>(null);

   // Features drawer state
   const [featuredPlan, setFeaturedPlan] = useState<SubscriptionPlan | null>(null);
   const [isDrawerOpen, setIsDrawerOpen] = useState(false);

   // Delete confirmation state
   const [deletingPlan, setDeletingPlan] = useState<SubscriptionPlan | null>(null);

   // ── Load plans ─────────────────────────────────────────────────────────────
   const loadPlans = useCallback(async () => {
      try {
         setLoading(true);
         const res = await getPlans();
         if (res.success) {
            setPlans(res.data);
            // Sync featured plan after reload so the drawer stays up-to-date
            if (featuredPlan) {
               const updated = (res.data as SubscriptionPlan[]).find((p) => p.id === featuredPlan.id);
               if (updated) setFeaturedPlan(updated);
            }
         } else {
            toast.error(res.message || "Failed to load plans");
         }
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Error loading plans");
      } finally {
         setLoading(false);
      }
   }, [featuredPlan]);

   useEffect(() => {
      loadPlans();
      // eslint-disable-next-line react-hooks/exhaustive-deps
   }, []);

   // ── Handlers ───────────────────────────────────────────────────────────────

   const handleOpenCreate = () => {
      setEditingPlan(null);
      setIsPlanModalOpen(true);
   };

   const handleOpenEdit = (plan: SubscriptionPlan) => {
      setEditingPlan(plan);
      setIsPlanModalOpen(true);
   };

   const handleToggleActive = async (plan: SubscriptionPlan) => {
      try {
         await updatePlan(plan.id, { isActive: !plan.isActive });
         toast.success(`Plan ${plan.isActive ? "deactivated" : "activated"}`);
         loadPlans();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update plan");
      }
   };

   const handleToggleMostPopular = async (plan: SubscriptionPlan) => {
      try {
         // If it's already most popular, untoggle it. If not, mark it as popular (backend handles untoggling others)
         await updatePlan(plan.id, { isMostPopular: !plan.isMostPopular });
         toast.success(`Plan marked as ${!plan.isMostPopular ? "most popular" : "regular"}`);
         loadPlans();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update most popular status");
      }
   };

   const handleDeleteConfirm = async () => {
      if (!deletingPlan) return;
      try {
         await deletePlan(deletingPlan.id);
         toast.success("Plan deleted");
         setDeletingPlan(null);
         loadPlans();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to delete plan");
      }
   };

   const handleManageFeatures = (plan: SubscriptionPlan) => {
      setFeaturedPlan(plan);
      setIsDrawerOpen(true);
   };

   // ── Render ─────────────────────────────────────────────────────────────────

   return (
      <div className="flex-1 space-y-6">
         {/* Header */}
         <div className="flex items-center justify-between">
            <div>
               <h2 className="text-3xl font-bold tracking-tight">Subscription Plans</h2>
               <p className="text-muted-foreground text-sm mt-1">Create and manage plans with dynamic key-value features.</p>
            </div>
            <Button onClick={handleOpenCreate} className="gap-2 rounded-full shadow-sm">
               <Plus className="h-4 w-4" />
               Add Plan
            </Button>
         </div>

         {/* Body */}
         {loading ? (
            <div className="flex flex-col items-center justify-center py-24 text-muted-foreground space-y-4">
               <div className="w-8 h-8 rounded-full border-4 border-primary/30 border-t-primary animate-spin" />
               <p className="text-sm">Loading plans…</p>
            </div>
         ) : plans.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-28 text-center border rounded-2xl bg-zinc-50/50 dark:bg-zinc-900/50 border-dashed">
               <div className="bg-primary/10 p-4 rounded-full mb-4">
                  <Plus className="h-6 w-6 text-primary" />
               </div>
               <h3 className="text-xl font-semibold text-zinc-800 dark:text-zinc-200">No Plans Yet</h3>
               <p className="text-sm text-muted-foreground mt-2 mb-6 max-w-sm">
                  Create your first subscription plan. Users will not be affected until they purchase a plan.
               </p>
               <Button onClick={handleOpenCreate} variant="outline" className="rounded-full shadow-sm">
                  Create your first plan
               </Button>
            </div>
         ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
               {plans.map((plan) => (
                  <PlanCard
                     key={plan.id}
                     plan={plan}
                     onEdit={handleOpenEdit}
                     onToggleActive={handleToggleActive}
                     onToggleMostPopular={handleToggleMostPopular}
                     onDelete={(p) => setDeletingPlan(p)}
                     onManageFeatures={handleManageFeatures}
                  />
               ))}
            </div>
         )}

         {/* Create / Edit Modal */}
         <CreateEditPlanModal
            isOpen={isPlanModalOpen}
            onClose={() => setIsPlanModalOpen(false)}
            onSuccess={loadPlans}
            editingPlan={editingPlan}
         />

         {/* Features Drawer */}
         <FeaturesDrawer
            plan={featuredPlan}
            isOpen={isDrawerOpen}
            onClose={() => {
               setIsDrawerOpen(false);
               setFeaturedPlan(null);
            }}
            onSuccess={loadPlans}
         />

         {/* Delete Confirmation */}
         <ConfirmationModal
            isOpen={!!deletingPlan}
            onClose={() => setDeletingPlan(null)}
            onConfirm={handleDeleteConfirm}
            title="Delete Plan"
            description={`Are you sure you want to delete the "${deletingPlan?.name}" plan? This will also remove all its features. This action cannot be undone.`}
         />
      </div>
   );
}
