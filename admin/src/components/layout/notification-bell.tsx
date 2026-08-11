import { useState, useEffect } from "react";
import { Bell } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useNavigate } from "react-router-dom";
import axiosInstance from "@/api/api.config";

export function NotificationBell() {
   const [pendingCount, setPendingCount] = useState(0);
   const navigate = useNavigate();

   const fetchSuspendedUsers = async () => {
      try {
         const res = await axiosInstance.get("/admin/users/suspended");
         const users = res.data.data;
         
         const pendingToLift = users.filter((user: any) => {
            if (!user.suspendedAt) return false;
            const suspendDate = new Date(user.suspendedAt);
            const now = new Date();
            const diffTime = now.getTime() - suspendDate.getTime();
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
            return diffDays >= 14;
         }).length;
         
         setPendingCount(pendingToLift);
      } catch (error) {
         console.error("Failed to fetch suspended users for notification", error);
      }
   };

   useEffect(() => {
      fetchSuspendedUsers();
      
      const interval = setInterval(() => {
         fetchSuspendedUsers();
      }, 5 * 60 * 1000); // Polling every 5 minutes
      
      return () => clearInterval(interval);
   }, []);

   return (
      <DropdownMenu>
         <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="relative">
               <Bell className="h-5 w-5" />
               {pendingCount > 0 && (
                  <span className="absolute top-0 right-0 inline-flex items-center justify-center px-1.5 py-0.5 text-xs font-bold leading-none text-white transform translate-x-1/4 -translate-y-1/4 bg-red-600 rounded-full">
                     {pendingCount}
                  </span>
               )}
            </Button>
         </DropdownMenuTrigger>
         <DropdownMenuContent align="end" className="w-64">
            {pendingCount > 0 ? (
               <DropdownMenuItem className="cursor-pointer" onClick={() => navigate("/suspended-users")}>
                  You have {pendingCount} user{pendingCount > 1 ? "s" : ""} whose temporary suspension is ready to be lifted.
               </DropdownMenuItem>
            ) : (
               <DropdownMenuItem disabled>
                  No new notifications
               </DropdownMenuItem>
            )}
         </DropdownMenuContent>
      </DropdownMenu>
   );
}
