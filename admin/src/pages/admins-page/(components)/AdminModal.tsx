import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { AdminInterface } from "@/interface/admin.interface";
import { useEffect, useState } from "react";

interface AdminModalProps {
   isOpen: boolean;
   onClose: () => void;
   onSave: (data: Partial<AdminInterface> & { password?: string }) => void;
   adminUser?: AdminInterface | null;
}

export function AdminModal({ isOpen, onClose, onSave, adminUser }: AdminModalProps) {
   const [formData, setFormData] = useState<Partial<AdminInterface> & { password?: string }>({
      username: "",
      password: "",
      role: "ADMIN",
   });

   useEffect(() => {
      if (adminUser) {
         setFormData({
            username: adminUser.username || "",
            role: adminUser.role || "ADMIN",
            password: "", // Keep empty, only fill if changing
         });
      } else {
         setFormData({
            username: "",
            password: "",
            role: "ADMIN",
         });
      }
   }, [adminUser, isOpen]);

   const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const { name, value } = e.target;
      setFormData((prev) => ({ ...prev, [name]: value }));
   };

   const handleRoleChange = (val: "ADMIN" | "SUPER_ADMIN") => {
      setFormData((prev) => ({ ...prev, role: val }));
   };

   const handleSubmit = (e: React.FormEvent) => {
      e.preventDefault();
      onSave(formData);
   };

   return (
      <Dialog open={isOpen} onOpenChange={onClose}>
         <DialogContent className="sm:max-w-106.25">
            <form onSubmit={handleSubmit}>
               <DialogHeader>
                  <DialogTitle>{adminUser ? "Edit Admin" : "Add Admin"}</DialogTitle>
                  <DialogDescription>{adminUser ? "Make changes to the admin account." : "Create a new admin account."}</DialogDescription>
               </DialogHeader>
               <div className="grid gap-4 py-4">
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="username" className="text-right">
                        Username
                     </Label>
                     <Input id="username" name="username" value={formData.username || ""} onChange={handleChange} className="col-span-3" placeholder="admin123" required />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="password" className="text-right">
                        Password
                     </Label>
                     <Input id="password" name="password" type="password" value={formData.password || ""} onChange={handleChange} className="col-span-3" placeholder={adminUser ? "Leave blank to keep same" : "securepassword"} required={!adminUser} />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="role" className="text-right">
                        Role
                     </Label>
                     <div className="col-span-3">
                        <Select value={formData.role} onValueChange={handleRoleChange}>
                           <SelectTrigger>
                              <SelectValue placeholder="Select a role" />
                           </SelectTrigger>
                           <SelectContent>
                              <SelectItem value="ADMIN">Admin</SelectItem>
                              <SelectItem value="SUPER_ADMIN">Super Admin</SelectItem>
                           </SelectContent>
                        </Select>
                     </div>
                  </div>
               </div>
               <DialogFooter>
                  <Button type="button" variant="outline" onClick={onClose}>
                     Cancel
                  </Button>
                  <Button type="submit">Save changes</Button>
               </DialogFooter>
            </form>
         </DialogContent>
      </Dialog>
   );
}
