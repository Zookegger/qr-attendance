import bcrypt from "bcrypt";
import crypto from "crypto";
import { Op } from "sequelize";
import { User, RefreshToken, UserDevice } from "@models";
import { UserRole } from "@models/user";
import { AuthResponse } from "@my-types/auth";
import { emailQueue } from "@utils/queues/emailQueue";
import EmailService from "./email.service";
import RefreshTokenService from "./refreshToken.service";
import { database } from "@config/index";

export default class AuthService {
	// server/src/services/auth.service.ts

	static async login(
		email: string,
		password: string,
		device_uuid: string,
		device_name: string,
		device_model: string,
		device_os_version: string,
		fcm_token?: string
	): Promise<AuthResponse> {
		const user = await User.findOne({ where: { email } });
		if (!user) throw new Error("Invalid credentials");

		const isMatch = await bcrypt.compare(password, user.password_hash);
		if (!isMatch) throw new Error("Invalid credentials");

		if (!device_uuid) throw new Error("Device UUID is required for login");

		let device = await UserDevice.findOne({ where: { user_id: user.id, device_uuid } });

		if (device) {
			//  Update existing device (including FCM)
			await device.update({
				device_name,
				device_model,
				device_os_version,
				last_login: new Date(),
				fcm_token: fcm_token ?? device.fcm_token // <--- Update here
			});
		} else {
			// Check Binding Constraints
			if (user.role === UserRole.USER) {
				const deviceCount = await UserDevice.count({ where: { user_id: user.id } });
				if (deviceCount >= 1) {
					// This logic ALREADY protects you. The controller check was redundant.
					throw new Error("This account is already bound to another device. Contact admin to reset.");
				}
			}

			// Create new device (including FCM)
			device = await UserDevice.create({
				user_id: user.id,
				device_uuid,
				device_name,
				device_model,
				device_os_version,
				fcm_token: fcm_token || null // <--- Insert here
			});
		}

		const { accessToken, refreshToken } = await RefreshTokenService.generateRefreshToken(
			user,
			{ id: user.id, role: user.role, deviceUuid: device.device_uuid },
		);

		return {
			accessToken,
			refreshToken,
			user: {
				id: user.id,
				name: user.name,
				email: user.email,
				role: user.role,
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
		await this.revokeAllUserSessions(user.id);
	}

	static async refresh(tokenString: string, deviceUuid: string): Promise<AuthResponse> {
		// Use RefreshTokenService to rotate tokens
		const { accessToken, refreshToken, user } = await RefreshTokenService.rotateRefreshToken(
			tokenString,
			deviceUuid,
		);

		return {
			accessToken,
			refreshToken,
			user: {
				id: user.id,
				name: user.name,
				email: user.email,
				role: user.role,
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
		await this.revokeAllUserSessions(user.id);
	}

	static async revokeAllUserSessions(userId: string) {
		const transaction = await database.transaction();
		try {
			const user = await User.findByPk(userId, { transaction });
			if (!user) {
				throw new Error("User not found for session revocation.");
			}

			// Remove device bindings for this user
			await UserDevice.destroy({ where: { user_id: userId }, transaction });

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
