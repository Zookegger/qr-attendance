import OfficeConfig, { GeofenceConfig, Point } from "@models/officeConfig";
import { CreateOfficeDTO, UpdateOfficeDTO } from "@my-types/office";

export default class OfficeService {
    static async getAllOffices() {
        return await OfficeConfig.findAll();
    }

    static async getOfficeById(id: string) {
        return await OfficeConfig.findByPk(id);
    }

    static async createOffice(dto: CreateOfficeDTO) {
        if (!dto.geofence && !dto.radius) {
            throw new Error();
        }

        let finalRadius: number | null = dto.radius;
        
        // Auto-calculate radius if polygon exists
        if (dto.geofence && dto.geofence.included && dto.geofence.included.length > 0) {
            const center: Point = { latitude: dto.latitude, longitude: dto.longitude };
            const minRadius = this.calculateGeofenceBoundingRadius(center, dto.geofence);

            // Use the calculated radius if it's larger than what the user provided,
            // or just strictly enforce the calculated one.
            // Option A (Strict): Always overwrite
            finalRadius = minRadius;

            // Option B (Flexible): allow user to set LARGER, but never SMALLER
            // finalRadius = Math.max(dto.radius, minRadius);
        }

        return await OfficeConfig.create({
            name: dto.name,
            latitude: dto.latitude,
            longitude: dto.longitude,
            geofence: dto.geofence,
            radius: finalRadius ?? 100,
            wifiSsid: dto.wifiSsid || null,
        });
    }

    static async updateOffice(id: string, dto: UpdateOfficeDTO) {
        const office = await OfficeConfig.findByPk(id);
        if (!office) {
            throw new Error("Office not found");
        }

        if (dto.name !== undefined) office.name = dto.name;
        if (dto.latitude !== undefined) office.latitude = dto.latitude;
        if (dto.longitude !== undefined) office.longitude = dto.longitude;

        // Handle logic when either radius or geofence is updated, or location changes affecting radius
        // If geofence is provided, recalculate radius
        if (dto.geofence !== undefined) {
            office.geofence = dto.geofence;
            if (dto.geofence && dto.geofence.included && dto.geofence.included.length > 0) {
                const center: Point = {
                    latitude: dto.latitude ?? office.latitude,
                    longitude: dto.longitude ?? office.longitude
                };
                office.radius = this.calculateGeofenceBoundingRadius(center, dto.geofence);
            } else if (dto.radius !== undefined) {
                // specific radius provided with empty/null geofence
                office.radius = dto.radius;
            }
        } else if (dto.radius !== undefined) {
            // Only radius updated, or fallback
            // If we have an existing geofence and only radius came in, maybe we should respect it or recalculate?
            // User requirement: "auto-calc radius ... if geofence is present". 
            // If we are just updating radius manual toggle, we use that.
            let finalRadius = dto.radius;
            // logic: if geofence exists in DB and wasn't cleared, we might want to recalculate if lat/long changed?
            // But let's stick to simplest implementation: if geofence is passed in DTO, we recalc. 
            // If just radius passed, we trust valid input.
            // However, if lat/long changed and we have a geofence, we should probably recalc.

            if (office.geofence && office.geofence.included && office.geofence.included.length > 0 && (dto.latitude || dto.longitude)) {
                const center: Point = {
                    latitude: dto.latitude ?? office.latitude,
                    longitude: dto.longitude ?? office.longitude
                };
                finalRadius = this.calculateGeofenceBoundingRadius(center, office.geofence);
            }
            office.radius = finalRadius;
        }

        if (dto.wifiSsid !== undefined) office.wifiSsid = dto.wifiSsid;

        await office.save();
        return office;
    }

    static async deleteOffice(id: string) {
        const office = await OfficeConfig.findByPk(id);
        if (!office) {
            throw new Error("Office not found");
        }
        await office.destroy();
        return { message: "Office deleted successfully" };
    }

