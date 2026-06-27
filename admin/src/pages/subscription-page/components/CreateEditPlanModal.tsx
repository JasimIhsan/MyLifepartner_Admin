import { createPlan, rupeesToPaise, updatePlan, type SubscriptionPlan } from "@/api/subscription.service";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { AxiosError } from "axios";
import { useEffect, useState } from "react";
import { toast } from "sonner";

interface CreateEditPlanModalProps {
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
   editingPlan?: SubscriptionPlan | null;
}

export default function CreateEditPlanModal({ isOpen, onClose, onSuccess, editingPlan }: CreateEditPlanModalProps) {
   const [name, setName] = useState("");
   const [identifier, setIdentifier] = useState("");
   const [priceRupees, setPriceRupees] = useState<string>("");
   const [durationDays, setDurationDays] = useState<string>("");
   const [loading, setLoading] = useState(false);

   const isEditing = !!editingPlan;

   // Pre-fill when editing
   useEffect(() => {
      if (editingPlan) {
         setName(editingPlan.name);
         setIdentifier(editingPlan.identifier || "");
         setPriceRupees(String(editingPlan.price / 100));
         setDurationDays(String(editingPlan.durationDays));
      } else {
         setName("");
         setIdentifier("");
         setPriceRupees("");
         setDurationDays("");
      }
   }, [editingPlan, isOpen]);

   const handleSubmit = async (e: React.FormEvent) => {
      e.preventDefault();
      const price = rupeesToPaise(parseFloat(priceRupees));
      const days = parseInt(durationDays);

      if (isNaN(price) || price < 0) {
         toast.error("Enter a valid price");
         return;
      }
      if (isNaN(days) || days < 1) {
         toast.error("Duration must be at least 1 day");
         return;
      }
      if (!identifier.trim()) {
         toast.error("Identifier is required");
         return;
      }

      try {
         setLoading(true);
         if (isEditing && editingPlan) {
            // Only send changed fields
            await updatePlan(editingPlan.id, { price, durationDays: days, identifier: identifier.trim() });
            toast.success("Plan updated successfully");
         } else {
            if (!name.trim()) {
               toast.error("Plan name is required");
               return;
            }
            await createPlan({ name: name.trim(), price, durationDays: days, identifier: identifier.trim() });
            toast.success("Plan created successfully");
         }
         onSuccess();
         onClose();
      } catch (err) {
         const axiosError = err as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Operation failed");
      } finally {
         setLoading(false);
      }
   };

   return (
      <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <DialogContent className="sm:max-w-md">
            <DialogHeader>
               <DialogTitle>{isEditing ? "Edit Plan" : "Create New Plan"}</DialogTitle>
            </DialogHeader>

            <form onSubmit={handleSubmit} className="space-y-4 mt-2">
               {/* Name – only for create */}
               {!isEditing && (
                  <div className="space-y-1.5">
                     <Label htmlFor="plan-name">Plan Name</Label>
                     <Input
                        id="plan-name"
                        placeholder="e.g. PREMIUM"
                        value={name}
                        onChange={(e) => setName(e.target.value.toUpperCase())}
                        className="uppercase"
                     />
                     <p className="text-xs text-muted-foreground">Letters, numbers, underscores only. Auto-uppercased.</p>
                  </div>
               )}

               {/* Identifier */}
               <div className="space-y-1.5">
                  <Label htmlFor="plan-identifier">Identifier (RevenueCat ID)</Label>
                  <Input
                     id="plan-identifier"
                     placeholder="e.g. premium_monthly"
                     value={identifier}
                     onChange={(e) => setIdentifier(e.target.value)}
                     required
                  />
                  <p className="text-xs text-muted-foreground">The exact product identifier from RevenueCat.</p>
               </div>

               {/* Price in ₹ */}
               <div className="space-y-1.5">
                  <Label htmlFor="plan-price">Price (₹)</Label>
                  <div className="relative">
                     <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground font-medium">₹</span>
                     <Input
                        id="plan-price"
                        type="number"
                        min="0"
                        step="1"
                        placeholder="999"
                        value={priceRupees}
                        onChange={(e) => setPriceRupees(e.target.value)}
                        className="pl-7"
                     />
                  </div>
                  <p className="text-xs text-muted-foreground">Stored internally in paise (₹1 = 100 paise).</p>
               </div>

               {/* Duration */}
               <div className="space-y-1.5">
                  <Label htmlFor="plan-duration">Duration (days)</Label>
                  <Input
                     id="plan-duration"
                     type="number"
                     min="1"
                     step="1"
                     placeholder="30"
                     value={durationDays}
                     onChange={(e) => setDurationDays(e.target.value)}
                  />
               </div>

               <DialogFooter className="pt-2">
                  <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
                     Cancel
                  </Button>
                  <Button type="submit" disabled={loading}>
                     {loading ? "Saving…" : isEditing ? "Save Changes" : "Create Plan"}
                  </Button>
               </DialogFooter>
            </form>
         </DialogContent>
      </Dialog>
   );
}
