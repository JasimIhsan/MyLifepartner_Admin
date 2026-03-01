import axiosInstance from "@/api/api.config";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { UserInterface } from "@/interface/user.interface";
import { Loader2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

interface SelfieModalProps {
   isOpen: boolean;
   onClose: () => void;
   user: UserInterface | null;
}

export function SelfieModal({ isOpen, onClose, user }: SelfieModalProps) {
   const [selfieUrl, setSelfieUrl] = useState<string | null>(null);
   const [isLoading, setIsLoading] = useState(false);

   useEffect(() => {
      if (isOpen && user?.id) {
         fetchSelfieUrl(user.id);
      } else {
         setSelfieUrl(null);
      }
   }, [isOpen, user?.id]);

   const fetchSelfieUrl = async (userId: number) => {
      setIsLoading(true);
      try {
         const response = await axiosInstance.get(`/admin/users/${userId}/selfie-url`);
         setSelfieUrl(response.data.data.url);
      } catch (error) {
         console.error("Failed to load selfie", error);
         toast.error("Failed to load selfie image");
         onClose();
      } finally {
         setIsLoading(false);
      }
   };

   return (
      <Dialog open={isOpen} onOpenChange={onClose}>
         <DialogContent className="sm:max-w-md max-h-[90vh]">
            <DialogHeader>
               <DialogTitle>Profile Selfie - {user?.name || "Unknown"}</DialogTitle>
            </DialogHeader>
            <div className="flex items-center justify-center p-4 min-h-75">
               {isLoading ? (
                  <div className="flex flex-col items-center justify-center text-muted-foreground gap-4">
                     <Loader2 className="h-8 w-8 animate-spin" />
                     <p>Loading secure image...</p>
                  </div>
               ) : selfieUrl ? (
                  <img src={selfieUrl} alt="User Selfie" className="max-w-full max-h-[70vh] object-contain rounded-md" />
               ) : (
                  <p className="text-muted-foreground">No selfie available</p>
               )}
            </div>
         </DialogContent>
      </Dialog>
   );
}
