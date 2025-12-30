import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { User } from "@models";
import { UserRole } from "@models/user";

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

		const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
		const user = await User.findByPk(decoded.id);

		if (!user) {
			return res.status(401).json({ message: "User not found" });
		}

		req.user = user;
		return next();
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
