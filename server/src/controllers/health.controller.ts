import { Request, Response, NextFunction } from "express";
import HealthService from "@services/health.service";

export class HealthController {
	private healthService: HealthService;

	constructor() {
		this.healthService = new HealthService();
	}

	public getHealth = (_req: Request, res: Response, next: NextFunction) => {
		try {
			const status = this.healthService.getHealthStatus();
			return res.status(200).json(status);
		} catch (error) {
			return next(error);
		}
	};
}
