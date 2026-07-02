import axiosInstance from "@/api/api.config";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ChevronDown, ChevronRight, MoreVertical, Plus, X } from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";

export interface Guide {
   id: number;
   question: string;
   answer: string;
   categoryId: number; // 1 = About LPA, 2 = Safety & Privacy, 3 = Account & Trust, 4 = Membership
   bullets: string[];
   createdAt: string;
   updatedAt: string;
}

const CATEGORIES = [
   { id: 1, name: "About LPA" },
   { id: 2, name: "Safety & Privacy" },
   { id: 3, name: "Account & Trust" },
   { id: 4, name: "Membership" },
];

const LpaGuidePage = () => {
   const [guides, setGuides] = useState<Guide[]>([]);
   const [isFetching, setIsFetching] = useState(true);
   const [isModalOpen, setIsModalOpen] = useState(false);
   const [selectedGuide, setSelectedGuide] = useState<Guide | null>(null);

   // Custom Delete Confirmation Modal state
   const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
   const [guideToDelete, setGuideToDelete] = useState<Guide | null>(null);

   // Collapsible Row state
   const [expandedRowIds, setExpandedRowIds] = useState<Set<number>>(new Set());

   // Pagination & Filter state
   const [page, setPage] = useState(1);
   const [limit, setLimit] = useState(10);
   const [totalGuides, setTotalGuides] = useState(0);
   const [categoryFilter, setCategoryFilter] = useState<string>("ALL");
   const [searchQuery, setSearchQuery] = useState("");

   // Form states
   const [question, setQuestion] = useState("");
   const [answer, setAnswer] = useState("");
   const [categoryId, setCategoryId] = useState("1");
   const [bullets, setBullets] = useState<string[]>([]);
   const [newBulletText, setNewBulletText] = useState("");

   const fetchGuides = useCallback(async () => {
      setIsFetching(true);
      try {
         const response = await axiosInstance.get("/admin/guides", {
            params: {
               page,
               limit,
               categoryId: categoryFilter !== "ALL" ? parseInt(categoryFilter) : undefined,
               search: searchQuery.trim() || undefined,
            },
         });
         setGuides(response.data.data.guides || []);
         setTotalGuides(response.data.data.total || 0);
      } catch (error) {
         console.error("Error fetching guides:", error);
         toast.error("Failed to fetch guide questions");
      } finally {
         setIsFetching(false);
      }
   }, [page, limit, categoryFilter, searchQuery]);

   useEffect(() => {
      const delayDebounceFn = setTimeout(() => {
         fetchGuides();
      }, 300);

      return () => clearTimeout(delayDebounceFn);
   }, [fetchGuides]);

   // Reset page to 1 on filter changes
   const handleCategoryChange = (val: string) => {
      setCategoryFilter(val);
      setPage(1);
   };

   const handleSearchChange = (val: string) => {
      setSearchQuery(val);
      setPage(1);
   };

   // Toggle expanded rows
   const toggleRowExpand = (id: number) => {
      setExpandedRowIds((prev) => {
         const next = new Set(prev);
         if (next.has(id)) {
            next.delete(id);
         } else {
            next.add(id);
         }
         return next;
      });
   };

   // Open modal for add
   const handleAddGuide = () => {
      setSelectedGuide(null);
      setQuestion("");
      setAnswer("");
      setCategoryId("1");
      setBullets([]);
      setNewBulletText("");
      setIsModalOpen(true);
   };

   // Open modal for edit
   const handleEditGuide = (guide: Guide) => {
      setSelectedGuide(guide);
      setQuestion(guide.question);
      setAnswer(guide.answer);
      setCategoryId(guide.categoryId.toString());
      setBullets(guide.bullets || []);
      setNewBulletText("");
      setIsModalOpen(true);
   };

   // Delete guide prompt
   const promptDeleteGuide = (guide: Guide) => {
      setGuideToDelete(guide);
      setIsDeleteModalOpen(true);
   };

   // Delete guide confirmed
   const confirmDeleteGuide = async () => {
      if (!guideToDelete) return;
      try {
         await axiosInstance.delete(`/admin/guides/${guideToDelete.id}`);
         toast.success("Guide question deleted successfully");
         setIsDeleteModalOpen(false);
         setGuideToDelete(null);
         fetchGuides();
      } catch (error) {
         console.error("Error deleting guide:", error);
         toast.error("Failed to delete guide question");
      }
   };

   // Add bullet to list
   const handleAddBullet = () => {
      const trimmed = newBulletText.trim();
      if (!trimmed) return;
      setBullets([...bullets, trimmed]);
      setNewBulletText("");
   };

   // Remove bullet from list
   const handleRemoveBullet = (index: number) => {
      const updated = bullets.filter((_, idx) => idx !== index);
      setBullets(updated);
   };

   // Save / update guide
   const handleSaveGuide = async (e: React.FormEvent) => {
      e.preventDefault();
      if (!question.trim() || !answer.trim()) {
         toast.error("Question and Answer are required");
         return;
      }

      const payload = {
         question: question.trim(),
         answer: answer.trim(),
         categoryId: parseInt(categoryId),
         bullets,
      };

      try {
         if (selectedGuide) {
            await axiosInstance.put(`/admin/guides/${selectedGuide.id}`, payload);
            toast.success("Guide question updated successfully");
         } else {
            await axiosInstance.post("/admin/guides", payload);
            toast.success("Guide question created successfully");
         }
         setIsModalOpen(false);
         fetchGuides();
      } catch (error: any) {
         console.error("Error saving guide:", error);
         const errMsg = error.response?.data?.message || "Failed to save guide question";
         toast.error(errMsg);
      }
   };

   const totalPages = Math.ceil(totalGuides / limit) || 1;

   return (
      <div className="space-y-6 flex flex-col w-full">
         <div className="flex items-center justify-between">
            <div>
               <h1 className="text-2xl font-bold tracking-tight">LPA Guide Management</h1>
               <p className="text-muted-foreground">Manage the Life Partner Again onboarding, safety, account, and membership guide questions.</p>
            </div>
            <Button onClick={handleAddGuide}>
               <Plus className="mr-2 h-4 w-4" />
               Add Guide Q&A
            </Button>
         </div>

         {/* Filters and search */}
         <div className="flex items-center gap-4">
            <Input placeholder="Search by keyword..." value={searchQuery} onChange={(e) => handleSearchChange(e.target.value)} className="max-w-xs" />
            <Select value={categoryFilter} onValueChange={handleCategoryChange}>
               <SelectTrigger className="w-48">
                  <SelectValue placeholder="All Categories" />
               </SelectTrigger>
               <SelectContent>
                  <SelectItem value="ALL">All Categories</SelectItem>
                  {CATEGORIES.map((c) => (
                     <SelectItem key={c.id} value={c.id.toString()}>
                        {c.name}
                     </SelectItem>
                  ))}
               </SelectContent>
            </Select>
            {(categoryFilter !== "ALL" || searchQuery) && (
               <Button
                  variant="ghost"
                  onClick={() => {
                     setCategoryFilter("ALL");
                     setSearchQuery("");
                     setPage(1);
                  }}
               >
                  Clear filters
               </Button>
            )}
         </div>

         {/* Guides Table */}
         <div className="rounded-md border bg-card">
            <Table>
               <TableHeader>
                  <TableRow>
                     <TableHead className="w-45">Category</TableHead>
                     <TableHead>Question</TableHead>
                     <TableHead className="w-50">Bullets Count</TableHead>
                     <TableHead className="w-20 text-right">Actions</TableHead>
                  </TableRow>
               </TableHeader>
               <TableBody>
                  {isFetching ? (
                     <TableRow>
                        <TableCell colSpan={4} className="h-24 text-center">
                           Loading guide questions...
                        </TableCell>
                     </TableRow>
                  ) : guides.length === 0 ? (
                     <TableRow>
                        <TableCell colSpan={4} className="h-24 text-center text-muted-foreground">
                           No guide questions found.
                        </TableCell>
                     </TableRow>
                  ) : (
                     guides.map((guide) => {
                        const cat = CATEGORIES.find((c) => c.id === guide.categoryId);
                        const isExpanded = expandedRowIds.has(guide.id);
                        return (
                           <React.Fragment key={guide.id}>
                              {/* Main Row */}
                              <TableRow onClick={() => toggleRowExpand(guide.id)} className="cursor-pointer hover:bg-muted/50 transition-colors">
                                 <TableCell>
                                    <Badge variant="secondary">{cat?.name || `Category ${guide.categoryId}`}</Badge>
                                 </TableCell>
                                 <TableCell className="font-medium max-w-md truncate">
                                    <div className="flex items-center gap-2">
                                       {isExpanded ? <ChevronDown className="h-4 w-4 text-primary shrink-0" /> : <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0" />}
                                       <span>{guide.question}</span>
                                    </div>
                                 </TableCell>
                                 <TableCell>{guide.bullets?.length || 0} bullets</TableCell>
                                 <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                                    <DropdownMenu>
                                       <DropdownMenuTrigger asChild>
                                          <Button variant="ghost" className="h-8 w-8 p-0">
                                             <MoreVertical className="h-4 w-4" />
                                          </Button>
                                       </DropdownMenuTrigger>
                                       <DropdownMenuContent align="end">
                                          <DropdownMenuItem onClick={() => handleEditGuide(guide)}>Edit</DropdownMenuItem>
                                          <DropdownMenuItem className="text-destructive" onClick={() => promptDeleteGuide(guide)}>
                                             Delete
                                          </DropdownMenuItem>
                                       </DropdownMenuContent>
                                    </DropdownMenu>
                                 </TableCell>
                              </TableRow>

                              {/* Expanded Row Detail */}
                              {isExpanded && (
                                 <TableRow className="bg-muted/10 hover:bg-muted/10 border-b">
                                    <TableCell colSpan={4} className="py-4 pl-12 pr-6">
                                       <div className="border-l-2 border-primary pl-4 space-y-3">
                                          <div>
                                             <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-1">Answer</h4>
                                             <p className="text-sm text-foreground whitespace-pre-wrap leading-relaxed">{guide.answer}</p>
                                          </div>
                                          {guide.bullets && guide.bullets.length > 0 && (
                                             <div>
                                                <h4 className="text-xs font-bold uppercase tracking-wider text-muted-foreground mb-1.5">Bullets</h4>
                                                <ul className="list-disc pl-5 space-y-1 text-sm text-muted-foreground">
                                                   {guide.bullets.map((bullet, idx) => (
                                                      <li key={idx}>{bullet}</li>
                                                   ))}
                                                </ul>
                                             </div>
                                          )}
                                       </div>
                                    </TableCell>
                                 </TableRow>
                              )}
                           </React.Fragment>
                        );
                     })
                  )}
               </TableBody>
            </Table>
         </div>

         {/* Pagination Controls */}
         {totalGuides > 0 && (
            <div className="flex items-center justify-between mt-4">
               <div className="text-sm text-muted-foreground">
                  Showing {Math.min((page - 1) * limit + 1, totalGuides)} to {Math.min(page * limit, totalGuides)} of {totalGuides} questions
               </div>
               <div className="flex items-center gap-2">
                  <Button variant="outline" size="sm" onClick={() => setPage((p) => Math.max(p - 1, 1))} disabled={page === 1}>
                     Previous
                  </Button>
                  <div className="text-sm font-medium px-2">
                     Page {page} of {totalPages}
                  </div>
                  <Button variant="outline" size="sm" onClick={() => setPage((p) => Math.min(p + 1, totalPages))} disabled={page >= totalPages}>
                     Next
                  </Button>
                  <Select
                     value={limit.toString()}
                     onValueChange={(val) => {
                        setLimit(parseInt(val));
                        setPage(1);
                     }}
                  >
                     <SelectTrigger className="w-20">
                        <SelectValue placeholder="10" />
                     </SelectTrigger>
                     <SelectContent>
                        <SelectItem value="5">5</SelectItem>
                        <SelectItem value="10">10</SelectItem>
                        <SelectItem value="20">20</SelectItem>
                        <SelectItem value="50">50</SelectItem>
                     </SelectContent>
                  </Select>
               </div>
            </div>
         )}

         {/* Create/Edit Modal Dialog */}
         <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
            <DialogContent className="max-w-xl max-h-[85vh] overflow-y-auto">
               <form onSubmit={handleSaveGuide}>
                  <DialogHeader>
                     <DialogTitle>{selectedGuide ? "Edit Guide Question" : "Add Guide Question"}</DialogTitle>
                     <DialogDescription>Create or edit help topic guide questions displayed in the mobile app.</DialogDescription>
                  </DialogHeader>

                  <div className="space-y-4 py-4">
                     <div className="space-y-2">
                        <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Category</label>
                        <Select value={categoryId} onValueChange={setCategoryId}>
                           <SelectTrigger>
                              <SelectValue placeholder="Select category" />
                           </SelectTrigger>
                           <SelectContent>
                              {CATEGORIES.map((c) => (
                                 <SelectItem key={c.id} value={c.id.toString()}>
                                    {c.name}
                                 </SelectItem>
                              ))}
                           </SelectContent>
                        </Select>
                     </div>

                     <div className="space-y-2">
                        <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Question</label>
                        <Input value={question} onChange={(e) => setQuestion(e.target.value)} placeholder="What is Life Partner Again?" required />
                     </div>

                     <div className="space-y-2">
                        <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Answer Content</label>
                        <textarea
                           className="flex min-h-20 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                           value={answer}
                           onChange={(e) => setAnswer(e.target.value)}
                           placeholder="Type the detailed answer explanation here..."
                           rows={4}
                           required
                        />
                     </div>

                     {/* Bullet builder */}
                     <div className="space-y-2 border rounded-lg p-3 bg-muted/40">
                        <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground block mb-1">Additional Bullet Points (Optional)</label>
                        <div className="flex gap-2 mb-2">
                           <Input
                              value={newBulletText}
                              onChange={(e) => setNewBulletText(e.target.value)}
                              placeholder="Add a bullet point..."
                              onKeyDown={(e) => {
                                 if (e.key === "Enter") {
                                    e.preventDefault();
                                    handleAddBullet();
                                 }
                              }}
                           />
                           <Button type="button" variant="outline" onClick={handleAddBullet}>
                              Add
                           </Button>
                        </div>
                        {bullets.length > 0 && (
                           <div className="space-y-2 mt-2">
                              {bullets.map((bullet, idx) => (
                                 <div key={idx} className="flex items-center justify-between text-sm bg-background border px-2.5 py-1.5 rounded-md">
                                    <span className="flex-1 mr-2">{bullet}</span>
                                    <button type="button" onClick={() => handleRemoveBullet(idx)} className="text-muted-foreground hover:text-destructive">
                                       <X className="h-4 w-4" />
                                    </button>
                                 </div>
                              ))}
                           </div>
                        )}
                     </div>
                  </div>

                  <DialogFooter className="mt-4">
                     <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)}>
                        Cancel
                     </Button>
                     <Button type="submit">Save</Button>
                  </DialogFooter>
               </form>
            </DialogContent>
         </Dialog>

         {/* Delete Confirmation Modal Dialog */}
         <Dialog open={isDeleteModalOpen} onOpenChange={setIsDeleteModalOpen}>
            <DialogContent className="max-w-md">
               <DialogHeader>
                  <DialogTitle className="text-destructive flex items-center gap-2">Delete Guide Question</DialogTitle>
                  <DialogDescription className="pt-2">
                     Are you sure you want to permanently delete the question:
                     <span className="block font-semibold text-foreground mt-2">"{guideToDelete?.question}"</span>
                     This action cannot be undone.
                  </DialogDescription>
               </DialogHeader>
               <DialogFooter className="mt-4">
                  <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)}>
                     Cancel
                  </Button>
                  <Button variant="destructive" onClick={confirmDeleteGuide}>
                     Delete Question
                  </Button>
               </DialogFooter>
            </DialogContent>
         </Dialog>
      </div>
   );
};

export default LpaGuidePage;
