import { addFeatures, deleteFeature, updateFeature, type PlanFeature, type SubscriptionPlan } from "@/api/subscription.service";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import type { AxiosError } from "axios";
import { Check, Pencil, Plus, Trash2, X } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

interface FeaturesDrawerProps {
   plan: SubscriptionPlan | null;
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
}

/** A single editable feature row */
function FeatureRow({
   feature,
   onUpdate,
   onDelete,
}: {
   feature: PlanFeature;
   onUpdate: (id: number, value: string) => Promise<void>;
   onDelete: (id: number) => Promise<void>;
}) {
   const [editing, setEditing] = useState(false);
   const [editedValue, setEditedValue] = useState(feature.value);
   const [loading, setLoading] = useState(false);

   const handleSave = async () => {
      if (editedValue.trim() === "") {
         toast.error("Value cannot be empty");
         return;
      }
      setLoading(true);
      await onUpdate(feature.id, editedValue.trim());
      setLoading(false);
      setEditing(false);
   };

   const handleCancel = () => {
      setEditedValue(feature.value);
      setEditing(false);
   };

   const handleDelete = async () => {
      setLoading(true);
      await onDelete(feature.id);
      setLoading(false);
   };

   return (
      <div className="flex items-center gap-2 p-2 rounded-lg bg-muted/40 hover:bg-muted/70 transition-colors">
         {/* Key */}
         <code className="text-xs font-mono text-muted-foreground flex-1 min-w-0 truncate">{feature.key}</code>

         {/* Value */}
         {editing ? (
            <Input
               value={editedValue}
               onChange={(e) => setEditedValue(e.target.value)}
               className="h-7 text-xs w-32"
               autoFocus
               onKeyDown={(e) => {
                  if (e.key === "Enter") handleSave();
                  if (e.key === "Escape") handleCancel();
               }}
            />
         ) : (
            <span className="text-xs font-semibold w-24 text-right truncate">{feature.value}</span>
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
   const [newKey, setNewKey] = useState("");
   const [newValue, setNewValue] = useState("");
   const [addLoading, setAddLoading] = useState(false);

   if (!plan) return null;

   // ── Add feature ────────────────────────────────────────────────────────────
   const handleAdd = async () => {
      const key = newKey.trim().toLowerCase().replace(/\s+/g, "_");
      const value = newValue.trim();
      if (!key || !value) {
         toast.error("Both key and value are required");
         return;
      }
      try {
         setAddLoading(true);
         await addFeatures(plan.id, [{ key, value }]);
         toast.success("Feature added");
         setNewKey("");
         setNewValue("");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to add feature");
      } finally {
         setAddLoading(false);
      }
   };

   // ── Update feature ─────────────────────────────────────────────────────────
   const handleUpdate = async (id: number, value: string) => {
      try {
         await updateFeature(id, value);
         toast.success("Feature updated");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update feature");
      }
   };

   // ── Delete feature ─────────────────────────────────────────────────────────
   const handleDelete = async (id: number) => {
      try {
         await deleteFeature(id);
         toast.success("Feature deleted");
         onSuccess();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to delete feature");
      }
   };

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
                  <FeatureRow key={f.id} feature={f} onUpdate={handleUpdate} onDelete={handleDelete} />
               ))}
            </div>

            {/* Add new feature row */}
            <div className="border-t px-6 py-4 space-y-3">
               <p className="text-sm font-semibold">Add Feature</p>
               <p className="text-xs text-muted-foreground -mt-1">
                  Key: lowercase, underscores. Example keys: <code>can_message</code>, <code>video_call_minutes</code>
               </p>
               <div className="flex gap-2">
                  <Input
                     placeholder="key (e.g. can_message)"
                     value={newKey}
                     onChange={(e) => setNewKey(e.target.value)}
                     className="text-xs font-mono h-8"
                  />
                  <Input
                     placeholder="value"
                     value={newValue}
                     onChange={(e) => setNewValue(e.target.value)}
                     className="text-xs h-8"
                     onKeyDown={(e) => e.key === "Enter" && handleAdd()}
                  />
                  <Button size="sm" className="h-8 gap-1 shrink-0" onClick={handleAdd} disabled={addLoading}>
                     <Plus className="h-3.5 w-3.5" />
                     Add
                  </Button>
               </div>
            </div>
         </SheetContent>
      </Sheet>
   );
}
