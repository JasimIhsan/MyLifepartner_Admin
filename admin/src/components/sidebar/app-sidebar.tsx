"use client";

import { NavSecondary } from "@/components/sidebar/nav-secondary";
import { NavUser } from "@/components/sidebar/nav-user";
import { Sidebar, SidebarContent, SidebarFooter, SidebarHeader, SidebarMenu, SidebarMenuButton, SidebarMenuItem } from "@/components/ui/sidebar";
import type { RootState } from "@/store";
import { Command, LayoutDashboard, LifeBuoy, ListChecks, Send, UserCheck2Icon, UsersIcon } from "lucide-react";
import * as React from "react";
import { useSelector } from "react-redux";
import { NavProjects } from "./nav-projects";

const data = {
   // navMain: [
   //    {
   //       title: "Playground",
   //       url: "#",
   //       icon: SquareTerminal,
   //       isActive: true,
   //       items: [
   //          {
   //             title: "History",
   //             url: "#",
   //          },
   //          {
   //             title: "Starred",
   //             url: "#",
   //          },
   //          {
   //             title: "Settings",
   //             url: "#",
   //          },
   //       ],
   //    },
   //    {
   //       title: "Models",
   //       url: "#",
   //       icon: Bot,
   //       items: [
   //          {
   //             title: "Genesis",
   //             url: "#",
   //          },
   //          {
   //             title: "Explorer",
   //             url: "#",
   //          },
   //          {
   //             title: "Quantum",
   //             url: "#",
   //          },
   //       ],
   //    },
   //    {
   //       title: "Documentation",
   //       url: "#",
   //       icon: BookOpen,
   //       items: [
   //          {
   //             title: "Introduction",
   //             url: "#",
   //          },
   //          {
   //             title: "Get Started",
   //             url: "#",
   //          },
   //          {
   //             title: "Tutorials",
   //             url: "#",
   //          },
   //          {
   //             title: "Changelog",
   //             url: "#",
   //          },
   //       ],
   //    },
   //    {
   //       title: "Settings",
   //       url: "#",
   //       icon: Settings2,
   //       items: [
   //          {
   //             title: "General",
   //             url: "#",
   //          },
   //          {
   //             title: "Team",
   //             url: "#",
   //          },
   //          {
   //             title: "Billing",
   //             url: "#",
   //          },
   //          {
   //             title: "Limits",
   //             url: "#",
   //          },
   //       ],
   //    },
   // ],
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
   projects: [
      {
         name: "Dashboard",
         url: "/",
         icon: LayoutDashboard,
      },

      {
         name: "Users",
         url: "/users",
         icon: UsersIcon,
      },
      {
         name: "Questionnaire",
         url: "/questionnaire",
         icon: ListChecks,
      },
      {
         name: "Profile Verification",
         url: "/profile-verification",
         icon: UserCheck2Icon,
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
                           <span className="truncate font-medium">MyLifePartner</span>
                           <span className="truncate text-xs">Admin Panel</span>
                        </div>
                     </a>
                  </SidebarMenuButton>
               </SidebarMenuItem>
            </SidebarMenu>
         </SidebarHeader>
         <SidebarContent>
            {/* <NavMain items={data.navMain} /> */}
            <NavProjects projects={data.projects} />
            <NavSecondary items={visibleNavSecondary} className="mt-auto" />
         </SidebarContent>
         <SidebarFooter>
            <NavUser />
         </SidebarFooter>
      </Sidebar>
   );
}
