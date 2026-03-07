import axiosInstance from "@/api/api.config";
import { ConfirmationModal } from "@/components/confirmation-modal";
import { SidebarMenu, SidebarMenuItem } from "@/components/ui/sidebar";
import type { RootState } from "@/store";
import { logoutAction } from "@/store/authSlice";
import { useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Button } from "../ui/button";

export function NavUser() {
   const { isAuthenticated } = useSelector((state: RootState) => state.auth);
   const dispatch = useDispatch();
   const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
   const [isLoggingOut, setIsLoggingOut] = useState(false);

   const handleLogoutClick = () => {
      setIsLogoutModalOpen(true);
   };

   const handleLogoutConfirm = async () => {
      if (!isAuthenticated) return;
      setIsLoggingOut(true);
      try {
         await axiosInstance.post("/admin/auth/logout");
      } catch (err) {
         console.error("Logout failed", err);
      } finally {
         dispatch(logoutAction());
         window.location.href = "/login";
      }
   };

   return (
      <SidebarMenu>
         <SidebarMenuItem>
            <Button size="sm" className="w-full" onClick={handleLogoutClick}>
               Logout
            </Button>
            <ConfirmationModal isOpen={isLogoutModalOpen} onClose={() => setIsLogoutModalOpen(false)} onConfirm={handleLogoutConfirm} title="Logout" description="Are you sure you want to log out?" confirmText="Logout" variant="default" isLoading={isLoggingOut} />
         </SidebarMenuItem>
      </SidebarMenu>
   );
}
