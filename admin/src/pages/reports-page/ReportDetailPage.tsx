import axiosInstance from "@/api/api.config";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { UserReport } from "@/interface/report.interface";
import { ArrowLeft, User as UserIcon } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { toast } from "sonner";

const ReportDetailPage = () => {
   const { id } = useParams<{ id: string }>();
   const navigate = useNavigate();
   const [report, setReport] = useState<UserReport | null>(null);
   const [isFetching, setIsFetching] = useState(true);

   const [statusLoading, setStatusLoading] = useState(false);
   const [actionLoading, setActionLoading] = useState(false);

   const [status, setStatus] = useState<string>("");
   const [action, setAction] = useState<string>("");
   const [reason, setReason] = useState<string>("");

   useEffect(() => {
      const fetchReport = async () => {
         try {
            const response = await axiosInstance.get(`/admin/reports/${id}`);
            const data = response.data.data;
            setReport(data);
            setStatus(data.status);
         } catch (error) {
            console.error("Error fetching report details:", error);
            toast.error("Failed to fetch report details");
         } finally {
            setIsFetching(false);
         }
      };

      if (id) fetchReport();
   }, [id]);

   const handleStatusChange = async () => {
      setStatusLoading(true);
      try {
         await axiosInstance.patch(`/admin/reports/${id}/status`, { status });
         toast.success("Report status updated");
         setReport((prev) => (prev ? { ...prev, status } : prev));
      } catch (error) {
         toast.error("Failed to update status");
      } finally {
         setStatusLoading(false);
      }
   };

   const handleTakeAction = async () => {
      if (!action || !reason) {
         toast.error("Please select an action and provide a reason");
         return;
      }
      setActionLoading(true);
      try {
         await axiosInstance.post(`/admin/reports/${id}/action`, { action, reason });
         toast.success("Moderation action applied");
         setReport((prev) => (prev ? { ...prev, status: "RESOLVED", actionTaken: action, resolution: reason } : prev));
         setStatus("RESOLVED");
      } catch (error) {
         toast.error("Failed to apply action");
      } finally {
         setActionLoading(false);
      }
   };

   if (isFetching) {
      return <div>Loading report details...</div>;
   }

   if (!report) {
      return <div>Report not found.</div>;
   }

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div className="flex items-center gap-4">
            <Button variant="outline" size="icon" onClick={() => navigate("/reports")}>
               <ArrowLeft className="h-4 w-4" />
            </Button>
            <div>
               <h1 className="text-2xl font-bold tracking-tight">Report Details #{report.id}</h1>
               <p className="text-muted-foreground">Review the report and take necessary actions.</p>
            </div>
            <div className="ml-auto">
               <Badge className="text-sm px-3 py-1" variant={report.status === "RESOLVED" ? "default" : "secondary"}>
                  {report.status}
               </Badge>
            </div>
         </div>

         <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
               <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                     <UserIcon className="h-5 w-5" /> Reported User
                  </CardTitle>
               </CardHeader>
               <CardContent className="space-y-2">
                  <p>
                     <strong>ID:</strong> {report.reportedUser?.id}
                  </p>
                  <p>
                     <strong>Email:</strong> {report.reportedUser?.email}
                  </p>
                  <p>
                     <strong>Name:</strong> {report.reportedUser?.profile?.name || "N/A"}
                  </p>
                  <p>
                     <strong>Status:</strong> {report.reportedUser?.isBlocked ? <Badge variant="destructive">BLOCKED</Badge> : <Badge variant="outline">ACTIVE</Badge>}
                  </p>
               </CardContent>
            </Card>

            <Card>
               <CardHeader>
                  <CardTitle className="text-lg flex items-center gap-2">
                     <UserIcon className="h-5 w-5" /> Reporter User
                  </CardTitle>
               </CardHeader>
               <CardContent className="space-y-2">
                  <p>
                     <strong>ID:</strong> {report.reporterUser?.id}
                  </p>
                  <p>
                     <strong>Email:</strong> {report.reporterUser?.email}
                  </p>
                  <p>
                     <strong>Name:</strong> {report.reporterUser?.profile?.name || "N/A"}
                  </p>
               </CardContent>
            </Card>
         </div>

         <Card>
            <CardHeader>
               <CardTitle>Report Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
               <div>
                  <h4 className="font-semibold text-sm mb-1">Reason</h4>
                  <Badge variant="outline">{report.reason.replace(/_/g, " ")}</Badge>
               </div>
               <div>
                  <h4 className="font-semibold text-sm mb-1">Description</h4>
                  <p className="text-sm bg-background p-3 rounded-md border">{report.description || "No description provided."}</p>
               </div>
               <div>
                  <h4 className="font-semibold text-sm mb-1">Source</h4>
                  <p className="text-sm">{report.source}</p>
               </div>
               <div>
                  <h4 className="font-semibold text-sm mb-1">Date</h4>
                  <p className="text-sm">{new Date(report.createdAt).toLocaleString()}</p>
               </div>

               {report.evidenceScreenshotsUrls && report.evidenceScreenshotsUrls.length > 0 && (
                  <div>
                     <h4 className="font-semibold text-sm mb-2">Evidence Screenshots</h4>
                     <div className="flex flex-wrap gap-4">
                        {report.evidenceScreenshotsUrls.map((url, idx) => (
                           <a key={idx} href={url} target="_blank" rel="noreferrer" className="block border rounded-md overflow-hidden hover:opacity-90 transition-opacity">
                              <img src={url} alt={`Evidence ${idx + 1}`} className="h-32 w-32 object-cover" />
                           </a>
                        ))}
                     </div>
                  </div>
               )}
            </CardContent>
         </Card>

         <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
               <CardHeader>
                  <CardTitle>Update Status</CardTitle>
               </CardHeader>
               <CardContent className="space-y-4">
                  <div className="space-y-2">
                     <label className="text-sm font-medium">Status</label>
                     <Select value={status} onValueChange={setStatus}>
                        <SelectTrigger>
                           <SelectValue placeholder="Select status" />
                        </SelectTrigger>
                        <SelectContent>
                           <SelectItem value="PENDING">PENDING</SelectItem>
                           <SelectItem value="UNDER_REVIEW">UNDER REVIEW</SelectItem>
                           <SelectItem value="RESOLVED">RESOLVED</SelectItem>
                           <SelectItem value="DISMISSED">DISMISSED</SelectItem>
                        </SelectContent>
                     </Select>
                  </div>
                  <Button onClick={handleStatusChange} disabled={statusLoading || status === report.status} className="w-full">
                     {statusLoading ? "Updating..." : "Update Status"}
                  </Button>
               </CardContent>
            </Card>

            <Card>
               <CardHeader>
                  <CardTitle>Take Moderation Action</CardTitle>
               </CardHeader>
               <CardContent className="space-y-4">
                  {report.actionTaken ? (
                     <div className="p-4 bg-muted/50 rounded-lg space-y-2">
                        <p className="text-sm font-semibold">Action Already Taken</p>
                        <p className="text-sm">
                           <span className="font-medium">Action:</span> {report.actionTaken.replace(/_/g, " ")}
                        </p>
                        <p className="text-sm">
                           <span className="font-medium">Resolution Notes:</span> {report.resolution}
                        </p>
                     </div>
                  ) : (
                     <>
                        <div className="space-y-2">
                           <label className="text-sm font-medium">Action to Take</label>
                           <Select value={action} onValueChange={setAction}>
                              <SelectTrigger>
                                 <SelectValue placeholder="Select action" />
                              </SelectTrigger>
                              <SelectContent>
                                 <SelectItem value="WARNING">Send Warning</SelectItem>
                                 <SelectItem value="PROFILE_HIDDEN">Hide Profile</SelectItem>
                                 <SelectItem value="TEMPORARY_SUSPENSION">Temporary Suspension</SelectItem>
                                 <SelectItem value="PERMANENT_BAN">Permanent Ban</SelectItem>
                                 <SelectItem value="NONE">No Action (Dismiss)</SelectItem>
                              </SelectContent>
                           </Select>
                        </div>
                        <div className="space-y-2">
                           <label className="text-sm font-medium">Internal Reason & Resolution Notes</label>
                           <textarea
                              className="flex min-h-20 w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                              placeholder="Why are you taking this action?"
                              value={reason}
                              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setReason(e.target.value)}
                           />
                        </div>
                        <Button onClick={handleTakeAction} disabled={actionLoading || !action} className="w-full" variant={action === "PERMANENT_BAN" ? "destructive" : "default"}>
                           {actionLoading ? "Applying..." : "Apply Action"}
                        </Button>
                     </>
                  )}
               </CardContent>
            </Card>
         </div>
      </div>
   );
};

export default ReportDetailPage;
