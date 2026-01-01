import bcrypt from "bcrypt";
import crypto from "crypto";
import { Op } from "sequelize";
<<<<<<< HEAD
import { User, RefreshToken } from "@models";
import { UserRole } from "@models/user";
import { AuthResponse } from "@my-types/auth";
import { emailQueue } from "@utils/queues/emailQueue";
import EmailService from "./email.service";
import RefreshTokenService from "./refreshToken.service";
import { database } from "@config/index";
=======
import { User } from "@models";
import { UserRole } from "@models/user";
import { LoginDTO, AuthResponse } from "@my-types/auth";
import {
	generateRefreshToken,
	rotateRefreshToken,
	revokeRefreshToken,
} from "./refreshToken.service";
import { emailQueue } from "@utils/queues/emailQueue";
import { EmailService } from "./email.service";
>>>>>>> 2b987e63c41171be42634f317c09b78ab48e0fd8

export default class AuthService {
	static async login(email: string, password: string, device_uuid: string, device_name: string, device_model: string, device_os_version: string): Promise<AuthResponse> {
		const user = await User.findOne({ where: { email } });
		if (!user) {
			throw new Error("Invalid credentials");
		}

		if (!user.device_name) user.device_model = device_name;
		if (!user.device_model) user.device_model = device_model;
		if (!user.device_os_version) user.device_os_version = device_os_version;
		await user.save();

		const isMatch = await bcrypt.compare(password, user.password_hash);
		if (!isMatch) {
			throw new Error("Invalid credentials");
		}

		// Device Binding Check (Only for non-admin users)
		if (user.role === UserRole.USER) {
			if (!device_uuid) {
				throw new Error("Device UUID is required for login");
			}

			if (user.device_uuid && user.device_uuid !== device_uuid) {
				throw new Error("This account is bound to another device.");
			}

			// Bind device if not bound
			if (!user.device_uuid) {
				user.device_uuid = device_uuid;
				await user.save();
			}
		}

		// Use RefreshTokenService to generate tokens
		const { accessToken, refreshToken } = await RefreshTokenService.generateRefreshToken(user, {
			id: user.id,
			role: user.role,
		});

		return {
			accessToken,
			refreshToken,
			user: {
				id: user.id,
				name: user.name,
				email: user.email,
				role: user.role,
				device_uuid: user.device_uuid,
			},
		};
	}

	static async logout(refreshToken: string): Promise<void> {
		if (!refreshToken) return;
		await RefreshTokenService.revokeRefreshToken(refreshToken);
	}

	static async forgotPassword(email: string): Promise<void> {
		if (!email) {
			throw { status: 400, message: "" };
		}

		const user = await User.findOne({ where: { email } });
		if (!user) {
			// avoid leaking which emails exist if desired — adjust message accordingly
			throw { status: 404, message: "User not found" };
		}

		// generate a one-time token and persist it (adjust fields to your schema)
		const token = crypto.randomBytes(32).toString("hex");
		const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 hour

		await user.update({
			password_reset_token: token,
			password_reset_expires: expiresAt
		});

		const resetLink = `${process.env.API_URL}/auth/reset-password?token=${token}&email=${encodeURIComponent(
			email
		)}`;

		await emailQueue.add(
			"send", // job name
			{
				to: email,
				subject: "Password reset request",
				html: EmailService.generateResetPasswordHTML(
					user.name ?? "User",
					resetLink
				),
				text: `Reset your password: ${resetLink}`,
			},
			{
				attempts: 3,
				backoff: { type: "exponential", delay: 60_000 },
				removeOnComplete: { age: 3600 },
			}
		);
	}

	static async resetPassword(
		email: string,
		token: string,
		newPassword: string
	): Promise<void> {
		const user = await User.findOne({
			where: {
				email,
				password_reset_token: token,
				password_reset_expires: { [Op.gt]: new Date() },
			},
		});

		if (!user) {
			throw { status: 400, message: "Invalid or expired password reset token" };
		}

		const salt = await bcrypt.genSalt(10);
		await user.update({
			password_hash: await bcrypt.hash(newPassword, salt),
			password_reset_token: null,
			password_reset_expires: null
		});

		// Revoke all sessions
		await this.revokeUserSessions(user.id);
	}

