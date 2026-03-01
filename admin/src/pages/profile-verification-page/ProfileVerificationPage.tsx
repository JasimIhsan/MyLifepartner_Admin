import axiosInstance from "@/api/api.config";
import type { UserInterface } from "@/interface/user.interface";
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";
import { SelfieModal } from "./components/SelfieModal";
import { VerificationTable } from "./components/VerificationTable";

const ProfileVerificationPage = () => {
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
               selfieStatus: "PENDING", // Only fetch users pending verification
            },
         });
         setUsers(response.data.data?.data || response.data.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching users:", error);
         toast.error("Failed to fetch pending verifications");
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
      setPageIndex(0);
   };

   const handlePageChange = (newPageIndex: number) => {
      setPageIndex(newPageIndex);
   };

   const handlePageSizeChange = (newPageSize: number) => {
      setPageSize(newPageSize);
      setPageIndex(0);
   };

   const handleViewSelfie = (user: UserInterface) => {
      setSelectedUser(user);
      setIsModalOpen(true);
   };

   const handleApprove = async (id: number) => {
      if (!confirm("Are you sure you want to approve this profile?")) return;
      try {
         await axiosInstance.patch(`/admin/users/${id}/verify-profile`);
         toast.success("Profile verified successfully");
         fetchUsers();
      } catch (error) {
         console.error("Error verifying user:", error);
         toast.error("Failed to approve profile");
      }
   };

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Profile Verification</h1>
            <p className="text-muted-foreground">Review and approve user selfies.</p>
         </div>
         <>
            <VerificationTable data={users} searchQuery={searchQuery} onSearchChange={handleSearchChange} pageIndex={pageIndex} pageSize={pageSize} totalCount={totalCount} onPageChange={handlePageChange} onPageSizeChange={handlePageSizeChange} isFetching={isFetching} onViewSelfie={handleViewSelfie} onApprove={handleApprove} />
            <SelfieModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} user={selectedUser} />
         </>
      </div>
   );
};

export default ProfileVerificationPage;
