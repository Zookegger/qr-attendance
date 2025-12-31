import { body, param } from "express-validator";

export const createWorkshiftValidator = [
  body("name").isString().notEmpty().withMessage("Name is required"),
  body("startTime")
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid startTime format (HH:MM)"),
  body("endTime")
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid endTime format (HH:MM)"),
  body("breakStart")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid breakStart format (HH:MM)"),
  body("breakEnd")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid breakEnd format (HH:MM)"),
  body("gracePeriod").optional().isInt({ min: 0 }).withMessage("Invalid gracePeriod"),
  body("workDays")
    .optional()
    .isArray()
    .withMessage("workDays must be an array of integers (0-6)"),
  body("workDays.*").optional().isInt({ min: 0, max: 6 }).withMessage("Invalid work day"),
  body("office_config_id").optional().isInt().withMessage("office_config_id must be an integer"),
];

export const updateWorkshiftValidator = [
  param("id").isInt().withMessage("Workshift id must be an integer"),
  body("name").optional().isString().notEmpty().withMessage("Name cannot be empty"),
  body("startTime")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid startTime format (HH:MM)"),
  body("endTime")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid endTime format (HH:MM)"),
  body("breakStart")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid breakStart format (HH:MM)"),
  body("breakEnd")
    .optional()
    .matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
    .withMessage("Invalid breakEnd format (HH:MM)"),
  body("gracePeriod").optional().isInt({ min: 0 }).withMessage("Invalid gracePeriod"),
  body("workDays")
    .optional()
    .isArray()
    .withMessage("workDays must be an array of integers (0-6)"),
  body("workDays.*").optional().isInt({ min: 0, max: 6 }).withMessage("Invalid work day"),
  body("office_config_id").optional().isInt().withMessage("office_config_id must be an integer"),
];

export const getWorkshiftValidator = [param("id").isInt().withMessage("Workshift id must be an integer")];

export const deleteWorkshiftValidator = [param("id").isInt().withMessage("Workshift id must be an integer")];
