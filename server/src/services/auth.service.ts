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
		deviceUuid: string,
		deviceName: string,
		deviceModel: string,
		deviceOsVersion: string,
		fcmToken?: string
	): Promise<AuthResponse> {
		const user = await User.findOne({ where: { email } });
		if (!user) throw new Error("Invalid credentials");

		const isMatch = await bcrypt.compare(password, user.passwordHash);
		if (!isMatch) throw new Error("Invalid credentials");

		if (!deviceUuid) throw new Error("Device UUID is required for login");

		// ===== SECURITY CHECKS =====
		
		// 1. Check for active sessions (non-revoked refresh tokens)
		const activeSessions = await RefreshToken.findAll({
			where: {
				userId: user.id,
				revoked: false,
				expiresAt: { [Op.gt]: new Date() }
			}
		});

		if (activeSessions.length > 0) {
			// 2. Check if any active session matches the current device UUID
			const matchingSession = activeSessions.find(
				session => session.deviceUuid === deviceUuid
			);

			if (!matchingSession) {
				// Active session exists but UUID doesn't match
				throw new Error(
					"This account has an active session on another device. " +
					"Please contact an administrator to revoke the existing session before logging in from a new device."
				);
			}

			// UUID matches - allow login by revoking old token and creating new one
			await RefreshToken.update(
				{ revoked: true },
				{ where: { id: matchingSession.id } }
			);
		}

		// 3. Check device binding for regular users
		let device = await UserDevice.findOne({ where: { userId: user.id, deviceUuid } });

		if (device) {
			// Update existing device (including FCM)
			console.log("Updating device:", {
				userId: user.id,
				deviceUuid,
				fcmToken,
				deviceName,
				deviceModel,
				deviceOsVersion
			});
			await device.update({
				deviceName,
				deviceModel,
				deviceOsVersion,
				lastLogin: new Date(),
				fcmToken: fcmToken ?? device.fcmToken
			});
		} else {
			// Check Binding Constraints
			if (user.role === UserRole.USER) {
				const deviceCount = await UserDevice.count({ where: { userId: user.id } });
				if (deviceCount >= 1) {
					throw new Error("This account is already bound to another device. Contact admin to reset.");
				}
			}

			// Create new device (including FCM)
			console.log("Creating device:", {
				userId: user.id,
				deviceUuid,
				fcmToken,
				deviceName,
				deviceModel,
				deviceOsVersion
			});
			device = await UserDevice.create({
				userId: user.id,
				deviceUuid,
				deviceName,
				deviceModel,
				deviceOsVersion,
				fcmToken: fcmToken
			});
		}

		const { accessToken, refreshToken } = await RefreshTokenService.generateRefreshToken(
			user,
			{ id: user.id, role: user.role, deviceUuid: device.deviceUuid },
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

	static async verifyPassword(email: string, password: string): Promise<boolean> {
		const user = await User.findOne({ where: { email } });
		if (!user) return false;

		const isMatch = await bcrypt.compare(password, user.passwordHash);
		return isMatch;
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
			passwordResetToken: token,
			passwordResetExpires: expiresAt
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
				passwordResetToken: token,
				passwordResetExpires: { [Op.gt]: new Date() },
			},
		});

		if (!user) {
			throw { status: 400, message: "Invalid or expired password reset token" };
		}

		const salt = await bcrypt.genSalt(10);
		await user.update({
			passwordHash: await bcrypt.hash(newPassword, salt),
			passwordResetToken: null,
			passwordResetExpires: null
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
		const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
		if (!isCurrentPasswordValid) {
			throw new Error("Current password is incorrect");
		}

		// Check if new password is different from current
		const isSameAsCurrent = await bcrypt.compare(newPassword, user.passwordHash);
		if (isSameAsCurrent) {
			throw new Error("New password must be different from current password");
		}

		// Hash the new password
		const salt = await bcrypt.genSalt(10);
		const hashedNewPassword = await bcrypt.hash(newPassword, salt);

		// Update the user's password
		await user.update({ passwordHash: hashedNewPassword });

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
			await UserDevice.destroy({ where: { userId: userId }, transaction });

			await RefreshToken.update(
				{ revoked: true },
				{ where: { userId: userId }, transaction }
			);

			await transaction.commit();
		} catch (err) {
			await transaction.rollback();
			throw err;
		}
	}
}
