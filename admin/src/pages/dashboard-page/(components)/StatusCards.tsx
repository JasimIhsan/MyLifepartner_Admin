import { Badge } from "@/components/ui/badge";
import { Card, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { TrendingDown, TrendingUp } from "lucide-react";

export function StatusCards() {
   return (
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
         {/* ────────────────────────────────────────────── */}
         <Card className="@container/card min-h-35 flex flex-col">
            <CardHeader className="flex-1 pb-2">
               <CardDescription>Total Revenue</CardDescription>
               <div className="mt-1 flex items-center justify-between gap-3">
                  <CardTitle className="text-2xl font-semibold tabular-nums @xs/card:text-3xl @sm/card:text-4xl">$1,250.00</CardTitle>
                  <Badge variant="outline" className="@xs/card:text-sm text-xs gap-1">
                     <TrendingUp className="size-3.5" />
                     +12.5%
                  </Badge>
               </div>
            </CardHeader>

            <CardFooter className="pt-1 text-xs @xs/card:text-sm flex-col items-start gap-1 text-muted-foreground">
               <div className="flex items-center gap-1.5 font-medium text-foreground">
                  Trending up this month
                  <TrendingUp className="size-3.5" />
               </div>
               <div>Visitors for the last 6 months</div>
            </CardFooter>
         </Card>

         {/* ────────────────────────────────────────────── */}
         <Card className="@container/card min-h-35 flex flex-col">
            <CardHeader className="flex-1 pb-2">
               <CardDescription>New Customers</CardDescription>
               <div className="mt-1 flex items-center justify-between gap-3">
                  <CardTitle className="text-2xl font-semibold tabular-nums @xs/card:text-3xl @sm/card:text-4xl">1,234</CardTitle>
                  <Badge variant="outline" className="@xs/card:text-sm text-xs gap-1 text-destructive">
                     <TrendingDown className="size-3.5" />
                     -20%
                  </Badge>
               </div>
            </CardHeader>

            <CardFooter className="pt-1 text-xs @xs/card:text-sm flex-col items-start gap-1 text-muted-foreground">
               <div className="flex items-center gap-1.5 font-medium text-destructive">
                  Down 20% this period
                  <TrendingDown className="size-3.5" />
               </div>
               <div>Acquisition needs attention</div>
            </CardFooter>
         </Card>

         {/* ────────────────────────────────────────────── */}
         <Card className="@container/card min-h-35 flex flex-col">
            <CardHeader className="flex-1 pb-2">
               <CardDescription>Active Accounts</CardDescription>
               <div className="mt-1 flex items-center justify-between gap-3">
                  <CardTitle className="text-2xl font-semibold tabular-nums @xs/card:text-3xl @sm/card:text-4xl">45,678</CardTitle>
                  <Badge variant="outline" className="@xs/card:text-sm text-xs gap-1">
                     <TrendingUp className="size-3.5" />
                     +12.5%
                  </Badge>
               </div>
            </CardHeader>

            <CardFooter className="pt-1 text-xs @xs/card:text-sm flex-col items-start gap-1 text-muted-foreground">
               <div className="flex items-center gap-1.5 font-medium text-foreground">
                  Strong user retention
                  <TrendingUp className="size-3.5" />
               </div>
               <div>Engagement exceed targets</div>
            </CardFooter>
         </Card>

         {/* ────────────────────────────────────────────── */}
         <Card className="@container/card min-h-35 flex flex-col">
            <CardHeader className="flex-1 pb-2">
               <CardDescription>Growth Rate</CardDescription>
               <div className="mt-1 flex items-center justify-between gap-3">
                  <CardTitle className="text-2xl font-semibold tabular-nums @xs/card:text-3xl @sm/card:text-4xl">4.5%</CardTitle>
                  <Badge variant="outline" className="@xs/card:text-sm text-xs gap-1">
                     <TrendingUp className="size-3.5" />
                     +4.5%
                  </Badge>
               </div>
            </CardHeader>

            <CardFooter className="pt-1 text-xs @xs/card:text-sm flex-col items-start gap-1 text-muted-foreground">
               <div className="flex items-center gap-1.5 font-medium text-foreground">
                  Steady performance increase
                  <TrendingUp className="size-3.5" />
               </div>
               <div>Meets growth projections</div>
            </CardFooter>
         </Card>
      </div>
   );
}
