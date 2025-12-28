import { NextFunction, Request, Response } from "express";
import { AuthService } from "@services/auth.service";

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
		const { refreshToken } = req.body;
		await AuthService.logout(refreshToken);
		return res.status(200).json({ success: true, message: "Logged out successfully" });
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

const forgotPassword = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const { email } = req.body;


		await AuthService.forgotPassword(email);
		return res.status(200).json({ success: true, message: "Password reset email sent" });
	} catch (error) {
		return next(error);
	}
};

const resetPasswordLanding = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const { token, email } = req.query;

		if (!token || !email) {
			return res.status(400).send("Missing token or email");
		}

		const deepLink = `qrattendance://reset-password?token=${token}&email=${email}`;

		const html = `
			<!DOCTYPE html>
			<html>
			<head>
			<title>Redirecting...</title>
			<script>
				window.onload = function() {
					window.location.href = "${deepLink}";
				};
			</script>
			</head>
			<body style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; font-family: sans-serif;">
			<p>Redirecting to the app...</p>
			<a href="${deepLink}" style="padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px;">Open App</a>
			</body>
			</html>
		`;

		return res.send(html);
	} catch (error) {
		return next(error);
	}
};

const resetPassword = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const { email, token, newPassword } = req.body;

		if (!email || !token || !newPassword) {
			return res.status(400).json({ message: "Missing required fields" });
		}

		await AuthService.resetPassword(email, token, newPassword);
		return res.status(200).json({ success: true, message: "Password reset successfully" });
	} catch (error) {
		return next(error);
	}
};

export const AuthController = {
	login,
	logout,
	refresh,
	me,
	forgotPassword,
	resetPasswordLanding,
	resetPassword,
};
