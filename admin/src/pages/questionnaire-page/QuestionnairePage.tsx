import { getSections, type ProfileSection } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import AddEditSectionModal from "./components/AddEditSectionModal";
import SectionList from "./components/SectionList";

export default function QuestionnairePage() {
   const [sections, setSections] = useState<ProfileSection[]>([]);
   const [loading, setLoading] = useState(true);
   const [isSectionModalOpen, setIsSectionModalOpen] = useState(false);

   const loadSections = async () => {
      try {
         setLoading(true);
         const res = await getSections();
         if (res.success) {
            setSections(res.data);
         } else {
            toast.error(res.message || "Failed to load sections");
         }
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Error loading sections");
      } finally {
         setLoading(false);
      }
   };

   useEffect(() => {
      loadSections();
   }, []);

   return (
      <div className="flex-1 space-y-4">
         <div className="flex items-center justify-between space-y-2">
            <div>
               <h2 className="text-3xl font-bold tracking-tight">Questionnaire</h2>
               <p className="text-muted-foreground text-sm mt-1">Manage profile sections and questions for users.</p>
            </div>
            <div className="flex items-center space-x-2">
               <Button onClick={() => setIsSectionModalOpen(true)} className="gap-2 shadow-sm rounded-full">
                  <Plus className="h-4 w-4" /> Add Section
               </Button>
            </div>
         </div>

         <div className="mt-8">
            {loading ? (
               <div className="flex flex-col items-center justify-center py-20 text-muted-foreground space-y-4">
                  <div className="w-8 h-8 rounded-full border-4 border-primary/30 border-t-primary animate-spin" />
                  <p className="text-sm">Loading sections...</p>
               </div>
            ) : sections.length === 0 ? (
               <div className="flex flex-col items-center justify-center py-24 text-center border rounded-2xl bg-zinc-50/50 dark:bg-zinc-900/50 border-dashed m-2">
                  <div className="bg-primary/10 p-4 rounded-full mb-4">
                     <Plus className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold text-zinc-800 dark:text-zinc-200">No Sections Yet</h3>
                  <p className="text-sm text-muted-foreground mt-2 mb-6 max-w-sm">Create your first section to start building the questionnaire layout.</p>
                  <Button onClick={() => setIsSectionModalOpen(true)} variant="outline" className="rounded-full shadow-sm">
                     Add your first section
                  </Button>
               </div>
            ) : (
               <SectionList sections={sections} setSections={setSections} reloadSections={loadSections} />
            )}
         </div>

         <AddEditSectionModal isOpen={isSectionModalOpen} onClose={() => setIsSectionModalOpen(false)} onSuccess={loadSections} />
      </div>
   );
}
