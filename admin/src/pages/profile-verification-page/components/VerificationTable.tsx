"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { UserInterface } from "@/interface/user.interface";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Search } from "lucide-react";

export function VerificationTable({
   data = [],
   searchQuery,
   onSearchChange,
   pageIndex = 0,
   pageSize = 10,
   totalCount = 0,
   onPageChange,
   onPageSizeChange,
   isFetching = false,
   onViewSelfie,
   onApprove,
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
   onViewSelfie?: (user: UserInterface) => void;
   onApprove?: (id: number) => void;
}) {
   const pageCount = Math.ceil(totalCount / pageSize);

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
                     value={searchQuery !== undefined ? searchQuery : ""}
                     onChange={(e) => {
                        onSearchChange?.(e.target.value);
                     }}
                     className="pl-8 bg-background"
                  />
               </div>
            </div>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead className="w-62.5">User</TableHead>
                        <TableHead className="w-50">Contact</TableHead>
                        <TableHead className="w-37.5">Joined</TableHead>
                        <TableHead className="w-40 text-center">Actions</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                              {isFetching ? "Loading..." : "No users pending verification."}
                           </TableCell>
                        </TableRow>
                     ) : (
                        data.map((user) => (
                           <TableRow key={user.id} className="group">
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
                              <TableCell className="text-sm text-muted-foreground">{formatDate(user.createdAt)}</TableCell>
                              <TableCell>
                                 <div className="flex items-center justify-center gap-2">
                                    <Button variant="outline" size="sm" onClick={() => onViewSelfie?.(user)}>
                                       View Selfie
                                    </Button>
                                    <Button variant="default" size="sm" onClick={() => onApprove?.(user.id)}>
                                       Approve
                                    </Button>
                                 </div>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>
         </div>

         <div className="flex flex-col sm:flex-row items-center justify-end gap-4 px-2">
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
      </div>
   );
}
