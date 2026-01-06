import { body, param } from "express-validator";

export const createOfficeValidator = [
	body("name").isString().notEmpty().withMessage("Name is required"),
	body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").optional().isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("wifiSsid").optional().isString().withMessage("WiFi SSID must be a string"),
	body("geofence")
		.optional()
		.isObject()
		.withMessage("Geofence must be a JSON object with included/excluded arrays"),
	body().custom((_value, { req }) => {
		const { radius, geofence } = req.body;
		
		// Check if radius is valid (present and positive)
		const hasRadius = radius !== undefined && radius !== null && Number(radius) > 0;
		
		// Check if geofence is valid (has at least one included zone)
		// Note: complex validation of polygon points could go here, but checking for existence is start.
		const hasGeofence = geofence && 
			((Array.isArray(geofence.included) && geofence.included.length > 0) ||
			(Array.isArray(geofence.excluded) && geofence.excluded.length > 0));

		if (!hasRadius && !hasGeofence) {
			throw new Error("Either a valid radius (>0) or a geofence configuration is required");
		}
		return true;
	}),
];

export const updateOfficeValidator = [
	body("name").optional().isString().notEmpty().withMessage("Name cannot be empty"),
	body("latitude").optional().isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
	body("longitude").optional().isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
	body("radius").optional().isFloat({ min: 0 }).withMessage("Radius must be positive"),
	body("wifiSsid").optional().isString().withMessage("WiFi SSID must be a string"),
	body("geofence")
		.optional()
		.isObject()
		.withMessage("Geofence must be a JSON object"),
	body().custom((_value, { req }) => {
		const { radius, geofence } = req.body;
		
		// Only run this check if radius is provided (create) or if we want to enforce consistency
		// ...
		
		if (radius !== undefined && geofence !== undefined) {
			const validRadius = Number(radius) > 0;
			const validGeofence = geofence && (
				(Array.isArray(geofence.included) && geofence.included.length > 0) ||
				(Array.isArray(geofence.excluded) && geofence.excluded.length > 0)
			);
			
			if (!validRadius && !validGeofence) {
				throw new Error("Cannot set both radius to 0 and remove geofence");
			}
		}
		
		return true;
	}),
];

export const officeIdValidator = [
	param("id").isInt({ min: 1 }).withMessage("Invalid office ID"),
];
