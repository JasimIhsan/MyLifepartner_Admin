import { CheckCircle, Clock, Code, Copy, Globe, Info, Server, Shield, User } from "lucide-react";
import { useState } from "react";
import AuditTimeline from "./AuditTimeline";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";

const JSONViewer = ({ data }: { data: any }) => {
   if (!data) return <span className="text-muted-foreground italic">None</span>;
   if (typeof data !== "object") return <span>{String(data)}</span>;

   return (
      <div className="space-y-2">
         {Object.entries(data).map(([key, value]) => (
            <div key={key} className="flex flex-col sm:flex-row sm:items-start gap-1 sm:gap-4 py-1 border-b border-border/50 last:border-0">
               <span className="font-medium text-foreground min-w-30">{key}</span>
               <span className="text-muted-foreground break-all">{typeof value === "object" && value !== null ? JSON.stringify(value) : String(value)}</span>
            </div>
         ))}
      </div>
   );
};

export default function AuditLogDetailsModal({ log, onClose }: { log: any; onClose: () => void }) {
   const [showTimeline, setShowTimeline] = useState(false);

   const copyToClipboard = (text: string) => {
      navigator.clipboard.writeText(text);
   };

   const formattedDate = new Date(log.createdAt).toLocaleString(undefined, {
      dateStyle: "full",
      timeStyle: "long",
   });

   return (
      <Dialog open={true} onOpenChange={(open) => !open && onClose()}>
         <DialogContent className="min-w-4xl max-h-[90vh] flex flex-col p-0 gap-0 overflow-hidden">
            <DialogHeader className="px-6 py-4 border-b border-border">
               <DialogTitle className="flex items-center gap-2 text-xl">
                  <Info className="w-5 h-5 text-indigo-500" />
                  Audit Log Details
               </DialogTitle>
            </DialogHeader>

            <div className="flex-1 overflow-y-auto p-6 space-y-6 bg-background">
               {showTimeline ? (
                  <div>
                     <Button variant="link" onClick={() => setShowTimeline(false)} className="px-0 mb-4 text-indigo-500">
                        &larr; Back to Details
                     </Button>
                     <AuditTimeline logId={log.id} />
                  </div>
               ) : (
                  <>
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="bg-card p-4 rounded-lg border border-border">
                           <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                              <Clock className="w-4 h-4" /> Timestamp
                           </h3>
                           <p className="text-muted-foreground">{formattedDate}</p>
                        </div>

                        <div className="bg-card p-4 rounded-lg border border-border">
                           <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                              <CheckCircle className="w-4 h-4" /> Status & Severity
                           </h3>
                           <div className="flex gap-2">
                              <Badge variant={log.status === "SUCCESS" ? "default" : log.status === "FAILED" ? "destructive" : "secondary"}>{log.status}</Badge>
                              <Badge variant="outline">Severity: {log.severity}</Badge>
                           </div>
                        </div>

                        <div className="bg-card p-4 rounded-lg border border-border">
                           <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                              <User className="w-4 h-4" /> Actor
                           </h3>
                           <div className="space-y-1">
                              <p className="text-sm text-muted-foreground">
                                 Type: <span className="font-medium text-foreground">{log.actorType}</span>
                              </p>
                              {log.user && (
                                 <div className="text-sm text-muted-foreground flex flex-col mt-1 gap-1">
                                    <p>
                                       User: <span className="font-medium text-foreground">{log.user.profile?.name || "No Name"}</span>
                                    </p>
                                    <p>
                                       Email: <span className="font-medium text-foreground">{log.user.email || "No Email"}</span> (ID: {log.user.id})
                                    </p>
                                 </div>
                              )}
                              {log.admin && (
                                 <p className="text-sm text-muted-foreground">
                                    Admin:{" "}
                                    <span className="font-medium text-foreground">
                                       {log.admin.username} (ID: {log.admin.id})
                                    </span>
                                 </p>
                              )}
                              {!log.user && !log.admin && (log.userId || log.adminId) && (
                                 <p className="text-sm text-muted-foreground">
                                    ID: <span className="font-medium text-foreground">{log.userId || log.adminId}</span>
                                 </p>
                              )}
                           </div>
                        </div>

                        <div className="bg-card p-4 rounded-lg border border-border">
                           <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                              <Shield className="w-4 h-4" /> Action
                           </h3>
                           <div className="space-y-1">
                              <p className="text-sm text-muted-foreground">
                                 Module: <span className="font-medium text-foreground">{log.module}</span>
                              </p>
                              <p className="text-sm text-muted-foreground">
                                 Action: <span className="font-medium text-foreground">{log.action}</span>
                              </p>
                              <p className="text-sm text-muted-foreground">
                                 Source: <span className="font-medium text-foreground">{log.source}</span>
                              </p>
                              {log.entityType && (
                                 <p className="text-sm text-muted-foreground">
                                    Target Entity:{" "}
                                    <span className="font-medium text-foreground">
                                       {log.entityType} ({log.entityId})
                                    </span>
                                 </p>
                              )}
                           </div>
                        </div>
                     </div>

                     <div>
                        <h3 className="text-sm font-semibold text-foreground mb-2">Event Message</h3>
                        <div className="bg-card p-4 rounded-lg border border-border text-foreground text-sm wrap-break-word">{log.message}</div>
                     </div>

                     {/* Request / Network Details */}
                     {(log.ipAddress || log.userAgent || log.route) && (
                        <div>
                           <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                              <Globe className="w-4 h-4" /> Network & Request Details
                           </h3>
                           <div className="bg-card p-4 rounded-lg border border-border text-sm space-y-2">
                              {log.ipAddress && (
                                 <p className="text-muted-foreground">
                                    IP Address: <span className="text-foreground">{log.ipAddress}</span>
                                 </p>
                              )}
                              {log.userAgent && (
                                 <p className="text-muted-foreground">
                                    User Agent: <span className="text-foreground">{log.userAgent}</span>
                                 </p>
                              )}
                              {log.route && (
                                 <p className="text-muted-foreground">
                                    API Route:{" "}
                                    <span className="text-foreground font-mono">
                                       {log.method} {log.route}
                                    </span>
                                 </p>
                              )}
                              {log.statusCode && (
                                 <p className="text-muted-foreground">
                                    Status Code: <span className="text-foreground">{log.statusCode}</span>
                                 </p>
                              )}
                           </div>
                        </div>
                     )}

                     <div>
                        <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                           <Server className="w-4 h-4" /> Identifiers
                        </h3>
                        <div className="bg-card p-4 rounded-lg border border-border text-sm space-y-2">
                           {log.correlationId && (
                              <div className="flex justify-between items-center group">
                                 <span className="text-muted-foreground">
                                    Correlation ID: <span className="text-foreground font-mono">{log.correlationId}</span>
                                 </span>
                                 <Button variant="ghost" size="icon" className="h-6 w-6 opacity-0 group-hover:opacity-100" onClick={() => copyToClipboard(log.correlationId)}>
                                    <Copy className="w-3 h-3 text-muted-foreground" />
                                 </Button>
                              </div>
                           )}
                           {log.transactionId && (
                              <div className="flex justify-between items-center group">
                                 <span className="text-muted-foreground">
                                    Transaction ID: <span className="text-foreground font-mono">{log.transactionId}</span>
                                 </span>
                                 <Button variant="ghost" size="icon" className="h-6 w-6 opacity-0 group-hover:opacity-100" onClick={() => copyToClipboard(log.transactionId)}>
                                    <Copy className="w-3 h-3 text-muted-foreground" />
                                 </Button>
                              </div>
                           )}
                           {log.revenueCatEventId && (
                              <div className="flex justify-between items-center group">
                                 <span className="text-muted-foreground">
                                    RevenueCat Event: <span className="text-foreground font-mono">{log.revenueCatEventId}</span>
                                 </span>
                                 <Button variant="ghost" size="icon" className="h-6 w-6 opacity-0 group-hover:opacity-100" onClick={() => copyToClipboard(log.revenueCatEventId)}>
                                    <Copy className="w-3 h-3 text-muted-foreground" />
                                 </Button>
                              </div>
                           )}
                           {!log.correlationId && !log.transactionId && !log.revenueCatEventId && <p className="text-muted-foreground italic">No identifiers available</p>}
                        </div>
                     </div>

                     <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                           <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                              <Code className="w-4 h-4" /> Old Value
                           </h3>
                           <div className="bg-card p-4 rounded-lg border border-border text-sm max-h-80 overflow-y-auto">
                              <JSONViewer data={log.oldValue} />
                           </div>
                        </div>
                        <div>
                           <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                              <Code className="w-4 h-4" /> New Value
                           </h3>
                           <div className="bg-card p-4 rounded-lg border border-border text-sm max-h-80 overflow-y-auto">
                              <JSONViewer data={log.newValue} />
                           </div>
                        </div>
                     </div>

                     <div>
                        <h3 className="text-sm font-semibold text-foreground mb-2 flex items-center gap-2">
                           <Code className="w-4 h-4" /> Additional Metadata
                        </h3>
                        <div className="bg-card p-4 rounded-lg border border-border text-sm">
                           <JSONViewer data={log.metadata} />
                        </div>
                     </div>
                  </>
               )}
            </div>
            {!showTimeline && (log.correlationId || log.transactionId) && (
               <div className="px-6 py-4 border-t border-border bg-card flex justify-end">
                  <Button onClick={() => setShowTimeline(true)} className="bg-indigo-600 hover:bg-indigo-700 text-white">
                     View Related Timeline
                  </Button>
               </div>
            )}
         </DialogContent>
      </Dialog>
   );
}
