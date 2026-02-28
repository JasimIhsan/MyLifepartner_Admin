import { type ProfileQuestion, deleteQuestion, toggleQuestionActive } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { Edit, Eye, EyeOff, GripVertical, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import AddEditQuestionModal from "./AddEditQuestionModal";

interface Props {
   question: ProfileQuestion;
   reloadSections: () => void;
}

export default function QuestionItem({ question, reloadSections }: Props) {
   const [isEditModalOpen, setIsEditModalOpen] = useState(false);
   const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);

   const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: question.id });

   const style = {
      transform: CSS.Transform.toString(transform),
      transition,
      opacity: isDragging ? 0.5 : 1,
   };

   const handleDelete = async () => {
      if (confirm("Are you sure you want to delete this question?")) {
         try {
            const res = await deleteQuestion(question.id);
            if (res.success) {
               toast.success("Question deleted");
               reloadSections();
            } else {
               toast.error(res.message);
            }
         } catch (error: any) {
            toast.error(error.response?.data?.message || "Failed to delete question");
         }
      }
   };

   const handleToggleActive = async () => {
      try {
         setIsUpdatingStatus(true);
         const res = await toggleQuestionActive(question.id);
         if (res.success) {
            toast.success(`Question ${question.isActive ? "hidden" : "unhidden"}`);
            reloadSections();
         } else {
            toast.error(res.message);
         }
      } catch (error: any) {
         toast.error(error.response?.data?.message || "Failed to toggle status");
      } finally {
         setIsUpdatingStatus(false);
      }
   };

   return (
      <div ref={setNodeRef} style={style} className={`bg-card text-card-foreground border border-border shadow-sm rounded-xl mb-3 flex items-start p-3 sm:p-4 group transition-all duration-200 ${!question.isActive ? "opacity-50 grayscale hover:grayscale-0" : ""} ${isDragging ? "shadow-md ring-1 ring-primary/20 z-50 relative" : ""}`}>
         <div {...attributes} {...listeners} className="cursor-grab hover:bg-muted p-1.5 rounded-md mt-0.5 sm:mt-1 mr-3 opacity-30 group-hover:opacity-100 transition-opacity">
            <GripVertical className="h-4 w-4 text-muted-foreground" />
         </div>

         <div className="flex-1 min-w-0">
            <div className="flex items-center flex-wrap gap-2 mb-2">
               <span className="text-[10px] font-semibold tracking-wider uppercase bg-muted text-muted-foreground px-2 py-0.5 rounded-md border border-border/50">{question.answerType.replace("_", " ")}</span>
               {question.isRequired && <span className="text-[10px] font-semibold uppercase tracking-wider text-red-600 dark:text-red-400 bg-red-100/50 dark:bg-red-950/50 border border-red-200 dark:border-red-900/50 px-2 py-0.5 rounded-md">Required</span>}
               {!question.isActive && <span className="text-[10px] font-semibold uppercase tracking-wider text-orange-600 dark:text-orange-400 bg-orange-100/50 dark:bg-orange-950/50 border border-orange-200 dark:border-orange-900/50 px-2 py-0.5 rounded-md">Hidden</span>}
            </div>
            <p className="font-medium text-sm text-foreground leading-snug">{question.question}</p>
            {question.options && Object.keys(question.options).length > 0 && (
               <div className="mt-2.5 flex flex-wrap gap-1.5">
                  {Object.entries(question.options).map(([val, label]) => (
                     <span key={val} className="text-[10px] text-muted-foreground bg-muted/50 px-1.5 py-0.5 rounded border border-border/50 truncate max-w-40">
                        {String(label)}
                     </span>
                  ))}
               </div>
            )}
         </div>

         <div className="flex items-center gap-1 ml-4 sm:ml-6 self-start sm:self-center opacity-40 group-hover:opacity-100 transition-opacity shrink-0">
            <Button variant="ghost" size="icon" onClick={handleToggleActive} disabled={isUpdatingStatus} title={question.isActive ? "Hide Question" : "Unhide Question"} className="h-8 w-8 rounded-full">
               {question.isActive ? <Eye className="h-4 w-4 text-muted-foreground" /> : <EyeOff className="h-4 w-4 text-muted-foreground" />}
            </Button>
            <Button variant="ghost" size="icon" onClick={() => setIsEditModalOpen(true)} className="h-8 w-8 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-950/50 rounded-full">
               <Edit className="h-4 w-4" />
            </Button>
            <Button variant="ghost" size="icon" onClick={handleDelete} className="h-8 w-8 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-950/50 rounded-full">
               <Trash2 className="h-4 w-4" />
            </Button>
         </div>

         <AddEditQuestionModal isOpen={isEditModalOpen} onClose={() => setIsEditModalOpen(false)} onSuccess={reloadSections} sectionId={question.sectionId} questionToEdit={question} />
      </div>
   );
}
