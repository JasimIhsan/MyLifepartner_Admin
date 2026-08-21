import axiosInstance from "@/api/api.config";
import { ConfirmationModal } from "@/components/confirmation-modal";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { CheckCircle2, Clock, RefreshCw, Search, ShieldAlert, UserX } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

interface SuspendedUser {
   id: number;
   name: string | null;
   email: string | null;

   suspendedAt: string | null;
}

export default function SuspendedUsersPage() {
   const [users, setUsers] = useState<SuspendedUser[]>([]);
   const [loading, setLoading] = useState(false);
   const [searchQuery, setSearchQuery] = useState("");
   const [selectedUser, setSelectedUser] = useState<SuspendedUser | null>(null);
   const [confirmModalOpen, setConfirmModalOpen] = useState(false);
   const [actionLoading, setActionLoading] = useState(false);

   const fetchUsers = async () => {
      try {
         setLoading(true);
         const res = await axiosInstance.get("/admin/users/suspended");
         setUsers(res.data.data);
      } catch (error) {
         toast.error("Failed to load suspended users");
      } finally {
         setLoading(false);
      }
   };

   useEffect(() => {
      fetchUsers();
   }, []);

   const calculateDaysRemaining = (suspendedAt: string | null) => {
      if (!suspendedAt) return 0;
      const suspendDate = new Date(suspendedAt);
      const now = new Date();
      const diffTime = now.getTime() - suspendDate.getTime();
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      return Math.max(0, 14 - diffDays);
   };

   const handleLiftClick = (user: SuspendedUser) => {
      setSelectedUser(user);
      setConfirmModalOpen(true);
   };

   const confirmLiftSuspension = async () => {
      if (!selectedUser) return;
      try {
         setActionLoading(true);
         await axiosInstance.patch(`/admin/users/${selectedUser.id}/lift-suspension`);
         toast.success(`Suspension lifted for ${selectedUser.name || selectedUser.email || "User"}`);
         setConfirmModalOpen(false);
         setSelectedUser(null);
         fetchUsers();
      } catch (error) {
         toast.error("Failed to lift suspension");
      } finally {
         setActionLoading(false);
      }
   };

   const filteredUsers = useMemo(() => {
      if (!searchQuery.trim()) return users;
      const query = searchQuery.toLowerCase().trim();
      return users.filter((u) => u.name?.toLowerCase().includes(query) || u.email?.toLowerCase().includes(query) || u.id.toString().includes(query));
   }, [users, searchQuery]);

   const stats = useMemo(() => {
      let readyCount = 0;
      let inProgressCount = 0;

      users.forEach((u) => {
         const days = calculateDaysRemaining(u.suspendedAt);
         if (days <= 0) readyCount++;
         else inProgressCount++;
      });

      return { total: users.length, readyCount, inProgressCount };
   }, [users]);

   return (
      <div className="w-full space-y-6">
         <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
               <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
                  <UserX className="h-6 w-6 text-orange-500" />
                  Suspension Management
               </h1>
               <p className="text-sm text-muted-foreground">Track and manage 14-day temporary user suspensions and lift restrictions.</p>
            </div>
            <Button variant="outline" size="sm" onClick={fetchUsers} disabled={loading} className="w-fit">
               <RefreshCw className={`mr-2 h-4 w-4 ${loading ? "animate-spin" : ""}`} />
               Refresh
            </Button>
         </div>

         {/* Stats Section */}
         <div className="grid gap-4 md:grid-cols-3">
            <Card>
               <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Total Suspended Users</CardTitle>
                  <ShieldAlert className="h-4 w-4 text-orange-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold">{stats.total}</div>
                  <p className="text-xs text-muted-foreground">Accounts currently in 14-day suspension period</p>
               </CardContent>
            </Card>

            <Card>
               <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Ready to Lift</CardTitle>
                  <CheckCircle2 className="h-4 w-4 text-green-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold text-green-600">{stats.readyCount}</div>
                  <p className="text-xs text-muted-foreground">Completed 14+ days suspension period</p>
               </CardContent>
            </Card>

            <Card>
               <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Suspension In Progress</CardTitle>
                  <Clock className="h-4 w-4 text-blue-500" />
               </CardHeader>
               <CardContent>
                  <div className="text-2xl font-bold text-blue-600">{stats.inProgressCount}</div>
                  <p className="text-xs text-muted-foreground">Active 14-day countdown in progress</p>
               </CardContent>
            </Card>
         </div>

         {/* Search Filter */}
         <div className="flex items-center space-x-2">
            <div className="relative w-full max-w-sm">
               <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
               <Input placeholder="Search by name, email, or ID..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="pl-8 bg-background" />
            </div>
         </div>

         {/* Users Table */}
         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <Table>
               <TableHeader className="bg-muted/50">
                  <TableRow>
                     <TableHead className="w-16">ID</TableHead>
                     <TableHead>User Details</TableHead>
                     <TableHead>Suspension Date</TableHead>
                     <TableHead>14-Day Progress</TableHead>
                     <TableHead>Remaining Days</TableHead>
                     <TableHead className="text-right">Action</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody>
                  {filteredUsers.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                           {loading ? "Loading..." : searchQuery ? "No suspended users match your search." : "No suspended users found."}
                        </TableCell>
                     </TableRow>
                  ) : (
                     filteredUsers.map((user) => {
                        const daysRemaining = calculateDaysRemaining(user.suspendedAt);
                        const daysCompleted = Math.min(14, 14 - daysRemaining);
                        const progressPercent = Math.min(100, Math.round((daysCompleted / 14) * 100));

                        return (
                           <TableRow key={user.id}>
                              <TableCell className="font-medium">#{user.id}</TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{user.name || "Unknown"}</span>
                                    <span className="text-xs text-muted-foreground">{user.email || "No email"}</span>
                                 </div>
                              </TableCell>
                              <TableCell className="text-sm text-muted-foreground">{user.suspendedAt ? new Date(user.suspendedAt).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" }) : "N/A"}</TableCell>
                              <TableCell className="w-48">
                                 <div className="flex flex-col gap-1">
                                    <div className="w-full bg-muted rounded-full h-2 overflow-hidden">
                                       <div className={`h-full transition-all ${daysRemaining <= 0 ? "bg-green-500" : "bg-orange-500"}`} style={{ width: `${progressPercent}%` }} />
                                    </div>
                                    <span className="text-xs text-muted-foreground">
                                       {daysCompleted} of 14 days passed ({progressPercent}%)
                                    </span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 {daysRemaining <= 0 ? (
                                    <Badge variant="default" className="bg-green-600 hover:bg-green-700">
                                       Ready to Lift
                                    </Badge>
                                 ) : (
                                    <Badge variant="outline" className="text-orange-600 border-orange-500 bg-orange-50 dark:bg-orange-950/30">
                                       {daysRemaining} day{daysRemaining > 1 ? "s" : ""} left
                                    </Badge>
                                 )}
                              </TableCell>
                              <TableCell className="text-right">
                                 <Button variant={daysRemaining <= 0 ? "default" : "outline"} size="sm" onClick={() => handleLiftClick(user)} className={daysRemaining <= 0 ? "bg-green-600 hover:bg-green-700 text-white" : ""}>
                                    Lift Suspension
                                 </Button>
                              </TableCell>
                           </TableRow>
                        );
                     })
                  )}
               </TableBody>
            </Table>
         </div>

         {/* Confirmation Modal */}
         <ConfirmationModal
            isOpen={confirmModalOpen}
            onClose={() => setConfirmModalOpen(false)}
            onConfirm={confirmLiftSuspension}
            title="Lift User Suspension"
            description={`Are you sure you want to lift the temporary suspension for ${selectedUser?.name || selectedUser?.email || "this user"}? They will regain immediate access to the app.`}
            confirmText={actionLoading ? "Lifting..." : "Lift Suspension"}
            variant="default"
         />
      </div>
   );
}
