import { AppSidebar } from "@/components/sidebar/app-sidebar";
import { ThemeToggle } from "@/components/theme-toggle";
import { Separator } from "@/components/ui/separator";
import { SidebarInset, SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { Outlet } from "react-router-dom";

export function AdminLayout() {
   return (
      <SidebarProvider>
         <AppSidebar />
         <SidebarInset>
            <header className="flex h-16 shrink-0 items-center justify-between border-b px-4">
               <div className="flex items-center gap-2">
                  <SidebarTrigger className="-ml-1" />
                  <Separator orientation="vertical" className="mr-2 h-4" />
               </div>
               <ThemeToggle />
            </header>
            <main className="flex flex-1 flex-col gap-4 p-4">
               <Outlet />
            </main>
         </SidebarInset>
      </SidebarProvider>
   );
}
