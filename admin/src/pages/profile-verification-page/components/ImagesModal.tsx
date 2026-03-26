import axiosInstance from "@/api/api.config";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { UserInterface } from "@/interface/user.interface";
import { Loader2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

interface ImagesModalProps {
   isOpen: boolean;
   onClose: () => void;
   user: UserInterface | null;
}

interface UserImage {
   id: number;
   imageUrl: string;
   isPrimary: boolean;
   url: string; // The presigned URL
}

export function ImagesModal({ isOpen, onClose, user }: ImagesModalProps) {
   const [images, setImages] = useState<UserImage[]>([]);
   const [selfieUrl, setSelfieUrl] = useState<string | null>(null);
   const [leftSelfieUrl, setLeftSelfieUrl] = useState<string | null>(null);
   const [rightSelfieUrl, setRightSelfieUrl] = useState<string | null>(null);
   const [locationText, setLocationText] = useState<string | null>(null);
   const [isLoading, setIsLoading] = useState(false);

   const fetchLocationName = async (lat: number, lng: number) => {
      try {
         const apiKey = import.meta.env.VITE_GEOCODING_API_KEY;
         if (!apiKey) {
            setLocationText(`${lat.toFixed(4)}, ${lng.toFixed(4)}`);
            return;
         }
         const res = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=AIzaSyB-fkDdlWX3_p50ZjHaiiD7p8nTeeOhopY`);
         const data = await res.json();
         if (data.results && data.results.length > 0) {
            setLocationText(data.results[0].formatted_address);
         } else {
            setLocationText(`${lat.toFixed(4)}, ${lng.toFixed(4)}`);
         }
      } catch (error) {
         console.error("Failed to fetch location name", error);
         setLocationText(`${lat.toFixed(4)}, ${lng.toFixed(4)}`);
      }
   };

   useEffect(() => {
      if (isOpen && user?.id) {
         fetchUserImages(user.id);
      } else {
         setImages([]);
         setSelfieUrl(null);
      }
   }, [isOpen, user?.id]);

   const fetchUserImages = async (userId: number) => {
      setIsLoading(true);
      try {
         const [imagesRes, selfieRes] = await Promise.allSettled([axiosInstance.get(`/admin/users/${userId}/images`), axiosInstance.get(`/admin/users/${userId}/selfie-url`)]);

         if (imagesRes.status === "fulfilled") {
            setImages(imagesRes.value.data.data || []);
         } else {
            console.error("Failed to load user images", imagesRes.reason);
            if (imagesRes.reason?.response?.status !== 404) {
               toast.error("Failed to load user images");
            }
            setImages([]);
         }

         if (selfieRes.status === "fulfilled") {
            const data = selfieRes.value.data.data;
            setSelfieUrl(data.url);
            setLeftSelfieUrl(data.leftUrl);
            setRightSelfieUrl(data.rightUrl);

            if (data.locationLat && data.locationLng) {
               fetchLocationName(data.locationLat, data.locationLng);
            } else {
               setLocationText(null);
            }
         } else {
            console.error("Failed to load selfie", selfieRes.reason);
            if (selfieRes.reason?.response?.status !== 404) {
               toast.error("Failed to load selfie image");
            }
            setSelfieUrl(null);
            setLeftSelfieUrl(null);
            setRightSelfieUrl(null);
            setLocationText(null);
         }
      } catch (error: unknown) {
         console.error("Failed to load data", error);
         toast.error("Failed to load user pictures");
         onClose();
      } finally {
         setIsLoading(false);
      }
   };

   return (
      <Dialog open={isOpen} onOpenChange={onClose}>
         <DialogContent className="sm:max-w-5xl w-11/12 max-h-[90vh] overflow-y-auto">
            <DialogHeader>
               <DialogTitle>User Pictures - {user?.name || "Unknown"}</DialogTitle>
            </DialogHeader>
            <div className="flex flex-col p-4 min-h-75 gap-6 overflow-y-auto">
               {isLoading ? (
                  <div className="flex flex-col items-center justify-center text-muted-foreground gap-4 my-auto min-h-40">
                     <Loader2 className="h-8 w-8 animate-spin" />
                     <p>Loading secure images...</p>
                  </div>
               ) : (
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 w-full">
                     {/* Selfie Section */}
                     <div className="space-y-4">
                        <h3 className="text-lg font-medium border-b pb-2">Selfies & Location</h3>

                        {locationText && (
                           <div className="flex items-center text-sm text-muted-foreground bg-muted/30 p-2 rounded w-full">
                              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mr-2">
                                 <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
                                 <circle cx="12" cy="10" r="3" />
                              </svg>
                              <span className="truncate" title={locationText}>
                                 {locationText}
                              </span>
                           </div>
                        )}

                        {selfieUrl || leftSelfieUrl || rightSelfieUrl ? (
                           <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-2">
                              {selfieUrl && (
                                 <div className="flex flex-col items-center gap-1 w-full">
                                    <span className="text-xs font-semibold text-muted-foreground">Front</span>
                                    <div className="flex justify-center bg-muted/50 rounded-md p-2 w-full aspect-square">
                                       <img src={selfieUrl} alt="User Front Selfie" className="w-full h-full object-contain rounded-md shadow-sm" />
                                    </div>
                                 </div>
                              )}
                              {leftSelfieUrl && (
                                 <div className="flex flex-col items-center gap-1 w-full">
                                    <span className="text-xs font-semibold text-muted-foreground">Left</span>
                                    <div className="flex justify-center bg-muted/50 rounded-md p-2 w-full aspect-square">
                                       <img src={leftSelfieUrl} alt="User Left Selfie" className="w-full h-full object-contain rounded-md shadow-sm" />
                                    </div>
                                 </div>
                              )}
                              {rightSelfieUrl && (
                                 <div className="flex flex-col items-center gap-1 w-full">
                                    <span className="text-xs font-semibold text-muted-foreground">Right</span>
                                    <div className="flex justify-center bg-muted/50 rounded-md p-2 w-full aspect-square">
                                       <img src={rightSelfieUrl} alt="User Right Selfie" className="w-full h-full object-contain rounded-md shadow-sm" />
                                    </div>
                                 </div>
                              )}
                           </div>
                        ) : (
                           <p className="text-muted-foreground text-sm italic">No selfies available for this user</p>
                        )}
                     </div>

                     {/* Profile Pictures Section */}
                     <div className="space-y-4">
                        <h3 className="text-lg font-medium border-b pb-2">Profile Pictures</h3>
                        {images.length > 0 ? (
                           <div className="grid grid-cols-1 md:grid-cols-2 gap-4 w-full">
                              {images.map((img) => (
                                 <div key={img.id} className="relative w-full aspect-portrait flex justify-center bg-muted/50 p-2 rounded-md overflow-hidden">
                                    <img src={img.url} alt={`User Image ${img.id}`} className="w-full h-full object-cover rounded shadow-sm" />
                                    {img.isPrimary && <div className="absolute top-4 left-4 bg-primary text-primary-foreground text-xs font-medium px-2 py-1 rounded shadow">Primary</div>}
                                 </div>
                              ))}
                           </div>
                        ) : (
                           <p className="text-muted-foreground text-sm italic">No profile pictures available for this user</p>
                        )}
                     </div>
                  </div>
               )}
            </div>
         </DialogContent>
      </Dialog>
   );
}
