import { NextFunction, Request, Response } from "express";
import AdminService  from "@services/admin.service";
import { UserRole } from "@models/user";
import { validationResult } from "express-validator";
import logger from "@utils/logger";
import AuthService from "@services/auth.service";

const generateQR = async (req: Request, res: Response, next: NextFunction) => {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const officeId = req.query.officeId ? parseInt(req.query.officeId as string, 10) : undefined;
		const result = await AdminService.generateQR(officeId);
		return res.json(result);
	} catch (error) {
		return next(error);
	}
};

const getOfficeConfig = async (req: Request, res: Response, next: NextFunction) => {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const config = await AdminService.listOfficeConfig();
		return res.json(config);
	} catch (error) {
		return next(error);
	}
};

const updateOfficeConfig = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		// const { latitude, longitude, radius, wifi_ssid } =
		// 	req.body;

		// const config = await AdminService.updateOfficeConfig({
		// 	latitude,
		// 	longitude,
		// 	radius,
		// 	wifi_ssid,
		// });
		// return res.json({ message: "Configuration updated", config });
		throw new Error("Not Implemented");
	} catch (error) {
		return next(error);
	}
};

const exportReport = async (req: Request, res: Response, next: NextFunction) => {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const { month, year } = req.query;

		const workbook = await AdminService.exportReport(month as string, year as string);

		res.setHeader(
			"Content-Type",
			"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		);
		res.setHeader(
			"Content-Disposition",
			`attachment; filename=attendance_report_${month}_${year}.xlsx`
		);

		await workbook.xlsx.write(res);
		return res.end();
	} catch (error) {
		return next(error);
	}
};

const addUser = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const {
			name,
			email,
			password,
			role,
			position,
			department,
			date_of_birth,
			phone_number,
			address,
			gender,
		} = req.body;

		const user = await AdminService.addUser({
			name,
			email,
			password,
			role,
			position,
			department,
			dateOfBirth: date_of_birth,
			phoneNumber: phone_number,
			address,
			gender,
		});

		return res.status(201).json({
			message: "User created successfully",
			user,
		});
	} catch (error) {
		return next(error);
	}
};

const findUserByID = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	const { id } = req.params;

	if (!id) {
		return res.status(400).json({ message: "No ID provided" });
	}

	try {
		const user = await AdminService.getUserById(id);

		logger.debug(user);

		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}
		return res.status(200).json({ user, message: "User found" });
	} catch (error) {
		return next(error);
	}
};

const updateUser = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const { id } = req.params;
		const {
			name,
			email,
			password,
			role,
			position,
			department,
			status,
			date_of_birth,
			phone_number,
			address,
			gender,
		} = req.body;

		const user = await AdminService.updateUser(id as string, {
			name,
			email,
			password,
			role,
			position,
			department,
			status,
			dateOfBirth: date_of_birth,
			phoneNumber: phone_number,
			address,
			gender,
		});

		return res.status(200).json({
			message: "User updated successfully",
			user,
		});
	} catch (error) {
		return next(error);
	}
};

const listUsers = async (req: Request, res: Response, next: NextFunction) => {
	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const users = await AdminService.listUsers();
		return res.json(users);
	} catch (error) {
		return next(error);
	}
};

const deleteUser = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const { id } = req.params;
		await AdminService.deleteUser(id as string, currentUser.id);
		return res.json({ message: "User deleted successfully" });
	} catch (error) {
		return next(error);
	}
};

const listUserSession = async (_req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(_req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const currentUser = _req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const { id } = _req.params;
		const sessions = await AdminService.listUserSessions(id as string);
		return res.json(sessions);
	} catch (error) {
		return next(error);
	}
};

const revokeAllUserSessions = async (_req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(_req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}
	
	try {
		const { userId } = _req.params;
		if (!userId) {
			return res.status(400).json({ message: 'User ID is required' });
		}

		await AuthService.revokeAllUserSessions(userId);
		return res.status(200).json({ message: "Session revoked successfully" });
	} catch (error) {
		return next(error);
	}
};

const unbindDevice = async (req: Request, res: Response, next: NextFunction) => {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	const { userId } = req.body;
	if (!userId) {
		return res.status(400).json({ message: "User ID is required" });
	}

	try {
		const result = await AdminService.unbindDevice(userId);
		return res.json(result);
	} catch (error) {
		return next(error);
	}
};

export const AdminController = {
	generateQR,
	getOfficeConfig,
	updateOfficeConfig,
	exportReport,
	addUser,
	findUserByID,
	updateUser,
	listUsers,
	deleteUser,
	listUserSession,
	revokeAllUserSessions,
	unbindDevice,
};
