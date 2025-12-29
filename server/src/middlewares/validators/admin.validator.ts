import { body, param } from "express-validator";

export const updateOfficeConfigValidator = [
	body("latitude").optional().isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").optional().isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").optional().isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("start_hour").optional().matches(/^([01]\d|2[0-3]):([0-5]\d)$/).withMessage("Invalid start hour format (HH:MM)"),
	body("end_hour").optional().matches(/^([01]\d|2[0-3]):([0-5]\d)$/).withMessage("Invalid end hour format (HH:MM)"),
	body("wifi_ssid").optional().isString().withMessage("WiFi SSID must be a string"),
];

export const addUserValidator = [
	body("name").isString().notEmpty().withMessage("Name is required"),
	body("email").isEmail().withMessage("Invalid email"),
	body("password").isLength({ min: 6 }).withMessage("Password must be at least 6 characters"),
	body("role").optional().isIn(["admin", "manager", "user"]).withMessage("Invalid role"),
	body("position").optional().isString().withMessage("Position must be a string"),
	body("department").optional().isString().withMessage("Department must be a string"),
	body("date_of_birth").optional().isISO8601().withMessage("Invalid date of birth"),
	body("phone_number").optional().isString().withMessage("Phone number must be a string"),
	body("address").optional().isString().withMessage("Address must be a string"),
	body("gender").optional().isIn(["male", "female", "other"]).withMessage("Invalid gender"),
];

export const updateUserValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
	body("name").optional().isString().notEmpty().withMessage("Name cannot be empty"),
	body("email").optional().isEmail().withMessage("Invalid email"),
	body("password").optional().isLength({ min: 6 }).withMessage("Password must be at least 6 characters"),
	body("role").optional().isIn(["admin", "manager", "user"]).withMessage("Invalid role"),
	body("position").optional().isString().withMessage("Position must be a string"),
	body("department").optional().isString().withMessage("Department must be a string"),
	body("status").optional().isIn(["active", "inactive", "pending"]).withMessage("Invalid status"),
	body("date_of_birth").optional().isISO8601().withMessage("Invalid date of birth"),
	body("phone_number").optional().isString().withMessage("Phone number must be a string"),
	body("address").optional().isString().withMessage("Address must be a string"),
	body("gender").optional().isIn(["male", "female", "other"]).withMessage("Invalid gender"),
];

export const deleteUserValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
];

export const listUserSessionValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
];

export const revokeUserSessionValidator = [
	param("id").isString().notEmpty().withMessage("Session ID is required"),
];