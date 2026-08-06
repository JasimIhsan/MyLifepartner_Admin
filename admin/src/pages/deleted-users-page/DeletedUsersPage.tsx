import axiosInstance from "@/api/api.config";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { ArchivedUserInterface } from "@/interface/user.interface";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Eye } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";

export const DeletedUsersPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);

   const [users, setUsers] = useState<ArchivedUserInterface[]>([]);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(true);
   const [pageIndex, setPageIndex] = useState(initialPage - 1);
   const [pageSize, setPageSize] = useState(initialLimit);
   const [selectedUser, setSelectedUser] = useState<ArchivedUserInterface | null>(null);

   const fetchUsers = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/users/archived", {
            params: {
               page: pageIndex + 1,
               limit: pageSize,
            },
         });
         setUsers(response.data.data?.data || response.data.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching archived users:", error);
         toast.error("Failed to fetch archived users");
      } finally {
         setIsFetching(false);
      }
   }, [pageIndex, pageSize]);

   useEffect(() => {
      fetchUsers();
   }, [fetchUsers]);

   useEffect(() => {
      const params = new URLSearchParams(searchParams);
      params.set("page", (pageIndex + 1).toString());
      params.set("limit", pageSize.toString());
      setSearchParams(params, { replace: true });
   }, [pageIndex, pageSize, setSearchParams, searchParams]);

   const handlePageChange = (newPageIndex: number) => {
      setPageIndex(newPageIndex);
   };

   const handlePageSizeChange = (newPageSize: number) => {
      setPageSize(newPageSize);
      setPageIndex(0);
   };

   const pageCount = Math.ceil(totalCount / pageSize);

   const formatDate = (date: string | Date) => {
      return new Date(date).toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
      });
   };

   const maskEmail = (email: string) => {
      if (!email || !email.includes("@")) return email;
      const [local, domain] = email.split("@");
      if (local.length <= 2) return `${local[0]}***@${domain}`;
      return `${local.substring(0, 3)}***@${domain}`;
   };

   return (
      <div className="space-y-6">
         <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
               <h2 className="text-2xl font-bold tracking-tight">Deleted Users Archive</h2>
               <p className="text-muted-foreground">View users who have deleted their accounts and their retained data.</p>
            </div>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead className="w-[100px]">User ID</TableHead>
                        <TableHead>Email</TableHead>
                        <TableHead>Reason</TableHead>
                        <TableHead className="w-[150px]">Archived At</TableHead>
                        <TableHead className="w-[100px] text-center">Actions</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {users.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                              {isFetching ? "Loading..." : "No archived users found."}
                           </TableCell>
                        </TableRow>
                     ) : (
                        users.map((user) => (
                           <TableRow key={user.id}>
                              <TableCell className="font-medium">#{user.userId}</TableCell>
                              <TableCell>
                                 <span className="text-sm">{maskEmail(user.originalEmail)}</span>
                              </TableCell>
                              <TableCell>
                                 <span className="text-sm truncate block max-w-[200px]" title={user.reasonForArchive || "N/A"}>
                                    {user.reasonForArchive || "N/A"}
                                 </span>
                              </TableCell>
                              <TableCell className="text-muted-foreground text-sm">{formatDate(user.archivedAt)}</TableCell>
                              <TableCell className="text-center">
                                 <Button variant="ghost" size="icon" onClick={() => setSelectedUser(user)} title="View Details">
                                    <Eye className="h-4 w-4" />
                                 </Button>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>

            <div className="flex flex-col sm:flex-row items-center justify-between px-4 py-4 border-t gap-4 bg-muted/20">
               <div className="flex items-center text-sm text-muted-foreground w-full sm:w-auto justify-between sm:justify-start">
                  <div className="flex items-center gap-2">
                     <p className="hidden sm:block">Rows per page</p>
                     <Select value={pageSize.toString()} onValueChange={(value) => handlePageSizeChange(Number(value))}>
                        <SelectTrigger className="h-8 w-[70px]">
                           <SelectValue placeholder={pageSize} />
                        </SelectTrigger>
                        <SelectContent side="top">
                           {[10, 20, 30, 40, 50].map((size) => (
                              <SelectItem key={size} value={size.toString()}>
                                 {size}
                              </SelectItem>
                           ))}
                        </SelectContent>
                     </Select>
                  </div>
                  <div className="flex sm:hidden items-center text-sm font-medium">
                     Page {pageIndex + 1} of {pageCount || 1}
                  </div>
               </div>

               <div className="flex items-center space-x-6 lg:space-x-8 w-full sm:w-auto justify-between sm:justify-start">
                  <div className="hidden sm:flex items-center text-sm font-medium">
                     Page {pageIndex + 1} of {pageCount || 1}
                  </div>
                  <div className="flex items-center space-x-2">
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex" onClick={() => handlePageChange(0)} disabled={pageIndex === 0}>
                        <span className="sr-only">Go to first page</span>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0" onClick={() => handlePageChange(pageIndex - 1)} disabled={pageIndex === 0}>
                        <span className="sr-only">Go to previous page</span>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0" onClick={() => handlePageChange(pageIndex + 1)} disabled={pageIndex >= pageCount - 1}>
                        <span className="sr-only">Go to next page</span>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex" onClick={() => handlePageChange(pageCount - 1)} disabled={pageIndex >= pageCount - 1}>
                        <span className="sr-only">Go to last page</span>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            </div>
         </div>

         {/* View Details Modal */}
         <Dialog open={!!selectedUser} onOpenChange={(open) => !open && setSelectedUser(null)}>
            <DialogContent className="sm:max-w-[425px]">
               <DialogHeader>
                  <DialogTitle>Deleted User Details</DialogTitle>
                  <DialogDescription>Retained information for User #{selectedUser?.userId}</DialogDescription>
               </DialogHeader>
               {selectedUser && (
                  <div className="grid gap-4 py-4">
                     <div className="grid grid-cols-4 items-center gap-4">
                        <span className="font-medium text-sm text-right">User ID:</span>
                        <span className="col-span-3 text-sm">{selectedUser.userId}</span>
                     </div>
                     <div className="grid grid-cols-4 items-center gap-4">
                        <span className="font-medium text-sm text-right">Email:</span>
                        <span className="col-span-3 text-sm">{selectedUser.originalEmail}</span>
                     </div>
                     <div className="grid grid-cols-4 items-center gap-4">
                        <span className="font-medium text-sm text-right">Name:</span>
                        <span className="col-span-3 text-sm">{selectedUser.originalName || "N/A"}</span>
                     </div>
                     <div className="grid grid-cols-4 items-center gap-4">
                        <span className="font-medium text-sm text-right">Phone:</span>
                        <span className="col-span-3 text-sm">{selectedUser.originalPhone || "N/A"}</span>
                     </div>
                     <div className="grid grid-cols-4 items-start gap-4">
                        <span className="font-medium text-sm text-right pt-1">Reason:</span>
                        <span className="col-span-3 text-sm">{selectedUser.reasonForArchive || "N/A"}</span>
                     </div>
                     <div className="grid grid-cols-4 items-center gap-4">
                        <span className="font-medium text-sm text-right">Archived:</span>
                        <span className="col-span-3 text-sm">{formatDate(selectedUser.archivedAt)}</span>
                     </div>
                  </div>
               )}
            </DialogContent>
         </Dialog>
      </div>
   );
};

export default DeletedUsersPage;
