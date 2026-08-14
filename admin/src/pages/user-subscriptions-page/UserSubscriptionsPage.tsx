import { getPlans, getUserSubscriptions, paiseToRupees, updateUserSubscriptionPlan, type SubscriptionPlan, type UserSubscriptionStatusFilter } from "@/api/subscription.service";
import { ConfirmationModal } from "@/components/confirmation-modal";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { UserInterface } from "@/interface/user.interface";
import type { AxiosError } from "axios";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, CreditCard, RefreshCw, Search } from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";

const STATUS_OPTIONS: { value: UserSubscriptionStatusFilter; label: string }[] = [
   { value: "ALL", label: "All statuses" },
   { value: "ACTIVE", label: "Active" },
   { value: "CANCELLED_PENDING_EXPIRY", label: "Cancelled pending expiry" },
   { value: "BILLING_ISSUE", label: "Billing issue" },
   { value: "GRACE_PERIOD", label: "Grace period" },
   { value: "NO_ACTIVE_SUBSCRIPTION", label: "No active subscription" },
];

const PAGE_SIZE_OPTIONS = [10, 20, 50];

function formatStatusText(value?: string | null) {
   if (!value) return "No Active Subscription";
   return value
      .replace(/_/g, " ")
      .toLowerCase()
      .replace(/\b\w/g, (char) => char.toUpperCase());
}

function getStatusBadgeClass(status?: string | null) {
   if (status === "ACTIVE") return "border-emerald-500 bg-emerald-50 text-emerald-700";
   if (status === "GRACE_PERIOD" || status === "BILLING_ISSUE") return "border-orange-500 bg-orange-50 text-orange-700";
   if (status === "CANCELLED_PENDING_EXPIRY") return "border-sky-500 bg-sky-50 text-sky-700";
   return "border-border bg-muted/40 text-muted-foreground";
}

function formatDate(date?: string | Date | null) {
   if (!date) return "N/A";
   const parsed = new Date(date);
   if (Number.isNaN(parsed.getTime())) return "N/A";

   return parsed.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
   });
}

function getPlanChangeAction(user: UserInterface | null, targetPlan?: SubscriptionPlan) {
   if (!user || !targetPlan) return "Change";
   const currentPlan = user.activeSubscription?.plan;
   if (!currentPlan) return "Assign";
   if (targetPlan.price > currentPlan.price) return "Upgrade";
   if (targetPlan.price < currentPlan.price) return "Downgrade";
   return "Change";
}

