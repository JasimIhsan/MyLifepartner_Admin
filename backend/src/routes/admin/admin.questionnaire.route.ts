import * as adminQuestionnaireController from "@/controllers/admin/admin.questionnaire.controller";
import { Router } from "express";

const adminQuestionnaireRoute = Router();

// ==========================================
// Sections
// ==========================================
adminQuestionnaireRoute.post("/sections", adminQuestionnaireController.createSection);
adminQuestionnaireRoute.get("/sections", adminQuestionnaireController.getSections);
adminQuestionnaireRoute.put("/sections/reorder", adminQuestionnaireController.reorderSections); // Needs to be before /:id
adminQuestionnaireRoute.put("/sections/:id", adminQuestionnaireController.updateSection);
adminQuestionnaireRoute.delete("/sections/:id", adminQuestionnaireController.deleteSection);

// ==========================================
// Questions
// ==========================================
// We use nested routes for questions under sections for creation & reading, but direct IDs for update/delete
// Actually, for creation and get:
adminQuestionnaireRoute.post("/sections/:sectionId/questions", adminQuestionnaireController.createQuestion);
adminQuestionnaireRoute.put("/sections/:sectionId/questions/reorder", adminQuestionnaireController.reorderQuestions);

// For update, delete, and toggle, having just the question id is fine:
adminQuestionnaireRoute.put("/questions/:id", adminQuestionnaireController.updateQuestion);
adminQuestionnaireRoute.patch("/questions/:id/toggle-active", adminQuestionnaireController.toggleQuestionActive);
adminQuestionnaireRoute.delete("/questions/:id", adminQuestionnaireController.deleteQuestion);

export default adminQuestionnaireRoute;
