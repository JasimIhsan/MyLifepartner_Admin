import { forceSync, getPlans, getUserSubscriptions, paiseToRupees, updateUserSubscriptionPlan, type SubscriptionPlan, type UserSubscriptionStatusFilter } from "@/api/subscription.service";
import { ConfirmationModal } from "@/components/confirmation-modal";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

import type { UserInterface } from "@/interface/user.interface";
import type { AxiosError } from "axios";
import { AlertTriangle, CheckCircle2, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, CreditCard, FileText, Info, MoreHorizontal, RefreshCw, RotateCw, Search, Sparkles, Undo2, Users } from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";

import { useDebounce } from "use-debounce";
import { UserSubscriptionLogsDrawer } from "./(components)/UserSubscriptionLogsDrawer";

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

function getRevenueCatAppUserId(userId: number) {
   const hex = userId.toString(16);
   return `00000000-0000-4000-8000-${hex.padStart(12, "0")}`;
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

   // Modals and Drawers
   const [isPlanModalOpen, setIsPlanModalOpen] = useState(false);
   const [isUpdatingPlan, setIsUpdatingPlan] = useState(false);

   const [isStoreGuideModalOpen, setIsStoreGuideModalOpen] = useState(false);

   const [isLogsDrawerOpen, setIsLogsDrawerOpen] = useState(false);
   const [logsUserId, setLogsUserId] = useState<number | null>(null);
   const [logsUserName, setLogsUserName] = useState("");
   const [syncingUserId, setSyncingUserId] = useState<number | null>(null);

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

   const handleForceSync = async (user: UserInterface) => {
      setSyncingUserId(user.id);
      const promise = (async () => {
         await forceSync(user.id);
         await fetchUsers();
      })();

      toast.promise(promise, {
         loading: `Force syncing subscription for ${user.name || "user"}...`,
         success: `Subscription synchronized successfully for ${user.name || "user"}!`,
         error: (err: any) => err?.response?.data?.message || "Failed to force sync subscription",
         finally: () => setSyncingUserId(null),
      });
   };

   const openStoreGuideModal = (user: UserInterface) => {
      setSelectedUser(user);
      setIsStoreGuideModalOpen(true);
   };

   const openLogsDrawer = (user: UserInterface) => {
      setLogsUserId(user.id);
      setLogsUserName(user.name || "");
      setIsLogsDrawerOpen(true);
   };

   const planChangeAction = getPlanChangeAction(selectedUser, selectedPlan);
   const isSameActivePlan = Boolean(selectedUser?.activeSubscription?.status === "ACTIVE" && selectedPlan?.id === selectedUser.activeSubscription.planId);
   const cannotConfirmPlanChange = !selectedPlan || isSameActivePlan;

   const activeSubscribersCount = useMemo(() => {
      return users.filter((u) => {
         const sub = u.activeSubscription;
         if (!sub || sub.status !== "ACTIVE") return false;
         const planName = sub.plan?.name?.toUpperCase();
         const price = sub.plan?.price ?? 0;
         return planName !== "FREE" && price > 0;
      }).length;
   }, [users]);

   const issuesCount = useMemo(() => {
      return users.filter((u) => u.activeSubscription?.status === "BILLING_ISSUE" || u.activeSubscription?.status === "GRACE_PERIOD").length;
   }, [users]);

   const foundingMembersCount = useMemo(() => {
      return users.filter((u) => u.isFoundingMember).length;
   }, [users]);

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
               <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
                  <CreditCard className="h-6 w-6 text-primary" />
                  User Subscription Management
               </h1>
               <p className="text-muted-foreground">Monitor real-time subscription health, manage plans, and sync store purchases.</p>
            </div>
            <Button variant="outline" size="sm" onClick={fetchUsers} disabled={isFetching} className="w-fit gap-2">
               <RefreshCw className={`h-4 w-4 ${isFetching ? "animate-spin" : ""}`} />
               Refresh
            </Button>
         </div>

         <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
            <Card className="rounded-lg shadow-sm hover:shadow transition-shadow">
               <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-muted-foreground">Total Users</CardTitle>
                  <Users className="h-4 w-4 text-muted-foreground" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold">{totalCount}</div>
                  <p className="text-xs text-muted-foreground mt-1">Across all tiers & plans</p>
               </CardContent>
            </Card>

            <Card 
               className={`rounded-lg shadow-sm transition-all cursor-pointer hover:border-emerald-500/50 ${statusFilter === "ACTIVE" && planFilter !== "ALL" ? "border-emerald-500 ring-1 ring-emerald-500/20 bg-emerald-500/5" : ""}`}
               onClick={() => {
                  const firstPaidPlan = plans.find((p) => p.name?.toUpperCase() !== "FREE" && p.price > 0);
                  if (statusFilter === "ACTIVE" && planFilter !== "ALL") {
                     setStatusFilter("ALL");
                     setPlanFilter("ALL");
                  } else {
                     setStatusFilter("ACTIVE");
                     if (firstPaidPlan) {
                        setPlanFilter(firstPaidPlan.id.toString());
                     }
                  }
                  setPageIndex(0);
               }}
            >
               <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-emerald-600 dark:text-emerald-400">Premium Users</CardTitle>
                  <CheckCircle2 className="h-4 w-4 text-emerald-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">{activeSubscribersCount}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                     {statusFilter === "ACTIVE" && planFilter !== "ALL" ? "Filtered: Premium paid plans" : "Active paid users (click to filter)"}
                  </p>
               </CardContent>
            </Card>

            <Card 
               className={`rounded-lg shadow-sm transition-all cursor-pointer hover:border-amber-500/50 ${statusFilter === "BILLING_ISSUE" || statusFilter === "GRACE_PERIOD" ? "border-amber-500 ring-1 ring-amber-500/20 bg-amber-500/5" : ""}`}
               onClick={() => handleStatusFilterChange(statusFilter === "BILLING_ISSUE" ? "ALL" : "BILLING_ISSUE")}
            >
               <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-amber-600 dark:text-amber-400">Needs Attention</CardTitle>
                  <AlertTriangle className="h-4 w-4 text-amber-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold text-amber-600 dark:text-amber-400">{issuesCount}</div>
                  <p className="text-xs text-muted-foreground mt-1">
                     {statusFilter === "BILLING_ISSUE" ? "Filtered: Billing issues" : "Billing issues / Grace period"}
                  </p>
               </CardContent>
            </Card>

            <Card className="rounded-lg shadow-sm">
               <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium text-yellow-600 dark:text-yellow-400">Founders & Plans</CardTitle>
                  <Sparkles className="h-4 w-4 text-yellow-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold flex items-baseline gap-2">
                     <span>{foundingMembersCount} <span className="text-xs font-normal text-muted-foreground">Founders</span></span>
                     <span className="text-sm text-muted-foreground font-normal">/</span>
                     <span className="text-base text-muted-foreground font-semibold">{activePlans.length} <span className="text-xs font-normal">Plans</span></span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">Founding VIPs & live plans</p>
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
            {/* <Select value={envFilter} onValueChange={handleEnvFilterChange}>
               <SelectTrigger className="w-full lg:w-40">
                  <SelectValue placeholder="Environment" />
               </SelectTrigger>
               <SelectContent>
                  <SelectItem value="ALL">All Envs</SelectItem>
                  <SelectItem value="PRODUCTION">Production</SelectItem>
                  <SelectItem value="SANDBOX">Sandbox</SelectItem>
               </SelectContent>
            </Select> */}
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <Table>
               <TableHeader className="bg-muted/50">
                  <TableRow>
                     <TableHead>User</TableHead>
                     <TableHead>Current Plan</TableHead>
                     <TableHead>Status</TableHead>
                     <TableHead>Store / Env</TableHead>
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
                                    {subscription?.status === "BILLING_ISSUE" && <div className="ml-1.5 h-1.5 w-1.5 rounded-full bg-red-500 inline-block"></div>}
                                 </Badge>
                                 {user.isFoundingMember && (
                                    <Badge variant="default" className="ml-2 bg-yellow-500 text-black hover:bg-yellow-600">
                                       ⭐ Founder
                                    </Badge>
                                 )}
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col space-y-1">
                                    <span className="text-sm font-medium">{subscription?.store || "N/A"}</span>
                                    {subscription?.environment && (
                                       <Badge variant={subscription.environment === "SANDBOX" ? "secondary" : "default"} className="w-fit text-[10px]">
                                          {subscription.environment}
                                       </Badge>
                                    )}
                                 </div>
                              </TableCell>
                              <TableCell>{formatDate(subscription?.endDate)}</TableCell>
                              <TableCell>{subscription ? (subscription.willRenew ? "Yes" : "No") : "N/A"}</TableCell>
                              <TableCell className="text-right">
                                 <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                       <Button variant="ghost" className="h-8 w-8 p-0" disabled={syncingUserId === user.id}>
                                          <span className="sr-only">Open menu</span>
                                          {syncingUserId === user.id ? <RotateCw className="h-4 w-4 animate-spin text-primary" /> : <MoreHorizontal className="h-4 w-4" />}
                                       </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                       <DropdownMenuItem onClick={() => navigate(`/users/${user.id}`)}>
                                          <Search className="mr-2 h-4 w-4" /> View Profile
                                       </DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => openLogsDrawer(user)}>
                                          <FileText className="mr-2 h-4 w-4" /> View Logs
                                       </DropdownMenuItem>
                                       <DropdownMenuSeparator />
                                       <DropdownMenuItem onClick={() => openPlanModal(user)} disabled={activePlans.length === 0}>
                                          <CreditCard className="mr-2 h-4 w-4" /> Change Plan
                                       </DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => handleForceSync(user)} disabled={syncingUserId === user.id}>
                                          <RotateCw className={`mr-2 h-4 w-4 ${syncingUserId === user.id ? "animate-spin" : ""}`} />
                                          {syncingUserId === user.id ? "Syncing..." : "Force Sync"}
                                       </DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => openStoreGuideModal(user)}>
                                          <Undo2 className="mr-2 h-4 w-4" /> Manage in Store (Cancel/Refund)
                                       </DropdownMenuItem>
                                       <DropdownMenuSeparator />
                                    </DropdownMenuContent>
                                 </DropdownMenu>
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

         {/* Store Management Guide Modal */}
         <Dialog open={isStoreGuideModalOpen} onOpenChange={setIsStoreGuideModalOpen}>
            <DialogContent>
               <DialogHeader>
                  <DialogTitle>Manage Subscription in Store</DialogTitle>
                  <DialogDescription>
                     <p>Because {selectedUser?.name || "this user"} purchased their subscription via the App Store or Google Play, you must cancel or refund it directly in the store console.</p>
                     <p className="mt-2 text-orange-600 font-medium">Our system will automatically downgrade the user's plan for you as soon as the store processes the refund/cancellation.</p>
                  </DialogDescription>
               </DialogHeader>
               <div className="grid gap-4 py-4">
                  {selectedUser && (
                     <div className="flex flex-col gap-2 p-3 bg-muted rounded-md border text-sm">
                        <span className="font-medium">User's RevenueCat ID (for searching):</span>
                        <div className="flex items-center gap-2">
                           <code className="bg-background px-2 py-1 rounded border flex-1">{getRevenueCatAppUserId(selectedUser.id)}</code>
                           <Button
                              variant="outline"
                              size="sm"
                              onClick={() => {
                                 navigator.clipboard.writeText(getRevenueCatAppUserId(selectedUser.id));
                                 toast.success("Copied RevenueCat ID to clipboard!");
                              }}
                           >
                              Copy
                           </Button>
                           <Button variant="outline" size="sm" onClick={() => window.open("https://app.revenuecat.com", "_blank")}>
                              Open RC
                           </Button>
                        </div>
                     </div>
                  )}

                  <div className="rounded-md border p-4 bg-muted/30 space-y-4">
                     <h4 className="font-semibold flex items-center gap-2 text-primary">
                        <Info className="h-4 w-4" /> Step-by-Step Instructions
                     </h4>
                     <div className="space-y-3 text-sm text-foreground">
                        <div>
                           <p className="font-bold">Android (Google Play)</p>
                           <ol className="list-decimal pl-4 mt-1 space-y-1 text-muted-foreground">
                              <li>Click "Copy" above to copy the user's ID.</li>
                              <li>Click "Open RC" and search for that ID in RevenueCat to find their exact Google Play Order ID.</li>
                              <li>Log into the Google Play Console and go to "Order Management".</li>
                              <li>Search for the Order ID and click "Refund" or "Cancel Subscription".</li>
                           </ol>
                        </div>
                        <div className="pt-2 border-t">
                           <p className="font-bold">iOS (App Store)</p>
                           <ul className="list-disc pl-4 mt-1 space-y-1 text-muted-foreground">
                              <li>Apple restricts developers from issuing refunds directly.</li>
                              <li>
                                 Tell the user they must request the refund themselves via <code>reportaproblem.apple.com</code>.
                              </li>
                              <li>To just stop future renewals, you can cancel it in App Store Connect.</li>
                           </ul>
                        </div>
                     </div>
                  </div>
               </div>
               <DialogFooter>
                  <Button variant="outline" onClick={() => setIsStoreGuideModalOpen(false)}>
                     Done
                  </Button>
               </DialogFooter>
            </DialogContent>
         </Dialog>

         <UserSubscriptionLogsDrawer isOpen={isLogsDrawerOpen} onClose={() => setIsLogsDrawerOpen(false)} userId={logsUserId} userName={logsUserName} />
      </div>
   );
}
