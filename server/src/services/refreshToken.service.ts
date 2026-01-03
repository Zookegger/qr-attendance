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
	deviceUuid: string;
}

export default class RefreshTokenService {
	/**
	 * Generates a new Access/Refresh token pair.
	 * Returns a "Composite Key" for the refresh token: [DB_ID].[RAW_SECRET]
	 */
	static generateRefreshToken = async (
		user: User,
		payload: RefreshTokenPayload,

	): Promise<{ refreshToken: string; accessToken: string }> => {
		// 1. Generate Access Token (JWT)
		const accessToken = jwt.sign(payload, JWT_SECRET, {
			expiresIn: ACCESS_TOKEN_EXPIRES as ms.StringValue,
		});

		// 2. Generate Refresh Token (Opaque / Reference Token)
		const refreshRaw = crypto.randomBytes(64).toString("hex");

		// Hash the raw token before storing (Security Best Practice)
		const refreshHash = crypto
			.createHash("sha256")
			.update(refreshRaw)
			.digest("hex");

		const refreshExpires = new Date(
			Date.now() + REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000
		);

		const tokenRecord = await RefreshToken.create({
			userId: user.id,
			tokenHash: refreshHash,
			deviceUuid: payload.deviceUuid,
			expiresAt: refreshExpires,
			revoked: false,
		});

		// 3. Return Composite Key: ID + Secret
		// This allows us to look up the token by ID (fast) then verify the secret (secure)
		return {
			accessToken,
			refreshToken: `${tokenRecord.id}.${refreshRaw}`,
		};
	};

	/**
	 * Validates a refresh token string, checks revocation, expiration, and hash match.
	 */
	static verifyRefreshToken = async (
		tokenString: string
	): Promise<RefreshToken> => {
		// 1. Split Composite Key
		const parts = tokenString.split(".");
		if (parts.length !== 2) {
			throw new Error("Invalid refresh token format");
		}

		const [tokenId, tokenSecret] = parts;

		if (!tokenSecret) {
			throw new Error("Invalid refresh token format: missing token secret");
		}

		// 2. Find Token in DB
		const tokenRecord = await RefreshToken.findByPk(tokenId, {
			include: [{ model: User, as: "user" }], // Eager load user for role checks later
		});

		if (!tokenRecord) {
			throw new Error("Invalid refresh token");
		}

		// 3. Security Checks
		if (tokenRecord.revoked) {
			// TODO: Implement Token Reuse Detection here (revoke all user tokens if this happens)
			throw new Error("Refresh token revoked");
		}

		if (new Date() > tokenRecord.expiresAt) {
			throw new Error("Refresh token expired");
		}

		// 4. Verify Hash
		const inputHash = crypto
			.createHash("sha256")
			.update(tokenSecret)
			.digest("hex");

		// Use timingSafeEqual to prevent timing attacks
		const hashMatch = crypto.timingSafeEqual(
			Buffer.from(inputHash),
			Buffer.from(tokenRecord.tokenHash)
		);

		if (!hashMatch) {
			throw new Error("Invalid refresh token");
		}

		return tokenRecord;
	};

	/**
	 * The main flow: Verify old token -> Revoke it -> Issue new pair
	 */
	static rotateRefreshToken = async (
		oldRefreshTokenString: string,
		deviceUuid: string,
	): Promise<{ refreshToken: string; accessToken: string; user: User }> => {
		// 1. Verify and fetch the record from DB
		const tokenRecord = await this.verifyRefreshToken(oldRefreshTokenString);

		// 2. Validate Device Binding (Security Check)
		// Ensure the device trying to refresh is the same one that created the token
		if (!tokenRecord.deviceUuid || tokenRecord.deviceUuid !== deviceUuid) {
			// Optional: Revoke token immediately if this looks like a theft attempt
			await tokenRecord.update({ revoked: true });
			throw new Error("Invalid device for this session");
		}

		// 3. Revoke the used token (Rotation)
		await tokenRecord.update({ revoked: true });

		// 4. Ensure User exists
		const user = await User.findByPk(tokenRecord.userId);
		if (!user) throw new Error("User not found");

		// 5. Generate New Pair
		const tokens = await this.generateRefreshToken(user, {
			id: user.id,
			role: user.role as UserRole,
			deviceUuid: tokenRecord.deviceUuid
		},);

		return { ...tokens, user };
	};

	/**
	 * Standard logout (revoke)
	 */
	static revokeRefreshToken = async (
		tokenString: string
	): Promise<void> => {
		try {
			const [tokenId] = tokenString.split(".");
			if (!tokenId) return;

			await RefreshToken.update(
				{ revoked: true },
				{ where: { id: tokenId } }
			);
		} catch (error) {
			// Ignore errors on logout (don't block the user)
		}
	};

	static listUserSessions = async (userId: string): Promise<RefreshToken[] | null> => {
		try {
			const user = await User.findByPk(userId);
			if (!user) throw new Error("User not found");
			const tokens = await RefreshToken.findAll({ where: { userId: userId } });
			return tokens;
		} catch (err) {
			throw err;
		}
	}
}