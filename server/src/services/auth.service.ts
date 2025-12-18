import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { User, RefreshToken } from "@models";
import { UserRole } from "@models/user";
import { RegisterDTO, LoginDTO, AuthResponse } from "@my-types/auth";

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key";
const REFRESH_TOKEN_DAYS = Number(process.env.REFRESH_TOKEN_DAYS) || 30;

export class AuthService {
	static async register(dto: RegisterDTO): Promise<AuthResponse> {
		const existingUser = await User.findOne({ where: { email: dto.email } });
		if (existingUser) {
			throw new Error("Email already exists");
		}

		const passwordHash = await bcrypt.hash(dto.password, 10);

		const user = await User.create({
			name: dto.name,
			email: dto.email,
			password_hash: passwordHash,
			role: dto.role,
			position: dto.position,
			department: dto.department,
			status: "ACTIVE", // Default status
		} as any);

		return this.generateAuthResponse(user, null);
	}

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

		return this.generateAuthResponse(user, dto.device_uuid || null);
	}

	static async refresh(tokenString: string): Promise<AuthResponse> {
		const parts = tokenString.split(".");
		if (parts.length !== 2) {
			throw new Error("Invalid refresh token format");
		}

		const [tokenId, tokenSecret] = parts;

		if (!tokenId || !tokenSecret) {
			throw new Error("Invalid refresh token format");
		}

		const refreshTokenRecord = await RefreshToken.findByPk(tokenId);
		if (!refreshTokenRecord) {
			throw new Error("Invalid refresh token");
		}

		if (refreshTokenRecord.revoked) {
			// Token reuse detection could go here (revoke all user tokens)
			throw new Error("Refresh token revoked");
		}

		if (new Date() > refreshTokenRecord.expires_at) {
			throw new Error("Refresh token expired");
		}

		const isValid = await bcrypt.compare(
			tokenSecret,
			refreshTokenRecord.token_hash
		);
		if (!isValid) {
			throw new Error("Invalid refresh token");
		}

		// Rotate Token: Revoke the old one
		refreshTokenRecord.revoked = true;
		await refreshTokenRecord.save();

		const user = await User.findByPk(refreshTokenRecord.user_id);
		if (!user) {
			throw new Error("User not found");
		}

		// Create a new one
		return this.generateAuthResponse(user, refreshTokenRecord.device_uuid || null);
	}

	private static async generateAuthResponse(
		user: User,
		deviceUuid: string | null
	): Promise<AuthResponse> {
		// Issue short-lived access token
		const accessToken = jwt.sign(
			{ id: user.id, role: user.role },
			JWT_SECRET,
			{
				expiresIn: "15m",
			}
		);

		// Generate Refresh Token
		const randomSecret = crypto.randomBytes(32).toString("hex");
		const tokenHash = await bcrypt.hash(randomSecret, 10);
		const expiresAt = new Date(
			Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000
		);

		const refreshTokenRecord = await RefreshToken.create({
			user_id: user.id,
			token_hash: tokenHash,
			device_uuid: deviceUuid,
			revoked: false,
			expires_at: expiresAt,
		});

		// Composite Key: [db_id].[random_secret]
		const compositeRefreshToken = `${refreshTokenRecord.id}.${randomSecret}`;

		return {
			accessToken,
			refreshToken: compositeRefreshToken,
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
