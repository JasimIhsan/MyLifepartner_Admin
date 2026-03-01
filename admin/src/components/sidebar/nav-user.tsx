import axiosInstance from "@/api/api.config";
import { SidebarMenu, SidebarMenuItem } from "@/components/ui/sidebar";
import type { RootState } from "@/store";
import { logoutAction } from "@/store/authSlice";
import { useDispatch, useSelector } from "react-redux";
import { Button } from "../ui/button";

export function NavUser() {
   //  const { isMobile } = useSidebar();
   const { isAuthenticated } = useSelector((state: RootState) => state.auth);
   const dispatch = useDispatch();

   const handleLogout = async () => {
      if (!isAuthenticated) return;
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
            <Button size="sm" className="w-full" onClick={handleLogout}>
               Logout
            </Button>
            {/* <DropdownMenu>
               <DropdownMenuTrigger asChild>
                  <SidebarMenuButton size="lg" className="data-[state=open]:bg-sidebar-accent data-[state=open]:text-sidebar-accent-foreground">
                     <Avatar className="h-8 w-8 rounded-lg">
                        <AvatarImage src={user?.avatar} alt={user?.name} />
                        <AvatarFallback className="rounded-lg">CN</AvatarFallback>
                     </Avatar>
                     <div className="grid flex-1 text-left text-sm leading-tight">
                        <span className="truncate font-medium">{user?.name}</span>
                        <span className="truncate text-xs">{user?.email}</span>
                     </div>
                     <ChevronsUpDown className="ml-auto size-4" />
                  </SidebarMenuButton>
               </DropdownMenuTrigger>
               <DropdownMenuContent className="w-(--radix-dropdown-menu-trigger-width) min-w-56 rounded-lg" side={isMobile ? "bottom" : "right"} align="end" sideOffset={4}>
                  <DropdownMenuLabel className="p-0 font-normal">
                     <div className="flex items-center gap-2 px-1 py-1.5 text-left text-sm">
                        <Avatar className="h-8 w-8 rounded-lg">
                           <AvatarImage src={user.avatar} alt={user.name} />
                           <AvatarFallback className="rounded-lg">CN</AvatarFallback>
                        </Avatar>
                        <div className="grid flex-1 text-left text-sm leading-tight">
                           <span className="truncate font-medium">{user.name}</span>
                           <span className="truncate text-xs">{user.email}</span>
                        </div>
                     </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuGroup>
                     <DropdownMenuItem>
                        <Sparkles />
                        Upgrade to Pro
                     </DropdownMenuItem>
                  </DropdownMenuGroup>
                  <DropdownMenuSeparator />
                  <DropdownMenuGroup>
                     <DropdownMenuItem>
                        <BadgeCheck />
                        Account
                     </DropdownMenuItem>
                     <DropdownMenuItem>
                        <CreditCard />
                        Billing
                     </DropdownMenuItem>
                     <DropdownMenuItem>
                        <Bell />
                        Notifications
                     </DropdownMenuItem>
                  </DropdownMenuGroup>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem>
                     <LogOut />
                     Log out
                  </DropdownMenuItem>
               </DropdownMenuContent>
            </DropdownMenu> */}
         </SidebarMenuItem>
      </SidebarMenu>
   );
}