export default function UserSubscriptionsPage() {
   const navigate = useNavigate();
   const [users, setUsers] = useState<UserInterface[]>([]);
   const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
   const [searchQuery, setSearchQuery] = useState("");
   const [statusFilter, setStatusFilter] = useState<UserSubscriptionStatusFilter>("ALL");
   const [planFilter, setPlanFilter] = useState("ALL");
   const [pageIndex, setPageIndex] = useState(0);
   const [pageSize, setPageSize] = useState(10);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(false);
   const [selectedUser, setSelectedUser] = useState<UserInterface | null>(null);
   const [selectedPlanId, setSelectedPlanId] = useState("");
   const [isPlanModalOpen, setIsPlanModalOpen] = useState(false);
   const [isUpdatingPlan, setIsUpdatingPlan] = useState(false);
   const [debouncedSearch] = useDebounce(searchQuery, 400);

   const activePlans = useMemo(() => plans.filter((plan) => plan.isActive), [plans]);
   const selectedPlan = activePlans.find((plan) => plan.id.toString() === selectedPlanId);
   const pageCount = Math.ceil(totalCount / pageSize);

   const fetchPlans = useCallback(async () => {
      try {
         const response = await getPlans();
         setPlans(response.data || []);
      } catch (error) {
         console.error("Failed to fetch subscription plans:", error);
         toast.error("Failed to fetch subscription plans");
      }
   }, []);

   const fetchUsers = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await getUserSubscriptions({
            search: debouncedSearch,
            page: pageIndex + 1,
            limit: pageSize,
            status: statusFilter,
            planId: planFilter === "ALL" ? undefined : Number(planFilter),
         });
         setUsers(response.data.data || []);
         setTotalCount(response.data.total || 0);
      } catch (error) {
         console.error("Failed to fetch user subscriptions:", error);
         toast.error("Failed to fetch user subscriptions");
      } finally {
         setIsFetching(false);
      }
   }, [debouncedSearch, pageIndex, pageSize, planFilter, statusFilter]);

   useEffect(() => {
      fetchPlans();
   }, [fetchPlans]);

   useEffect(() => {
      fetchUsers();
   }, [fetchUsers]);

   const handleSearchChange = (value: string) => {
      setSearchQuery(value);
      setPageIndex(0);
   };

   const handleStatusFilterChange = (value: string) => {
      setStatusFilter(value as UserSubscriptionStatusFilter);
      setPageIndex(0);
   };

   const handlePlanFilterChange = (value: string) => {
      setPlanFilter(value);
      setPageIndex(0);
   };

   const handlePageSizeChange = (value: string) => {
      setPageSize(Number(value));
      setPageIndex(0);
   };

   const openPlanModal = (user: UserInterface) => {
      const firstDifferentPlan = activePlans.find((plan) => plan.id !== user.activeSubscription?.planId);
      const fallbackPlan = activePlans[0];
      setSelectedUser(user);
      setSelectedPlanId((firstDifferentPlan ?? fallbackPlan)?.id.toString() ?? "");
      setIsPlanModalOpen(true);
   };

   const handleConfirmPlanChange = async () => {
      if (!selectedUser || !selectedPlan) return;

      setIsUpdatingPlan(true);
      try {
         await updateUserSubscriptionPlan(selectedUser.id, selectedPlan.id);
         toast.success(`${selectedUser.name || "User"} moved to ${selectedPlan.name}`);
         setIsPlanModalOpen(false);
         setSelectedUser(null);
         setSelectedPlanId("");
         await fetchUsers();
      } catch (error) {
         console.error("Failed to update user subscription:", error);
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "Failed to update user subscription");
      } finally {
         setIsUpdatingPlan(false);
      }
   };

   const planChangeAction = getPlanChangeAction(selectedUser, selectedPlan);
   const isSameActivePlan = Boolean(selectedUser?.activeSubscription?.status === "ACTIVE" && selectedPlan?.id === selectedUser.activeSubscription.planId);
   const cannotConfirmPlanChange = !selectedPlan || isSameActivePlan;

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
               <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
                  <CreditCard className="h-6 w-6 text-primary" />
                  User Subscription Management
               </h1>
               <p className="text-muted-foreground">Review current user plans and apply admin-side plan changes.</p>
            </div>
            <Button variant="outline" size="sm" onClick={fetchUsers} disabled={isFetching} className="w-fit gap-2">
               <RefreshCw className={`h-4 w-4 ${isFetching ? "animate-spin" : ""}`} />
               Refresh
            </Button>
         </div>

         <div className="grid gap-4 md:grid-cols-3">
            <Card className="rounded-lg">
               <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Visible Users</CardTitle>
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold">{totalCount}</div>
                  <p className="text-xs text-muted-foreground">Matching current filters</p>
               </CardContent>
            </Card>
            <Card className="rounded-lg">
               <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Assignable Plans</CardTitle>
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold">{activePlans.length}</div>
                  <p className="text-xs text-muted-foreground">Active plans available for admin changes</p>
               </CardContent>
            </Card>
            <Card className="rounded-lg">
               <CardHeader className="pb-2">
                  <CardTitle className="text-sm font-medium">Selected Filter</CardTitle>
               </CardHeader>
               <CardContent>
                  <div className="truncate text-2xl font-bold">{STATUS_OPTIONS.find((option) => option.value === statusFilter)?.label}</div>
                  <p className="text-xs text-muted-foreground">Current subscription status filter</p>
               </CardContent>
            </Card>
         </div>

         <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
            <div className="relative w-full max-w-sm">
               <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
               <Input placeholder="Search users..." value={searchQuery} onChange={(event) => handleSearchChange(event.target.value)} className="pl-8 bg-background" />
            </div>
            <Select value={statusFilter} onValueChange={handleStatusFilterChange}>
               <SelectTrigger className="w-full lg:w-60">
                  <SelectValue placeholder="Status" />
               </SelectTrigger>
               <SelectContent>
                  {STATUS_OPTIONS.map((option) => (
                     <SelectItem key={option.value} value={option.value}>
                        {option.label}
                     </SelectItem>
                  ))}
               </SelectContent>
            </Select>
            <Select value={planFilter} onValueChange={handlePlanFilterChange}>
               <SelectTrigger className="w-full lg:w-56">
                  <SelectValue placeholder="Plan" />
               </SelectTrigger>
               <SelectContent>
                  <SelectItem value="ALL">All plans</SelectItem>
                  {plans.map((plan) => (
                     <SelectItem key={plan.id} value={plan.id.toString()}>
                        {plan.name}
                     </SelectItem>
                  ))}
               </SelectContent>
            </Select>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <Table>
               <TableHeader className="bg-muted/50">
                  <TableRow>
                     <TableHead>User</TableHead>
                     <TableHead>Current Plan</TableHead>
                     <TableHead>Status</TableHead>
                     <TableHead>Ends On</TableHead>
                     <TableHead>Renews</TableHead>
                     <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                  {users.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                           {isFetching ? "Loading..." : "No users found."}
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
                                    <span className="font-medium">{subscription?.plan?.name || "No active plan"}</span>
                                    <span className="text-xs text-muted-foreground">{subscription?.plan ? paiseToRupees(subscription.plan.price) : "N/A"}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <Badge variant="outline" className={getStatusBadgeClass(subscription?.status)}>
                                    {formatStatusText(subscription?.status)}
                                 </Badge>
                              </TableCell>
                              <TableCell>{formatDate(subscription?.endDate)}</TableCell>
                              <TableCell>{subscription ? (subscription.willRenew ? "Yes" : "No") : "N/A"}</TableCell>
                              <TableCell className="text-right">
                                 <div className="flex justify-end gap-2">
                                    <Button variant="outline" size="sm" onClick={() => navigate(`/users/${user.id}`)}>
                                       View
                                    </Button>
                                    <Button size="sm" onClick={() => openPlanModal(user)} disabled={activePlans.length === 0}>
                                       Change Plan
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
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">Total {totalCount} users</div>
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
            isOpen={isPlanModalOpen}
            onClose={() => setIsPlanModalOpen(false)}
            onConfirm={handleConfirmPlanChange}
            title={`${planChangeAction} Subscription`}
            description={
               <div className="space-y-3 text-left">
                  <p>
                     Move {selectedUser?.name || "this user"} from {selectedUser?.activeSubscription?.plan?.name || "no active plan"} to {selectedPlan?.name || "the selected plan"}.
                  </p>
                  <Select value={selectedPlanId} onValueChange={setSelectedPlanId}>
                     <SelectTrigger>
                        <SelectValue placeholder="Select plan" />
                     </SelectTrigger>
                     <SelectContent>
                        {activePlans.map((plan) => (
                           <SelectItem key={plan.id} value={plan.id.toString()}>
                              {plan.name} - {paiseToRupees(plan.price)}
                           </SelectItem>
                        ))}
                     </SelectContent>
                  </Select>
                  {isSameActivePlan && <p className="text-xs font-medium text-orange-700">Choose a different plan before confirming.</p>}
                  <p className="text-xs text-muted-foreground">The selected plan starts immediately, the previous active subscription is expired, and feature limits are reset.</p>
               </div>
            }
            confirmText={planChangeAction}
            variant={planChangeAction === "Downgrade" ? "destructive" : "default"}
            isLoading={isUpdatingPlan}
            confirmDisabled={cannotConfirmPlanChange}
         />
      </div>
   );
}
