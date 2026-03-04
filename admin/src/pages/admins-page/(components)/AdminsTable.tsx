"use client";

import { ConfirmationModal } from "@/components/confirmation-modal";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { AdminInterface } from "@/interface/admin.interface";
import { MoreVertical, ShieldAlert, ShieldCheck } from "lucide-react";
import * as React from "react";

export function AdminsTable({ data = [], isFetching = false, currentAdminId, onAdd, onEdit, onDelete }: { data?: AdminInterface[]; isFetching?: boolean; currentAdminId?: number; onAdd?: () => void; onEdit?: (admin: AdminInterface) => void; onDelete?: (id: number) => void }) {
   const [actionModalOpen, setActionModalOpen] = React.useState(false);
   const [selectedAdmin, setSelectedAdmin] = React.useState<AdminInterface | null>(null);

   const formatDate = (date: string | Date) => {
      return new Date(date).toLocaleDateString("en-US", {
         year: "numeric",
         month: "short",
         day: "numeric",
      });
   };

   const handleActionClick = (admin: AdminInterface) => {
      setSelectedAdmin(admin);
      setActionModalOpen(true);
   };

   const handleConfirmAction = () => {
      if (!selectedAdmin) return;
      if (onDelete) {
         onDelete(selectedAdmin.id);
      }
      setActionModalOpen(false);
   };

   return (
      <div className="w-full space-y-4">
         <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex flex-1 items-center space-x-2"></div>
            <div className="flex items-center space-x-2 w-full sm:w-auto">
               <Button size="sm" className="w-full sm:w-auto" onClick={onAdd}>
                  Add Admin
               </Button>
            </div>
         </div>

         <div className="rounded-md border bg-card text-card-foreground shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
               <Table>
                  <TableHeader className="bg-muted/50">
                     <TableRow>
                        <TableHead className="w-24">ID</TableHead>
                        <TableHead>Username</TableHead>
                        <TableHead>Role</TableHead>
                        <TableHead>Joined</TableHead>
                        <TableHead className="w-12.5"></TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody className={isFetching ? "opacity-50 pointer-events-none" : ""}>
                     {data.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                              {isFetching ? "Loading..." : "No admins found."}
                           </TableCell>
                        </TableRow>
                     ) : (
                        data.map((admin) => (
                           <TableRow key={admin.id} className="group">
                              <TableCell className="font-medium">{admin.id}</TableCell>
                              <TableCell>
                                 <div className="flex flex-col">
                                    <span className="font-medium">{admin.username}</span>
                                    {admin.id === currentAdminId && <span className="text-xs text-primary font-semibold">(You)</span>}
                                 </div>
                              </TableCell>
                              <TableCell>
                                 <div className="flex items-center gap-1.5 whitespace-nowrap">
                                    {admin.role === "SUPER_ADMIN" ? <ShieldAlert className="h-4 w-4 text-primary" /> : <ShieldCheck className="h-4 w-4 text-muted-foreground" />}
                                    <span className={admin.role === "SUPER_ADMIN" ? "font-semibold text-primary" : "text-muted-foreground"}>{admin.role === "SUPER_ADMIN" ? "Super Admin" : "Admin"}</span>
                                 </div>
                              </TableCell>
                              <TableCell className="text-sm text-muted-foreground">{formatDate(admin.createdAt)}</TableCell>
                              <TableCell>
                                 <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                       <Button variant="ghost" className="h-8 w-8 p-0 opacity-0 group-hover:opacity-100 transition-opacity focus:opacity-100 data-[state=open]:opacity-100">
                                          <span className="sr-only">Open menu</span>
                                          <MoreVertical className="h-4 w-4" />
                                       </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end" className="w-40">
                                       <DropdownMenuItem onClick={() => onEdit?.(admin)}>Edit Admin</DropdownMenuItem>
                                       {admin.id !== currentAdminId && (
                                          <>
                                             <DropdownMenuSeparator />
                                             <DropdownMenuItem className="text-destructive" onClick={() => handleActionClick(admin)}>
                                                Delete Admin
                                             </DropdownMenuItem>
                                          </>
                                       )}
                                    </DropdownMenuContent>
                                 </DropdownMenu>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </div>
         </div>

         <ConfirmationModal isOpen={actionModalOpen} onClose={() => setActionModalOpen(false)} onConfirm={handleConfirmAction} title="Delete Admin" description={`Are you sure you want to delete ${selectedAdmin?.username || "this admin"}? This action cannot be undone.`} confirmText="Delete" variant="destructive" />
      </div>
   );
}
