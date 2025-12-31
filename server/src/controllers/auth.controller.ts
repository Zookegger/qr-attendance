import { NextFunction, Request, Response } from "express";
import AuthService from "@services/auth.service";
import { validationResult } from "express-validator";
import { ChangePasswordDTO, LoginRequestDTO, LogoutRequestDTO, RefreshRequestDTO, ForgotPasswordRequestDTO, ResetPasswordRequestDTO } from "@my-types/auth";
import { RefreshToken, User } from "@models";

const login = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const dto: LoginRequestDTO = req.body;
		const result = await AuthService.login(dto.email, dto.password, dto.device_uuid);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
};

const logout = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const dto: LogoutRequestDTO = req.body;
		await AuthService.logout(dto.refreshToken);
		return res.status(200).json({ success: true, message: "Logged out successfully" });
	} catch (error) {
		return next(error);
	}
};

const refresh = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const dto: RefreshRequestDTO = req.body;
		const result = await AuthService.refresh(dto.refreshToken);
		return res.status(200).json(result);
	} catch (error) {
		return next(error);
	}
};

const me = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user: User = req.user as User;

		if (!user) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		const now = new Date();
		const token = await RefreshToken.findOne({ where: { user_id: user.id }, order: [['created_at', 'DESC']] });

		if (!token) {
			return res.status(401).json({ message: "No active session" });
		}

		if (token.revoked) {
			return res.status(401).json({ message: "Session revoked. Please sign in again." });
		}

		if (token.expires_at && now >= token.expires_at) {
			await token.update({ revoked: true });
			return res.status(401).json({ message: "Session expired. Please sign in again." });
		}

		// If middleware rotated tokens, it will expose them via response headers.
		const newAccess = res.getHeader ? res.getHeader('x-access-token') : undefined;
		const newRefresh = res.getHeader ? res.getHeader('x-refresh-token') : undefined;

		if (newAccess || newRefresh) {
			return res.status(200).json({
				accessToken: String(newAccess || ''),
				refreshToken: String(newRefresh || ''),
				user: {
					id: user.id,
					name: user.name,
					email: user.email,
					role: user.role,
					device_uuid: user.device_uuid,
				},
			});
		}

		return res.json(user);
	} catch (error) {
		return next(error);
	}
};

const forgotPassword = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const dto: ForgotPasswordRequestDTO = req.body;
		await AuthService.forgotPassword(dto.email);
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
		const dto: ResetPasswordRequestDTO = req.body;

		if (!dto.email || !dto.token || !dto.newPassword) {
			return res.status(400).json({ message: "Missing required fields" });
		}

		await AuthService.resetPassword(dto.email, dto.token, dto.newPassword);

		return res.status(200).json({ success: true, message: "Password reset successfully" });
	} catch (error) {
		return next(error);
	}
};

const changePassword = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	try {
		const user = (req as any).user;
		if (!user) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		const dto: ChangePasswordDTO = req.body;
		const { currentPassword, newPassword, confirmNewPassword } = dto;

		await AuthService.changePassword(user.id, currentPassword, newPassword, confirmNewPassword);
		return res.status(200).json({ success: true, message: "Password changed successfully" });
	} catch (error) {
		return next(error);
	}
}

export const AuthController = {
	login,
	logout,
	refresh,
	me,
	forgotPassword,
	resetPasswordLanding,
	resetPassword,
	changePassword
};
