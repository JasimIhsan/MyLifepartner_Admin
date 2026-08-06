import { Activity, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, RefreshCw, Trash2, CheckCircle2, XCircle } from "lucide-react";
import { useEffect, useState } from "react";
import axiosInstance from "../../api/api.config";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { ConfirmationModal } from "@/components/confirmation-modal";

export default function DeletionRequestsPage() {
   const [requests, setRequests] = useState<any[]>([]);
   const [loading, setLoading] = useState(false);
   const [page, setPage] = useState(1);
   const [totalPages, setTotalPages] = useState(1);
   const [pageSize, setPageSize] = useState(20);
   const [totalCount, setTotalCount] = useState(0);

   const [actionModalOpen, setActionModalOpen] = useState(false);
   const [actionType, setActionType] = useState<"approve" | "reject" | null>(null);
   const [selectedUserId, setSelectedUserId] = useState<number | null>(null);

   const fetchRequests = async () => {
      setLoading(true);
      try {
         const response = await axiosInstance.get("/admin/users/deletion-requests", {
            params: {
               page,
               limit: pageSize,
            },
         });
         setRequests(response.data.data.data);
         setTotalCount(response.data.data.total);
         setTotalPages(Math.ceil(response.data.data.total / pageSize));
      } catch (error) {
         console.error("Failed to fetch deletion requests", error);
         toast.error("Failed to fetch deletion requests");
      } finally {
         setLoading(false);
      }
   };

   useEffect(() => {
      fetchRequests();
   }, [page, pageSize]);

   const handleActionConfirm = async () => {
      if (!selectedUserId || !actionType) return;
      try {
         if (actionType === "approve") {
            await axiosInstance.post(`/admin/users/${selectedUserId}/approve-deletion`);
            toast.success("Account deletion approved and data anonymized.");
         } else if (actionType === "reject") {
            await axiosInstance.post(`/admin/users/${selectedUserId}/reject-deletion`);
            toast.success("Account deletion request rejected.");
         }
         fetchRequests();
      } catch (error) {
         console.error(`Failed to ${actionType} request`, error);
         toast.error(`Failed to ${actionType} request`);
      } finally {
         setActionModalOpen(false);
         setSelectedUserId(null);
         setActionType(null);
      }
   };

   const openModal = (userId: number, type: "approve" | "reject") => {
      setSelectedUserId(userId);
      setActionType(type);
      setActionModalOpen(true);
   };

   return (
      <div className="space-y-6 flex flex-col w-full h-full pb-8">
         <div className="flex flex-col gap-4">
            <div className="flex items-start justify-between">
               <div>
                  <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
                     <Trash2 className="w-6 h-6 text-red-500" />
                     Account Deletion Requests
                  </h1>
                  <p className="text-muted-foreground mt-1">Review and process user account deletion requests in compliance with GDPR.</p>
               </div>
               <Button onClick={fetchRequests} variant="outline" size="icon" title="Refresh Requests" className="shrink-0">
                  <RefreshCw className="h-4 w-4" />
               </Button>
            </div>
         </div>

         <div className="bg-card rounded-lg border border-border shadow-sm flex flex-col flex-1 overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader>
                     <TableRow className="bg-muted/50">
                        <TableHead>User ID</TableHead>
                        <TableHead>Email</TableHead>
                        <TableHead>Requested At</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody>
                     {loading ? (
                        <TableRow>
                           <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                              Loading requests...
                           </TableCell>
                        </TableRow>
                     ) : requests.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                              No pending deletion requests found.
                           </TableCell>
                        </TableRow>
                     ) : (
                        requests.map((request) => (
                           <TableRow key={request.id}>
                              <TableCell className="font-medium">#{request.id}</TableCell>
                              <TableCell>{request.email}</TableCell>
                              <TableCell>{new Date(request.deleteRequestedAt).toLocaleString()}</TableCell>
                              <TableCell>
                                 <Badge variant="outline" className="text-amber-600 bg-amber-50 border-amber-200">
                                    PENDING
                                 </Badge>
                              </TableCell>
                              <TableCell className="text-right space-x-2">
                                 <Button variant="outline" size="sm" onClick={() => openModal(request.id, "approve")} className="text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                                    <CheckCircle2 className="w-4 h-4 mr-1" /> Approve
                                 </Button>
                                 <Button variant="outline" size="sm" onClick={() => openModal(request.id, "reject")} className="text-red-600 border-red-200 hover:bg-red-50">
                                    <XCircle className="w-4 h-4 mr-1" /> Reject
                                 </Button>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>

            {totalCount > 0 && (
               <div className="flex items-center justify-between px-4 py-3 border-t border-border bg-muted/20 mt-auto">
                  <div className="text-sm text-muted-foreground">
                     Showing {Math.min((page - 1) * pageSize + 1, totalCount)} to {Math.min(page * pageSize, totalCount)} of {totalCount} entries
                  </div>
                  <div className="flex items-center gap-2">
                     <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPage(1)} disabled={page === 1 || loading}>
                        <ChevronsLeft className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1 || loading}>
                        <ChevronLeft className="h-4 w-4" />
                     </Button>
                     <span className="text-sm font-medium px-2">
                        Page {page} of {totalPages || 1}
                     </span>
                     <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages || totalPages === 0 || loading}>
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => setPage(totalPages)} disabled={page === totalPages || totalPages === 0 || loading}>
                        <ChevronsRight className="h-4 w-4" />
                     </Button>
                  </div>
               </div>
            )}
         </div>

         <ConfirmationModal
            isOpen={actionModalOpen}
            onClose={() => setActionModalOpen(false)}
            onConfirm={handleActionConfirm}
            title={actionType === "approve" ? "Approve Deletion Request" : "Reject Deletion Request"}
            description={
               actionType === "approve"
                  ? "Are you sure you want to approve this request? This will permanently anonymize the user's data and delete their media files. This action cannot be undone."
                  : "Are you sure you want to reject this request? The user's account suspension will be lifted."
            }
            confirmText={actionType === "approve" ? "Approve & Delete" : "Reject"}
            confirmVariant={actionType === "approve" ? "destructive" : "default"}
         />
      </div>
   );
}
