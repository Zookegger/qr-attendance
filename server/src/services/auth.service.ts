import bcrypt from "bcrypt";
import crypto from "crypto";
import { Op } from "sequelize";
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

export class AuthService {
	static async login(dto: LoginDTO): Promise<AuthResponse> {
		const user = await User.findOne({ where: { email: dto.email } });
		if (!user) {
			throw new Error("Invalid credentials");
		}

		const isMatch = await bcrypt.compare(dto.password, user.password_hash);
		if (!isMatch) {
			throw new Error("Invalid credentials");
		}

		// Device Binding Check (Only for non-admin users)
		if (user.role === UserRole.USER) {
			if (!dto.device_uuid) {
				throw new Error("Device UUID is required for login");
			}

			if (user.device_uuid && user.device_uuid !== dto.device_uuid) {
				throw new Error("This account is bound to another device.");
			}

			// Bind device if not bound
			if (!user.device_uuid) {
				user.device_uuid = dto.device_uuid;
				await user.save();
			}
		}

		// Use RefreshTokenService to generate tokens
		const { accessToken, refreshToken } = await generateRefreshToken(user, {
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
		await revokeRefreshToken(refreshToken);
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
		const { accessToken, refreshToken, user } = await rotateRefreshToken(
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
}
