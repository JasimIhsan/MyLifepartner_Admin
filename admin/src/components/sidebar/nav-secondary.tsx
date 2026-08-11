import { type LucideIcon } from "lucide-react";
import * as React from "react";
import { Link, useLocation } from "react-router-dom";

import {
   SidebarGroup,
   SidebarGroupContent,
   SidebarMenu,
   SidebarMenuButton,
   SidebarMenuItem,
} from "@/components/ui/sidebar";

const isPathActive = (pathname: string, url: string) => {
   if (!url.startsWith("/")) return false;
   return url === "/" ? pathname === url : pathname === url || pathname.startsWith(`${url}/`);
};

export function NavSecondary({
   items,
   ...props
}: {
   items: {
      title: string;
      url: string;
      icon: LucideIcon;
   }[];
} & React.ComponentPropsWithoutRef<typeof SidebarGroup>) {
   const { pathname } = useLocation();

   return (
      <SidebarGroup {...props}>
         <SidebarGroupContent>
            <SidebarMenu>
               {items.map((item) => {
                  const isInternalRoute = item.url.startsWith("/");

                  return (
                     <SidebarMenuItem key={item.title}>
                        <SidebarMenuButton asChild={isInternalRoute} size="sm" isActive={isPathActive(pathname, item.url)} type={isInternalRoute ? undefined : "button"}>
                           {isInternalRoute ? (
                              <Link to={item.url}>
                                 <item.icon />
                                 <span>{item.title}</span>
                              </Link>
                           ) : (
                              <>
                                 <item.icon />
                                 <span>{item.title}</span>
                              </>
                           )}
                        </SidebarMenuButton>
                     </SidebarMenuItem>
                  );
               })}
            </SidebarMenu>
         </SidebarGroupContent>
      </SidebarGroup>
   );
}
