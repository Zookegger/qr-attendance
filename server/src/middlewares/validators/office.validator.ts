import { body, param } from "express-validator";

export const createOfficeValidator = [
    body("name").isString().notEmpty().withMessage("Name is required"),
    body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Invalid latitude"),
    body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Invalid longitude"),
    
    // 1. Allow radius to be null (or float >= 0)
    body("radius")
        .optional({ nullable: true })
        .isFloat({ min: 0 })
        .withMessage("Radius must be a positive number"),

    // 2. Allow wifiSsid to be null (or string)
    body("wifiSsid")
        .optional({ nullable: true })
        .isString()
        .withMessage("WiFi SSID must be a string"),

    body("geofence")
        .optional({ nullable: true })
        .isObject()
        .withMessage("Geofence must be a JSON object with included/excluded arrays"),

    // Custom check: Ensure at least one method (Radius OR Geofence) is active
    body().custom((_value, { req }) => {
        const { radius, geofence } = req.body;

        // Radius is valid if it exists, is not null, and is > 0
        const hasRadius = radius != null && Number(radius) > 0;

        // Geofence is valid if it exists and has at least one included/excluded zone
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
    
    // 1. Allow radius to be null
    body("radius")
        .optional({ nullable: true })
        .isFloat({ min: 0 })
        .withMessage("Radius must be a positive number"),

    // 2. Allow wifiSsid to be null
    body("wifiSsid")
        .optional({ nullable: true })
        .isString()
        .withMessage("WiFi SSID must be a string"),

    body("geofence")
        .optional({ nullable: true })
        .isObject()
        .withMessage("Geofence must be a JSON object"),

    body().custom((_value, { req }) => {
        const { radius, geofence } = req.body;

        // Only enforce consistency if both fields are being touched in this update
        if (radius !== undefined && geofence !== undefined) {
            const hasRadius = radius != null && Number(radius) > 0;
            const hasGeofence = geofence && (
                (Array.isArray(geofence.included) && geofence.included.length > 0) ||
                (Array.isArray(geofence.excluded) && geofence.excluded.length > 0)
            );

            if (!hasRadius && !hasGeofence) {
                throw new Error("Cannot set both radius to 0/null and remove geofence");
            }
        }
        
        return true;
    }),
];

export const officeIdValidator = [
    param("id").isInt({ min: 1 }).withMessage("Invalid office ID"),
];