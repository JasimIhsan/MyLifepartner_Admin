import axiosInstance from "@/api/api.config";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { ImageAssetsTable } from "./components/ImageAssetsTable";
import { ImageAssetModal } from "./components/ImageAssetModal";

export interface ImageAsset {
   id: number;
   section: string;
   title: string;
   imageUrl: string;
   altText?: string;
   redirectUrl?: string;
   displayOrder: number;
   isActive: boolean;
   createdAt: string;
   updatedAt: string;
}

const ImageAssetsPage = () => {
   const [assets, setAssets] = useState<ImageAsset[]>([]);
   const [isFetching, setIsFetching] = useState(true);
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [selectedAsset, setSelectedAsset] = useState<ImageAsset | null>(null);
   const [sectionFilter, setSectionFilter] = useState<string>("");

   const fetchAssets = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/image-assets", {
            params: {
               section: sectionFilter || undefined,
            },
         });
         setAssets(response.data.assets || []);
      } catch (error) {
         console.error("Error fetching assets:", error);
         toast.error("Failed to fetch image assets");
      } finally {
         setIsFetching(false);
      }
   }, [sectionFilter]);

   useEffect(() => {
      fetchAssets();
   }, [fetchAssets]);

   const handleAddAsset = () => {
      setSelectedAsset(null);
      setIsModalOpen(true);
   };

   const handleEditAsset = (asset: ImageAsset) => {
      setSelectedAsset(asset);
      setIsModalOpen(true);
   };

   const handleDeleteAsset = async (id: number) => {
      if (!confirm("Are you sure you want to delete this asset?")) return;
      try {
         await axiosInstance.delete(`/admin/image-assets/${id}`);
         toast.success("Asset deleted successfully");
         fetchAssets();
      } catch (error) {
         console.error("Error deleting asset:", error);
         toast.error("Failed to delete asset");
      }
   };

   const handleSaveAsset = async (formData: FormData) => {
      try {
         if (selectedAsset) {
            await axiosInstance.put(`/admin/image-assets/${selectedAsset.id}`, formData, {
               headers: { "Content-Type": "multipart/form-data" },
            });
            toast.success("Asset updated successfully");
         } else {
            await axiosInstance.post("/admin/image-assets", formData, {
               headers: { "Content-Type": "multipart/form-data" },
            });
            toast.success("Asset added successfully");
         }
         setIsModalOpen(false);
         fetchAssets();
      } catch (error) {
         console.error("Error saving asset:", error);
         toast.error("Failed to save asset");
      }
   };

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Image Assets Management</h1>
            <p className="text-muted-foreground">Manage landing page images, banners, and other app assets.</p>
         </div>
         <ImageAssetsTable
            data={assets}
            isFetching={isFetching}
            onAdd={handleAddAsset}
            onEdit={handleEditAsset}
            onDelete={handleDeleteAsset}
            sectionFilter={sectionFilter}
            onSectionFilterChange={setSectionFilter}
         />
         <ImageAssetModal
            isOpen={isModalOpen}
            onClose={() => setIsModalOpen(false)}
            onSave={handleSaveAsset}
            asset={selectedAsset}
         />
      </div>
   );
};

export default ImageAssetsPage;
