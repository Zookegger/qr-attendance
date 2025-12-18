import { NextFunction, Request, Response } from "express";
import { AuthService } from "../services/auth.service";

async function register(req: Request, res: Response, next: NextFunction) {
	try {
		const result = await AuthService.register(req.body);
		return res.status(201).json(result);
	} catch (error) {
		return next(error);
	}
}

async function login(req: Request, res: Response, next: NextFunction) {
	try {
		const result = await AuthService.login(req.body);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
}

async function refresh(req: Request, res: Response, next: NextFunction) {
	try {
		const { refreshToken } = req.body;
		const result = await AuthService.refresh(refreshToken);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
}

async function me(req: Request, res: Response, next: NextFunction) {
	try {
		const user = (req as any).user;
		if (!user) {
			return res.status(401).json({ message: "Unauthorized" });
		}
		return res.json(user);
	} catch (error) {
		return next(error);
	}
}

export const AuthController = {
	register,
	login,
	refresh,
	me,
};
