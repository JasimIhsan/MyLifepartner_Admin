import axiosInstance from "@/api/api.config";
import type { TransactionInterface } from "@/interface/transaction.interface";
import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import { useDebounce } from "use-debounce";
import { TransactionsTable } from "./(components)/TransactionsTable";

const TransactionsPage = () => {
   const [searchParams, setSearchParams] = useSearchParams();
   const initialSearch = searchParams.get("search") || "";
   const initialPage = parseInt(searchParams.get("page") || "1", 10);
   const initialLimit = parseInt(searchParams.get("limit") || "10", 10);
   const initialStatus = searchParams.get("status") || "ALL";

   const [transactions, setTransactions] = useState<TransactionInterface[]>([]);
   const [totalCount, setTotalCount] = useState(0);
   const [isFetching, setIsFetching] = useState(true);
   
   const [searchQuery, setSearchQuery] = useState(initialSearch);
   const [statusFilter, setStatusFilter] = useState(initialStatus);
   const [pageIndex, setPageIndex] = useState(initialPage - 1);
   const [pageSize, setPageSize] = useState(initialLimit);

   const [debouncedSearch] = useDebounce(searchQuery, 500);

   const fetchTransactions = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/transactions", {
            params: {
               search: debouncedSearch,
               status: statusFilter === "ALL" ? undefined : statusFilter,
               page: pageIndex + 1,
               limit: pageSize,
            },
         });
         setTransactions(response.data.data?.transactions || response.data.data || []);
         setTotalCount(response.data.data?.total || 0);
      } catch (error) {
         console.error("Error fetching transactions:", error);
         toast.error("Failed to fetch transactions");
      } finally {
         setIsFetching(false);
      }
   }, [debouncedSearch, statusFilter, pageIndex, pageSize]);

   useEffect(() => {
      fetchTransactions();
   }, [fetchTransactions]);

   useEffect(() => {
      const params = new URLSearchParams(searchParams);
      if (debouncedSearch) {
         params.set("search", debouncedSearch);
      } else {
         params.delete("search");
      }
      
      if (statusFilter !== "ALL") {
         params.set("status", statusFilter);
      } else {
         params.delete("status");
      }

      params.set("page", (pageIndex + 1).toString());
      params.set("limit", pageSize.toString());
      setSearchParams(params, { replace: true });
   }, [debouncedSearch, statusFilter, pageIndex, pageSize, setSearchParams, searchParams]);

   const handleSearchChange = (value: string) => {
      setSearchQuery(value);
      setPageIndex(0); // Reset to first page on new search
   };

   const handleStatusFilterChange = (value: string) => {
      setStatusFilter(value);
      setPageIndex(0); // Reset to first page on filter change
   };

   const handlePageChange = (newPageIndex: number) => {
      setPageIndex(newPageIndex);
   };

   const handlePageSizeChange = (newPageSize: number) => {
      setPageSize(newPageSize);
      setPageIndex(0); // Reset to first page when changing page size
   };

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Transaction History</h1>
            <p className="text-muted-foreground">View and track all subscription and payment transactions.</p>
         </div>
         <>
            <TransactionsTable
               data={transactions}
               searchQuery={searchQuery}
               onSearchChange={handleSearchChange}
               statusFilter={statusFilter}
               onStatusFilterChange={handleStatusFilterChange}
               pageIndex={pageIndex}
               pageSize={pageSize}
               totalCount={totalCount}
               onPageChange={handlePageChange}
               onPageSizeChange={handlePageSizeChange}
               isFetching={isFetching}
            />
         </>
      </div>
   );
};

export default TransactionsPage;
