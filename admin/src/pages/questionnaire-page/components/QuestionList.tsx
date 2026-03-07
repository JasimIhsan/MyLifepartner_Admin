import { closestCenter, DndContext, type DragEndEvent, KeyboardSensor, PointerSensor, useSensor, useSensors } from "@dnd-kit/core";
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from "@dnd-kit/sortable";

import { type ProfileQuestion, reorderQuestions } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import AddEditQuestionModal from "./AddEditQuestionModal";
import QuestionItem from "./QuestionItem";

interface Props {
   sectionId: number;
   initialQuestions: ProfileQuestion[];
   reloadSections: () => void;
}

export default function QuestionList({ sectionId, initialQuestions, reloadSections }: Props) {
   const [questions, setQuestions] = useState<ProfileQuestion[]>(initialQuestions);
   const [isQuestionModalOpen, setIsQuestionModalOpen] = useState(false);

   // Sync questions from props when sections reload
   useEffect(() => {
      setQuestions(initialQuestions);
   }, [initialQuestions]);

   const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }), useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }));

   const handleDragEnd = async (event: DragEndEvent) => {
      const { active, over } = event;

      if (over && active.id !== over.id) {
         setQuestions((items) => {
            const oldIndex = items.findIndex((item) => item.id === active.id);
            const newIndex = items.findIndex((item) => item.id === over.id);

            const newOrder = arrayMove(items, oldIndex, newIndex);

            // Sync with backend
            const orderedIds = newOrder.map((q) => q.id);
            reorderQuestions(sectionId, orderedIds).catch(() => {
               toast.error("Failed to save reordered questions");
               reloadSections(); // Revert on failure
            });

            return newOrder;
         });
      }
   };

   return (
      <div className="space-y-4 sm:pl-4">
         <div className="flex justify-between items-center mb-4">
            <h4 className="font-semibold text-sm text-muted-foreground uppercase tracking-wider">Questions</h4>
            <Button size="sm" variant="secondary" onClick={() => setIsQuestionModalOpen(true)} className="h-8 rounded-full px-3 text-xs">
               <Plus className="mr-1.5 h-3.5 w-3.5" /> Add Question
            </Button>
         </div>

         {questions.length === 0 ? (
            <p className="text-sm text-muted-foreground/60 italic text-center py-6 border border-dashed rounded-xl bg-background/50">No questions added yet.</p>
         ) : (
            <div className="pl-2 border-l-2 border-border/60 ml-2 space-y-3">
               <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
                  <SortableContext items={questions.map((q) => q.id)} strategy={verticalListSortingStrategy}>
                     {questions.map((question) => (
                        <QuestionItem key={question.id} question={question} reloadSections={reloadSections} />
                     ))}
                  </SortableContext>
               </DndContext>
            </div>
         )}

         <AddEditQuestionModal isOpen={isQuestionModalOpen} onClose={() => setIsQuestionModalOpen(false)} onSuccess={reloadSections} sectionId={sectionId} />
      </div>
   );
}
