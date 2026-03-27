import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card";
import { paiseToRupees, type SubscriptionPlan } from "@/api/subscription.service";
import { Calendar, CheckCircle2, Edit2, Settings2, Trash2, XCircle, Zap } from "lucide-react";

interface PlanCardProps {
   plan: SubscriptionPlan;
   onEdit: (plan: SubscriptionPlan) => void;
   onToggleActive: (plan: SubscriptionPlan) => void;
   onToggleMostPopular: (plan: SubscriptionPlan) => void;
   onDelete: (plan: SubscriptionPlan) => void;
   onManageFeatures: (plan: SubscriptionPlan) => void;
}

export default function PlanCard({ plan, onEdit, onToggleActive, onToggleMostPopular, onDelete, onManageFeatures }: PlanCardProps) {
   return (
      <Card
         className={`flex flex-col border shadow-sm hover:shadow-md transition-all duration-200 ${
            plan.isMostPopular ? "border-primary/50 bg-primary/5 ring-1 ring-primary/20" : ""
         }`}
      >
         <CardHeader className="pb-3">
            <div className="flex items-start justify-between">
               <div className="flex items-center gap-2">
                  <div className="bg-primary/10 p-2 rounded-lg">
                     <Zap className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                     <div className="flex items-center gap-2">
                        <h3 className="text-lg font-bold tracking-tight">{plan.name}</h3>
                        {plan.isMostPopular && (
                           <Badge variant="default" className="bg-primary text-[10px] uppercase font-bold px-1.5 py-0">
                              Popular
                           </Badge>
                        )}
                     </div>
                     <p className="text-2xl font-extrabold text-primary mt-0.5">{paiseToRupees(plan.price)}</p>
                  </div>
               </div>
               <Badge variant={plan.isActive ? "default" : "secondary"} className="shrink-0">
                  {plan.isActive ? (
                     <span className="flex items-center gap-1">
                        <CheckCircle2 className="h-3 w-3" /> Active
                     </span>
                  ) : (
                     <span className="flex items-center gap-1">
                        <XCircle className="h-3 w-3" /> Inactive
                     </span>
                  )}
               </Badge>
            </div>
         </CardHeader>

         <CardContent className="pb-4 flex-1 space-y-3">
            {/* Duration */}
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
               <Calendar className="h-4 w-4 shrink-0" />
               <span>{plan.durationDays} days</span>
            </div>

            {/* Features chip list */}
            <div className="space-y-1">
               <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                  {plan.features.length} Feature{plan.features.length !== 1 ? "s" : ""}
               </p>
               {plan.features.length > 0 ? (
                  <div className="flex flex-wrap gap-1.5">
                     {plan.features.slice(0, 5).map((f) => (
                        <Badge key={f.id} variant="outline" className="text-xs font-mono">
                           {f.featureKey}: {f.limit}
                        </Badge>
                     ))}

                     {plan.features.length > 5 && (
                        <Badge variant="outline" className="text-xs">
                           +{plan.features.length - 5} more
                        </Badge>
                     )}
                  </div>
               ) : (
                  <p className="text-xs text-muted-foreground italic">No features yet</p>
               )}
            </div>
         </CardContent>

         <CardFooter className="pt-0 flex flex-wrap gap-2">
            {/* Manage Features */}
            <Button size="sm" variant="default" className="gap-1.5 flex-1" onClick={() => onManageFeatures(plan)}>
               <Settings2 className="h-3.5 w-3.5" />
               Features
            </Button>
            {/* Edit */}
            <Button size="sm" variant="outline" className="gap-1.5" onClick={() => onEdit(plan)}>
               <Edit2 className="h-3.5 w-3.5" />
            </Button>
            {/* Toggle Most Popular */}
            <Button
               size="sm"
               variant={plan.isMostPopular ? "default" : "outline"}
               className={`gap-1.5 ${plan.isMostPopular ? "bg-orange-500 hover:bg-orange-600 border-none" : ""}`}
               onClick={() => onToggleMostPopular(plan)}
               title={plan.isMostPopular ? "Unmark as Popular" : "Mark as Popular"}
            >
               <Zap className={`h-3.5 w-3.5 ${plan.isMostPopular ? "fill-current" : ""}`} />
            </Button>
            {/* Toggle Active */}
            <Button size="sm" variant="outline" className="gap-1.5" onClick={() => onToggleActive(plan)}>
               {plan.isActive ? <XCircle className="h-3.5 w-3.5 text-orange-500" /> : <CheckCircle2 className="h-3.5 w-3.5 text-green-500" />}
            </Button>
            {/* Delete */}
            {plan.name !== "FREE" && (
               <Button size="sm" variant="outline" className="gap-1.5" onClick={() => onDelete(plan)}>
                  <Trash2 className="h-3.5 w-3.5 text-destructive" />
               </Button>
            )}
         </CardFooter>
      </Card>
   );
}
