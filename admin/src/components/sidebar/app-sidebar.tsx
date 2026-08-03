"use client";

import { NavSecondary } from "@/components/sidebar/nav-secondary";
import { NavUser } from "@/components/sidebar/nav-user";
import { Sidebar, SidebarContent, SidebarFooter, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar";
import type { RootState } from "@/store";
import { BookOpen, Command, CreditCard, LayoutDashboard, LifeBuoy, ListChecks, Send, UserCheck2Icon, UsersIcon } from "lucide-react";
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
      {
         title: "Users",
         url: "/users",
         icon: UsersIcon,
      },
      {
         title: "Reports",
         url: "/reports",
         icon: Send, // Reusing an icon or we could import ShieldAlert
      },
      {
         title: "Questionnaire",
         url: "/questionnaire",
         icon: ListChecks,
      },
      {
         title: "Profile Verification",
         url: "/profile-verification",
         icon: UserCheck2Icon,
      },
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
      {
         title: "Subscriptions",
         url: "#",
         icon: CreditCard,
         isActive: true,
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
                        <div className="bg-sidebar-primary text-sidebar-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg">
                           <Command className="size-4" />
                        </div>
                        <div className="grid flex-1 text-left text-sm leading-tight">
                           <span className="truncate font-medium">Life Partner Again</span>
                           <span className="truncate text-xs">Admin Panel</span>
                        </div>
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
