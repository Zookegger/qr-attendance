import { RefreshToken, User } from "@models";
import { UserRole } from "@models/user";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import ms from "ms";

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key";
const ACCESS_TOKEN_EXPIRES = process.env.ACCESS_TOKEN_EXPIRES || "15m";
const REFRESH_TOKEN_DAYS = Number(process.env.REFRESH_TOKEN_DAYS || 30);

interface RefreshTokenPayload {
	id: string;
	role: UserRole;
}

export const generateRefreshToken = async (
	user: User,
	payload: RefreshTokenPayload
): Promise<{ refreshToken: string; accessToken: string }> => {
	const accessToken = jwt.sign(payload, JWT_SECRET, {
		expiresIn: ACCESS_TOKEN_EXPIRES as ms.StringValue,
	});

	const refreshRaw = crypto.randomBytes(64).toString("hex");
	const refreshHash = crypto
		.createHash("sha256")
		.update(refreshRaw)
		.digest("hex");
	const refreshExpires = new Date(
		Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000
	);

	await RefreshToken.create({
		user_id: user.id,
		token_hash: refreshHash,
		device_uuid: user.device_uuid || null,
		expires_at: refreshExpires,
		revoked: false,
	});

	return { accessToken, refreshToken: refreshRaw };
};