    /**
     * Calculates the great-circle distance between two points on the Earth's surface 
     * using the Haversine formula.
     * @param {Point} point1 - The starting coordinate object containing latitude and longitude.
     * @param {Point} point2 - The destination coordinate object containing latitude and longitude.
     * @returns {number} The straight-line distance between the two points in meters.
     */
    static calculateDistance = (
        point1: Point,
        point2: Point,
    ): number => {
        const R = 6371e3; // Earth radius in meters
        const phi1 = (point1.latitude * Math.PI) / 180;
        const phi2 = (point2.latitude * Math.PI) / 180;
        const deltaPhi = ((point2.latitude - point1.latitude) * Math.PI) / 180;
        const deltaLambda = ((point2.longitude - point1.longitude) * Math.PI) / 180;

        const a =
            Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
            Math.cos(phi1) *
            Math.cos(phi2) *
            Math.sin(deltaLambda / 2) *
            Math.sin(deltaLambda / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c; // Distance in meters
    };

    /**
     * Determines if a geographic point resides within a defined polygon perimeter 
     * using the Even-Odd Rule (Ray Casting) algorithm.
     * @see {@link https://en.wikipedia.org/wiki/Ray_casting}
     * @param {Point} point - The target coordinates containing latitude and longitude.
     * @param {Point[]} polygon - An ordered array of points representing the polygon vertices. Must contain at least 3 points to form an area.
     * @returns {boolean} True if the point is contained within the polygon; otherwise, false.
     * @throws {TypeError} If the polygon data is malformed or null.
     */
    static isPointInPolygon = (point: Point, polygon: Point[]): boolean => {
        if (!point || !polygon || polygon.length < 3) {
            return false;
        }

        let isInside = false;
        const x = point.latitude;
        const y = point.longitude;

        for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
            const p1 = polygon[i];
            const p2 = polygon[j];

            if (!p1 || !p2) continue;

            const xi = p1.longitude, yi = p1.latitude;
            const xj = p2.longitude, yj = p2.latitude;

            // Ray Casting Logic: Check if a horizontal ray from the point intersects the polygon edge
            const intersect = ((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
            if (intersect) isInside = !isInside;
        }

        return isInside;
    }

    /**
     * Calculates the minimum radius required to encompass all points in the polygon
     * relative to the center office location.
     * @param center The central point (office location)
     * @param polygon The array of points defining the perimeter
     * @returns The maximum distance found + 20% buffer (in meters)
     */
    static calculateGeofenceBoundingRadius = (center: Point, geofence: GeofenceConfig): number => {
        if (!geofence || !geofence.included || geofence.included.length === 0) return 0;

        let maxDistance = 0;
        for (const polygon of geofence.included) {
            for (const vertex of polygon) {
                const dist = this.calculateDistance(center, vertex);
                if (dist > maxDistance) {
                    maxDistance = dist;
                }
            }
        }

        // Add a 20% buffer to handle GPS noise at the edge of the polygon
        return Math.ceil(maxDistance * 1.2);
    }

    /**
     * Checks if a point is valid within a geofence configuration.
     * Logic: Point must be inside AT LEAST ONE included zone AND inside NO excluded zones.
     */
    static isPointInGeofence = (point: Point, config: GeofenceConfig): boolean => {
        if (!config) return false;

        // Check inclusion (must be in at least one)
        let isIncluded = false;
        if (config.included && config.included.length > 0) {
            for (const polygon of config.included) {
                if (this.isPointInPolygon(point, polygon)) {
                    isIncluded = true;
                    break;
                }
            }
        } else {
            // If no inclusion zones defined, default to valid (unless strict mode expected, but usually this means 'radius only' or 'empty config')
            // However, based on user requirements "isPointInGeofence(point, config) logic: (Any Included) AND (Not Any Excluded)", implies strictly this.
            // If config exists but has empty included, it technically fails logic "Any Included".
            // But let's assume if usage passes config, it expects validation.
            isIncluded = false;
        }

        if (!isIncluded) return false;

        // Check exclusion (must be in none)
        if (config.excluded && config.excluded.length > 0) {
            for (const polygon of config.excluded) {
                if (this.isPointInPolygon(point, polygon)) {
                    return false; // Point is in an excluded zone
                }
            }
        }

        return true;
    };

}
