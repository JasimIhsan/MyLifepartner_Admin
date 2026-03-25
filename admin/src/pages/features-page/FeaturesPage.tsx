import { Edit2, Fingerprint, KeySquare, Plus, Settings2, Sparkles, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { createGlobalFeature, deleteGlobalFeature, getGlobalFeatures, updateGlobalFeature, type GlobalFeature } from "../../api/subscription.service";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ConfirmationModal } from "../../components/confirmation-modal";

export function FeaturesPage() {
   const [features, setFeatures] = useState<GlobalFeature[]>([]);
   const [loading, setLoading] = useState(true);

   // Modal states
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [editingFeature, setEditingFeature] = useState<GlobalFeature | null>(null);
   const [formData, setFormData] = useState({ key: "", name: "", description: "" });
   const [isSubmitting, setIsSubmitting] = useState(false);

   // Delete confirmation state
   const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
   const [featureToDelete, setFeatureToDelete] = useState<GlobalFeature | null>(null);

   useEffect(() => {
      fetchFeatures();
   }, []);

   const fetchFeatures = async () => {
      try {
         setLoading(true);
         const res = await getGlobalFeatures();
         setFeatures(res.data);
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to fetch features");
      } finally {
         setLoading(false);
      }
   };

   const openCreateModal = () => {
      setEditingFeature(null);
      setFormData({ key: "", name: "", description: "" });
      setIsModalOpen(true);
   };

   const openEditModal = (feature: GlobalFeature) => {
      setEditingFeature(feature);
      setFormData({ key: feature.key, name: feature.name, description: feature.description || "" });
      setIsModalOpen(true);
   };

   const handleSave = async () => {
      if (!formData.name) return toast.error("Name is required");
      if (!editingFeature && !formData.key) return toast.error("Key is required");

      try {
         setIsSubmitting(true);
         if (editingFeature) {
            await updateGlobalFeature(editingFeature.id, {
               name: formData.name,
               description: formData.description,
            });
            toast.success("Feature updated");
         } else {
            await createGlobalFeature(formData);
            toast.success("Feature created");
         }
         setIsModalOpen(false);
         fetchFeatures();
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to save feature");
      } finally {
         setIsSubmitting(false);
      }
   };

   const handleDelete = async () => {
      if (!featureToDelete) return;
      try {
         await deleteGlobalFeature(featureToDelete.id);
         toast.success("Feature deleted");
         setIsDeleteModalOpen(false);
         fetchFeatures();
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to delete feature");
      }
   };

   return (
      <div className="space-y-6">
         <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
               <h1 className="text-3xl font-bold tracking-tight">Global Features</h1>
               <p className="text-muted-foreground mt-1 text-sm sm:text-base">Define what's possible. These features act as templates that can be assigned to different subscription plans.</p>
            </div>
            <Button onClick={openCreateModal} size="lg" className="gap-2 shrink-0">
               <Plus className="h-4 w-4" /> Create Feature
            </Button>
         </div>

         {loading ? (
            <div className="rounded-xl border border-border/40 overflow-hidden bg-background/50 backdrop-blur-sm shadow-sm">
               <div className="overflow-x-auto">
                  <table className="w-full text-left">
                     <thead className="bg-muted/30 border-b border-border/40 h-10">
                        <tr>
                           <th className="px-6 py-3 w-1/3"><div className="h-3 bg-muted/60 rounded w-24 animate-pulse"></div></th>
                           <th className="px-6 py-3 w-1/3"><div className="h-3 bg-muted/60 rounded w-24 animate-pulse"></div></th>
                           <th className="px-6 py-3 w-1/6"><div className="h-3 bg-muted/60 rounded w-16 animate-pulse"></div></th>
                           <th className="px-6 py-3 w-1/6"><div className="h-3 bg-muted/60 rounded w-16 ml-auto animate-pulse"></div></th>
                        </tr>
                     </thead>
                     <tbody className="divide-y divide-border/40">
                        {[1, 2, 3, 4, 5].map((i) => (
                           <tr key={i} className="animate-pulse">
                              <td className="px-6 py-4">
                                 <div className="flex items-center gap-3">
                                    <div className="h-10 w-10 bg-muted/60 rounded-xl"></div>
                                    <div className="flex flex-col gap-2">
                                       <div className="h-4 bg-muted/60 rounded w-32"></div>
                                       <div className="h-2 bg-muted/60 rounded w-20"></div>
                                    </div>
                                 </div>
                              </td>
                              <td className="px-6 py-4"><div className="h-3 bg-muted/60 rounded w-full max-w-50"></div></td>
                              <td className="px-6 py-4"><div className="h-3 bg-muted/60 rounded w-16"></div></td>
                              <td className="px-6 py-4 flex justify-end"><div className="h-8 w-8 bg-muted/60 rounded-full"></div></td>
                           </tr>
                        ))}
                     </tbody>
                  </table>
               </div>
            </div>
         ) : features.length === 0 ? (
            <Card className="border-dashed bg-muted/20 border-border/50">
               <CardContent className="flex flex-col items-center justify-center h-64 text-center px-4">
                  <div className="bg-primary/10 p-4 rounded-full mb-4 ring-8 ring-primary/5">
                     <Sparkles className="h-8 w-8 text-primary animate-pulse" />
                  </div>
                  <h3 className="text-xl font-bold mb-2 tracking-tight">No Features Defined Yet</h3>
                  <p className="text-muted-foreground max-w-md mb-6 leading-relaxed">Start building your platform's capabilities by creating global features that can be distributed across various plans.</p>
                  <Button onClick={openCreateModal} variant="default" className="gap-2 rounded-full px-6 shadow-md hover:shadow-lg transition-all">
                     <Plus className="h-4 w-4" /> Create Your First Feature
                  </Button>
               </CardContent>
            </Card>
         ) : (
            <div className="rounded-xl border border-border/40 overflow-hidden bg-background/60 backdrop-blur-sm shadow-sm">
               <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                     <thead className="text-xs text-muted-foreground uppercase bg-muted/30 border-b border-border/40">
                        <tr>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider">Feature</th>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider">Description</th>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider">Registry</th>
                           <th scope="col" className="px-6 py-4 font-medium tracking-wider text-right">Actions</th>
                        </tr>
                     </thead>
                     <tbody className="divide-y divide-border/40">
                        {features.map((feature) => (
                           <tr key={feature.id} className="group hover:bg-muted/20 hover:shadow-sm transition-all duration-200">
                              <td className="px-6 py-4">
                                 <div className="flex items-center gap-4">
                                    <div className="p-2 sm:p-2.5 bg-linear-to-br from-primary/20 to-primary/5 border border-primary/10 rounded-xl shadow-xs transition-transform duration-500 group-hover:scale-105">
                                       <Settings2 className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
                                    </div>
                                    <div className="flex flex-col min-w-0">
                                       <span 
                                          className="font-semibold text-base sm:text-md text-foreground/90 group-hover:text-foreground transition-colors truncate"
                                          title={feature.name}
                                       >
                                          {feature.name}
                                       </span>
                                       <div className="flex items-center gap-1.5 mt-0.5 opacity-80">
                                          <Fingerprint className="h-3 w-3 text-primary/60" />
                                          <span className="font-mono text-[10px] sm:text-xs text-muted-foreground/80 truncate">
                                             {feature.key}
                                          </span>
                                       </div>
                                    </div>
                                 </div>
                              </td>
                              <td className="px-6 py-4 max-w-xs xl:max-w-md">
                                 <p className="text-sm text-muted-foreground/90 leading-relaxed truncate" title={feature.description || ""}>
                                    {feature.description ? (
                                       feature.description
                                    ) : (
                                       <span className="inline-flex items-center gap-1.5 italic opacity-60">
                                          <Sparkles className="h-3 w-3" /> No description provided.
                                       </span>
                                    )}
                                 </p>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                 <div className="flex items-center gap-1.5">
                                    <div className="h-1.5 w-1.5 rounded-full bg-emerald-500/80 animate-pulse" />
                                    <span className="text-[10px] font-medium text-muted-foreground/80 uppercase tracking-widest">Global</span>
                                 </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-right">
                                 <div className="flex items-center justify-end gap-2 opacity-100 lg:opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                                    <Button 
                                       variant="ghost" 
                                       size="icon" 
                                       className="h-8 w-8 rounded-full hover:bg-primary/10 hover:text-primary transition-colors cursor-pointer" 
                                       onClick={() => openEditModal(feature)}
                                    >
                                       <Edit2 className="h-4 w-4" />
                                       <span className="sr-only">Edit</span>
                                    </Button>
                                    <Button
                                       variant="ghost"
                                       size="icon"
                                       className="h-8 w-8 rounded-full hover:bg-destructive/15 hover:text-destructive transition-colors cursor-pointer"
                                       onClick={() => {
                                          setFeatureToDelete(feature);
                                          setIsDeleteModalOpen(true);
                                       }}
                                    >
                                       <Trash2 className="h-4 w-4" /> 
                                       <span className="sr-only">Delete</span>
                                    </Button>
                                 </div>
                              </td>
                           </tr>
                        ))}
                     </tbody>
                  </table>
               </div>
            </div>
         )}

         {/* Create / Edit Modal */}
         <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
            <DialogContent className="sm:max-w-106.25">
               <DialogHeader>
                  <DialogTitle className="flex items-center gap-2">
                     <KeySquare className="h-5 w-5 text-primary" />
                     {editingFeature ? "Edit Feature" : "Create Global Feature"}
                  </DialogTitle>
                  <DialogDescription>{editingFeature ? "Update the display name and description for this feature." : "Define a new feature that can be added to any subscription plan."}</DialogDescription>
               </DialogHeader>
               <div className="space-y-5 py-4">
                  {!editingFeature && (
                     <div className="space-y-1.5">
                        <Label className="text-sm font-semibold">
                           Action Key <span className="text-destructive">*</span>
                        </Label>
                        <Input placeholder="e.g. video_call" value={formData.key} onChange={(e) => setFormData({ ...formData, key: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "") })} className="font-mono text-sm" />
                        <p className="text-[11px] text-muted-foreground flex items-center gap-1 mt-1">Used by your backend specifically. Cannot be changed later.</p>
                     </div>
                  )}

                  <div className="space-y-1.5">
                     <Label className="text-sm font-semibold">
                        Display Name <span className="text-destructive">*</span>
                     </Label>
                     <Input placeholder="e.g. HD Video Calls" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} />
                  </div>

                  <div className="space-y-1.5">
                     <Label className="text-sm font-semibold">Description</Label>
                     <Input placeholder="e.g. Access to 1080p high definition calls" value={formData.description} onChange={(e) => setFormData({ ...formData, description: e.target.value })} />
                     <p className="text-[11px] text-muted-foreground mt-1">Optional context to display in the admin dashboard.</p>
                  </div>
               </div>
               <DialogFooter className="flex gap-2">
                  <Button variant="outline" onClick={() => setIsModalOpen(false)}>
                     Cancel
                  </Button>
                  <Button onClick={handleSave} disabled={isSubmitting} className="min-w-25">
                     {isSubmitting ? "Saving..." : "Save Feature"}
                  </Button>
               </DialogFooter>
            </DialogContent>
         </Dialog>

         {/* Delete Confirmation */}
         <ConfirmationModal
            isOpen={isDeleteModalOpen}
            onClose={() => setIsDeleteModalOpen(false)}
            onConfirm={handleDelete}
            title="Delete Feature?"
            description={`Are you sure you want to delete "${featureToDelete?.name}"? This action cannot be undone and will immediately unmap it from all associated subscription plans.`}
            confirmText="Yes, Delete Feature"
         />
      </div>
   );
}
