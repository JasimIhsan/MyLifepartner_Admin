import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { UserReport } from "@/interface/report.interface";
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Eye, ShieldAlert } from "lucide-react";
import { useNavigate } from "react-router-dom";

interface ReportsTableProps {
   data: UserReport[];
   isFetching: boolean;
   pageIndex: number;
   pageSize: number;
   totalCount: number;
   onPageChange: (page: number) => void;
   onPageSizeChange: (size: number) => void;
}

export const ReportsTable = ({ data, isFetching, pageIndex, pageSize, totalCount, onPageChange, onPageSizeChange }: ReportsTableProps) => {
   const navigate = useNavigate();
   const totalPages = Math.ceil(totalCount / pageSize);

   const getStatusBadge = (status: string) => {
      switch (status) {
         case "PENDING":
            return (
               <Badge variant="outline" className="text-yellow-600 bg-yellow-50">
                  {status}
               </Badge>
            );
         case "UNDER_REVIEW":
            return (
               <Badge variant="outline" className="text-blue-600 bg-blue-50">
                  {status}
               </Badge>
            );
         case "RESOLVED":
            return (
               <Badge variant="outline" className="text-green-600 bg-green-50">
                  {status}
               </Badge>
            );
         case "DISMISSED":
            return (
               <Badge variant="outline" className="text-gray-600 bg-gray-50">
                  {status}
               </Badge>
            );
         default:
            return <Badge variant="outline">{status}</Badge>;
      }
   };

   return (
      <div className="w-full space-y-4">
         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead>Report ID</TableHead>
                        <TableHead>Reported User</TableHead>
                        <TableHead>Reporter</TableHead>
                        <TableHead>Reason</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {isFetching && data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={7} className="h-24 text-center text-muted-foreground">
                              Loading reports...
                           </TableCell>
                        </TableRow>
                     ) : data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={7} className="h-24 text-center text-muted-foreground">
                              No reports found.
                           </TableCell>
                        </TableRow>
                     ) : (
                        data.map((report) => (
                           <TableRow key={report.id} className="group">
                              <TableCell className="font-medium">#{report.id}</TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{report.reportedUser?.profile?.name || report.reportedUser?.email || `User ${report.reportedUserId}`}</span>
                                    {report.reportedUser?.isBlocked && <span className="text-xs text-destructive font-semibold">Blocked</span>}
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{report.reporterUser?.profile?.name || report.reporterUser?.email || `User ${report.reporterUserId}`}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex items-center gap-2">
                                    <ShieldAlert className="h-4 w-4 text-muted-foreground" />
                                    <span className="truncate max-w-40 text-sm" title={report.reason}>
                                       {report.reason.replace(/_/g, " ")}
                                    </span>
                                 </div>
                              </TableCell>
                              <TableCell>{getStatusBadge(report.status)}</TableCell>
                              <TableCell className="text-sm text-muted-foreground">{new Date(report.createdAt).toLocaleDateString()}</TableCell>
                              <TableCell className="text-right">
                                 <Button variant="ghost" size="sm" onClick={() => navigate(`/reports/${report.id}`)}>
                                    <Eye className="h-4 w-4 mr-2" />
                                    View Details
                                 </Button>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>
         </div>

         <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-2">
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">Total {totalCount} report(s)</div>
            <div className="flex flex-col sm:flex-row items-center space-y-2 sm:space-y-0 sm:space-x-6 lg:space-x-8">
               <div className="flex items-center space-x-2">
                  <p className="text-sm font-medium">Rows per page</p>
                  <Select
                     value={`${pageSize}`}
                     onValueChange={(value) => {
                        onPageSizeChange(Number(value));
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
                     Page {totalPages > 0 ? pageIndex + 1 : 0} of {totalPages}
                  </div>
                  <div className="flex items-center space-x-1">
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => onPageChange(0)} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to first page</span>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => onPageChange(Math.max(0, pageIndex - 1))} disabled={pageIndex === 0 || isFetching}>
                        <span className="sr-only">Go to previous page</span>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => onPageChange(Math.min(totalPages - 1, pageIndex + 1))} disabled={pageIndex >= totalPages - 1 || totalPages === 0 || isFetching}>
                        <span className="sr-only">Go to next page</span>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => onPageChange(totalPages - 1)} disabled={pageIndex >= totalPages - 1 || totalPages === 0 || isFetching}>
                        <span className="sr-only">Go to last page</span>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            </div>
         </div>
      </div>
   );
};
