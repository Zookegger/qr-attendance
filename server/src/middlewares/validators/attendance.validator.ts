import { body } from "express-validator";

export const checkInValidator = [
	body("qr_code").isString().notEmpty().withMessage("QR code is required"),
	body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
];

export const checkOutValidator = [
	body("qr_code").isString().notEmpty().withMessage("QR code is required"),
	body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
];