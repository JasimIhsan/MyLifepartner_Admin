import axiosInstance from "@/api/api.config";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Plus, Eye } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { ConfirmationModal } from "@/components/confirmation-modal";

export interface LegalDocument {
   id: number;
   type: "TERMS" | "PRIVACY_POLICY" | "CONSENT";
   title: string;
   content: string;
   version: string;
   status: "DRAFT" | "PUBLISHED";
   publishedAt?: string;
   createdAt: string;
   updatedAt: string;
}

export default function LegalDocumentsPage() {
   const [documents, setDocuments] = useState<LegalDocument[]>([]);
   const [isLoading, setIsLoading] = useState(true);
   const [typeFilter, setTypeFilter] = useState<string>("ALL");
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [isPublishingId, setIsPublishingId] = useState<number | null>(null);
   const [publishTargetId, setPublishTargetId] = useState<number | null>(null);
   const [viewDocument, setViewDocument] = useState<LegalDocument | null>(null);

   const [formData, setFormData] = useState<{
      id?: number;
      type: string;
      title: string;
      content: string;
      version: string;
   }>({ type: "TERMS", title: "", content: "", version: "" });

   const fetchDocuments = async () => {
      setIsLoading(true);
      try {
         const url = typeFilter === "ALL" ? "/admin/legal-documents" : `/admin/legal-documents?type=${typeFilter}`;
         const response = await axiosInstance.get(url);
         setDocuments(response.data.data);
      } catch (error) {
         toast.error("Failed to fetch legal documents");
      } finally {
         setIsLoading(false);
      }
   };

   useEffect(() => {
      fetchDocuments();
   }, [typeFilter]);

   const handleSaveDraft = async () => {
      try {
         if (!formData.title || !formData.content || !formData.version) {
            toast.error("Please fill all required fields");
            return;
         }

         if (formData.id) {
            await axiosInstance.put(`/admin/legal-documents/${formData.id}`, formData);
            toast.success("Draft updated successfully");
         } else {
            await axiosInstance.post("/admin/legal-documents", formData);
            toast.success("New draft created successfully");
         }

         setIsModalOpen(false);
         fetchDocuments();
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to save document");
      }
   };

   const confirmPublish = async () => {
      if (!publishTargetId) return;
      const id = publishTargetId;
      setIsPublishingId(id);
      try {
         await axiosInstance.post(`/admin/legal-documents/${id}/publish`);
         toast.success("Document published successfully");
         fetchDocuments();
         setPublishTargetId(null);
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to publish document");
      } finally {
         setIsPublishingId(null);
      }
   };

   const openModal = (doc?: LegalDocument) => {
      if (doc) {
         if (doc.status === "PUBLISHED") {
            toast.error("Cannot edit a published document. Create a new draft instead.");
            return;
         }
         setFormData({
            id: doc.id,
            type: doc.type,
            title: doc.title,
            content: doc.content,
            version: doc.version,
         });
      } else {
         setFormData({ type: typeFilter !== "ALL" ? typeFilter : "TERMS", title: "", content: "", version: "" });
      }
      setIsModalOpen(true);
   };

   return (
      <div className="space-y-6">
         <div className="flex items-center justify-between">
            <div>
               <h1 className="text-3xl font-bold tracking-tight">Legal Documents</h1>
               <p className="text-muted-foreground">Manage Terms, Privacy Policy, and other legal documents.</p>
            </div>
            <Button onClick={() => openModal()}>
               <Plus className="mr-2 h-4 w-4" /> Add Document
            </Button>
         </div>

         <div className="flex gap-4">
            <Select value={typeFilter} onValueChange={setTypeFilter}>
               <SelectTrigger className="w-50">
                  <SelectValue placeholder="Filter by type" />
               </SelectTrigger>
               <SelectContent>
                  <SelectItem value="ALL">All Types</SelectItem>
                  <SelectItem value="TERMS">Terms & Conditions</SelectItem>
                  <SelectItem value="PRIVACY_POLICY">Privacy Policy</SelectItem>
               </SelectContent>
            </Select>
         </div>

         <div className="rounded-md border">
            <Table>
               <TableHeader>
                  <TableRow>
                     <TableHead>Type</TableHead>
                     <TableHead>Title</TableHead>
                     <TableHead>Version</TableHead>
                     <TableHead>Status</TableHead>
                     <TableHead>Updated At</TableHead>
                     <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody>
                  {isLoading ? (
                     <TableRow>
                        <TableCell colSpan={6} className="text-center">
                           Loading...
                        </TableCell>
                     </TableRow>
                  ) : documents.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={6} className="text-center">
                           No documents found.
                        </TableCell>
                     </TableRow>
                  ) : (
                     documents.map((doc) => (
                        <TableRow key={doc.id}>
                           <TableCell className="font-medium">{doc.type}</TableCell>
                           <TableCell>{doc.title}</TableCell>
                           <TableCell>{doc.version}</TableCell>
                           <TableCell>
                              <Badge variant={doc.status === "PUBLISHED" ? "default" : "secondary"}>{doc.status}</Badge>
                           </TableCell>
                           <TableCell>{new Date(doc.updatedAt).toLocaleDateString()}</TableCell>
                           <TableCell className="text-right">
                                 <div className="flex justify-end gap-2">
                                    <Button variant="secondary" size="sm" onClick={() => setViewDocument(doc)}>
                                       <Eye className="mr-2 h-4 w-4" /> View
                                    </Button>
                                    {doc.status === "DRAFT" && (
                                       <>
                                          <Button variant="outline" size="sm" onClick={() => openModal(doc)}>
                                             Edit
                                          </Button>
                                          <Button size="sm" onClick={() => setPublishTargetId(doc.id)} disabled={isPublishingId === doc.id}>
                                             {isPublishingId === doc.id ? "Publishing..." : "Publish"}
                                          </Button>
                                       </>
                                    )}
                                 </div>
                           </TableCell>
                        </TableRow>
                     ))
                  )}
               </TableBody>
            </Table>
         </div>

         <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
            <DialogContent className="sm:max-w-150">
               <DialogHeader>
                  <DialogTitle>{formData.id ? "Edit Draft" : "Create New Document"}</DialogTitle>
                  <DialogDescription>Create a draft version of a legal document. You can publish it later.</DialogDescription>
               </DialogHeader>
               <div className="grid gap-4 py-4 max-h-[60vh] overflow-y-auto px-1">
                  <div className="grid gap-2">
                     <label className="text-sm font-medium">Type</label>
                     <Select value={formData.type} onValueChange={(val) => setFormData({ ...formData, type: val })} disabled={!!formData.id}>
                        <SelectTrigger>
                           <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                           <SelectItem value="TERMS">Terms & Conditions</SelectItem>
                           <SelectItem value="PRIVACY_POLICY">Privacy Policy</SelectItem>
                        </SelectContent>
                     </Select>
                  </div>
                  <div className="grid gap-2">
                     <label className="text-sm font-medium">Title</label>
                     <Input placeholder="e.g. Terms and Conditions v1" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} />
                  </div>
                  <div className="grid gap-2">
                     <label className="text-sm font-medium">Version</label>
                     <Input placeholder="e.g. 1.0.0" value={formData.version} onChange={(e) => setFormData({ ...formData, version: e.target.value })} />
                  </div>
                  <div className="grid gap-2">
                     <label className="text-sm font-medium">Content (Markdown supported)</label>
                     <Tabs defaultValue="edit" className="w-full">
                        <TabsList className="grid w-full grid-cols-2 mb-2">
                           <TabsTrigger value="edit">Edit</TabsTrigger>
                           <TabsTrigger value="preview">Preview</TabsTrigger>
                        </TabsList>
                        <TabsContent value="edit">
                           <Textarea placeholder="Enter the full text in markdown here..." className="min-h-[300px]" value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} />
                        </TabsContent>
                        <TabsContent value="preview" className="border rounded-md p-4 min-h-[300px] max-h-[500px] overflow-y-auto bg-background">
                           <div className="markdown-preview">
                              {formData.content ? (
                                 <ReactMarkdown remarkPlugins={[remarkGfm]}>{formData.content}</ReactMarkdown>
                              ) : (
                                 <p className="text-muted-foreground italic">Nothing to preview...</p>
                              )}
                           </div>
                        </TabsContent>
                     </Tabs>
                  </div>
               </div>
               <DialogFooter>
                  <Button variant="outline" onClick={() => setIsModalOpen(false)}>
                     Cancel
                  </Button>
                  <Button onClick={handleSaveDraft}>Save Draft</Button>
               </DialogFooter>
            </DialogContent>
         </Dialog>

         <Dialog open={viewDocument !== null} onOpenChange={(open) => !open && setViewDocument(null)}>
            <DialogContent className="sm:max-w-3xl max-h-[85vh] flex flex-col">
               <DialogHeader>
                  <DialogTitle>{viewDocument?.title}</DialogTitle>
                  <DialogDescription>
                     Version {viewDocument?.version} • {viewDocument?.status}
                  </DialogDescription>
               </DialogHeader>
               <div className="flex-1 overflow-y-auto pr-2 py-4 border-t border-b">
                  <div className="markdown-preview">
                     <ReactMarkdown remarkPlugins={[remarkGfm]}>{viewDocument?.content || ""}</ReactMarkdown>
                  </div>
               </div>
               <DialogFooter>
                  <Button onClick={() => setViewDocument(null)}>Close</Button>
               </DialogFooter>
            </DialogContent>
         </Dialog>

         <ConfirmationModal
            isOpen={publishTargetId !== null}
            onClose={() => setPublishTargetId(null)}
            onConfirm={confirmPublish}
            title="Publish Document"
            description="Are you sure you want to publish this version? This will replace the currently published version."
            confirmText="Publish"
            isLoading={isPublishingId !== null}
         />
      </div>
   );
}
