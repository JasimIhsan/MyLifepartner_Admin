import { useState, useEffect } from "react";
import { toast } from "sonner";
import { Plus, Edit2, Trash2 } from "lucide-react";
import {
   getGlobalFeatures,
   createGlobalFeature,
   updateGlobalFeature,
   deleteGlobalFeature,
   type GlobalFeature,
} from "../../api/subscription.service";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
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
      <div className="p-6 max-w-5xl mx-auto space-y-6">
         <div className="flex items-center justify-between">
            <div>
               <h1 className="text-3xl font-bold tracking-tight">Global Features</h1>
               <p className="text-muted-foreground mt-1">Manage all available subscription features.</p>
            </div>
            <Button onClick={openCreateModal} className="gap-2">
               <Plus className="h-4 w-4" /> Add Feature
            </Button>
         </div>

         <Card>
            <CardContent className="p-0">
               <Table>
                  <TableHeader>
                     <TableRow>
                        <TableHead>Key</TableHead>
                        <TableHead>Name</TableHead>
                        <TableHead>Description</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                     </TableRow>
                  </TableHeader>
                  <TableBody>
                     {loading ? (
                        <TableRow>
                           <TableCell colSpan={4} className="h-24 text-center">
                              Loading features...
                           </TableCell>
                        </TableRow>
                     ) : features.length === 0 ? (
                        <TableRow>
                           <TableCell colSpan={4} className="h-24 text-center text-muted-foreground">
                              No features found. Create one above.
                           </TableCell>
                        </TableRow>
                     ) : (
                        features.map((feature) => (
                           <TableRow key={feature.id}>
                              <TableCell className="font-mono text-xs">{feature.key}</TableCell>
                              <TableCell className="font-medium">{feature.name}</TableCell>
                              <TableCell className="text-muted-foreground">{feature.description || "-"}</TableCell>
                              <TableCell className="text-right">
                                 <div className="flex justify-end gap-2">
                                    <Button variant="ghost" size="icon" onClick={() => openEditModal(feature)}>
                                       <Edit2 className="h-4 w-4" />
                                       <span className="sr-only">Edit</span>
                                    </Button>
                                    <Button
                                       variant="ghost"
                                       size="icon"
                                       className="text-destructive hover:bg-destructive/10"
                                       onClick={() => {
                                          setFeatureToDelete(feature);
                                          setIsDeleteModalOpen(true);
                                       }}
                                    >
                                       <Trash2 className="h-4 w-4" />
                                       <span className="sr-only">Delete</span>
                                    </Button>
                                 </div>
                              </TableCell>
                           </TableRow>
                        ))
                     )}
                  </TableBody>
               </Table>
            </CardContent>
         </Card>

         {/* Create / Edit Modal */}
         <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
            <DialogContent>
               <DialogHeader>
                  <DialogTitle>{editingFeature ? "Edit Feature" : "Create New Feature"}</DialogTitle>
               </DialogHeader>
               <div className="space-y-4 py-4">
                  {!editingFeature && (
                     <div className="space-y-2">
                        <Label>Action Key</Label>
                        <Input
                           placeholder="e.g. video_call"
                           value={formData.key}
                           onChange={(e) => setFormData({ ...formData, key: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "") })}
                        />
                        <p className="text-xs text-muted-foreground">Used internally and for logic checks. Cannot be changed later.</p>
                     </div>
                  )}

                  <div className="space-y-2">
                     <Label>Display Name</Label>
                     <Input
                        placeholder="e.g. Video Calls"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                     />
                  </div>

                  <div className="space-y-2">
                     <Label>Description (Optional)</Label>
                     <Input
                        placeholder="e.g. Minutes allowed per month"
                        value={formData.description}
                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                     />
                  </div>
               </div>
               <DialogFooter>
                  <Button variant="outline" onClick={() => setIsModalOpen(false)}>
                     Cancel
                  </Button>
                  <Button onClick={handleSave} disabled={isSubmitting}>
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
            description={`Are you sure you want to delete "${featureToDelete?.name}"? This will immediately remove it from all plans.`}
            confirmText="Delete Feature"
         />
      </div>
   );
}
