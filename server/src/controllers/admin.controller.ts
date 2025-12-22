import { Request, Response } from "express";
import { OfficeConfig, Attendance, User, UserStatus } from "@models";
import ExcelJS from "exceljs";
import { Op } from "sequelize";
import { startOfMonth, endOfMonth, format } from "date-fns";
import bcrypt from "bcrypt";
import { UserRole } from "@models/user";

// TODO: Put info into here so admin can generate QR code from attendace info
async function generateQR(req: Request, res: Response) {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	// In a real app, this should be encrypted
	const timestamp = Date.now();
	return res.json({ qr_code: timestamp.toString() });
}

async function getOfficeConfig(req: Request, res: Response) {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		let config = await OfficeConfig.findOne();
		if (!config) {
			// Create default if not exists
			config = await OfficeConfig.create({
				latitude: 0,
				longitude: 0,
				radius: 100,
				start_hour: "09:00",
				end_hour: "18:00",
			});
		}
		return res.json(config);
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function updateOfficeConfig(req: Request, res: Response) {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const { latitude, longitude, radius, start_hour, end_hour, wifi_ssid } =
			req.body;
		let config = await OfficeConfig.findOne();

		if (config) {
			config.latitude = latitude;
			config.longitude = longitude;
			config.radius = radius;
			config.start_hour = start_hour;
			config.end_hour = end_hour;
			config.wifi_ssid = wifi_ssid;
			await config.save();
		} else {
			config = await OfficeConfig.create({
				latitude,
				longitude,
				radius,
				start_hour,
				end_hour,
				wifi_ssid,
			});
		}

		return res.json({ message: "Configuration updated", config });
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function exportReport(req: Request, res: Response) {
	const user = req.user;
	if (!user) {
		return res.status(403).json({ status: 403, message: "Unauthorized" });
	}
	try {
		const { month, year } = req.query;

		if (!month || !year) {
			return res
				.status(400)
				.json({ message: "Month and Year are required" });
		}

		const reportDate = new Date(Number(year), Number(month) - 1);
		const startDate = startOfMonth(reportDate);
		const endDate = endOfMonth(reportDate);

		const attendances = await Attendance.findAll({
			where: {
				date: {
					[Op.between]: [
						format(startDate, "yyyy-MM-dd"),
						format(endDate, "yyyy-MM-dd"),
					],
				},
			},
			include: [
				{
					model: User,
					as: "user",
					attributes: ["name", "email", "department"],
				},
			],
			order: [["date", "ASC"]],
		});

		const workbook = new ExcelJS.Workbook();
		const worksheet = workbook.addWorksheet("Attendance Report");

		worksheet.columns = [
			{ header: "Date", key: "date", width: 15 },
			{ header: "Employee Name", key: "name", width: 25 },
			{ header: "Email", key: "email", width: 25 },
			{ header: "Department", key: "department", width: 20 },
			{ header: "Check In", key: "check_in", width: 15 },
			{ header: "Check Out", key: "check_out", width: 15 },
			{ header: "Status", key: "status", width: 15 },
		];

		attendances.forEach((record) => {
			const user = record.user as unknown as User; // Type assertion
			worksheet.addRow({
				date: record.date,
				name: user?.name || "Unknown",
				email: user?.email || "Unknown",
				department: user?.department || "N/A",
				check_in: record.check_in_time
					? new Date(record.check_in_time).toLocaleTimeString()
					: "-",
				check_out: record.check_out_time
					? new Date(record.check_out_time).toLocaleTimeString()
					: "-",
				status: record.status,
			});
		});

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
		return res.status(500).json({ message: "Server error", error });
	}
}

async function addUser(req: Request, res: Response) {
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

		const existingUser = await User.findOne({ where: { email } });
		if (existingUser) {
			return res.status(400).json({ message: "User already exists" });
		}

		const salt = await bcrypt.genSalt(10);
		const password_hash = await bcrypt.hash(password, salt);

		const user = await User.create({
			name,
			email,
			password_hash,
			role: role || "user",
			position,
			department,
			date_of_birth,
			phone_number,
			address,
			gender,
		});

		return res.status(201).json({
			message: "User created successfully",
			user: {
				id: user.id,
				name: user.name,
				email: user.email,
				status: user.status,
				role: user.role,
				position: user.position,
				department: user.department,
				date_of_birth: user.date_of_birth,
				phone_number: user.phone_number,
				address: user.address,
				gender: user.gender,
			},
		});
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function updateUser(req: Request, res: Response) {
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

		const user = await User.findByPk(id);
		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}

		if (email && email !== user.email) {
			const existingUser = await User.findOne({ where: { email } });
			if (existingUser) {
				return res
					.status(400)
					.json({ message: "Email already in use" });
			}
			user.email = email;
		}

		if (name) user.name = name;
		if (role) user.role = role;
		if (position) user.position = position;
		if (department) user.department = department;
		if (status && Object.values(UserStatus).includes(status)) {
			user.status = status;
		}
		if (date_of_birth) user.date_of_birth = date_of_birth;
		if (phone_number) user.phone_number = phone_number;
		if (address) user.address = address;
		if (gender) user.gender = gender;

		if (password) {
			const salt = await bcrypt.genSalt(10);
			user.password_hash = await bcrypt.hash(password, salt);
		}

		await user.save();

		return res.status(200).json({
			message: "User updated successfully",
			user: {
				id: user.id,
				name: user.name,
				status: user.status,
				email: user.email,
				role: user.role,
				position: user.position,
				department: user.department,
				date_of_birth: user.date_of_birth,
				phone_number: user.phone_number,
				address: user.address,
				gender: user.gender,
			},
		});
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function listUsers(req: Request, res: Response) {
	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const users = await User.findAll({
			attributes: { exclude: ["password_hash"] },
			order: [["createdAt", "DESC"]],
		});
		return res.json(users);
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function deleteUser(req: Request, res: Response) {
	const currentUser = req.user;
	if (!currentUser || currentUser.role !== UserRole.ADMIN) {
		return res.status(403).json({ message: "Unauthorized" });
	}

	try {
		const { id } = req.params;
		const user = await User.findByPk(id);

		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}

		// Prevent deleting self
		if (currentUser.id === user.id) {
			return res
				.status(400)
				.json({ message: "Cannot delete your own account" });
		}

		await user.destroy();
		return res.json({ message: "User deleted successfully" });
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

export const AdminController = {
	generateQR,
	getOfficeConfig,
	updateOfficeConfig,
	exportReport,
	addUser,
	updateUser,
	listUsers,
	deleteUser,
};
