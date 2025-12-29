import { NextFunction, Request, Response } from "express";
import { AdminService } from "@services/admin.service";
import { UserRole } from "@models/user";
import { validationResult } from "express-validator";

const generateQR = async (req: Request, res: Response, next: NextFunction) => {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const qr_code = await AdminService.generateQR();
		return res.json({ qr_code });
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
		let config = await AdminService.getOfficeConfig();
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
		const { latitude, longitude, radius, start_hour, end_hour, wifi_ssid } =
			req.body;

		const config = await AdminService.updateOfficeConfig({
			latitude,
			longitude,
			radius,
			start_hour,
			end_hour,
			wifi_ssid,
		});
		return res.json({ message: "Configuration updated", config });
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
			date_of_birth,
			phone_number,
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
			date_of_birth,
			phone_number,
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

const revokeUserSession = async (_req: Request, res: Response, next: NextFunction) => {
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
		await AdminService.revokeUserSession(id as string);
		return res.json({ message: "Session revoked successfully" });
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
	updateUser,
	listUsers,
	deleteUser,
	listUserSession,
	revokeUserSession,
};
