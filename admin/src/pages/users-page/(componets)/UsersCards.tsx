"use client";

import { ConfirmationModal } from "@/components/confirmation-modal";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { UserInterface } from "@/interface/user.interface";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, MoreVertical, Search, Mail, Phone, CalendarDays } from "lucide-react";
import * as React from "react";
import { Card, CardContent, CardFooter, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

type UserActionType = "delete" | "ban" | "unban" | "grantFoundingMember" | "revokeFoundingMember";

export function UsersCards({
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
               <div className="flex items-center space-x-2 mr-2">
                  <Checkbox checked={data.length > 0 && selectedIds.size === data.length ? true : selectedIds.size > 0 ? "indeterminate" : false} onCheckedChange={toggleSelectAll} aria-label="Select all" />
               </div>
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

         <div className={isFetching ? "opacity-50 pointer-events-none" : ""}>
            {data.length === 0 ? (
               <div className="flex items-center justify-center h-40 border rounded-md bg-card text-muted-foreground">{isFetching ? "Loading..." : "No users found matching your criteria."}</div>
            ) : (
               <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                  {data.map((user) => (
                     <Card key={user.id} className={`relative group ${selectedIds.has(user.id) ? "border-primary" : ""}`}>
                        <div className="absolute top-4 left-4 z-10">
                           <Checkbox checked={selectedIds.has(user.id)} onCheckedChange={() => toggleSelectRow(user.id)} aria-label="Select row" />
                        </div>
                        <div className="absolute top-3 right-3 z-10">
                           <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                 <Button variant="ghost" className="h-8 w-8 p-0">
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
                        </div>

                        <CardHeader className="text-center pt-8 pb-4 cursor-pointer" onClick={() => onViewDetails?.(user)}>
                           <div className="mx-auto w-16 h-16 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-3 text-2xl font-bold">{user.name ? user.name.charAt(0).toUpperCase() : "U"}</div>
                           <CardTitle className="truncate">{user.name || "Unknown"}</CardTitle>
                           <CardDescription>ID: {user.id}</CardDescription>

                           <div className="flex flex-wrap gap-1 mt-2 justify-center">
                              {user.isBanned && <Badge variant="destructive">Banned</Badge>}
                              {user.isSuspended && (
                                 <Badge variant="outline" className="text-orange-500 border-orange-500">
                                    Suspended
                                 </Badge>
                              )}
                              {user.isFoundingMember && (
                                 <Badge variant="secondary" className="bg-amber-100 text-amber-700 hover:bg-amber-100">
                                    Founding Member
                                 </Badge>
                              )}
                              {user.profileStatus === "COMPLETED" && (
                                 <Badge variant="default" className="bg-green-100 text-green-700 hover:bg-green-100">
                                    Completed
                                 </Badge>
                              )}
                              {user.profileStatus !== "COMPLETED" && <Badge variant="secondary">{user.profileStatus?.replace("_", " ").toLowerCase() || "Incomplete"}</Badge>}
                           </div>
                        </CardHeader>

                        <CardContent className="pb-4 pt-0">
                           <div className="space-y-2 text-sm px-2">
                              <div className="flex items-center text-muted-foreground overflow-hidden">
                                 <Mail className="h-4 w-4 mr-2 shrink-0" />
                                 <span className="truncate">{user.email || "No email"}</span>
                              </div>
                              <div className="flex items-center text-muted-foreground overflow-hidden">
                                 <Phone className="h-4 w-4 mr-2 shrink-0" />
                                 <span className="truncate">{user.mobileNumber || "No phone"}</span>
                              </div>
                              <div className="flex items-center text-muted-foreground">
                                 <CalendarDays className="h-4 w-4 mr-2 shrink-0" />
                                 <span className="truncate">Joined {formatDate(user.createdAt)}</span>
                              </div>
                           </div>
                        </CardContent>
                        <CardFooter className="pt-0 justify-center">
                           <Button variant="secondary" className="w-full mx-2" onClick={() => onViewDetails?.(user)}>
                              View Details
                           </Button>
                        </CardFooter>
                     </Card>
                  ))}
               </div>
            )}
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
                  <p className="text-sm font-medium">Cards per page</p>
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
                        {[12, 20, 24, 36, 48].map((size) => (
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

         <ConfirmationModal isOpen={actionModalOpen} onClose={() => setActionModalOpen(false)} onConfirm={handleConfirmAction} title={getActionTitle()} description={getActionDescription()} confirmText={getConfirmText()} variant={actionType === "delete" || actionType === "ban" || actionType === "revokeFoundingMember" ? "destructive" : "default"} />
      </div>
   );
}
