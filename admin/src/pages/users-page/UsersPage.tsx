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
import { SubscriptionManagementTab } from "./(componets)/SubscriptionManagementTab";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CreditCard, LayoutGrid, List, Users } from "lucide-react";

type UsersPageTab = "users" | "subscriptions";

const UsersPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialSearch = searchParams.get("search") || "";
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);
   const initialTab: UsersPageTab = searchParams.get("tab") === "subscriptions" ? "subscriptions" : "users";

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
   const [activeTab, setActiveTab] = useState<UsersPageTab>(initialTab);
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
      if (activeTab === "users") {
         fetchUsers();
      }
   }, [activeTab, fetchUsers]);

   useEffect(() => {
      const params = new URLSearchParams(searchParams);
      if (debouncedSearch) {
         params.set("search", debouncedSearch);
      } else {
         params.delete("search");
      }
      params.set("page", (pageIndex + 1).toString());
      params.set("limit", pageSize.toString());
      if (activeTab === "subscriptions") {
         params.set("tab", "subscriptions");
      } else {
         params.delete("tab");
      }
      setSearchParams(params, { replace: true });
   }, [activeTab, debouncedSearch, pageIndex, pageSize, setSearchParams, searchParams]);

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

   const handleDowngradeGracePeriod = async (id: number) => {
      try {
         await axiosInstance.patch(`/admin/users/${id}/downgrade-grace-period`);
         toast.success("User downgraded to base plan successfully");
         fetchUsers();
      } catch (error) {
         console.error("Error downgrading grace period user:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to downgrade user to base plan");
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
         <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as UsersPageTab)} className="space-y-4">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
               <div>
                  <h1 className="text-2xl font-bold tracking-tight">Users Management</h1>
                  <p className="text-muted-foreground">Manage users, subscriptions, and account statuses.</p>
               </div>
               <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                  <TabsList variant="line" className="w-full justify-start sm:w-auto">
                     <TabsTrigger value="users" className="flex items-center gap-2">
                        <Users className="h-4 w-4" />
                        Users
                     </TabsTrigger>
                     <TabsTrigger value="subscriptions" className="flex items-center gap-2">
                        <CreditCard className="h-4 w-4" />
                        Grace Period Users
                     </TabsTrigger>
                  </TabsList>
                  {activeTab === "users" && (
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
                  )}
               </div>
            </div>

            <TabsContent value="users" className="mt-0">
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
                     onDowngradeGracePeriod={handleDowngradeGracePeriod}
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
                     onDowngradeGracePeriod={handleDowngradeGracePeriod}
                     onViewAuditHistory={handleViewAuditHistory}
                     onViewDetails={handleViewDetails}
                  />
               )}
            </TabsContent>

            <TabsContent value="subscriptions" className="mt-0">
               <SubscriptionManagementTab onViewDetails={handleViewDetails} onDowngradeSuccess={fetchUsers} />
            </TabsContent>

            <UserModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onSave={handleSaveUser} user={selectedUser} />
            <UserAuditHistoryModal 
               isOpen={isAuditModalOpen} 
               onClose={() => setIsAuditModalOpen(false)} 
               userId={auditUser?.id} 
               userName={auditUser?.name} 
            />
         </Tabs>
      </div>
   );
};

export default UsersPage;
