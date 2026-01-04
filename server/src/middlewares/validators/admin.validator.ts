import { Gender, UserRole, UserStatus } from "@models/user";
import { body, param } from "express-validator";

export const updateOfficeConfigValidator = [
	body("name").optional().isString().withMessage("Name must be a string"),
	body("latitude").optional().isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").optional().isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").optional().isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("wifiSsid").optional().isString().withMessage("WiFi SSID must be a string"),
];

export const addUserValidator = [
	body("name").isString().notEmpty().withMessage("Name is required"),
	body("email").isEmail().withMessage("Invalid email"),
	body("password").isLength({ min: 6 }).withMessage("Password must be at least 6 characters"),
	body("role").optional().isIn(Object.values(UserRole)).withMessage("Invalid role"),
	body("position").optional().isString().withMessage("Position must be a string"),
	body("department").optional().isString().withMessage("Department must be a string"),
	body("date_of_birth").optional().isISO8601().withMessage("Invalid date of birth"),
	body("phone_number").optional().isString().withMessage("Phone number must be a string"),
	body("address").optional().isString().withMessage("Address must be a string"),
	body("gender").optional().isIn(Object.values(Gender)).withMessage("Invalid gender"),
];

export const updateUserValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
	body("name").optional().isString().notEmpty().withMessage("Name cannot be empty"),
	body("email").optional().isEmail().withMessage("Invalid email"),
	body("password").optional().isLength({ min: 6 }).withMessage("Password must be at least 6 characters"),
	body("role").optional().isIn(Object.values(UserRole)).withMessage("Invalid role"),
	body("position").optional().isString().withMessage("Position must be a string"),
	body("department").optional().isString().withMessage("Department must be a string"),
	body("status").optional().isIn(Object.values(UserStatus)).withMessage("Invalid status"),
	body("date_of_birth").optional().isISO8601().withMessage("Invalid date of birth"),
	body("phone_number").optional().isString().withMessage("Phone number must be a string"),
	body("address").optional().isString().withMessage("Address must be a string"),
	body("gender").optional().isIn(Object.values(Gender)).withMessage("Invalid gender"),
];

export const deleteUserValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
];

export const listUserSessionValidator = [
	param("id").isString().notEmpty().withMessage("User ID is required"),
];

export const revokeAllUserSessionsValidator = [
	param("id").isString().notEmpty().withMessage("Session ID is required"),
];
export const unbindDeviceValidator = [
body("userId").isString().notEmpty().withMessage("User ID is required"),
];
