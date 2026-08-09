"use client";

import AppLogoLight from "@/assets/app_logo.png";
import AppLogoDark from "@/assets/app_logo_dark.png";
import { NavSecondary } from "@/components/sidebar/nav-secondary";
import { NavUser } from "@/components/sidebar/nav-user";
import { Sidebar, SidebarContent, SidebarFooter, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar";
import type { RootState } from "@/store";
import { BookOpen, Command, CreditCard, LayoutDashboard, LifeBuoy, Send, Trash2, UserCheck2Icon, UserX, UsersIcon } from "lucide-react";
import * as React from "react";
import { useSelector } from "react-redux";
import { NavMain } from "./nav-main";

const data = {
   navMain: [
      {
         title: "Dashboard",
         url: "/",
         icon: LayoutDashboard,
      },

      // User Management
      {
         title: "Users",
         url: "/users",
         icon: UsersIcon,
      },
      {
         title: "Profile Verification",
         url: "/profile-verification",
         icon: UserCheck2Icon,
      },
      {
         title: "Suspended Users",
         url: "/suspended-users",
         icon: UserX,
      },
      {
         title: "Deletion Requests",
         url: "/deletion-requests",
         icon: Trash2,
      },
      // {
      //    title: "Deleted Users Archive",
      //    url: "/deleted-users",
      //    icon: ArchiveX,
      // },

      // Trust & Safety
      {
         title: "Reports",
         url: "/reports",
         icon: Send,
      },

      // Payments & Subscriptions
      {
         title: "Subscriptions",
         url: "#",
         icon: CreditCard,
         items: [
            {
               title: "Plans",
               url: "/subscriptions/plans",
            },
            {
               title: "Features",
               url: "/subscriptions/features",
            },
         ],
      },

      // Content
      {
         title: "Image Assets",
         url: "/image-assets",
         icon: Command,
      },
      {
         title: "LPA Guide",
         url: "/lpa-guide",
         icon: BookOpen,
      },

      // System
      {
         title: "Audit Logs",
         url: "/audit-logs",
         icon: Command,
      },
   ],

   navSecondary: [
      {
         title: "Admins",
         url: "/admins",
         icon: Command,
         roles: ["SUPER_ADMIN"],
      },
      {
         title: "Support",
         url: "#",
         icon: LifeBuoy,
      },
      {
         title: "Feedback",
         url: "#",
         icon: Send,
      },
   ],
};

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
   const user = useSelector((state: RootState) => state.auth.user);

   const visibleNavSecondary = data.navSecondary.filter((item) => !item.roles || item.roles.includes(user?.role as string));

   return (
      <Sidebar variant="inset" {...props}>
         <SidebarHeader>
            <SidebarMenu>
               <SidebarMenuItem>
                  <SidebarMenuButton size="lg" asChild>
                     <a href="#">
                        <div className="flex h-8 items-center justify-center">
                           <img src={AppLogoLight} alt="App Logo" className="h-8 w-auto object-contain dark:hidden" />
                           <img src={AppLogoDark} alt="App Logo" className="hidden h-8 w-auto object-contain dark:block" />
                        </div>
                        {/* <div className="grid flex-1 text-left text-sm leading-tight">
                           <span className="truncate font-medium">Life Partner Again</span>
                           <span className="truncate text-xs">Admin Panel</span>
                        </div> */}
                     </a>
                  </SidebarMenuButton>
               </SidebarMenuItem>
            </SidebarMenu>
         </SidebarHeader>
         <SidebarContent>
            <NavMain items={data.navMain} label="Platform" />
            <NavSecondary items={visibleNavSecondary} className="mt-auto" />
         </SidebarContent>
         <SidebarFooter>
            <NavUser />
         </SidebarFooter>
      </Sidebar>
   );
}
