"use client";

import { ConfirmationModal } from "@/components/confirmation-modal";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { UserInterface } from "@/interface/user.interface";
import { CheckCircle2, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, MoreVertical, Search, XCircle } from "lucide-react";
import * as React from "react";

export function UsersTable({
   data: initialData = [],
   searchQuery,
   onSearchChange,
   pageIndex = 0,
   pageSize = 10,
   totalCount = 0,
   onPageChange,
   onPageSizeChange,
   isFetching = false,
   onAdd,
   onEdit,
   onToggleBlock,
   onDelete,
}: {
   data?: UserInterface[];
   searchQuery?: string;
   onSearchChange?: (value: string) => void;
   pageIndex?: number;
   pageSize?: number;
   totalCount?: number;
   onPageChange?: (pageIndex: number) => void;
   onPageSizeChange?: (pageSize: number) => void;
   isFetching?: boolean;
   onAdd?: () => void;
   onEdit?: (user: UserInterface) => void;
   onToggleBlock?: (id: number, currentStatus: boolean) => void;
   onDelete?: (id: number) => void;
}) {
   const [data, setData] = React.useState<UserInterface[]>(initialData);
   const [selectedIds, setSelectedIds] = React.useState<Set<number>>(new Set());

   // Modal state
   const [actionModalOpen, setActionModalOpen] = React.useState(false);
   const [actionType, setActionType] = React.useState<"delete" | "block" | "unblock" | null>(null);
   const [selectedUser, setSelectedUser] = React.useState<UserInterface | null>(null);

   React.useEffect(() => {
      setData(initialData);
   }, [initialData]);

   const pageCount = Math.ceil(totalCount / pageSize);

   const toggleSelectAll = () => {
      if (selectedIds.size === data.length && data.length > 0) {
         setSelectedIds(new Set());
      } else {
         setSelectedIds(new Set(data.map((u) => u.id)));
      }
   };

   const toggleSelectRow = (id: number) => {
      const newSet = new Set(selectedIds);
      if (newSet.has(id)) {
         newSet.delete(id);
      } else {
         newSet.add(id);
      }
      setSelectedIds(newSet);
   };

   const formatDate = (date: string | Date) => {
      return new Date(date).toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
      });
   };

   const handleActionClick = (user: UserInterface, type: "delete" | "block" | "unblock") => {
      setSelectedUser(user);
      setActionType(type);
      setActionModalOpen(true);
   };

   const handleConfirmAction = () => {
      if (!selectedUser) return;

      if (actionType === "delete" && onDelete) {
         onDelete(selectedUser.id);
      } else if ((actionType === "block" || actionType === "unblock") && onToggleBlock) {
         onToggleBlock(selectedUser.id, selectedUser.isBlocked);
      }
      setActionModalOpen(false);
   };

   return (
      <div className="w-full space-y-4">
         <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex flex-1 items-center space-x-2">
               <div className="relative w-full max-w-sm">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                     placeholder="Search users..."
                     value={searchQuery !== undefined ? searchQuery : ""}
                     onChange={(e) => {
                        onSearchChange?.(e.target.value);
                     }}
                     className="pl-8 bg-background"
                  />
               </div>
            </div>
            <div className="flex items-center space-x-2 w-full sm:w-auto">
               {selectedIds.size > 0 && <span className="text-sm text-muted-foreground mr-2 hidden sm:inline-block">{selectedIds.size} selected</span>}
               <Button variant="outline" size="sm" className="hidden sm:flex">
                  Export
               </Button>
               <Button size="sm" className="w-full sm:w-auto" onClick={onAdd}>
                  Add User
               </Button>
            </div>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead className="w-12 text-center">
                           <Checkbox checked={data.length > 0 && selectedIds.size === data.length ? true : selectedIds.size > 0 ? "indeterminate" : false} onCheckedChange={toggleSelectAll} aria-label="Select all" />
                        </TableHead>
                        <TableHead className="w-62.5">User</TableHead>
                        <TableHead className="w-50">Contact</TableHead>
                        <TableHead className="w-37.5">Status</TableHead>
                        <TableHead className="w-37.5">Joined</TableHead>
                        <TableHead className="w-12.5"></TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                              {isFetching ? "Loading..." : "No users found matching your criteria."}
                           </TableCell>
                        </TableRow>
                     ) : (
                        data.map((user) => (
                           <TableRow key={user.id} data-state={selectedIds.has(user.id) ? "selected" : undefined} className="group">
                              <TableCell className="text-center align-middle">
                                 <Checkbox checked={selectedIds.has(user.id)} onCheckedChange={() => toggleSelectRow(user.id)} aria-label="Select row" />
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{user.name || "Unknown"}</span>
                                    {user.isBlocked && <span className="text-xs text-destructive font-semibold">Blocked</span>}
                                    <span className="text-xs text-muted-foreground">ID: {user.id}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="text-sm truncate max-w-45" title={user.email || ""}>
                                       {user.email || "No email"}
                                    </span>
                                    <span className="text-xs text-muted-foreground">{user.mobileNumber}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col gap-1.5">
                                    {/* <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                       {user.isEmailVerified ? <CheckCircle2 className="h-3.5 w-3.5 text-green-500" /> : <XCircle className="h-3.5 w-3.5" />}
                                       <span>Email Verified</span>
                                    </div> */}
                                    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                       {user.profileStatus === "COMPLETED" ? <CheckCircle2 className="h-3.5 w-3.5 text-green-500" /> : user.profileStatus === "ONBOARDING_COMPLETED" ? <CheckCircle2 className="h-3.5 w-3.5 text-yellow-500" /> : <XCircle className="h-3.5 w-3.5" />}
                                       <span className="capitalize">{user.profileStatus?.replace("_", " ").toLowerCase() || "Incomplete"}</span>
                                    </div>
                                 </div>
                              </TableCell>
                              <TableCell className="text-sm text-muted-foreground">{formatDate(user.createdAt)}</TableCell>
                              <TableCell>
                                 <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                       <Button variant="ghost" className="h-8 w-8 p-0 opacity-0 group-hover:opacity-100 transition-opacity focus:opacity-100 data-[state=open]:opacity-100">
                                          <span className="sr-only">Open menu</span>
                                          <MoreVertical className="h-4 w-4" />
                                       </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end" className="w-40">
                                       <DropdownMenuItem>View Details</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => onEdit?.(user)}>Edit User</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => handleActionClick(user, user.isBlocked ? "unblock" : "block")}>{user.isBlocked ? "Unblock User" : "Block User"}</DropdownMenuItem>
                                       <DropdownMenuSeparator />
                                       <DropdownMenuItem className="text-destructive" onClick={() => handleActionClick(user, "delete")}>
                                          Delete User
                                       </DropdownMenuItem>
                                    </DropdownMenuContent>
                                 </DropdownMenu>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>
         </div>

         <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-2">
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">
               {selectedIds.size > 0 ? (
                  <>
                     {selectedIds.size} of {totalCount} user(s) selected.
                  </>
               ) : (
                  <>Total {totalCount} users</>
               )}
            </div>
            <div className="flex flex-col sm:flex-row items-center space-y-2 sm:space-y-0 sm:space-x-6 lg:space-x-8">
               <div className="flex items-center space-x-2">
                  <p className="text-sm font-medium">Rows per page</p>
                  <Select
                     value={`${pageSize}`}
                     onValueChange={(value) => {
                        onPageSizeChange?.(Number(value));
                     }}
                  >
                     <SelectTrigger className="h-8 w-17.5">
                        <SelectValue placeholder={pageSize} />
                     </SelectTrigger>
                     <SelectContent side="top">
                        {[10, 20, 30, 40, 50].map((size) => (
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
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => onPageChange?.(0)} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to first page</span>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => onPageChange?.(Math.max(0, pageIndex - 1))} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to previous page</span>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => onPageChange?.(Math.min(pageCount - 1, pageIndex + 1))} disabled={pageIndex >= pageCount - 1 || pageCount === 0 || isFetching}>
                        <span className="sr-only">Go to next page</span>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => onPageChange?.(pageCount - 1)} disabled={pageIndex >= pageCount - 1 || pageCount === 0 || isFetching}>
                        <span className="sr-only">Go to last page</span>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            </div>
         </div>

         <ConfirmationModal
            isOpen={actionModalOpen}
            onClose={() => setActionModalOpen(false)}
            onConfirm={handleConfirmAction}
            title={actionType === "delete" ? "Delete User" : actionType === "block" ? "Block User" : "Unblock User"}
            description={
               actionType === "delete"
                  ? `Are you sure you want to delete ${selectedUser?.name || "this user"}? This action cannot be undone and will permanently remove all their data.`
                  : actionType === "block"
                    ? `Are you sure you want to block ${selectedUser?.name || "this user"}? They will no longer be able to log in or access the application.`
                    : `Are you sure you want to unblock ${selectedUser?.name || "this user"}? They will regain access to the application.`
            }
            confirmText={actionType === "delete" ? "Delete" : actionType === "block" ? "Block User" : "Unblock User"}
            variant={actionType === "delete" ? "destructive" : actionType === "block" ? "destructive" : "default"}
         />
      </div>
   );
}
