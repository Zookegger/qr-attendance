import { Request, Response } from "express";
import StatisticsService from "@services/statistics.service";

export default class StatisticsController {
	/**
	 * GET /api/statistics/personal/:userId
	 * Get personal statistics for a user
	 */
	static async getPersonalStats(req: Request, res: Response): Promise<void> {
		try {
			const { userId } = req.params;
			if (!userId) {
				res.status(400).json({
					success: false,
					message: "User ID is required",
				});
				return;
			}

			const { month, year } = req.query;

			const monthNum = month ? parseInt(month as string) : undefined;
			const yearNum = year ? parseInt(year as string) : undefined;

			const stats = await StatisticsService.getPersonalStats(
				userId,
				monthNum,
				yearNum
			);

			res.json({
				success: true,
				data: stats,
			});
		} catch (error) {
			console.error("Error fetching personal stats:", error);
			res.status(500).json({
				success: false,
				message: "Failed to fetch personal statistics",
			});
		}
	}

	/**
	 * GET /api/statistics/today/:userId
	 * Get today's shift status for a user
	 */
	static async getTodayShift(req: Request, res: Response): Promise<void> {
		try {
			const { userId } = req.params;
			if (!userId) {
				res.status(400).json({
					success: false,
					message: "User ID is required",
				});
				return;
			}

			const shift = await StatisticsService.getTodayShift(userId);

			res.json({
				success: true,
				data: shift,
			});
		} catch (error) {
			console.error("Error fetching today's shift:", error);
			res.status(500).json({
				success: false,
				message: "Failed to fetch today's shift",
			});
		}
	}

	/**
	 * GET /api/statistics/team
	 * Get team statistics for today (managers/admins only)
	 */
	static async getTeamStats(_req: Request, res: Response) {
		try {
			const stats = await StatisticsService.getTeamStats();

			res.json({
				success: true,
				data: stats,
			});
		} catch (error) {
			console.error("Error fetching team stats:", error);
			res.status(500).json({
				success: false,
				message: "Failed to fetch team statistics",
			});
		}
	}

	/**
	 * GET /api/statistics/team/details
	 * Get detailed team attendance for today (managers/admins only)
	 */
	static async getTeamAttendanceDetails(_req: Request, res: Response) {
		try {
			const details = await StatisticsService.getTeamAttendanceDetails();

			res.json({
				success: true,
				data: details,
			});
		} catch (error) {
			console.error("Error fetching team attendance details:", error);
			res.status(500).json({
				success: false,
				message: "Failed to fetch team attendance details",
			});
		}
	}
}
