import { Fingerprint, Settings2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { getGlobalFeatures, type GlobalFeature } from "../../api/subscription.service";

export function FeaturesPage() {
   const [features, setFeatures] = useState<GlobalFeature[]>([]);
   const [loading, setLoading] = useState(true);

   useEffect(() => {
      fetchFeatures();
   }, []);

   const fetchFeatures = async () => {
      try {
         setLoading(true);
         const res = await getGlobalFeatures();
         setFeatures(res.data);
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to fetch features");
      } finally {
         setLoading(false);
      }
   };

   return (
      <div className="space-y-6">
         <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
               <h1 className="text-3xl font-bold tracking-tight">System Features</h1>
               <p className="text-muted-foreground mt-1 text-sm sm:text-base">
                  These are core capabilities defined in the application. They can be assigned to subscription plans to control user access.
               </p>
            </div>
            <div className="px-4 py-2 bg-primary/10 border border-primary/20 rounded-full text-primary text-xs font-semibold flex items-center gap-2">
               <Settings2 className="h-3.5 w-3.5" />
               Developer Controlled
            </div>
         </div>

         {loading ? (
            <div className="rounded-xl border border-border/40 overflow-hidden bg-background/50 backdrop-blur-sm shadow-sm">
               <div className="overflow-x-auto">
                  <table className="w-full text-left">
                     <thead className="bg-muted/30 border-b border-border/40 h-10">
                        <tr>
                           <th className="px-6 py-3 w-1/3"><div className="h-3 bg-muted/60 rounded w-24 animate-pulse"></div></th>
                           <th className="px-6 py-3 w-1/2"><div className="h-3 bg-muted/60 rounded w-24 animate-pulse"></div></th>
                           <th className="px-6 py-3 w-1/6 text-right"><div className="h-3 bg-muted/60 rounded w-16 ml-auto animate-pulse"></div></th>
                        </tr>
                     </thead>
                     <tbody className="divide-y divide-border/40">
                        {[1, 2, 3, 4, 5, 6, 7, 8].map((i) => (
                           <tr key={i} className="animate-pulse">
                              <td className="px-6 py-4">
                                 <div className="flex items-center gap-3">
                                    <div className="h-10 w-10 bg-muted/60 rounded-xl"></div>
                                    <div className="flex flex-col gap-2">
                                       <div className="h-4 bg-muted/60 rounded w-32"></div>
                                       <div className="h-2 bg-muted/60 rounded w-20"></div>
                                    </div>
                                 </div>
                              </td>
                              <td className="px-6 py-4"><div className="h-3 bg-muted/60 rounded w-full max-w-50"></div></td>
                              <td className="px-6 py-4 text-right"><div className="h-3 bg-muted/60 rounded w-16 ml-auto"></div></td>
                           </tr>
                        ))}
                     </tbody>
                  </table>
               </div>
            </div>
         ) : (
            <div className="rounded-xl border border-border/40 overflow-hidden bg-background/60 backdrop-blur-sm shadow-sm">
               <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                     <thead className="text-xs text-muted-foreground uppercase bg-muted/30 border-b border-border/40">
                        <tr>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider">Feature</th>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider">Description</th>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider text-right">Registry</th>
                        </tr>
                     </thead>
                     <tbody className="divide-y divide-border/40">
                        {features.map((feature) => (
                           <tr key={feature.id} className="group hover:bg-muted/20 transition-all duration-200">
                              <td className="px-6 py-4">
                                 <div className="flex items-center gap-4">
                                    <div className="p-2 sm:p-2.5 bg-linear-to-br from-primary/20 to-primary/5 border border-primary/10 rounded-xl shadow-xs transition-transform duration-500 group-hover:scale-105">
                                       <Settings2 className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                       <span className="font-semibold text-base sm:text-md text-foreground/90 group-hover:text-foreground transition-colors truncate">
                                          {feature.name}
                                       </span>
                                       <div className="flex items-center gap-1.5 mt-0.5 opacity-80">
                                          <Fingerprint className="h-3 w-3 text-primary/60" />
                                          <span className="font-mono text-[10px] sm:text-xs text-muted-foreground/80 truncate">
                                             {feature.key}
                                          </span>
                                       </div>
                                    </div>
                                 </div>
                              </td>
                              <td className="px-6 py-4 max-w-xs xl:max-w-md">
                                 <p className="text-sm text-muted-foreground/90 leading-relaxed" title={feature.description || ""}>
                                    {feature.description || "No description provided."}
                                 </p>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-right">
                                 <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-zinc-100 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700">
                                    <div className="h-1.5 w-1.5 rounded-full bg-blue-500" />
                                    <span className="text-[10px] font-bold text-zinc-600 dark:text-zinc-400 uppercase tracking-tight">System</span>
                                 </div>
                              </td>
                           </tr>
                        ))}
                     </tbody>
                  </table>
               </div>
            </div>
         )}
      </div>
   );
}

