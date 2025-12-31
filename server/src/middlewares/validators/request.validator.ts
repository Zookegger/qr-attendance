import { body } from "express-validator";
import { RequestType } from "@models/request";
import { param, query } from "express-validator";
import { RequestStatus } from "@models/request";

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
		.isString()
		.notEmpty()
		.withMessage("Reason must be a non-empty string"),
	// Attachments are handled by multer as files; no image_url string expected
];

// Update route expects :id in path
export const updateRequestValidator = [
	param("id").isUUID().withMessage("Invalid request id"),
	body("type").optional().isIn(Object.values(RequestType)).withMessage("Invalid request type"),
	body("from_date").optional().isISO8601().withMessage("Invalid from_date format"),
	body("to_date").optional().isISO8601().withMessage("Invalid to_date format"),
	body("reason").optional().isString().withMessage("Reason must be a string"),
];

export const listRequestsValidator = [
	query("status").optional().isIn(Object.values(RequestStatus)).withMessage("Invalid status"),
	query("type").optional().isIn(Object.values(RequestType)).withMessage("Invalid type"),
	query("from_date").optional().isISO8601().withMessage("Invalid from_date format"),
	query("user_id").optional().isUUID().withMessage("Invalid user_id"),
];

export const reviewRequestValidator = [
	param("id").isUUID().withMessage("Invalid request id"),
	body("status").isIn(Object.values(RequestStatus)).withMessage("Invalid status value"),
	body("review_note").optional().isString().withMessage("Review note must be a string"),
];

export const requestIdParamValidator = [
	param("id").isUUID().withMessage("Invalid request id"),
];
