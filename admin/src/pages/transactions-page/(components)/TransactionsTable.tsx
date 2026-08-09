"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { TransactionInterface } from "@/interface/transaction.interface";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Search } from "lucide-react";

export function TransactionsTable({
   data = [],
   searchQuery,
   onSearchChange,
   statusFilter,
   onStatusFilterChange,
   pageIndex = 0,
   pageSize = 10,
   totalCount = 0,
   onPageChange,
   onPageSizeChange,
   isFetching = false,
}: {
   data?: TransactionInterface[];
   searchQuery?: string;
   onSearchChange?: (value: string) => void;
   statusFilter?: string;
   onStatusFilterChange?: (value: string) => void;
   pageIndex?: number;
   pageSize?: number;
   totalCount?: number;
   onPageChange?: (pageIndex: number) => void;
   onPageSizeChange?: (pageSize: number) => void;
   isFetching?: boolean;
}) {
   const pageCount = Math.ceil(totalCount / pageSize);

   const formatDate = (date: string | Date) => {
      return new Date(date).toLocaleString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
         hour: "2-digit",
         minute: "2-digit",
      });
   };

   return (
      <div className="w-full space-y-4">
         <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex flex-1 items-center gap-2">
               <div className="relative w-full max-w-sm">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                     placeholder="Search user email or transaction ID..."
                     value={searchQuery !== undefined ? searchQuery : ""}
                     onChange={(e) => {
                        onSearchChange?.(e.target.value);
                     }}
                     className="pl-8 bg-background"
                  />
               </div>
               <Select value={statusFilter || "ALL"} onValueChange={onStatusFilterChange}>
                  <SelectTrigger className="w-45 bg-background">
                     <SelectValue placeholder="Status Filter" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="ALL">All Statuses</SelectItem>
                     <SelectItem value="PAID">Paid</SelectItem>
                     <SelectItem value="FAILED">Failed</SelectItem>
                     <SelectItem value="REFUNDED">Refunded</SelectItem>
                     <SelectItem value="CANCELLED">Cancelled</SelectItem>
                     <SelectItem value="RENEWAL">Renewal</SelectItem>
                  </SelectContent>
               </Select>
            </div>
            <div className="flex items-center space-x-2 w-full sm:w-auto">
               <Button variant="outline" size="sm" className="hidden sm:flex">
                  Export CSV
               </Button>
            </div>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead>User</TableHead>
                        <TableHead>Transaction ID</TableHead>
                        <TableHead>Plan</TableHead>
                        <TableHead>Amount</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Date</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                              {isFetching ? "Loading..." : "No transactions found matching your criteria."}
                           </TableCell>
                        </TableRow>
                     ) : (
                        data.map((transaction) => (
                           <TableRow key={transaction.id} className="group">
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">
                                       {transaction.user.profile?.name || "Unknown"}
                                    </span>
                                    <span className="text-xs text-muted-foreground">{transaction.user.email}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{transaction.originalTransactionId || "N/A"}</span>
                                    <span className="text-xs text-muted-foreground">Store: {transaction.store || "N/A"}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <span className="font-medium">{transaction.plan?.name || "N/A"}</span>
                              </TableCell>
                              <TableCell>
                                 <span className="font-medium">
                                    {transaction.currency} {transaction.amount}
                                 </span>
                              </TableCell>
                              <TableCell>
                                 <span
                                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold
                                       ${
                                          transaction.status === "PAID" || transaction.status === "RENEWAL"
                                             ? "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
                                             : transaction.status === "FAILED"
                                               ? "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
                                               : transaction.status === "REFUNDED"
                                                 ? "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400"
                                                 : "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400"
                                       }
                                    `}
                                 >
                                    {transaction.status}
                                 </span>
                              </TableCell>
                              <TableCell className="text-sm text-muted-foreground">{formatDate(transaction.createdAt)}</TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>
         </div>

         <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-2">
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">Total {totalCount} transactions</div>
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
