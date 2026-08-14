import axiosInstance from "@/api/api.config";
import type { UserInterface } from "@/interface/user.interface";
import type { AxiosError } from "axios";
import { useCallback, useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";
import { UserModal } from "./(componets)/UserModal";
import { UsersTable } from "./(componets)/UsersTable";
import { UsersCards } from "./(componets)/UsersCards";
import { UserAuditHistoryModal } from "./(componets)/UserAuditHistoryModal";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { LayoutGrid, List } from "lucide-react";

const UsersPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialSearch = searchParams.get("search") || "";
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);

   const [users, setUsers] = useState<UserInterface[]>([]);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(true);
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [isAuditModalOpen, setIsAuditModalOpen] = useState(false);
   const [selectedUser, setSelectedUser] = useState<UserInterface | null>(null);
   const [auditUser, setAuditUser] = useState<UserInterface | null>(null);
   const [searchQuery, setSearchQuery] = useState(initialSearch);
   const [pageIndex, setPageIndex] = useState(initialPage - 1);
   const [pageSize, setPageSize] = useState(initialLimit);
   const [viewMode, setViewMode] = useState<"table" | "cards">("cards");
   const navigate = useNavigate();

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

   const handleViewAuditHistory = (user: UserInterface) => {
      setAuditUser(user);
      setIsAuditModalOpen(true);
   };

   const handleViewDetails = (user: UserInterface) => {
      navigate(`/users/${user.id}`);
   };

   const handleDeleteUser = async (id: number) => {
      try {
         await axiosInstance.delete(`/admin/users/${id}`);
         toast.success("User deleted successfully");
         fetchUsers();
      } catch (error) {
         console.error("Error deleting user:", error);
         toast.error("Failed to delete user");
      }
   };

   const handleToggleBan = async (id: number, currentStatus: boolean) => {
      try {
         await axiosInstance.patch(`/admin/users/${id}/ban`);
         setUsers(users.map((user) => (user.id === id ? { ...user, isBanned: !currentStatus } : user)));
         toast.success(`User ${currentStatus ? "unbanned" : "banned"} successfully`);
      } catch (error) {
         console.error("Error toggling ban status:", error);
         toast.error("Failed to update user status");
      }
   };

   const handleToggleFoundingMember = async (id: number, currentStatus: boolean) => {
      try {
         const response = await axiosInstance.patch(`/admin/users/${id}/founding-member`);
         const updatedUser = response.data.data as UserInterface | undefined;
         setUsers((currentUsers) =>
            currentUsers.map((user) =>
               user.id === id
                  ? {
                       ...user,
                       isFoundingMember: updatedUser?.isFoundingMember ?? !currentStatus,
                       foundingMemberSince: updatedUser?.foundingMemberSince ?? (!currentStatus ? new Date() : null),
                    }
                  : user
            )
         );
         toast.success(`Founding Member status ${currentStatus ? "revoked" : "granted"} successfully`);
      } catch (error) {
         console.error("Error toggling founding member status:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update Founding Member status");
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
         <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
               <h1 className="text-2xl font-bold tracking-tight">Users Management</h1>
               <p className="text-muted-foreground">Manage your users, view their details and statuses.</p>
            </div>
            <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as "table" | "cards")}>
               <TabsList>
                  <TabsTrigger value="table" className="flex items-center gap-2">
                     <List className="h-4 w-4" />
                     Table
                  </TabsTrigger>
                  <TabsTrigger value="cards" className="flex items-center gap-2">
                     <LayoutGrid className="h-4 w-4" />
                     Cards
                  </TabsTrigger>
               </TabsList>
            </Tabs>
         </div>
         <>
            {viewMode === "table" ? (
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
                  onToggleBan={handleToggleBan}
                  onToggleFoundingMember={handleToggleFoundingMember}
                  onViewAuditHistory={handleViewAuditHistory}
                  onViewDetails={handleViewDetails}
               />
            ) : (
               <UsersCards
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
                  onToggleBan={handleToggleBan}
                  onToggleFoundingMember={handleToggleFoundingMember}
                  onViewAuditHistory={handleViewAuditHistory}
                  onViewDetails={handleViewDetails}
               />
            )}
            <UserModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onSave={handleSaveUser} user={selectedUser} />
            <UserAuditHistoryModal 
               isOpen={isAuditModalOpen} 
               onClose={() => setIsAuditModalOpen(false)} 
               userId={auditUser?.id} 
               userName={auditUser?.name} 
            />
         </>
      </div>
   );
};

export default UsersPage;
