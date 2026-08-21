import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { UserInterface } from "@/interface/user.interface";
import { useEffect, useState } from "react";

interface UserModalProps {
   isOpen: boolean;
   onClose: () => void;
   onSave: (data: Partial<UserInterface>) => void;
   user?: UserInterface | null;
}

export function UserModal({ isOpen, onClose, onSave, user }: UserModalProps) {
   const [formData, setFormData] = useState<Partial<UserInterface>>({
      name: "",
      email: "",

   });

   useEffect(() => {
      if (user) {
         setFormData({
            name: user.name || "",
            email: user.email || "",

         });
      } else {
         setFormData({
            name: "",
            email: "",

         });
      }
   }, [user, isOpen]);

   const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      const { name, value } = e.target;
      setFormData((prev) => ({ ...prev, [name]: value }));
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
                  <DialogTitle>{user ? "Edit User" : "Add User"}</DialogTitle>
                  <DialogDescription>{user ? "Make changes to the user's details below." : "Enter details for the new user."}</DialogDescription>
               </DialogHeader>
               <div className="grid gap-4 py-4">
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="name" className="text-right">
                        Name
                     </Label>
                     <Input id="name" name="name" value={formData.name || ""} onChange={handleChange} className="col-span-3" placeholder="John Doe" />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                     <Label htmlFor="email" className="text-right">
                        Email
                     </Label>
                     <Input id="email" name="email" type="email" value={formData.email || ""} onChange={handleChange} className="col-span-3" placeholder="john@example.com" />
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
