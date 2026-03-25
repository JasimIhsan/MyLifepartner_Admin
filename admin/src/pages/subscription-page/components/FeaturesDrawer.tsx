import { useState, useEffect } from "react";
import type { AxiosError } from "axios";
import { toast } from "sonner";
import { Check, Pencil, Plus, Trash2, X } from "lucide-react";

import {
   addFeaturesToPlan,
   deletePlanFeature,
   updatePlanFeature,
   getGlobalFeatures,
   type GlobalFeature,
   type PlanFeature,
   type SubscriptionPlan,
} from "@/api/subscription.service";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";

interface FeaturesDrawerProps {
   plan: SubscriptionPlan | null;
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
}

/** A single editable feature row */
function FeatureRow({
   planId,
   feature,
   onUpdate,
   onDelete,
}: {
   planId: number;
   feature: PlanFeature;
   onUpdate: (planId: number, id: number, limit: string) => Promise<void>;
   onDelete: (planId: number, id: number) => Promise<void>;
}) {
   const [editing, setEditing] = useState(false);
   const [editedLimit, setEditedLimit] = useState(feature.limit);
   const [loading, setLoading] = useState(false);

   const handleSave = async () => {
      if (editedLimit.trim() === "") {
         toast.error("Limit cannot be empty");
         return;
      }
      setLoading(true);
      await onUpdate(planId, feature.id, editedLimit.trim());
      setLoading(false);
      setEditing(false);
   };

   const handleCancel = () => {
      setEditedLimit(feature.limit);
      setEditing(false);
   };

   const handleDelete = async () => {
      setLoading(true);
      await onDelete(planId, feature.id);
      setLoading(false);
   };

   return (
      <div className="flex items-center gap-2 p-2 rounded-lg bg-muted/40 hover:bg-muted/70 transition-colors">
         <code className="text-xs font-mono text-muted-foreground flex-1 min-w-0 truncate">
            {feature.featureKey}
         </code>

         {/* Limit */}
         {editing ? (
            <Input
               value={editedLimit}
               onChange={(e) => setEditedLimit(e.target.value)}
               className="h-7 text-xs w-32"
               autoFocus
               onKeyDown={(e) => {
                  if (e.key === "Enter") handleSave();
                  if (e.key === "Escape") handleCancel();
               }}
            />
         ) : (
            <span className="text-xs font-semibold w-24 text-right truncate">{feature.limit}</span>
         )}

         {/* Actions */}
         <div className="flex items-center gap-1 shrink-0">
            {editing ? (
               <>
                  <Button size="icon" variant="ghost" className="h-6 w-6" onClick={handleSave} disabled={loading}>
                     <Check className="h-3 w-3 text-green-600" />
                  </Button>
                  <Button size="icon" variant="ghost" className="h-6 w-6" onClick={handleCancel} disabled={loading}>
                     <X className="h-3 w-3 text-muted-foreground" />
                  </Button>
               </>
            ) : (
               <>
                  <Button size="icon" variant="ghost" className="h-6 w-6" onClick={() => setEditing(true)} disabled={loading}>
                     <Pencil className="h-3 w-3 text-muted-foreground" />
                  </Button>
                  <Button size="icon" variant="ghost" className="h-6 w-6" onClick={handleDelete} disabled={loading}>
                     <Trash2 className="h-3 w-3 text-destructive" />
                  </Button>
               </>
            )}
         </div>
      </div>
   );
}

