import type { AxiosError } from "axios";
import { Check, Pencil, Plus, Trash2, X } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { addFeaturesToPlan, deletePlanFeature, getGlobalFeatures, updatePlanFeature, type GlobalFeature, type PlanFeature, type SubscriptionPlan } from "@/api/subscription.service";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Switch } from "@/components/ui/switch";

interface FeaturesDrawerProps {
   plan: SubscriptionPlan | null;
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
}

interface FeatureRowProps {
   planId: number;
   feature: PlanFeature;
   globalFeature?: GlobalFeature;
   isEditing: boolean;
   onStartEdit: () => void;
   onCancelEdit: () => void;
   onUpdate: (data: { limit: string; description?: string }) => Promise<void>;
   onDelete: () => Promise<void>;
}

/** A single editable feature row */
function FeatureRow({ planId, feature, globalFeature, isEditing, onStartEdit, onCancelEdit, onUpdate, onDelete }: FeatureRowProps) {
   const [editedLimit, setEditedLimit] = useState(feature.limit);
   const [editedDesc, setEditedDesc] = useState(feature.description || "");
   const [loading, setLoading] = useState(false);

   // Sync local fields when drawer/edit state changes
   useEffect(() => {
      setEditedLimit(feature.limit);
      setEditedDesc(feature.description || "");
   }, [feature, isEditing]);

   const handleSave = async () => {
      if (editedLimit.trim() === "") {
         toast.error("Limit cannot be empty");
         return;
      }
      setLoading(true);
      await onUpdate({ limit: editedLimit.trim(), description: editedDesc.trim() || undefined });
      setLoading(false);
   };

   const handleDelete = async () => {
      setLoading(true);
      await onDelete();
      setLoading(false);
   };

   return (
      <div className={`group flex flex-col gap-2 p-3.5 rounded-xl border transition-all duration-200 ${isEditing ? "border-primary bg-primary/5 ring-1 ring-primary/10 shadow-sm" : "border-muted bg-card hover:border-primary/20 hover:shadow-sm"}`}>
         <div className="flex items-center justify-between gap-3">
            <div className="flex flex-col min-w-0">
               <span className="text-sm font-semibold text-foreground truncate">{globalFeature?.name || feature.featureKey}</span>
               <span className="text-[10px] text-muted-foreground font-mono truncate">{feature.featureKey}</span>
            </div>

            <div className="flex items-center gap-2 shrink-0">
               {isEditing ? (
                  globalFeature?.boolean ? (
                     <div className="flex items-center gap-2">
                        <Switch checked={editedLimit === "true"} onCheckedChange={(checked) => setEditedLimit(checked ? "true" : "false")} />
                        <span className="text-xs font-medium text-muted-foreground">{editedLimit === "true" ? "Enabled" : "Disabled"}</span>
                     </div>
                  ) : (
                     <Input value={editedLimit} onChange={(e) => setEditedLimit(e.target.value)} className="h-8 text-xs w-28 px-2 font-semibold bg-background" placeholder="Limit" />
                  )
               ) : globalFeature?.boolean ? (
                  <span className={`text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full ${feature.limit === "true" ? "bg-green-100 text-green-700" : "bg-muted text-muted-foreground"}`}>{feature.limit === "true" ? "Enabled" : "Disabled"}</span>
               ) : (
                  <span className="text-sm font-bold text-primary bg-primary/5 px-2 py-0.5 rounded-md border border-primary/10">{feature.limit}</span>
               )}
            </div>
         </div>

         {/* Description & Action Row */}
         <div className="flex items-end justify-between gap-3 ">
            <div className="flex-1 min-w-0">
               {isEditing ? (
                  <Input
                     value={editedDesc}
                     onChange={(e) => setEditedDesc(e.target.value)}
                     className="h-7 text-xs px-2 bg-background"
                     placeholder="Custom description (Optional)"
                     onKeyDown={(e) => {
                        if (e.key === "Enter") handleSave();
                        if (e.key === "Escape") onCancelEdit();
                     }}
                  />
               ) : feature.description ? (
                  <p className="text-xs text-muted-foreground leading-snug line-clamp-2" title={feature.description}>
                     {feature.description}
                  </p>
               ) : (
                  <p className="text-[11px] text-muted-foreground/55 italic">Default description used</p>
               )}
            </div>

            {/* Actions */}
            <div className="flex items-center gap-1 shrink-0">
               {isEditing ? (
                  <>
                     <Button size="icon" variant="outline" className="h-7 w-7 text-green-600 hover:text-green-700 hover:bg-green-50 border-green-200" onClick={handleSave} disabled={loading}>
                        <Check className="h-4 w-4" />
                     </Button>
                     <Button size="icon" variant="outline" className="h-7 w-7 text-muted-foreground hover:bg-muted border-muted-foreground/20" onClick={onCancelEdit} disabled={loading}>
                        <X className="h-4 w-4" />
                     </Button>
                  </>
               ) : (
                  <>
                     <Button size="icon" variant="ghost" className="h-7 w-7 text-muted-foreground hover:text-foreground hover:bg-muted opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity" onClick={onStartEdit} disabled={loading}>
                        <Pencil className="h-3.5 w-3.5" />
                     </Button>
                     <Button size="icon" variant="ghost" className="h-7 w-7 text-muted-foreground hover:text-destructive hover:bg-destructive/10 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity" onClick={handleDelete} disabled={loading}>
                        <Trash2 className="h-3.5 w-3.5" />
                     </Button>
                  </>
               )}
            </div>
         </div>
      </div>
   );
}

