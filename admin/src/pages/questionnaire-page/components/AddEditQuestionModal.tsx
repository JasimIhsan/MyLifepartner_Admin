import { createQuestion, updateQuestion, type ProfileQuestion } from "@/api/questionnaire.service";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import type { AxiosError } from "axios";
import { Plus, X } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

interface Props {
   isOpen: boolean;
   onClose: () => void;
   onSuccess: () => void;
   sectionId: number;
   questionToEdit?: ProfileQuestion | null;
}

export default function AddEditQuestionModal({ isOpen, onClose, onSuccess, sectionId, questionToEdit }: Props) {
   const [questionText, setQuestionText] = useState("");
   const [answerType, setAnswerType] = useState<ProfileQuestion["answerType"]>("TEXT");
   const [isRequired, setIsRequired] = useState(true);
   const [weight, setWeight] = useState(1);
   const [minWords, setMinWords] = useState<number | "">("");
   const [options, setOptions] = useState<{ label: string; value: string }[]>([]);

   const [loading, setLoading] = useState(false);

   useEffect(() => {
      if (isOpen) {
         if (questionToEdit) {
            setQuestionText(questionToEdit.question);
            setAnswerType(questionToEdit.answerType);
            setIsRequired(questionToEdit.isRequired);
            setWeight(questionToEdit.weight);
            setMinWords(questionToEdit.minWords || "");

            // Parse options if they exist
            if (questionToEdit.options && typeof questionToEdit.options === "object") {
               const parsedOptions = Object.entries(questionToEdit.options).map(([value, label]) => ({
                  value,
                  label: String(label),
               }));
               setOptions(parsedOptions);
            } else {
               setOptions([]);
            }
         } else {
            setQuestionText("");
            setAnswerType("TEXT");
            setIsRequired(true);
            setWeight(1);
            setMinWords("");
            setOptions([]);
         }
      }
   }, [isOpen, questionToEdit]);

   const handleAddOption = () => {
      setOptions([...options, { label: "", value: "" }]);
   };

   const handleRemoveOption = (index: number) => {
      const newOptions = [...options];
      newOptions.splice(index, 1);
      setOptions(newOptions);
   };

   const handleOptionChange = (index: number, field: "label" | "value", val: string) => {
      const newOptions = [...options];
      newOptions[index][field] = val;
      setOptions(newOptions);
   };

   const handleSubmit = async (e: React.FormEvent) => {
      e.preventDefault();
      if (!questionText) {
         toast.error("Question text is required");
         return;
      }

      // Format options into key-value map
      let formattedOptions: Record<string, string> | null = null;
      if (["SINGLE_CHOICE", "MULTI_CHOICE"].includes(answerType)) {
         if (options.length === 0) {
            toast.error("At least one option is required for Choice types");
            return;
         }
         formattedOptions = {};
         for (const opt of options) {
            if (!opt.label || !opt.value) {
               toast.error("All options must have both label and value");
               return;
            }
            formattedOptions[opt.value] = opt.label;
         }
      }

      const payload = {
         question: questionText,
         answerType,
         isRequired,
         weight,
         minWords: minWords === "" ? undefined : Number(minWords),
         options: formattedOptions,
      };

      try {
         setLoading(true);
         if (questionToEdit) {
            const res = await updateQuestion(questionToEdit.id, payload);
            if (res.success) {
               toast.success("Question updated");
               onSuccess();
               onClose();
            } else {
               toast.error(res.message);
            }
         } else {
            const res = await createQuestion(sectionId, payload);
            if (res.success) {
               toast.success("Question created");
               onSuccess();
               onClose();
            } else {
               toast.error(res.message);
            }
         }
      } catch (error) {
         const axiosError = error as AxiosError<{ message: string }>;
         toast.error(axiosError.response?.data?.message || "An error occurred");
      } finally {
         setLoading(false);
      }
   };

   return (
      <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
         <DialogContent className="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col p-0">
            <DialogHeader className="pt-6 px-6 pb-2">
               <DialogTitle className="text-xl">{questionToEdit ? "Edit Question" : "Add Question"}</DialogTitle>
            </DialogHeader>
            <div className="overflow-y-auto px-6 py-2">
               <form onSubmit={handleSubmit} className="space-y-6">
                  <div className="space-y-2">
                     <Label>Question Text</Label>
                     <Input value={questionText} onChange={(e) => setQuestionText(e.target.value)} placeholder="e.g. What are your hobbies?" autoFocus className="font-medium" />
                  </div>

                  <div className="grid grid-cols-2 gap-5">
                     <div className="space-y-2">
                        <Label>Answer Type</Label>
                        <select
                           className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                           value={answerType}
                           onChange={(e) => setAnswerType(e.target.value as ProfileQuestion["answerType"])}
                        >
                           <option value="TEXT">Short/Long Text</option>
                           <option value="SINGLE_CHOICE">Single Choice</option>
                           <option value="MULTI_CHOICE">Multiple Choice</option>
                           <option value="RATING">Rating (1-5)</option>
                           <option value="BOOLEAN">Yes/No</option>
                        </select>
                     </div>

                     <div className="space-y-2">
                        <Label>Ordering Weight</Label>
                        <Input type="number" value={weight} onChange={(e) => setWeight(Number(e.target.value))} min={1} />
                        <p className="text-[10px] text-muted-foreground">Used for prioritizing questions (higher evaluates heavier).</p>
                     </div>
                  </div>

                  <div className="grid grid-cols-2 gap-5">
                     <div className="flex items-center justify-between rounded-lg border border-border p-3 bg-muted/20">
                        <div className="space-y-0.5">
                           <Label className="text-sm font-medium">Required Response</Label>
                           <p className="text-[10px] text-muted-foreground">Must the user answer this?</p>
                        </div>
                        <Switch checked={isRequired} onCheckedChange={setIsRequired} />
                     </div>

                     {answerType === "TEXT" ? (
                        <div className="space-y-2">
                           <Label>Minimum Words</Label>
                           <Input type="number" value={minWords} onChange={(e) => setMinWords(e.target.value ? Number(e.target.value) : "")} min={0} placeholder="Leave blank for none" />
                        </div>
                     ) : (
                        <div />
                     )}
                  </div>

                  {["SINGLE_CHOICE", "MULTI_CHOICE"].includes(answerType) && (
                     <div className="space-y-4 rounded-xl border border-border p-4 bg-muted/10">
                        <div className="flex justify-between items-center">
                           <Label className="text-base font-semibold">Multiple Choice Options</Label>
                           <Button type="button" size="sm" variant="secondary" onClick={handleAddOption} className="h-8 rounded-full px-3 text-xs">
                              <Plus className="h-3.5 w-3.5 mr-1.5" /> Add Option
                           </Button>
                        </div>

                        {options.length === 0 ? (
                           <p className="text-sm text-muted-foreground/60 italic text-center py-4 border border-dashed rounded-lg bg-background">No options added yet.</p>
                        ) : (
                           <div className="space-y-2.5">
                              {options.map((opt, idx) => (
                                 <div key={idx} className="flex flex-col sm:flex-row items-start sm:items-center gap-2 bg-background p-2 rounded-lg border border-border/60 shadow-sm relative group">
                                    <div className="flex-1 w-full space-y-1">
                                       <Label className="text-[10px] uppercase text-muted-foreground ml-1">Label</Label>
                                       <Input placeholder="e.g. Software Engineer" value={opt.label} onChange={(e) => handleOptionChange(idx, "label", e.target.value)} className="h-8" />
                                    </div>
                                    <div className="flex-1 w-full space-y-1">
                                       <Label className="text-[10px] uppercase text-muted-foreground ml-1">Value</Label>
                                       <Input placeholder="e.g. software_engineer" value={opt.value} onChange={(e) => handleOptionChange(idx, "value", e.target.value)} className="h-8 font-mono text-xs" />
                                    </div>
                                    <Button type="button" variant="ghost" size="icon" onClick={() => handleRemoveOption(idx)} className="h-8 w-8 sm:mt-5 text-muted-foreground hover:text-red-500 hover:bg-red-50/50 absolute right-1 top-1 sm:relative sm:right-auto sm:top-auto opacity-40 group-hover:opacity-100 transition-opacity">
                                       <X className="h-4 w-4" />
                                    </Button>
                                 </div>
                              ))}
                           </div>
                        )}
                     </div>
                  )}
               </form>
            </div>
            <DialogFooter className="border-t border-border p-6 pt-4 bg-muted/10">
               <Button variant="ghost" onClick={onClose}>
                  Cancel
               </Button>
               <Button onClick={handleSubmit} disabled={loading}>
                  {loading ? "Saving Setup..." : "Save Question"}
               </Button>
            </DialogFooter>
         </DialogContent>
      </Dialog>
   );
}