	static async forgotPassword(email: string): Promise<void> {
		// TODO: Implement Email Queue

		if (!email) {
			throw { status: 400, message: "" };
		}

		const user = await User.findOne({ where: { email } });
		if (!user) {
			// avoid leaking which emails exist if desired — adjust message accordingly
			throw { status: 404, message: "User not found" };
		}

		// generate a one-time token and persist it (adjust fields to your schema)
		const token = crypto.randomBytes(32).toString("hex");
		const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 hour

		// persist token — update to match your DB model (example fields)
		// if your User model doesn't have these fields, create a PasswordReset table instead
		(user as any).password_reset_token = token;
		(user as any).password_reset_expires = expiresAt;
		await user.save();

		const resetLink = `${process.env.API_URL}/auth/reset-password?token=${token}&email=${encodeURIComponent(
			email
		)}`;

		await emailQueue.add(
			"send", // job name
			{
				to: email,
				subject: "Password reset request",
				html: EmailService.generateResetPasswordHTML(
					user.name ?? "User",
					resetLink
				),
				text: `Reset your password: ${resetLink}`,
			},
			{
				attempts: 3,
				backoff: { type: "exponential", delay: 60_000 },
				removeOnComplete: { age: 3600 },
			}
		);
	}

	static async resetPassword(
		email: string,
		token: string,
		newPassword: string
	): Promise<void> {
		const user = await User.findOne({
			where: {
				email,
				password_reset_token: token,
				password_reset_expires: { [Op.gt]: new Date() },
			},
		});

		if (!user) {
			throw { status: 400, message: "Invalid or expired password reset token" };
		}

		const salt = await bcrypt.genSalt(10);
		user.password_hash = await bcrypt.hash(newPassword, salt);
		user.password_reset_token = null;
		user.password_reset_expires = null;
		await user.save();
	}

	static async refresh(tokenString: string): Promise<AuthResponse> {
		// Use RefreshTokenService to rotate tokens
		const { accessToken, refreshToken, user } = await RefreshTokenService.rotateRefreshToken(
			tokenString
		);

		return {
			accessToken,
			refreshToken,
			user: {
				id: user.id,
				name: user.name,
				email: user.email,
				role: user.role,
				device_uuid: user.device_uuid,
			},
		};
	}

	static async changePassword(userId: string, currentPassword: string, newPassword: string, confirmNewPassword: string): Promise<void> {
		// Validate input
		if (!userId || !currentPassword || !newPassword || !confirmNewPassword) {
			throw new Error("All fields are required");
		}

		// Validate password strength
		if (newPassword.length < 6) {
			throw new Error("New password must be at least 6 characters long");
		}

		// Check if new password and confirmation match
		if (newPassword !== confirmNewPassword) {
			throw new Error("New password and confirmation do not match");
		}

		// Find the user
		const user = await User.findByPk(userId);
		if (!user) {
			throw new Error("User not found");
		}

		// Verify current password
		const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
		if (!isCurrentPasswordValid) {
			throw new Error("Current password is incorrect");
		}

		// Check if new password is different from current
		const isSameAsCurrent = await bcrypt.compare(newPassword, user.password_hash);
		if (isSameAsCurrent) {
			throw new Error("New password must be different from current password");
		}

		// Hash the new password
		const salt = await bcrypt.genSalt(10);
		const hashedNewPassword = await bcrypt.hash(newPassword, salt);

		// Update the user's password
		await user.update({ password_hash: hashedNewPassword });

		// Revoke all sessions
		await this.revokeUserSessions(user.id);
	}

	static async revokeUserSessions(userId: string) {
		const transaction = await database.transaction();
		try {
			const user = await User.findByPk(userId, { transaction });
			if (!user) {
				throw new Error("User not found for session revocation.");
			}

			await user.update({ device_uuid: null, device_name: null, device_model: null, device_os_version: null }, { transaction });

			await RefreshToken.update(
				{ revoked: true },
				{ where: { user_id: userId }, transaction }
			);

			await transaction.commit();
		} catch (err) {
			await transaction.rollback();
			throw err;
		}
	}
}
