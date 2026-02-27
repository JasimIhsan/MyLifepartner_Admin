"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { CheckCircle2, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, MoreVertical, Search, SlidersHorizontal, XCircle } from "lucide-react";
import * as React from "react";

export type User = {
   id: number;
   mobileNumber: string;
   email: string | null;
   name: string | null;
   isVerified: boolean;
   isEmailVerified: boolean;
   isProfileCompleted: boolean;
   hasCompletedImageUpload: boolean;
   selfieUrl: string | null;
   selfieStatus: "PENDING" | "APPROVED" | "REJECTED" | null;
   role: "USER" | "ADMIN";
   createdAt: string | Date;
   updatedAt: string | Date;
};

export function UsersTable({ data: initialData = [] }: { data?: User[] }) {
   const [data, setData] = React.useState<User[]>(initialData);
   const [searchQuery, setSearchQuery] = React.useState("");
   const [selectedIds, setSelectedIds] = React.useState<Set<number>>(new Set());
   const [pageIndex, setPageIndex] = React.useState(0);
   const [pageSize, setPageSize] = React.useState(10);
   const [roleFilter, setRoleFilter] = React.useState<string>("ALL");

   React.useEffect(() => {
      setData(initialData);
   }, [initialData]);

   const filteredData = React.useMemo(() => {
      let result = data;

      if (roleFilter !== "ALL") {
         result = result.filter((u) => u.role === roleFilter);
      }

      if (searchQuery) {
         const lowerQuery = searchQuery.toLowerCase();
         result = result.filter((user) => user.name?.toLowerCase().includes(lowerQuery) || user.email?.toLowerCase().includes(lowerQuery) || user.mobileNumber.toLowerCase().includes(lowerQuery));
      }

      return result;
   }, [data, searchQuery, roleFilter]);

   const pageCount = Math.ceil(filteredData.length / pageSize);
   const paginatedData = React.useMemo(() => {
      const start = pageIndex * pageSize;
      return filteredData.slice(start, start + pageSize);
   }, [filteredData, pageIndex, pageSize]);

   const toggleSelectAll = () => {
      if (selectedIds.size === paginatedData.length && paginatedData.length > 0) {
         setSelectedIds(new Set());
      } else {
         setSelectedIds(new Set(paginatedData.map((u) => u.id)));
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

   return (
      <div className="w-full space-y-4">
         <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex flex-1 items-center space-x-2">
               <div className="relative w-full max-w-sm">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                     placeholder="Search users..."
                     value={searchQuery}
                     onChange={(e) => {
                        setSearchQuery(e.target.value);
                        setPageIndex(0);
                     }}
                     className="pl-8 bg-background"
                  />
               </div>
               <Select
                  value={roleFilter}
                  onValueChange={(val) => {
                     setRoleFilter(val);
                     setPageIndex(0);
                  }}
               >
                  <SelectTrigger className="w-32.5 bg-background">
                     <SlidersHorizontal className="mr-2 h-4 w-4 text-muted-foreground" />
                     <SelectValue placeholder="Role" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="ALL">All Roles</SelectItem>
                     <SelectItem value="USER">User</SelectItem>
                     <SelectItem value="ADMIN">Admin</SelectItem>
                  </SelectContent>
               </Select>
            </div>
            <div className="flex items-center space-x-2 w-full sm:w-auto">
               {selectedIds.size > 0 && <span className="text-sm text-muted-foreground mr-2 hidden sm:inline-block">{selectedIds.size} selected</span>}
               <Button variant="outline" size="sm" className="hidden sm:flex">
                  Export
               </Button>
               <Button size="sm" className="w-full sm:w-auto">
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
                           <Checkbox checked={paginatedData.length > 0 && selectedIds.size === paginatedData.length ? true : selectedIds.size > 0 ? "indeterminate" : false} onCheckedChange={toggleSelectAll} aria-label="Select all" />
                        </TableHead>
                        <TableHead className="w-62.5">User</TableHead>
                        <TableHead className="w-50">Contact</TableHead>
                        <TableHead className="w-25">Role</TableHead>
                        <TableHead className="w-37.5">Status</TableHead>
                        <TableHead className="w-37.5">Joined</TableHead>
                        <TableHead className="w-12.5"></TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody>
                     {paginatedData.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={7} className="h-24 text-center text-muted-foreground">
                              No users found matching your criteria.
                           </TableCell>
                        </TableRow>
                     ) : (
                        paginatedData.map((user) => (
                           <TableRow key={user.id} data-state={selectedIds.has(user.id) ? "selected" : undefined} className="group">
                              <TableCell className="text-center align-middle">
                                 <Checkbox checked={selectedIds.has(user.id)} onCheckedChange={() => toggleSelectRow(user.id)} aria-label="Select row" />
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{user.name || "Unknown"}</span>
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
                                 <Badge variant={user.role === "ADMIN" ? "default" : "secondary"} className="font-normal">
                                    {user.role}
                                 </Badge>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col gap-1.5">
                                    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                       {user.isVerified ? <CheckCircle2 className="h-3.5 w-3.5 text-green-500" /> : <XCircle className="h-3.5 w-3.5" />}
                                       <span>Verified</span>
                                    </div>
                                    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                                       {user.isProfileCompleted ? <CheckCircle2 className="h-3.5 w-3.5 text-green-500" /> : <XCircle className="h-3.5 w-3.5" />}
                                       <span>Profile</span>
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
                                       <DropdownMenuItem>Edit User</DropdownMenuItem>
                                       <DropdownMenuSeparator />
                                       <DropdownMenuItem className="text-destructive">Delete User</DropdownMenuItem>
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
                     {selectedIds.size} of {filteredData.length} user(s) selected.
                  </>
               ) : (
                  <>Total {filteredData.length} users</>
               )}
            </div>
            <div className="flex flex-col sm:flex-row items-center space-y-2 sm:space-y-0 sm:space-x-6 lg:space-x-8">
               <div className="flex items-center space-x-2">
                  <p className="text-sm font-medium">Rows per page</p>
                  <Select
                     value={`${pageSize}`}
                     onValueChange={(value) => {
                        setPageSize(Number(value));
                        setPageIndex(0);
                     }}
                  >
                     <SelectTrigger className="h-8 w-17.5">
                        <SelectValue placeholder={pageSize} />
                     </SelectTrigger>
                     <SelectContent side="top">
                        {[10, 20, 30, 40, 50].map((pageSize) => (
                           <SelectItem key={pageSize} value={`${pageSize}`}>
                              {pageSize}
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
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPageIndex(0)} disabled={pageIndex === 0}>
                        <span className="sr-only">Go to first page</span>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPageIndex((p) => Math.max(0, p - 1))} disabled={pageIndex === 0}>
                        <span className="sr-only">Go to previous page</span>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPageIndex((p) => Math.min(pageCount - 1, p + 1))} disabled={pageIndex >= pageCount - 1 || pageCount === 0}>
                        <span className="sr-only">Go to next page</span>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPageIndex(pageCount - 1)} disabled={pageIndex >= pageCount - 1 || pageCount === 0}>
                        <span className="sr-only">Go to last page</span>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            </div>
         </div>
      </div>
   );
}
