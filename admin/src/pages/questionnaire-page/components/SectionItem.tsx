import { type ProfileSection, deleteSection } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { ChevronDown, Edit, GripVertical, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import AddEditSectionModal from "./AddEditSectionModal";
import QuestionList from "./QuestionList";

interface Props {
   section: ProfileSection;
   reloadSections: () => void;
}

export default function SectionItem({ section, reloadSections }: Props) {
   const [isExpanded, setIsExpanded] = useState(false);
   const [isEditModalOpen, setIsEditModalOpen] = useState(false);

   const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: section.id });

   const style = {
      transform: CSS.Transform.toString(transform),
      transition,
      opacity: isDragging ? 0.5 : 1,
   };

   const handleDelete = async () => {
      if (confirm("Are you sure you want to delete this section? All questions must be deleted first.")) {
         try {
            const res = await deleteSection(section.id);
            if (res.success) {
               toast.success("Section deleted");
               reloadSections();
            } else {
               toast.error(res.message);
            }
         } catch (error: any) {
            toast.error(error.response?.data?.message || "Failed to delete section");
         }
      }
   };

   return (
      <div ref={setNodeRef} style={style} className={`bg-card text-card-foreground border border-border rounded-xl shadow-sm mb-4 transition-all duration-200 overflow-hidden ${isDragging ? "shadow-md ring-2 ring-primary/20 z-50 relative" : ""}`}>
         <div className={`flex items-center justify-between p-4 transition-colors group ${isExpanded ? "bg-muted/30 border-b border-border space-y-0" : "hover:bg-muted/10"}`}>
            <div className="flex items-center gap-4">
               <div {...attributes} {...listeners} className="cursor-grab hover:bg-muted/50 p-1.5 rounded-md transition-colors opacity-40 group-hover:opacity-100 flex items-center justify-center">
                  <GripVertical className="h-5 w-5 text-muted-foreground" />
               </div>
               <div>
                  <div className="flex items-center gap-2">
                     <h3 className="font-semibold text-base text-foreground tracking-tight">{section.title}</h3>
                     {section.isPrimary && <span className="text-[10px] uppercase tracking-wider font-semibold bg-primary/10 text-primary px-2.5 py-0.5 rounded-full ring-1 ring-primary/20">Primary</span>}
                  </div>
                  <p className="text-xs text-muted-foreground font-mono mt-0.5 bg-muted/60 inline-flex px-1.5 py-0.5 rounded-md">{section.key}</p>
               </div>
            </div>

            <div className="flex items-center gap-1 opacity-60 hover:opacity-100 transition-opacity">
               <Button variant="ghost" size="icon" onClick={() => setIsEditModalOpen(true)} className="h-8 w-8 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-950/50 rounded-full">
                  <Edit className="h-4 w-4" />
               </Button>
               <Button variant="ghost" size="icon" onClick={handleDelete} className="h-8 w-8 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/50 rounded-full">
                  <Trash2 className="h-4 w-4" />
               </Button>
               <div className="w-px h-5 bg-border mx-1.5" />
               <Button variant="ghost" size="icon" onClick={() => setIsExpanded(!isExpanded)} className={`h-8 w-8 transition-transform duration-200 rounded-full ${isExpanded ? "bg-muted text-foreground" : ""}`}>
                  <ChevronDown className={`h-5 w-5 transition-transform duration-200 ${isExpanded ? "rotate-180" : ""}`} />
               </Button>
            </div>
         </div>

         <div className={`grid transition-[grid-template-rows,opacity] duration-300 ease-in-out ${isExpanded ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"}`}>
            <div className="overflow-hidden">
               <div className="p-2 sm:p-5 bg-muted/10">
                  <QuestionList sectionId={section.id} initialQuestions={section.questions || []} reloadSections={reloadSections} />
               </div>
            </div>
         </div>

         <AddEditSectionModal isOpen={isEditModalOpen} onClose={() => setIsEditModalOpen(false)} onSuccess={reloadSections} sectionToEdit={section} />
      </div>
   );
}
