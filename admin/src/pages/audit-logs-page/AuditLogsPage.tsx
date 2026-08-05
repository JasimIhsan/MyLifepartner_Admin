import { Activity, Search, Eye, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, RefreshCw } from "lucide-react";
import { useEffect, useState } from "react";
import axiosInstance from "../../api/api.config";
import AuditLogDetailsModal from "./AuditLogDetailsModal";

import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";

export default function AuditLogsPage() {
   const [logs, setLogs] = useState<any[]>([]);
   const [loading, setLoading] = useState(false);
   const [search, setSearch] = useState("");
   const [module, setModule] = useState("all");
   const [actorType, setActorType] = useState("all");
   const [severity, setSeverity] = useState("all");
   const [status, setStatus] = useState("all");
   const [page, setPage] = useState(1);
   const [totalPages, setTotalPages] = useState(1);
   const [pageSize, setPageSize] = useState(20);
   const [totalCount, setTotalCount] = useState(0);

   const [selectedLog, setSelectedLog] = useState<any>(null);

   const fetchLogs = async () => {
      setLoading(true);
      try {
         const response = await axiosInstance.get("/admin/audit-logs", {
            params: {
               page,
               limit: pageSize,
               search,
               module: module === "all" ? "" : module,
               actorType: actorType === "all" ? "" : actorType,
               severity: severity === "all" ? "" : severity,
               status: status === "all" ? "" : status,
            },
         });
         setLogs(response.data.data);
         setTotalPages(response.data.pagination.totalPages);
         setTotalCount(response.data.pagination.total);
      } catch (error) {
         console.error("Failed to fetch audit logs", error);
      } finally {
         setLoading(false);
      }
   };

   useEffect(() => {
      fetchLogs();
   }, [page, pageSize, module, actorType, severity, status]);

   const getStatusBadge = (logStatus: string) => {
      switch (logStatus) {
         case "SUCCESS":
            return (
               <Badge variant="outline" className="text-emerald-600 bg-emerald-50 dark:bg-emerald-500/10 border-emerald-200">
                  {logStatus}
               </Badge>
            );
         case "FAILED":
            return (
               <Badge variant="outline" className="text-red-600 bg-red-50 dark:bg-red-500/10 border-red-200">
                  {logStatus}
               </Badge>
            );
         default:
            return (
               <Badge variant="outline" className="text-amber-600 bg-amber-50 dark:bg-amber-500/10 border-amber-200">
                  {logStatus}
               </Badge>
            );
      }
   };

   return (
      <div className="space-y-6 flex flex-col w-full h-full pb-8">
         <div className="flex flex-col gap-4">
            <div className="flex items-start justify-between">
               <div>
                  <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
                     <Activity className="w-6 h-6 text-indigo-500" />
                     Audit Logs
                  </h1>
                  <p className="text-muted-foreground mt-1">Monitor system activities and user actions.</p>
               </div>
               <Button onClick={fetchLogs} variant="outline" size="icon" title="Refresh Logs" className="shrink-0">
                  <RefreshCw className="h-4 w-4" />
               </Button>
            </div>

            <div className="flex flex-wrap items-center gap-3 bg-card p-3 rounded-lg border border-border shadow-sm">
               <div className="relative flex-1 min-w-50">
                  <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input placeholder="Search messages, IDs..." className="pl-9 w-full bg-background" value={search} onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => e.key === "Enter" && fetchLogs()} />
               </div>

               <Select
                  value={module}
                  onValueChange={(val) => {
                     setModule(val);
                     setPage(1);
                  }}
               >
                  <SelectTrigger className="w-35 bg-background">
                     <SelectValue placeholder="Module" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="all">All Modules</SelectItem>
                     <SelectItem value="AUTH">Auth</SelectItem>
                     <SelectItem value="PROFILE">Profile</SelectItem>
                     <SelectItem value="SUBSCRIPTION">Subscription</SelectItem>
                     <SelectItem value="PAYMENT">Payment</SelectItem>
                     <SelectItem value="CHAT">Chat</SelectItem>
                     <SelectItem value="CALL">Call</SelectItem>
                     <SelectItem value="MODERATION">Moderation</SelectItem>
                     <SelectItem value="NOTIFICATION">Notification</SelectItem>
                     <SelectItem value="ACCOUNT">Account</SelectItem>
                     <SelectItem value="ADMIN">Admin</SelectItem>
                  </SelectContent>
               </Select>

               <Select
                  value={actorType}
                  onValueChange={(val) => {
                     setActorType(val);
                     setPage(1);
                  }}
               >
                  <SelectTrigger className="w-35 bg-background">
                     <SelectValue placeholder="Actor Type" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="all">All Actors</SelectItem>
                     <SelectItem value="USER">User</SelectItem>
                     <SelectItem value="ADMIN">Admin</SelectItem>
                     <SelectItem value="SYSTEM">System</SelectItem>
                     <SelectItem value="WEBHOOK">Webhook</SelectItem>
                  </SelectContent>
               </Select>

               <Select
                  value={severity}
                  onValueChange={(val) => {
                     setSeverity(val);
                     setPage(1);
                  }}
               >
                  <SelectTrigger className="w-35 bg-background">
                     <SelectValue placeholder="Severity" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="all">All Severities</SelectItem>
                     <SelectItem value="INFO">Info</SelectItem>
                     <SelectItem value="WARNING">Warning</SelectItem>
                     <SelectItem value="ERROR">Error</SelectItem>
                     <SelectItem value="CRITICAL">Critical</SelectItem>
                  </SelectContent>
               </Select>

               <Select
                  value={status}
                  onValueChange={(val) => {
                     setStatus(val);
                     setPage(1);
                  }}
               >
                  <SelectTrigger className="w-35 bg-background">
                     <SelectValue placeholder="Status" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="all">All Statuses</SelectItem>
                     <SelectItem value="SUCCESS">Success</SelectItem>
                     <SelectItem value="FAILED">Failed</SelectItem>
                     <SelectItem value="PENDING">Pending</SelectItem>
                  </SelectContent>
               </Select>

               <Button onClick={fetchLogs} variant="default" className="bg-indigo-600 hover:bg-indigo-700 w-full sm:w-auto">
                  Search
               </Button>
            </div>
         </div>

         <div className="w-full space-y-4">
            <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
               <div className="overflow-x-auto">
                  <Table>
                     <TableHeader className="bg-muted/50">
                        <TableRow>
                           <TableHead>Timestamp</TableHead>
                           <TableHead>Module / Action</TableHead>
                           <TableHead>Actor</TableHead>
                           <TableHead>Status</TableHead>
                           <TableHead>Message</TableHead>
                           <TableHead className="text-right">Actions</TableHead>
                        </TableRow>
                     </TableHeader>
                     <TableBody className={loading ? "opacity-50 pointer-events-none" : ""}>
                        {loading && logs.length === 0 ? (
                           <TableRow>
                              <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                                 Loading logs...
                              </TableCell>
                           </TableRow>
                        ) : logs.length === 0 ? (
                           <TableRow>
                              <TableCell colSpan={6} className="h-24 text-center text-muted-foreground">
                                 No audit logs found matching criteria.
                              </TableCell>
                           </TableRow>
                        ) : (
                           logs.map((log) => (
                              <TableRow key={log.id} className="group">
                                 <TableCell className="text-muted-foreground whitespace-nowrap">{new Date(log.createdAt).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" })}</TableCell>
                                 <TableCell>
                                    <div className="flex flex-col">
                                       <span className="font-medium text-foreground">{log.module}</span>
                                       <span className="text-xs text-muted-foreground">{log.action}</span>
                                    </div>
                                 </TableCell>
                                 <TableCell>
                                    <div className="flex flex-col">
                                       <span className="text-foreground">{log.actorType}</span>
                                       <div className="flex flex-col mt-0.5">
                                          {log.user ? (
                                             <>
                                                {log.user.profile?.name && <span className="font-medium text-foreground">{log.user.profile.name}</span>}
                                                <span className="text-xs text-muted-foreground">{log.user.email || `User: ${log.user.id}`}</span>
                                             </>
                                          ) : log.admin ? (
                                             <span className="font-medium text-foreground">{log.admin.username || `Admin: ${log.admin.id}`}</span>
                                          ) : log.userId ? (
                                             <span className="text-xs text-muted-foreground">User ID: {log.userId}</span>
                                          ) : log.adminId ? (
                                             <span className="text-xs text-muted-foreground">Admin ID: {log.adminId}</span>
                                          ) : null}
                                       </div>
                                    </div>
                                 </TableCell>
                                 <TableCell>{getStatusBadge(log.status)}</TableCell>
                                 <TableCell className="text-muted-foreground max-w-xs truncate">{log.message}</TableCell>
                                 <TableCell className="text-right">
                                    <Button variant="ghost" size="sm" onClick={() => setSelectedLog(log)}>
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
               <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">Total {totalCount || logs.length} log(s)</div>
               <div className="flex flex-col sm:flex-row items-center space-y-2 sm:space-y-0 sm:space-x-6 lg:space-x-8">
                  <div className="flex items-center space-x-2">
                     <p className="text-sm font-medium">Rows per page</p>
                     <Select
                        value={`${pageSize}`}
                        onValueChange={(value) => {
                           setPageSize(Number(value));
                           setPage(1);
                        }}
                     >
                        <SelectTrigger className="h-8 w-17.5">
                           <SelectValue placeholder={pageSize} />
                        </SelectTrigger>
                        <SelectContent side="top">
                           {[10, 20, 50, 100].map((size) => (
                              <SelectItem key={size} value={`${size}`}>
                                 {size}
                              </SelectItem>
                           ))}
                        </SelectContent>
                     </Select>
                  </div>
                  <div className="flex items-center space-x-2">
                     <div className="flex w-25 items-center justify-center text-sm font-medium">
                        Page {totalPages > 0 ? page : 0} of {totalPages}
                     </div>
                     <div className="flex items-center space-x-1">
                        <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPage(1)} disabled={page === 1 || loading}>
                           <span className="sr-only">Go to first page</span>
                           <ChevronsLeft className="h-4 w-4" />
                        </Button>
                        <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1 || loading}>
                           <span className="sr-only">Go to previous page</span>
                           <ChevronLeft className="h-4 w-4" />
                        </Button>
                        <Button variant="outline" className="h-8 w-8 p-0 bg-background" onClick={() => setPage(Math.min(totalPages, page + 1))} disabled={page >= totalPages || totalPages === 0 || loading}>
                           <span className="sr-only">Go to next page</span>
                           <ChevronRight className="h-4 w-4" />
                        </Button>
                        <Button variant="outline" className="hidden h-8 w-8 p-0 lg:flex bg-background" onClick={() => setPage(totalPages)} disabled={page >= totalPages || totalPages === 0 || loading}>
                           <span className="sr-only">Go to last page</span>
                           <ChevronsRight className="h-4 w-4" />
                        </Button>
                     </div>
                  </div>
               </div>
            </div>
         </div>

         {selectedLog && <AuditLogDetailsModal log={selectedLog} onClose={() => setSelectedLog(null)} />}
      </div>
   );
}
