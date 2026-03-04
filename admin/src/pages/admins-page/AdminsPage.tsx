import axiosInstance from "@/api/api.config";
import type { AdminInterface } from "@/interface/admin.interface";
import type { RootState } from "@/store";
import type { AxiosError } from "axios";
import { useCallback, useEffect, useState } from "react";
import { useSelector } from "react-redux";
import { toast } from "sonner";
import { AdminModal } from "./(components)/AdminModal";
import { AdminsTable } from "./(components)/AdminsTable";

const AdminsPage = () => {
   const [admins, setAdmins] = useState<AdminInterface[]>([]);
   const [isFetching, setIsFetching] = useState(true);
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [selectedAdmin, setSelectedAdmin] = useState<AdminInterface | null>(null);

   const currentUser = useSelector((state: RootState) => state.auth.user);

   const fetchAdmins = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/managers");
         setAdmins(response.data.data?.admins || []);
      } catch (error) {
         console.error("Error fetching admins:", error);
         toast.error("Failed to fetch admins");
      } finally {
         setIsFetching(false);
      }
   }, []);

   useEffect(() => {
      fetchAdmins();
   }, [fetchAdmins]);

   const handleAddAdmin = () => {
      setSelectedAdmin(null);
      setIsModalOpen(true);
   };

   const handleEditAdmin = (admin: AdminInterface) => {
      setSelectedAdmin(admin);
      setIsModalOpen(true);
   };

   const handleDeleteAdmin = async (id: number) => {
      try {
         await axiosInstance.delete(`/admin/managers/${id}`);
         toast.success("Admin deleted successfully");
         fetchAdmins();
      } catch (error) {
         console.error("Error deleting admin:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to delete admin");
      }
   };

   const handleSaveAdmin = async (data: Partial<AdminInterface> & { password?: string }) => {
      try {
         if (selectedAdmin) {
            await axiosInstance.put(`/admin/managers/${selectedAdmin.id}`, data);
            toast.success("Admin updated successfully");
         } else {
            await axiosInstance.post("/admin/managers", data);
            toast.success("Admin added successfully");
         }
         setIsModalOpen(false);
         fetchAdmins();
      } catch (error) {
         console.error("Error saving admin:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to save admin");
      }
   };

   if (currentUser?.role !== "SUPER_ADMIN") {
      return (
         <div className="flex items-center justify-center p-8 bg-card rounded-md border mt-8">
            <div className="text-center space-y-2">
               <h2 className="text-2xl font-bold tracking-tight text-destructive">Access Denied</h2>
               <p className="text-muted-foreground">You do not have permission to view or manage administrators.</p>
            </div>
         </div>
      );
   }

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Admins Management</h1>
            <p className="text-muted-foreground">Manage your admin and super admin staff accounts.</p>
         </div>
         <>
            <AdminsTable data={admins} isFetching={isFetching} currentAdminId={currentUser?.id} onAdd={handleAddAdmin} onEdit={handleEditAdmin} onDelete={handleDeleteAdmin} />
            <AdminModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onSave={handleSaveAdmin} adminUser={selectedAdmin} />
         </>
      </div>
   );
};

export default AdminsPage;
