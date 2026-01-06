import { body, param } from "express-validator";

export const createOfficeValidator = [
	body("name").isString().notEmpty().withMessage("Name is required"),
	body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("wifiSsid").optional().isString().withMessage("WiFi SSID must be a string"),
];

export const updateOfficeValidator = [
	body("name").optional().isString().notEmpty().withMessage("Name cannot be empty"),
	body("latitude").optional().isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").optional().isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").optional().isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("wifiSsid").optional().isString().withMessage("WiFi SSID must be a string"),
];

export const officeIdValidator = [
	param("id").isInt({ min: 1 }).withMessage("Invalid office ID"),
];
