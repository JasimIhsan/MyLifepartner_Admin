import { adminQuestionnaireController } from "@/composer/composer";
import { Router } from "express";

const adminQuestionnaireRoute = Router();

// ==========================================
// Sections
// ==========================================

/**
 * @route   POST /api/v1/admin/questionnaires/sections
 * @desc    Create a new questionnaire section
 * @access  Admin
 */
adminQuestionnaireRoute.post("/sections", adminQuestionnaireController.createSection);

/**
 * @route   GET /api/v1/admin/questionnaires/sections
 * @desc    Get all questionnaire sections
 * @access  Admin
 */
adminQuestionnaireRoute.get("/sections", adminQuestionnaireController.getSections);

/**
 * @route   PUT /api/v1/admin/questionnaires/sections/reorder
 * @desc    Reorder questionnaire sections
 * @access  Admin
 */
adminQuestionnaireRoute.put("/sections/reorder", adminQuestionnaireController.reorderSections);

/**
 * @route   PUT /api/v1/admin/questionnaires/sections/:id
 * @desc    Update questionnaire section by ID
 * @access  Admin
 */
adminQuestionnaireRoute.put("/sections/:id", adminQuestionnaireController.updateSection);

/**
 * @route   DELETE /api/v1/admin/questionnaires/sections/:id
 * @desc    Delete questionnaire section by ID
 * @access  Admin
 */
adminQuestionnaireRoute.delete("/sections/:id", adminQuestionnaireController.deleteSection);

// ==========================================
// Questions
// ==========================================

/**
 * @route   POST /api/v1/admin/questionnaires/sections/:sectionId/questions
 * @desc    Create a new question under a section
 * @access  Admin
 */
adminQuestionnaireRoute.post("/sections/:sectionId/questions", adminQuestionnaireController.createQuestion);

/**
 * @route   PUT /api/v1/admin/questionnaires/sections/:sectionId/questions/reorder
 * @desc    Reorder questions within a section
 * @access  Admin
 */
adminQuestionnaireRoute.put("/sections/:sectionId/questions/reorder", adminQuestionnaireController.reorderQuestions);

/**
 * @route   PUT /api/v1/admin/questionnaires/questions/:id
 * @desc    Update question by ID
 * @access  Admin
 */
adminQuestionnaireRoute.put("/questions/:id", adminQuestionnaireController.updateQuestion);

/**
 * @route   PATCH /api/v1/admin/questionnaires/questions/:id/toggle-active
 * @desc    Toggle active status of a question
 * @access  Admin
 */
adminQuestionnaireRoute.patch("/questions/:id/toggle-active", adminQuestionnaireController.toggleQuestionActive);

/**
 * @route   DELETE /api/v1/admin/questionnaires/questions/:id
 * @desc    Delete question by ID
 * @access  Admin
 */
adminQuestionnaireRoute.delete("/questions/:id", adminQuestionnaireController.deleteQuestion);

export default adminQuestionnaireRoute;
