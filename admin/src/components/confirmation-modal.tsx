import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Loader2 } from "lucide-react";
import * as React from "react";

export interface ConfirmationModalProps {
   isOpen: boolean;
   onClose: () => void;
   onConfirm: () => void;
   title: string;
   description?: React.ReactNode;
   confirmText?: string;
   cancelText?: string;
   variant?: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link";
   isLoading?: boolean;
   confirmDisabled?: boolean;
}

export function ConfirmationModal({ isOpen, onClose, onConfirm, title, description, confirmText = "Confirm", cancelText = "Cancel", variant = "default", isLoading = false, confirmDisabled = false }: ConfirmationModalProps) {
   return (
      <Dialog
         open={isOpen}
         onOpenChange={(open) => {
            if (!open && !isLoading) {
               onClose();
            }
         }}
      >
         <DialogContent className="sm:max-w-106.25" showCloseButton={!isLoading}>
            <DialogHeader>
               <DialogTitle>{title}</DialogTitle>
               {description && (typeof description === "string" ? <DialogDescription className="pt-2">{description}</DialogDescription> : <div className="pt-2 text-sm text-muted-foreground">{description}</div>)}
            </DialogHeader>
            <DialogFooter className="mt-4 flex gap-2">
               <Button variant="outline" onClick={onClose} disabled={isLoading}>
                  {cancelText}
               </Button>
               <Button variant={variant} onClick={onConfirm} disabled={isLoading || confirmDisabled}>
                  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  {confirmText}
               </Button>
            </DialogFooter>
         </DialogContent>
      </Dialog>
   );
}
