import { NextFunction, Request, Response } from "express";
import { AuthService } from "../services/auth.service";

const login = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const result = await AuthService.login(req.body);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
};

const logout = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = (req as any).user;

		const isLoggedout = await AuthService.logout(user);

		return res.status(200).json();
	} catch (error) {
		return next(error);
	}
};

const refresh = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const { refreshToken } = req.body;
		const result = await AuthService.refresh(refreshToken);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
};

const me = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = (req as any).user;
		if (!user) {
			return res.status(401).json({ message: "Unauthorized" });
		}
		return res.json(user);
	} catch (error) {
		return next(error);
	}
};

export const AuthController = {
	login,
	logout,
	refresh,
	me,
};
