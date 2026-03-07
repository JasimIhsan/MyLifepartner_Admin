import { adminQuestionnaireController } from "@/composer/composer";
import { Router } from "express";

const adminQuestionnaireRoute = Router();

// ==========================================
// Sections
// ==========================================
adminQuestionnaireRoute.post("/sections", adminQuestionnaireController.createSection);
adminQuestionnaireRoute.get("/sections", adminQuestionnaireController.getSections);
adminQuestionnaireRoute.put("/sections/reorder", adminQuestionnaireController.reorderSections); // before /:id
adminQuestionnaireRoute.put("/sections/:id", adminQuestionnaireController.updateSection);
adminQuestionnaireRoute.delete("/sections/:id", adminQuestionnaireController.deleteSection);

// ==========================================
// Questions
// ==========================================
adminQuestionnaireRoute.post("/sections/:sectionId/questions", adminQuestionnaireController.createQuestion);
adminQuestionnaireRoute.put("/sections/:sectionId/questions/reorder", adminQuestionnaireController.reorderQuestions);

adminQuestionnaireRoute.put("/questions/:id", adminQuestionnaireController.updateQuestion);
adminQuestionnaireRoute.patch("/questions/:id/toggle-active", adminQuestionnaireController.toggleQuestionActive);
adminQuestionnaireRoute.delete("/questions/:id", adminQuestionnaireController.deleteQuestion);

export default adminQuestionnaireRoute;
