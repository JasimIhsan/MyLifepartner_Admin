import { useEffect, useState } from "react";
import axiosInstance from "../../api/api.config";
import { ArrowRight } from "lucide-react";

export default function AuditTimeline({ logId }: { logId: number }) {
   const [timeline, setTimeline] = useState<any[]>([]);
   const [loading, setLoading] = useState(false);

   useEffect(() => {
      const fetchTimeline = async () => {
         setLoading(true);
         try {
            const response = await axiosInstance.get(`/admin/audit-logs/${logId}/timeline`);
            setTimeline(response.data.data);
         } catch (error) {
            console.error("Failed to fetch timeline", error);
         } finally {
            setLoading(false);
         }
      };
      fetchTimeline();
   }, [logId]);

   if (loading) {
      return <div className="p-8 text-center text-muted-foreground">Loading timeline...</div>;
   }

   if (timeline.length === 0) {
      return <div className="p-8 text-center text-muted-foreground">No related events found.</div>;
   }

   return (
      <div className="relative border-l border-border ml-4 py-2 space-y-6">
         {timeline.map((event) => (
            <div key={event.id} className="relative pl-6">
               <span className="absolute -left-2 top-1.5 w-4 h-4 rounded-full flex items-center justify-center bg-background ring-2 ring-border">
                  {event.status === 'SUCCESS' ? <div className="w-2 h-2 rounded-full bg-emerald-500" /> :
                   event.status === 'FAILED' ? <div className="w-2 h-2 rounded-full bg-red-500" /> :
                   <div className="w-2 h-2 rounded-full bg-amber-500" />}
               </span>
               
               <div className={`p-4 rounded-lg border ${event.id === logId ? 'border-indigo-500 bg-indigo-50 dark:bg-indigo-500/10 dark:border-indigo-500/50' : 'border-border bg-card/50'}`}>
                  <div className="flex justify-between items-start mb-2">
                     <div>
                        <span className="text-xs font-semibold text-indigo-600 dark:text-indigo-400 uppercase tracking-wider">{event.module} &rarr; {event.action}</span>
                        <p className="text-sm text-foreground font-medium mt-1">{event.message}</p>
                     </div>
                     <span className="text-xs text-muted-foreground whitespace-nowrap ml-4">
                        {new Date(event.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                     </span>
                  </div>
                  
                  {event.oldValue && event.newValue && (
                     <div className="mt-3 flex items-center gap-3 text-xs">
                        <div className="bg-background px-2 py-1 rounded border border-border text-muted-foreground">
                           {JSON.stringify(event.oldValue)}
                        </div>
                        <ArrowRight className="w-3 h-3 text-muted-foreground" />
                        <div className="bg-background px-2 py-1 rounded border border-indigo-200 dark:border-indigo-700 text-indigo-700 dark:text-indigo-300">
                           {JSON.stringify(event.newValue)}
                        </div>
                     </div>
                  )}
               </div>
            </div>
         ))}
      </div>
   );
}
