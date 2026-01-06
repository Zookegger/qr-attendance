import { Point } from "@models/officeConfig";


/**
 * Calculates the great-circle distance between two points on the Earth's surface 
 * using the Haversine formula.
 * @param {Point} point1 - The starting coordinate object containing latitude and longitude.
 * @param {Point} point2 - The destination coordinate object containing latitude and longitude.
 * @returns {number} The straight-line distance between the two points in meters.
 */
export const calculateDistance = (
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
 * @param {Point[]} polygon - An ordered array of points representing the polygon vertices. 
 * Must contain at least 3 points to form an area.
 * @returns {boolean} True if the point is contained within the polygon; otherwise, false.
 * @throws {TypeError} If the polygon data is malformed or null.
 */
export const isPointInPolygon = (point: Point, polygon: Point[]): boolean => {
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