export default function FeaturesDrawer({ plan, isOpen, onClose, onSuccess }: FeaturesDrawerProps) {
   const [globalFeatures, setGlobalFeatures] = useState<GlobalFeature[]>([]);
   const [selectedFeatureKey, setSelectedFeatureKey] = useState<string>("");
   const [newLimit, setNewLimit] = useState("");
   const [addLoading, setAddLoading] = useState(false);

   useEffect(() => {
      if (isOpen) {
         fetchGlobalFeatures();
      }
   }, [isOpen]);

   const fetchGlobalFeatures = async () => {
      try {
         const res = await getGlobalFeatures();
         setGlobalFeatures(res.data);
      } catch (err) {
         console.error("Failed to load global features for drawer", err);
      }
   };

   if (!plan) return null;

   // ── Add feature ────────────────────────────────────────────────────────────
   const handleAdd = async () => {
      if (!selectedFeatureKey || !newLimit.trim()) {
         toast.error("Please select a feature and enter a limit");
         return;
      }
      try {
         setAddLoading(true);
         await addFeaturesToPlan(plan.id, [{ featureKey: selectedFeatureKey, limit: newLimit.trim() }]);
         toast.success("Feature added to plan");
         setSelectedFeatureKey("");
         setNewLimit("");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to add feature");
      } finally {
         setAddLoading(false);
      }
   };

   // ── Update feature ─────────────────────────────────────────────────────────
   const handleUpdate = async (planId: number, planFeatureId: number, limit: string) => {
      try {
         await updatePlanFeature(planId, planFeatureId, limit);
         toast.success("Plan feature updated");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update feature");
      }
   };

   // ── Delete feature ─────────────────────────────────────────────────────────
   const handleDelete = async (planId: number, planFeatureId: number) => {
      try {
         await deletePlanFeature(planId, planFeatureId);
         toast.success("Plan feature deleted");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to delete feature");
      }
   };

   // Filter out features that the plan already has
   const availableFeatures = globalFeatures.filter((gf) => !plan.features.some((pf) => pf.featureKey === gf.key));

   return (
      <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <SheetContent className="sm:max-w-md flex flex-col gap-0 p-0">
            <SheetHeader className="px-6 pt-6 pb-4 border-b">
               <SheetTitle>Manage Features</SheetTitle>
               <SheetDescription>
                  <span className="font-semibold text-foreground">{plan.name}</span> plan · {plan.features.length} feature
                  {plan.features.length !== 1 ? "s" : ""}
               </SheetDescription>
            </SheetHeader>

            {/* Feature list */}
            <div className="flex-1 overflow-y-auto px-6 py-4 space-y-2">
               {plan.features.length === 0 && (
                  <p className="text-sm text-muted-foreground text-center py-8">No features yet. Add one below.</p>
               )}
               {plan.features.map((f) => (
                  <FeatureRow key={f.id} planId={plan.id} feature={f} onUpdate={handleUpdate} onDelete={handleDelete} />
               ))}
            </div>

            {/* Add new feature row */}
            <div className="border-t px-6 py-4 space-y-3 bg-muted/10">
               <p className="text-sm font-semibold">Extend Plan</p>
               <div className="flex flex-col gap-3">
                  <div className="space-y-1">
                     <Label className="text-xs">Feature</Label>
                     <Select value={selectedFeatureKey} onValueChange={setSelectedFeatureKey}>
                        <SelectTrigger className="h-8 text-xs">
                           <SelectValue placeholder="Select a generic feature" />
                        </SelectTrigger>
                        <SelectContent>
                           {availableFeatures.length === 0 && (
                              <div className="p-2 text-xs text-muted-foreground text-center">No more features available</div>
                           )}
                           {availableFeatures.map((gf) => (
                              <SelectItem key={gf.key} value={gf.key} className="text-xs">
                                 {gf.name} ({gf.key})
                              </SelectItem>
                           ))}
                        </SelectContent>
                     </Select>

                  </div>
                  <div className="space-y-1">
                     <Label className="text-xs">Limit Definition</Label>
                     <div className="flex gap-2">
                        <Input
                           placeholder="e.g. 100, Unlimited, 5 / day"
                           value={newLimit}
                           onChange={(e) => setNewLimit(e.target.value)}
                           className="h-8 text-xs font-medium bg-background"
                           onKeyDown={(e) => e.key === "Enter" && handleAdd()}
                        />
                        <Button size="sm" className="h-8 gap-1 shrink-0" onClick={handleAdd} disabled={addLoading}>
                           <Plus className="h-3.5 w-3.5" />
                           Add
                        </Button>
                     </div>
                  </div>
               </div>
            </div>
         </SheetContent>
      </Sheet>
   );
}
