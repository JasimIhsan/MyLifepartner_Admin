"use client";

import axiosInstance from "@/api/api.config";
import { ConfirmationModal } from "@/components/confirmation-modal";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { UserInterface } from "@/interface/user.interface";
import type { AxiosError } from "axios";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, CircleMinus, Eye, RefreshCw, Search } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";

type SubscriptionManagementTabProps = {
   onViewDetails?: (user: UserInterface) => void;
   onDowngradeSuccess?: () => void;
};

const PAGE_SIZE_OPTIONS = [10, 20, 50];
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function SubscriptionManagementTab({ onViewDetails, onDowngradeSuccess }: SubscriptionManagementTabProps) {
   const [users, setUsers] = useState<UserInterface[]>([]);
   const [searchQuery, setSearchQuery] = useState("");
   const [pageIndex, setPageIndex] = useState(0);
   const [pageSize, setPageSize] = useState(10);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(false);
   const [selectedUser, setSelectedUser] = useState<UserInterface | null>(null);
   const [isConfirmOpen, setIsConfirmOpen] = useState(false);
   const [isDowngrading, setIsDowngrading] = useState(false);
   const [debouncedSearch] = useDebounce(searchQuery, 400);

   const fetchGracePeriodUsers = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/users/subscriptions/grace-period", {
            params: {
               search: debouncedSearch,
               page: pageIndex + 1,
               limit: pageSize,
            },
         });
         setUsers(response.data.data?.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching grace period users:", error);
         toast.error("Failed to fetch grace period users");
      } finally {
         setIsFetching(false);
      }
   }, [debouncedSearch, pageIndex, pageSize]);

   useEffect(() => {
      fetchGracePeriodUsers();
   }, [fetchGracePeriodUsers]);

   const pageCount = Math.ceil(totalCount / pageSize);

   const formatDate = (date?: string | Date | null) => {
      if (!date) return "N/A";
      const parsed = new Date(date);
      if (Number.isNaN(parsed.getTime())) return "N/A";

      return parsed.toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
      });
   };

   const formatPlanPrice = (price?: number | null) => {
      if (price === null || price === undefined) return "N/A";
      if (price === 0) return "Base";

      return `INR ${(price / 100).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
   };

   const getGracePeriodLabel = (date?: string | Date | null) => {
      if (!date) return "N/A";
      const parsed = new Date(date);
      if (Number.isNaN(parsed.getTime())) return "N/A";

      const daysRemaining = Math.ceil((parsed.getTime() - Date.now()) / MS_PER_DAY);

      if (daysRemaining <= 0) return "Due now";
      return `${daysRemaining} day${daysRemaining === 1 ? "" : "s"} left`;
   };

   const handleSearchChange = (value: string) => {
      setSearchQuery(value);
      setPageIndex(0);
   };

   const handlePageSizeChange = (value: string) => {
      setPageSize(Number(value));
      setPageIndex(0);
   };

   const openDowngradeConfirm = (user: UserInterface) => {
      setSelectedUser(user);
      setIsConfirmOpen(true);
   };

   const handleConfirmDowngrade = async () => {
      if (!selectedUser) return;

      setIsDowngrading(true);
      try {
         await axiosInstance.patch(`/admin/users/${selectedUser.id}/downgrade-grace-period`);
         toast.success("User downgraded to base plan successfully");
         setIsConfirmOpen(false);
         setSelectedUser(null);
         onDowngradeSuccess?.();
         await fetchGracePeriodUsers();
      } catch (error) {
         console.error("Error downgrading grace period user:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to downgrade user to base plan");
      } finally {
         setIsDowngrading(false);
      }
   };

   return (
      <div className="w-full space-y-4">
         <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full max-w-sm">
               <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
               <Input placeholder="Search grace period users..." value={searchQuery} onChange={(event) => handleSearchChange(event.target.value)} className="pl-8 bg-background" />
            </div>
            <Button variant="outline" size="sm" onClick={fetchGracePeriodUsers} disabled={isFetching} className="w-fit gap-2">
               <RefreshCw className={`h-4 w-4 ${isFetching ? "animate-spin" : ""}`} />
               Refresh
            </Button>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <Table>
               <TableHeader className="bg-muted/50">
                  <TableRow>
                     <TableHead>User</TableHead>
                     <TableHead>Current Plan</TableHead>
                     <TableHead>Subscription Status</TableHead>
                     <TableHead>Grace Ends</TableHead>
                     <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                  {users.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                           {isFetching ? "Loading..." : "No grace period users found."}
                        </TableCell>
                     </TableRow>
                  ) : (
                     users.map((user) => {
                        const subscription = user.activeSubscription;

                        return (
                           <TableRow key={user.id}>
                              <TableCell>
                                 <div className="flex min-w-0 flex-col">
                                    <span className="font-medium">{user.name || "Unknown"}</span>
                                    <span className="truncate text-xs text-muted-foreground" title={user.email || ""}>
                                       {user.email || "No email"}
                                    </span>
                                    <span className="text-xs text-muted-foreground">ID: {user.id}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex min-w-0 flex-col">
                                    <span className="font-medium">{subscription?.plan?.name || "N/A"}</span>
                                    <span className="text-xs text-muted-foreground">{formatPlanPrice(subscription?.plan?.price)}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <Badge variant="outline" className="border-orange-500 bg-orange-50 text-orange-600">
                                    Grace Period
                                 </Badge>
                              </TableCell>
                              <TableCell>
                                 <div className="flex min-w-0 flex-col">
                                    <span className="font-medium">{formatDate(subscription?.gracePeriodEndsAt)}</span>
                                    <span className="text-xs text-muted-foreground">{getGracePeriodLabel(subscription?.gracePeriodEndsAt)}</span>
                                 </div>
                              </TableCell>
                              <TableCell className="text-right">
                                 <div className="flex justify-end gap-2">
                                    <Button variant="outline" size="sm" className="gap-1.5" onClick={() => onViewDetails?.(user)}>
                                       <Eye className="h-4 w-4" />
                                       View
                                    </Button>
                                    <Button variant="destructive" size="sm" className="gap-1.5" onClick={() => openDowngradeConfirm(user)}>
                                       <CircleMinus className="h-4 w-4" />
                                       Downgrade
                                    </Button>
                                 </div>
                              </TableCell>
                           </TableRow>
                        );
                     })
                  )}
               </TableBody>
            </Table>
         </div>

         <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-2">
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">Total {totalCount} grace period users</div>
            <div className="flex flex-col sm:flex-row items-center space-y-2 sm:space-y-0 sm:space-x-6 lg:space-x-8">
               <div className="flex items-center space-x-2">
                  <p className="text-sm font-medium">Rows per page</p>
                  <Select value={`${pageSize}`} onValueChange={handlePageSizeChange}>
                     <SelectTrigger className="h-8 w-17.5">
                        <SelectValue placeholder={pageSize} />
                     </SelectTrigger>
                     <SelectContent side="top">
                        {PAGE_SIZE_OPTIONS.map((size) => (
                           <SelectItem key={size} value={`${size}`}>
                              {size}
                           </SelectItem>
                        ))}
                     </SelectContent>
                  </Select>
               </div>
               <div className="flex items-center space-x-2">
                  <div className="flex w-25 items-center justify-center text-sm font-medium">
                     Page {pageCount > 0 ? pageIndex + 1 : 0} of {pageCount}
                  </div>
                  <div className="flex items-center space-x-1">
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPageIndex(0)} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to first page</span>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPageIndex((current) => Math.max(0, current - 1))} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to previous page</span>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPageIndex((current) => Math.min(pageCount - 1, current + 1))} disabled={pageIndex >= pageCount - 1 || pageCount === 0 || isFetching}>
                        <span className="sr-only">Go to next page</span>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPageIndex(pageCount - 1)} disabled={pageIndex >= pageCount - 1 || pageCount === 0 || isFetching}>
                        <span className="sr-only">Go to last page</span>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            </div>
         </div>

         <ConfirmationModal
            isOpen={isConfirmOpen}
            onClose={() => setIsConfirmOpen(false)}
            onConfirm={handleConfirmDowngrade}
            title="Downgrade to Base Plan"
            description={`Downgrade ${selectedUser?.name || "this user"} from grace period access to the base plan now? Their premium access and feature limits will be reset immediately.`}
            confirmText="Downgrade"
            variant="destructive"
            isLoading={isDowngrading}
         />
      </div>
   );
}
