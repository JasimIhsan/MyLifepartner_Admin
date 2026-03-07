import { createSection, updateSection, type ProfileSection } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import type { AxiosError } from "axios";
import { useEffect, useState } from "react";
import { toast } from "sonner";

interface Props {
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
   sectionToEdit?: ProfileSection | null;
}

export default function AddEditSectionModal({ isOpen, onClose, onSuccess, sectionToEdit }: Props) {
   const [key, setKey] = useState("");
   const [title, setTitle] = useState("");
   const [isPrimary, setIsPrimary] = useState(false);
   const [loading, setLoading] = useState(false);

   useEffect(() => {
      if (isOpen) {
         if (sectionToEdit) {
            setKey(sectionToEdit.key);
            setTitle(sectionToEdit.title);
            setIsPrimary(sectionToEdit.isPrimary);
         } else {
            setKey("");
            setTitle("");
            setIsPrimary(false);
         }
      }
   }, [isOpen, sectionToEdit]);

   const handleSubmit = async (e: React.FormEvent) => {
      e.preventDefault();
      if (!key || !title) {
         toast.error("Key and Title are required");
         return;
      }

      try {
         setLoading(true);
         if (sectionToEdit) {
            const res = await updateSection(sectionToEdit.id, { key, title, isPrimary });
            if (res.success) {
               toast.success("Section updated");
               onSuccess();
               onClose();
            } else {
               toast.error(res.message);
            }
         } else {
            const res = await createSection({ key, title, isPrimary });
            if (res.success) {
               toast.success("Section created");
               onSuccess();
               onClose();
            } else {
               toast.error(res.message);
            }
         }
      } catch (error) {
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "An error occurred");
      } finally {
         setLoading(false);
      }
   };

   return (
      <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <DialogContent className="sm:max-w-106.25">
            <DialogHeader>
               <DialogTitle className="text-xl">{sectionToEdit ? "Edit Section" : "Add Section"}</DialogTitle>
            </DialogHeader>
            <form onSubmit={handleSubmit} className="space-y-5 py-4">
               <div className="space-y-2">
                  <Label>Section Title</Label>
                  <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Personal Information" autoFocus />
               </div>
               <div className="space-y-2">
                  <Label>Key Identifier</Label>
                  <Input value={key} onChange={(e) => setKey(e.target.value)} placeholder="e.g. personal_info" className="font-mono text-sm" />
                  <p className="text-[11px] text-muted-foreground">Unique identifier used by the system. Avoid spaces or special characters.</p>
               </div>
               <div className="flex flex-row items-center justify-between rounded-lg border border-border p-4 bg-muted/20">
                  <div className="space-y-0.5">
                     <Label className="text-sm font-medium">Primary Section</Label>
                     <p className="text-xs text-muted-foreground">Marks this section as the main profile category.</p>
                  </div>
                  <Switch checked={isPrimary} onCheckedChange={setIsPrimary} />
               </div>
            </form>
            <DialogFooter className="pt-2">
               <Button variant="ghost" onClick={onClose} className="w-full sm:w-auto">
                  Cancel
               </Button>
               <Button onClick={handleSubmit} disabled={loading} className="w-full sm:w-auto">
                  {loading ? "Saving..." : "Save Section"}
               </Button>
            </DialogFooter>
         </DialogContent>
      </Dialog>
   );
}
