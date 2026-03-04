import axiosInstance from "@/api/api.config";
import type { UserInterface } from "@/interface/user.interface";
import type { AxiosError } from "axios";
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";
import { UserModal } from "./(componets)/UserModal";
import { UsersTable } from "./(componets)/UsersTable";

const UsersPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialSearch = searchParams.get("search") || "";
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);

   const [users, setUsers] = useState<UserInterface[]>([]);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(true);
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [selectedUser, setSelectedUser] = useState<UserInterface | null>(null);
   const [searchQuery, setSearchQuery] = useState(initialSearch);
   const [pageIndex, setPageIndex] = useState(initialPage - 1);
   const [pageSize, setPageSize] = useState(initialLimit);

   const [debouncedSearch] = useDebounce(searchQuery, 500);

   const fetchUsers = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/users", {
            params: {
               search: debouncedSearch,
               page: pageIndex + 1,
               limit: pageSize,
            },
         });
         setUsers(response.data.data?.data || response.data.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching users:", error);
         toast.error("Failed to fetch users");
      } finally {
         setIsFetching(false);
      }
   }, [debouncedSearch, pageIndex, pageSize]);

   useEffect(() => {
      fetchUsers();
   }, [fetchUsers]);

   useEffect(() => {
      const params = new URLSearchParams(searchParams);
      if (debouncedSearch) {
         params.set("search", debouncedSearch);
      } else {
         params.delete("search");
      }
      params.set("page", (pageIndex + 1).toString());
      params.set("limit", pageSize.toString());
      setSearchParams(params, { replace: true });
   }, [debouncedSearch, pageIndex, pageSize, setSearchParams, searchParams]);

   const handleSearchChange = (value: string) => {
      setSearchQuery(value);
      setPageIndex(0); // Reset to first page on new search
   };

   const handlePageChange = (newPageIndex: number) => {
      setPageIndex(newPageIndex);
   };

   const handlePageSizeChange = (newPageSize: number) => {
      setPageSize(newPageSize);
      setPageIndex(0); // Reset to first page when changing page size
   };

   const handleAddUser = () => {
      setSelectedUser(null);
      setIsModalOpen(true);
   };

   const handleEditUser = (user: UserInterface) => {
      setSelectedUser(user);
      setIsModalOpen(true);
   };

   const handleDeleteUser = async (id: number) => {
      if (!confirm("Are you sure you want to delete this user?")) return;
      try {
         await axiosInstance.delete(`/admin/users/${id}`);
         toast.success("User deleted successfully");
         fetchUsers();
      } catch (error) {
         console.error("Error deleting user:", error);
         toast.error("Failed to delete user");
      }
   };

   const handleToggleBlock = async (id: number, currentStatus: boolean) => {
      try {
         await axiosInstance.patch(`/admin/users/${id}/block-status`);
         toast.success(`User ${currentStatus ? "unblocked" : "blocked"} successfully`);
         fetchUsers();
      } catch (error) {
         console.error("Error toggling block status:", error);
         toast.error("Failed to update user status");
      }
   };

   const handleSaveUser = async (data: Partial<UserInterface>) => {
      try {
         if (selectedUser) {
            await axiosInstance.put(`/admin/users/${selectedUser.id}`, data);
            toast.success("User updated successfully");
         } else {
            await axiosInstance.post("/admin/users", data);
            toast.success("User added successfully");
         }
         setIsModalOpen(false);
         fetchUsers();
      } catch (error) {
         console.error("Error saving user:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to save user");
      }
   };

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Users Management</h1>
            <p className="text-muted-foreground">Manage your users, view their details and statuses.</p>
         </div>
         <>
            <UsersTable
               data={users}
               searchQuery={searchQuery}
               onSearchChange={handleSearchChange}
               pageIndex={pageIndex}
               pageSize={pageSize}
               totalCount={totalCount}
               onPageChange={handlePageChange}
               onPageSizeChange={handlePageSizeChange}
               isFetching={isFetching}
               onAdd={handleAddUser}
               onEdit={handleEditUser}
               onDelete={handleDeleteUser}
               onToggleBlock={handleToggleBlock}
            />
            <UserModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onSave={handleSaveUser} user={selectedUser} />
         </>
      </div>
   );
};

export default UsersPage;
