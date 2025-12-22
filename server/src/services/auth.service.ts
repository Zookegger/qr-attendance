import bcrypt from "bcrypt";
import { User } from "@models";
import { UserRole } from "@models/user";
import { LoginDTO, AuthResponse } from "@my-types/auth";
import {
	generateRefreshToken,
	rotateRefreshToken,
	revokeRefreshToken,
} from "./refreshToken.service";

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
