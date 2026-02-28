import { closestCenter, DndContext, type DragEndEvent, KeyboardSensor, PointerSensor, useSensor, useSensors } from "@dnd-kit/core";
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy } from "@dnd-kit/sortable";

import { type ProfileSection, reorderSections } from "@/api/questionnaire.service";
import { toast } from "sonner";
import SectionItem from "./SectionItem";

interface Props {
   sections: ProfileSection[];
   setSections: React.Dispatch<React.SetStateAction<ProfileSection[]>>;
   reloadSections: () => void;
}

export default function SectionList({ sections, setSections, reloadSections }: Props) {
   const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }), useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }));

   const handleDragEnd = async (event: DragEndEvent) => {
      const { active, over } = event;

      if (over && active.id !== over.id) {
         setSections((items) => {
            const oldIndex = items.findIndex((item) => item.id === active.id);
            const newIndex = items.findIndex((item) => item.id === over.id);

            const newOrder = arrayMove(items, oldIndex, newIndex);

            // Sync with backend
            const orderedIds = newOrder.map((s) => s.id);
            reorderSections(orderedIds).catch((_) => {
               toast.error("Failed to save reordered sections");
               reloadSections(); // Revert on failure
            });

            return newOrder;
         });
      }
   };

   return (
      <div className="space-y-4">
         <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
            <SortableContext items={sections.map((s) => s.id)} strategy={verticalListSortingStrategy}>
               {sections.map((section) => (
                  <SectionItem key={section.id} section={section} reloadSections={reloadSections} />
               ))}
            </SortableContext>
         </DndContext>
      </div>
   );
}
