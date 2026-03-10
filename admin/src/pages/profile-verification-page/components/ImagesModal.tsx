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
    const [isLoading, setIsLoading] = useState(false);

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
            const [imagesRes, selfieRes] = await Promise.allSettled([
                axiosInstance.get(`/admin/users/${userId}/images`),
                axiosInstance.get(`/admin/users/${userId}/selfie-url`)
            ]);

            if (imagesRes.status === 'fulfilled') {
                setImages(imagesRes.value.data.data || []);
            } else {
                console.error("Failed to load user images", imagesRes.reason);
                if (imagesRes.reason?.response?.status !== 404) {
                    toast.error("Failed to load user images");
                }
                setImages([]);
            }

            if (selfieRes.status === 'fulfilled') {
                setSelfieUrl(selfieRes.value.data.data.url);
            } else {
                console.error("Failed to load selfie", selfieRes.reason);
                if (selfieRes.reason?.response?.status !== 404) {
                    toast.error("Failed to load selfie image");
                }
                setSelfieUrl(null);
            }
        } catch (error: any) {
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
                                <h3 className="text-lg font-medium border-b pb-2">Selfie</h3>
                                {selfieUrl ? (
                                    <div className="flex justify-center bg-muted/50 rounded-md p-4">
                                        <img src={selfieUrl} alt="User Selfie" className="max-w-full max-h-[40vh] object-contain rounded-md shadow-sm" />
                                    </div>
                                ) : (
                                    <p className="text-muted-foreground text-sm italic">No selfie available for this user</p>
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
                                                {img.isPrimary && (
                                                    <div className="absolute top-4 left-4 bg-primary text-primary-foreground text-xs font-medium px-2 py-1 rounded shadow">
                                                        Primary
                                                    </div>
                                                )}
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
