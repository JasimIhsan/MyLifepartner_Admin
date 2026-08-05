import { useEffect, useState } from "react";
import axiosInstance from "../../../api/api.config";
import { X, Activity } from "lucide-react";
import AuditLogDetailsModal from "../../audit-logs-page/AuditLogDetailsModal";

export function UserAuditHistoryModal({ isOpen, onClose, userId, userName }: { isOpen: boolean; onClose: () => void; userId: number | undefined; userName: string | null | undefined }) {
   const [logs, setLogs] = useState<any[]>([]);
   const [loading, setLoading] = useState(false);
   const [page, setPage] = useState(1);
   const [totalPages, setTotalPages] = useState(1);
   const [selectedLog, setSelectedLog] = useState<any>(null);

   useEffect(() => {
      if (!isOpen || !userId) return;

      const fetchLogs = async () => {
         setLoading(true);
         try {
            const response = await axiosInstance.get(`/admin/audit-logs/user/${userId}`, {
               params: { page, limit: 10 }
            });
            setLogs(response.data.data);
            setTotalPages(response.data.pagination.totalPages);
         } catch (error) {
            console.error("Failed to fetch user audit logs", error);
         } finally {
            setLoading(false);
         }
      };
      
      fetchLogs();
   }, [isOpen, userId, page]);

   if (!isOpen) return null;

   return (
      <div className="fixed inset-0 z-40 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
         <div className="bg-white dark:bg-slate-900 rounded-xl shadow-xl w-full max-w-5xl max-h-[90vh] flex flex-col">
            <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center">
               <h2 className="text-xl font-semibold text-slate-800 dark:text-white flex items-center gap-2">
                  <Activity className="w-5 h-5 text-indigo-500" />
                  Audit History: {userName} (ID: {userId})
               </h2>
               <button onClick={onClose} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors text-slate-500">
                  <X className="w-5 h-5" />
               </button>
            </div>

            <div className="flex-1 overflow-y-auto p-0">
               <table className="w-full text-left text-sm whitespace-nowrap">
                  <thead className="bg-slate-50 dark:bg-slate-900 border-b border-slate-200 dark:border-slate-700">
                     <tr>
                        <th className="px-6 py-4 font-semibold text-slate-600 dark:text-slate-300">Timestamp</th>
                        <th className="px-6 py-4 font-semibold text-slate-600 dark:text-slate-300">Module / Action</th>
                        <th className="px-6 py-4 font-semibold text-slate-600 dark:text-slate-300">Status</th>
                        <th className="px-6 py-4 font-semibold text-slate-600 dark:text-slate-300">Message</th>
                        <th className="px-6 py-4 font-semibold text-slate-600 dark:text-slate-300"></th>
                     </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                     {loading ? (
                        <tr>
                           <td colSpan={5} className="px-6 py-8 text-center text-slate-500">Loading history...</td>
                        </tr>
                     ) : logs.length === 0 ? (
                        <tr>
                           <td colSpan={5} className="px-6 py-8 text-center text-slate-500">No audit history found for this user.</td>
                        </tr>
                     ) : (
                        logs.map((log) => (
                           <tr key={log.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                              <td className="px-6 py-3 text-slate-600 dark:text-slate-400">
                                 {new Date(log.createdAt).toLocaleString()}
                              </td>
                              <td className="px-6 py-3">
                                 <div className="font-medium text-slate-800 dark:text-slate-200">{log.module}</div>
                                 <div className="text-xs text-slate-500">{log.action}</div>
                              </td>
                              <td className="px-6 py-3">
                                 <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                                    log.status === 'SUCCESS' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-400' :
                                    log.status === 'FAILED' ? 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400' :
                                    'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400'
                                 }`}>
                                    {log.status}
                                 </span>
                              </td>
                              <td className="px-6 py-3 text-slate-600 dark:text-slate-400 max-w-xs truncate">
                                 {log.message}
                              </td>
                              <td className="px-6 py-3 text-right">
                                 <button
                                    onClick={() => setSelectedLog(log)}
                                    className="text-indigo-600 hover:text-indigo-800 dark:text-indigo-400 dark:hover:text-indigo-300 text-sm font-medium"
                                 >
                                    View
                                 </button>
                              </td>
                           </tr>
                        ))
                     )}
                  </tbody>
               </table>
            </div>

            <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50 flex justify-between items-center">
               <span className="text-sm text-slate-500">Page {page} of {totalPages}</span>
               <div className="flex gap-2">
                  <button
                     disabled={page === 1}
                     onClick={() => setPage(p => Math.max(1, p - 1))}
                     className="px-3 py-1 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-md disabled:opacity-50"
                  >
                     Previous
                  </button>
                  <button
                     disabled={page === totalPages || totalPages === 0}
                     onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                     className="px-3 py-1 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-md disabled:opacity-50"
                  >
                     Next
                  </button>
               </div>
            </div>
         </div>

         {selectedLog && (
            <AuditLogDetailsModal log={selectedLog} onClose={() => setSelectedLog(null)} />
         )}
      </div>
   );
}
