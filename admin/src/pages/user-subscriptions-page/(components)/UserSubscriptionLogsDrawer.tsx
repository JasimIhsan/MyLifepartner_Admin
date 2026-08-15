import { getUserSubscriptionLogs } from "@/api/subscription.service";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Download, Loader2 } from "lucide-react";
import React, { useEffect, useState } from "react";
import { toast } from "sonner";

interface UserSubscriptionLogsDrawerProps {
   isOpen: boolean;
   onClose: () => void;
   userId: number | null;
   userName?: string;
}

export const UserSubscriptionLogsDrawer: React.FC<UserSubscriptionLogsDrawerProps> = ({ isOpen, onClose, userId, userName }) => {
   const [logs, setLogs] = useState<any[]>([]);
   const [loading, setLoading] = useState(false);

   useEffect(() => {
      if (isOpen && userId) {
         fetchLogs();
      } else {
         setLogs([]);
      }
   }, [isOpen, userId]);

   const fetchLogs = async () => {
      setLoading(true);
      try {
         const res = await getUserSubscriptionLogs(userId!, 1, 100);
         if (res?.data) {
            setLogs(res.data);
         }
      } catch (err: any) {
         toast.error(err.response?.data?.message || "Failed to fetch logs");
      } finally {
         setLoading(false);
      }
   };

   const handleExportCsv = () => {
      if (!logs.length) return;
      const headers = ["Event Type", "Source", "Reason", "Prev Plan", "New Plan", "Prev Status", "New Status", "Store", "Environment", "Timestamp"];
      const csvContent = [
         headers.join(","),
         ...logs.map((log) => [log.eventType || "-", log.source || "-", `"${(log.reason || "-").replace(/"/g, '""')}"`, log.previousPlanId || "-", log.newPlanId || "-", log.previousStatus || "-", log.newStatus || "-", log.store || "-", log.environment || "-", new Date(log.createdAt).toLocaleString()].join(",")),
      ].join("\n");

      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.setAttribute("href", url);
      link.setAttribute("download", `subscription_logs_user_${userId}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
   };

   return (
      <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <SheetContent className="sm:max-w-5xl overflow-y-auto p-3">
            <SheetHeader className="mb-6">
               <SheetTitle>Subscription Logs</SheetTitle>
               <SheetDescription>Audit trail for user {userName ? `"${userName}" (ID: ${userId})` : `ID: ${userId}`}</SheetDescription>
            </SheetHeader>

            <div className="flex justify-end mb-4">
               <Button variant="outline" size="sm" onClick={handleExportCsv} disabled={!logs.length || loading}>
                  <Download className="mr-2 h-4 w-4" />
                  Export CSV
               </Button>
            </div>
            {loading ? (
               <div className="flex justify-center items-center py-10">
                  <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
               </div>
            ) : logs.length === 0 ? (
               <div className="text-center py-10 text-muted-foreground">No subscription logs found for this user.</div>
            ) : (
               <div className="border rounded-md">
                  <Table>
                     <TableHeader>
                        <TableRow>
                           <TableHead>Date</TableHead>
                           <TableHead>Event Type / Source</TableHead>
                           <TableHead>Status Change</TableHead>
                           <TableHead>Plan Change</TableHead>
                           <TableHead>Store</TableHead>
                           <TableHead>Reason</TableHead>
                        </TableRow>
                     </TableHeader>
                     <TableBody>
                        {logs.map((log) => (
                           <TableRow key={log.id}>
                              <TableCell className="whitespace-nowrap">{new Date(log.createdAt).toLocaleString()}</TableCell>
                              <TableCell>
                                 <div className="flex flex-col space-y-1">
                                    <Badge variant="outline" className="w-fit">
                                       {log.eventType || "UNKNOWN"}
                                    </Badge>
                                    <span className="text-xs text-muted-foreground">{log.source}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex items-center space-x-2 text-sm">
                                    <span className="text-muted-foreground line-through">{log.previousStatus || "NONE"}</span>
                                    <span>→</span>
                                    <span className="font-medium">{log.newStatus}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex items-center space-x-2 text-sm">
                                    <span className="text-muted-foreground">{log.previousPlanId || "None"}</span>
                                    <span>→</span>
                                    <span className="font-medium">{log.newPlanId || "None"}</span>
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex flex-col space-y-1">
                                    <span>{log.store || "-"}</span>
                                    {log.environment && (
                                       <Badge variant={log.environment === "SANDBOX" ? "secondary" : "default"} className="w-fit text-[10px]">
                                          {log.environment}
                                       </Badge>
                                    )}
                                 </div>
                              </TableCell>
                              <TableCell className="text-xs max-w-50 truncate" title={log.reason}>
                                 {log.reason}
                              </TableCell>
                           </TableRow>
                        ))}
                     </TableBody>
                  </Table>
               </div>
            )}
         </SheetContent>
      </Sheet>
   );
};
