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

type UserActionType = "delete" | "ban" | "unban" | "grantFoundingMember" | "revokeFoundingMember";

export function UsersTable({
   data: initialData = [],
   searchQuery,
   onSearchChange,
   pageIndex = 0,
   pageSize = 20,
   totalCount = 0,
   onPageChange,
   onPageSizeChange,
   isFetching = false,
   onAdd,
   onEdit,
   onToggleBan,
   onToggleFoundingMember,
   onDelete,
   onViewAuditHistory,
   onViewDetails,
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
   onToggleBan?: (id: number, currentStatus: boolean) => void;
   onToggleFoundingMember?: (id: number, currentStatus: boolean) => void;
   onDelete?: (id: number) => void;
   onViewAuditHistory?: (user: UserInterface) => void;
   onViewDetails?: (user: UserInterface) => void;
}) {
   const [data, setData] = React.useState<UserInterface[]>(initialData);
   const [selectedIds, setSelectedIds] = React.useState<Set<number>>(new Set());

   // Modal state
   const [actionModalOpen, setActionModalOpen] = React.useState(false);
   const [actionType, setActionType] = React.useState<UserActionType | null>(null);
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

   const handleActionClick = (user: UserInterface, type: UserActionType) => {
      setSelectedUser(user);
      setActionType(type);
      setActionModalOpen(true);
   };

   const handleConfirmAction = () => {
      if (!selectedUser) return;

      if (actionType === "delete" && onDelete) {
         onDelete(selectedUser.id);
      } else if ((actionType === "ban" || actionType === "unban") && onToggleBan) {
         onToggleBan(selectedUser.id, selectedUser.isBanned);
      } else if ((actionType === "grantFoundingMember" || actionType === "revokeFoundingMember") && onToggleFoundingMember) {
         onToggleFoundingMember(selectedUser.id, selectedUser.isFoundingMember);
      }
      setActionModalOpen(false);
   };

   const getActionTitle = () => {
      if (actionType === "delete") return "Delete User";
      if (actionType === "ban") return "Ban User";
      if (actionType === "unban") return "Unban User";
      if (actionType === "grantFoundingMember") return "Grant Founding Member";
      return "Revoke Founding Member";
   };

   const getActionDescription = () => {
      if (actionType === "delete") {
         return `Are you sure you want to delete ${selectedUser?.name || "this user"}? This action cannot be undone and will permanently remove all their data.`;
      }
      if (actionType === "ban") {
         return `Are you sure you want to ban ${selectedUser?.name || "this user"}? They will no longer be able to log in or access the application.`;
      }
      if (actionType === "unban") {
         return `Are you sure you want to unban ${selectedUser?.name || "this user"}? They will regain access to the application.`;
      }
      if (actionType === "grantFoundingMember") {
         return `Grant Founding Member status to ${selectedUser?.name || "this user"}? They will receive all application features for free with unlimited usage.`;
      }
      return `Revoke Founding Member status from ${selectedUser?.name || "this user"}? They will immediately use their normal subscription and feature limits again.`;
   };

   const getConfirmText = () => {
      if (actionType === "delete") return "Delete";
      if (actionType === "ban") return "Ban User";
      if (actionType === "unban") return "Unban User";
      if (actionType === "grantFoundingMember") return "Grant";
      return "Revoke";
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
                                    {user.isBanned && <span className="text-xs text-destructive font-semibold">Banned</span>}
                                    {user.isSuspended && <span className="text-xs text-orange-500 font-semibold">Suspended</span>}
                                    {user.isFoundingMember && <span className="text-xs text-amber-600 font-semibold">Founding Member{user.foundingMemberSince ? ` since ${formatDate(user.foundingMemberSince)}` : ""}</span>}
                                    <span className="text-xs text-muted-foreground">ID: {user.id}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="text-sm truncate max-w-37.5 sm:max-w-50 md:max-w-75 lg:max-w-100 xl:max-w-125" title={user.email || ""}>
                                       {user.email || "No email"}
                                    </span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col gap-1.5">
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
                                       <DropdownMenuItem onClick={() => onViewDetails?.(user)}>View Details</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => onEdit?.(user)}>Edit User</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => onViewAuditHistory?.(user)}>View Audit History</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => handleActionClick(user, user.isBanned ? "unban" : "ban")}>{user.isBanned ? "Unban User" : "Ban User"}</DropdownMenuItem>
                                       <DropdownMenuItem onClick={() => handleActionClick(user, user.isFoundingMember ? "revokeFoundingMember" : "grantFoundingMember")}>{user.isFoundingMember ? "Revoke Founding Member" : "Grant Founding Member"}</DropdownMenuItem>
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
                        <SelectValue placeholder={`${pageSize}`} />
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
            title={getActionTitle()}
            description={getActionDescription()}
            confirmText={getConfirmText()}
            variant={actionType === "delete" || actionType === "ban" || actionType === "revokeFoundingMember" ? "destructive" : "default"}
         />
      </div>
   );
}
