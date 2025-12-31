import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { User, RefreshToken } from "@models";
import { UserRole } from "@models/user";
// RefreshTokenService rotation moved to client-side flow (interceptor + /auth/refresh route)

const JWT_SECRET = process.env.JWT_SECRET || "your_jwt_secret_key";

interface JwtPayload {
	id: string;
	role: string;
}

export const authenticate = async (
	req: Request,
	res: Response,
	next: NextFunction,
) => {
	try {
		const authHeader = req.headers.authorization;
		if (!authHeader) {
			return res
				.status(401)
				.json({ message: "Authorization header missing" });
		}

		const token = authHeader.split(" ")[1];
		if (!token) {
			return res.status(401).json({ message: "Token missing" });
		}
		try {
			const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
			const user = await User.findByPk(decoded.id);

			if (!user) {
				return res.status(401).json({ message: "User not found" });
			}

			// Ensure there is an active refresh token session for this user
			const now = new Date();
			const tokenRecord = await RefreshToken.findOne({ where: { user_id: user.id }, order: [['created_at', 'DESC']] });

			if (!tokenRecord) {
				return res.status(401).json({ message: "No active session" });
			}

			if (tokenRecord.revoked) {
				return res.status(401).json({ message: "Session revoked. Please sign in again." });
			}

			if (tokenRecord.expires_at && now >= tokenRecord.expires_at) {
				await tokenRecord.update({ revoked: true });
				return res.status(401).json({ message: "Session expired. Please sign in again." });
			}

			req.user = user;
			return next();
		} catch (err: any) {
			// Let client handle refresh. Return 401 when token invalid/expired.
			return res.status(401).json({ message: "Invalid or expired token" });
		}
	} catch (error) {
		return res.status(401).json({ message: "Invalid token" });
	}
};

export const authorize = (roles: UserRole[]) => {
	return (req: Request, res: Response, next: NextFunction) => {
		if (!req.user) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		if (!roles.includes(req.user.role)) {
			return res.status(403).json({ message: "Forbidden" });
		}

		return next();
	};
};
