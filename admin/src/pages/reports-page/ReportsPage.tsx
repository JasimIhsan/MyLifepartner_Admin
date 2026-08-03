import axiosInstance from "@/api/api.config";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { UserReport } from "@/interface/report.interface";
import { Search } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { ReportsTable } from "./(components)/ReportsTable";

const ReportsPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);

   const [reports, setReports] = useState<UserReport[]>([]);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(true);
   const [pageIndex, setPageIndex] = useState(initialPage - 1);
   const [pageSize, setPageSize] = useState(initialLimit);
   const [searchTerm, setSearchTerm] = useState(searchParams.get("search") || "");
   const [reasonFilter, setReasonFilter] = useState(searchParams.get("reason") || "all");

   const fetchReports = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/reports", {
            params: {
               page: pageIndex + 1,
               limit: pageSize,
               ...(searchTerm && { search: searchTerm }),
               ...(reasonFilter !== "all" && { reason: reasonFilter }),
            },
         });
         setReports(response.data.data?.reports || response.data.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching reports:", error);
         toast.error("Failed to fetch reports");
      } finally {
         setIsFetching(false);
      }
   }, [pageIndex, pageSize, searchTerm, reasonFilter]);

   useEffect(() => {
      const handler = setTimeout(() => {
         fetchReports();
      }, 300); // 300ms debounce

      return () => clearTimeout(handler);
   }, [fetchReports, searchTerm, reasonFilter]);

   useEffect(() => {
      const params = new URLSearchParams(searchParams);
      params.set("page", (pageIndex + 1).toString());
      params.set("limit", pageSize.toString());
      if (searchTerm) {
         params.set("search", searchTerm);
      } else {
         params.delete("search");
      }
      if (reasonFilter !== "all") {
         params.set("reason", reasonFilter);
      } else {
         params.delete("reason");
      }
      setSearchParams(params, { replace: true });
   }, [pageIndex, pageSize, searchTerm, reasonFilter, setSearchParams, searchParams]);

   const handlePageChange = (newPageIndex: number) => {
      setPageIndex(newPageIndex);
   };

   const handlePageSizeChange = (newPageSize: number) => {
      setPageSize(newPageSize);
      setPageIndex(0);
   };

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
               <h1 className="text-2xl font-bold tracking-tight">User Reports</h1>
               <p className="text-muted-foreground">Manage and review user reports, take moderation actions.</p>
            </div>
            <div className="flex items-center gap-2">
               <div className="relative">
                  <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                     placeholder="Search by ID, name, email..."
                     className="pl-8 w-full sm:w-75"
                     value={searchTerm}
                     onChange={(e) => {
                        setSearchTerm(e.target.value);
                        setPageIndex(0); // Reset to page 1 on search
                     }}
                  />
               </div>
               <Select
                  value={reasonFilter}
                  onValueChange={(val) => {
                     setReasonFilter(val);
                     setPageIndex(0);
                  }}
               >
                  <SelectTrigger className="w-50">
                     <SelectValue placeholder="Filter by reason" />
                  </SelectTrigger>
                  <SelectContent>
                     <SelectItem value="all">All Reasons</SelectItem>
                     <SelectItem value="FAKE_PROFILE">Fake Profile</SelectItem>
                     <SelectItem value="IMPERSONATION">Impersonation</SelectItem>
                     <SelectItem value="INAPPROPRIATE_PHOTOS">Inappropriate Photos</SelectItem>
                     <SelectItem value="INAPPROPRIATE_MESSAGES">Inappropriate Messages</SelectItem>
                     <SelectItem value="HARASSMENT">Harassment</SelectItem>
                     <SelectItem value="SPAM">Spam</SelectItem>
                     <SelectItem value="SCAM_OR_FRAUD">Scam or Fraud</SelectItem>
                     <SelectItem value="ASKING_FOR_MONEY">Asking for Money</SelectItem>
                     <SelectItem value="ABUSIVE_BEHAVIOR">Abusive Behavior</SelectItem>
                     <SelectItem value="SEXUAL_CONTENT">Sexual Content</SelectItem>
                     <SelectItem value="HATEFUL_CONTENT">Hateful Content</SelectItem>
                     <SelectItem value="THREATS">Threats</SelectItem>
                     <SelectItem value="UNDERAGE_USER">Underage User</SelectItem>
                     <SelectItem value="MARRIED_OR_FALSE_RELATIONSHIP_STATUS">Married / False Relationship Status</SelectItem>
                     <SelectItem value="FALSE_INFORMATION">False Information</SelectItem>
                     <SelectItem value="OFF_PLATFORM_SOLICITATION">Off Platform Solicitation</SelectItem>
                     <SelectItem value="OTHER">Other</SelectItem>
                  </SelectContent>
               </Select>
            </div>
         </div>
         <ReportsTable data={reports} pageIndex={pageIndex} pageSize={pageSize} totalCount={totalCount} onPageChange={handlePageChange} onPageSizeChange={handlePageSizeChange} isFetching={isFetching} />
      </div>
   );
};

export default ReportsPage;
