import { ChevronRight, type LucideIcon } from "lucide-react";
import { Link, useLocation } from "react-router-dom";

import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import {
   SidebarGroup,
   SidebarGroupLabel,
   SidebarMenu,
   SidebarMenuAction,
   SidebarMenuButton,
   SidebarMenuItem,
   SidebarMenuSub,
   SidebarMenuSubButton,
   SidebarMenuSubItem,
} from "@/components/ui/sidebar";

const isPathActive = (pathname: string, url: string) => {
   if (!url.startsWith("/")) return false;
   return url === "/" ? pathname === url : pathname === url || pathname.startsWith(`${url}/`);
};

export function NavMain({
   items,
   label,
}: {
   items: {
      title: string;
      url: string;
      icon: LucideIcon;
      isActive?: boolean;
      items?: {
         title: string;
         url: string;
      }[];
   }[];
   label?: string;
}) {
   const { pathname } = useLocation();

   return (
      <SidebarGroup>
         {label && <SidebarGroupLabel>{label}</SidebarGroupLabel>}
         <SidebarMenu>
            {items.map((item) => {
               const subItems = item.items ?? [];
               const hasSubItems = subItems.length > 0;
               const isActive = hasSubItems ? subItems.some((subItem) => isPathActive(pathname, subItem.url)) : isPathActive(pathname, item.url);

               if (hasSubItems) {
                  return (
                     <Collapsible key={item.title} asChild defaultOpen={item.isActive ?? isActive}>
                        <SidebarMenuItem>
                           <CollapsibleTrigger asChild>
                              <SidebarMenuButton tooltip={item.title} isActive={isActive} type="button">
                                 <item.icon />
                                 <span>{item.title}</span>
                              </SidebarMenuButton>
                           </CollapsibleTrigger>
                           <CollapsibleTrigger asChild>
                              <SidebarMenuAction className="data-[state=open]:rotate-90" type="button">
                                 <ChevronRight />
                                 <span className="sr-only">Toggle</span>
                              </SidebarMenuAction>
                           </CollapsibleTrigger>
                           <CollapsibleContent>
                              <SidebarMenuSub>
                                 {subItems.map((subItem) => (
                                    <SidebarMenuSubItem key={subItem.title}>
                                       <SidebarMenuSubButton asChild isActive={isPathActive(pathname, subItem.url)}>
                                          <Link to={subItem.url}>
                                             <span>{subItem.title}</span>
                                          </Link>
                                       </SidebarMenuSubButton>
                                    </SidebarMenuSubItem>
                                 ))}
                              </SidebarMenuSub>
                           </CollapsibleContent>
                        </SidebarMenuItem>
                     </Collapsible>
                  );
               }

               return (
                  <SidebarMenuItem key={item.title}>
                     <SidebarMenuButton asChild tooltip={item.title} isActive={isActive}>
                        <Link to={item.url}>
                           <item.icon />
                           <span>{item.title}</span>
                        </Link>
                     </SidebarMenuButton>
                  </SidebarMenuItem>
               );
            })}
         </SidebarMenu>
      </SidebarGroup>
   );
}
