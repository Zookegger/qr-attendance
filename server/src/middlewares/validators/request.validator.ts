import { body } from "express-validator";
import { RequestType } from "@models/request";

export const createRequestValidator = [
	body("type")
		.isIn(Object.values(RequestType))
		.withMessage("Invalid request type"),
	body("from_date")
		.optional()
		.isISO8601()
		.withMessage("Invalid from_date format"),
	body("to_date")
		.optional()
		.isISO8601()
		.withMessage("Invalid to_date format"),
	body("reason")
		.optional()
		.isString()
		.withMessage("Reason must be a string"),
	body("image_url")
		.optional()
		.isString()
		.withMessage("Image URL must be a string"),
];