export default function FeaturesDrawer({ plan, isOpen, onClose, onSuccess }: FeaturesDrawerProps) {
   const [globalFeatures, setGlobalFeatures] = useState<GlobalFeature[]>([]);
   const [selectedFeatureKey, setSelectedFeatureKey] = useState<string>("");
   const [newLimit, setNewLimit] = useState("");
   const [newDesc, setNewDesc] = useState("");
   const [addLoading, setAddLoading] = useState(false);

   // Track which feature ID is currently being edited. Only one can be edited at a time.
   const [editingFeatureId, setEditingFeatureId] = useState<number | null>(null);

   const availableFeatures = globalFeatures.filter((gf) => !plan?.features.some((pf) => pf.featureKey === gf.key));
   const selectedGlobalFeature = availableFeatures.find((f) => f.key === selectedFeatureKey);
   const isBooleanFeature = selectedGlobalFeature?.boolean;

   useEffect(() => {
      if (isBooleanFeature) {
         setNewLimit("true");
      } else {
         setNewLimit("");
      }
   }, [selectedFeatureKey, isBooleanFeature]);

   useEffect(() => {
      if (isOpen) {
         fetchGlobalFeatures();
         setEditingFeatureId(null); // Reset edit state when drawer opens
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
         await addFeaturesToPlan(plan.id, [{ featureKey: selectedFeatureKey, limit: newLimit.trim(), description: newDesc.trim() || undefined }]);
         toast.success("Feature added to plan");
         setSelectedFeatureKey("");
         setNewLimit("");
         setNewDesc("");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to add feature");
      } finally {
         setAddLoading(false);
      }
   };

   // ── Update feature ─────────────────────────────────────────────────────────
   const handleUpdate = async (planFeatureId: number, data: { limit: string; description?: string }) => {
      try {
         await updatePlanFeature(plan.id, planFeatureId, data);
         toast.success("Plan feature updated");
         setEditingFeatureId(null);
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update feature");
      }
   };

   // ── Delete feature ─────────────────────────────────────────────────────────
   const handleDelete = async (planFeatureId: number) => {
      try {
         await deletePlanFeature(plan.id, planFeatureId);
         toast.success("Plan feature deleted");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to delete feature");
      }
   };

   return (
      <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <SheetContent className="sm:max-w-xl flex flex-col gap-0 p-0">
            <SheetHeader className="px-6 pt-6 pb-4 border-b bg-card/50">
               <SheetTitle>Manage Features</SheetTitle>
               <SheetDescription>
                  <span className="font-semibold text-foreground">{plan.name}</span> plan · {plan.features.length} feature
                  {plan.features.length !== 1 ? "s" : ""}
               </SheetDescription>
            </SheetHeader>

            {/* Feature list */}
            <div className="flex-1 overflow-y-auto px-6 py-4 space-y-3">
               {plan.features.length === 0 && <p className="text-sm text-muted-foreground text-center py-8">No features yet. Add one below.</p>}
               {plan.features.map((f) => (
                  <FeatureRow
                     key={f.id}
                     planId={plan.id}
                     feature={f}
                     globalFeature={globalFeatures.find((gf) => gf.key === f.featureKey)}
                     isEditing={editingFeatureId === f.id}
                     onStartEdit={() => setEditingFeatureId(f.id)}
                     onCancelEdit={() => setEditingFeatureId(null)}
                     onUpdate={(data) => handleUpdate(f.id, data)}
                     onDelete={() => handleDelete(f.id)}
                  />
               ))}
            </div>

            {/* Add new feature section */}
            <div className="border-t px-6 py-4 space-y-3 bg-muted/20">
               <p className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Extend Plan Features</p>
               <div className="flex flex-col gap-3">
                  <div className="space-y-1">
                     <Label className="text-xs text-muted-foreground">Select Feature</Label>
                     <Select value={selectedFeatureKey} onValueChange={setSelectedFeatureKey}>
                        <SelectTrigger className="h-9 text-xs bg-background">
                           <SelectValue placeholder="Choose a generic feature to map..." />
                        </SelectTrigger>
                        <SelectContent>
                           {availableFeatures.length === 0 && <div className="p-2 text-xs text-muted-foreground text-center">No more features available</div>}
                           {availableFeatures.map((gf) => (
                              <SelectItem key={gf.key} value={gf.key} className="text-xs">
                                 {gf.name}
                              </SelectItem>
                           ))}
                        </SelectContent>
                     </Select>
                  </div>
                  <div className="space-y-1">
                     <Label className="text-xs text-muted-foreground">Limit & Custom Description</Label>
                     <div className="flex flex-col gap-2">
                        {isBooleanFeature ? (
                           <div className="flex items-center gap-2 h-9 px-3 border rounded-md bg-background">
                              <Switch checked={newLimit === "true"} onCheckedChange={(checked) => setNewLimit(checked ? "true" : "false")} />
                              <span className="text-xs text-muted-foreground">{newLimit === "true" ? "Enabled" : "Disabled"}</span>
                           </div>
                        ) : (
                           <Input placeholder="e.g. 100, Unlimited, 5 / day" value={newLimit} onChange={(e) => setNewLimit(e.target.value)} className="h-9 text-xs font-medium bg-background" />
                        )}
                        <div className="flex gap-2">
                           <Input placeholder="Override Description (Optional)" value={newDesc} onChange={(e) => setNewDesc(e.target.value)} className="h-9 text-xs bg-background" onKeyDown={(e) => e.key === "Enter" && handleAdd()} />
                           <Button size="sm" className="h-9 gap-1 shrink-0" onClick={handleAdd} disabled={addLoading}>
                              <Plus className="h-4 w-4" />
                              Add Feature
                           </Button>
                        </div>
                     </div>
                  </div>
               </div>
            </div>
         </SheetContent>
      </Sheet>
   );
}
