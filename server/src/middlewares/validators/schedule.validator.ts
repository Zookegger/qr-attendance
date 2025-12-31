import { body, param, query } from "express-validator";

export const createScheduleValidator = [
  body("user_id").isString().notEmpty().withMessage("user_id is required"),
  body("shift_id").isInt().withMessage("shift_id must be an integer"),
  body("start_date").isISO8601().withMessage("start_date must be a valid date"),
  body("end_date").optional().isISO8601().withMessage("end_date must be a valid date"),
];

export const updateScheduleValidator = [
  param("id").isInt().withMessage("Schedule id must be an integer"),
  body("user_id").optional().isString().withMessage("user_id must be a string"),
  body("shift_id").optional().isInt().withMessage("shift_id must be an integer"),
  body("start_date").optional().isISO8601().withMessage("start_date must be a valid date"),
  body("end_date").optional().isISO8601().withMessage("end_date must be a valid date"),
];

export const getScheduleValidator = [param("id").isInt().withMessage("Schedule id must be an integer")];

export const deleteScheduleValidator = [param("id").isInt().withMessage("Schedule id must be an integer")];

export const searchScheduleValidator = [
  query("user_id").optional().isString().withMessage("user_id must be a string"),
  query("shift_id").optional().isInt().withMessage("shift_id must be an integer"),
  query("start_date").optional().isISO8601().withMessage("start_date must be a valid date"),
  query("end_date").optional().isISO8601().withMessage("end_date must be a valid date"),
];
