import { OfficeConfig, Attendance, User, UserStatus, RefreshToken } from "@models";
import ExcelJS from "exceljs";
import { Op } from "sequelize";
import { startOfMonth, endOfMonth, format } from "date-fns";
import bcrypt from "bcrypt";
import { Gender, UserRole } from "@models/user";
import { AddUserDTO, UpdateUserDTO, OfficeConfigDTO } from "@my-types/admin";
import { listUserSessions } from "./refreshToken.service";

export class AdminService {
	static async generateQR(): Promise<string> {
		// In a real app, this should be encrypted
		const timestamp = Date.now();
		return timestamp.toString();
	}

	static async getOfficeConfig() {
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
		return config;
	}

	static async updateOfficeConfig(dto: OfficeConfigDTO) {
		const { latitude, longitude, radius, start_hour, end_hour, wifi_ssid } = dto;
		let config = await OfficeConfig.findOne();

		if (config) {
			if (latitude !== undefined) config.latitude = latitude;
			if (longitude !== undefined) config.longitude = longitude;
			if (radius !== undefined) config.radius = radius;
			if (start_hour !== undefined) config.start_hour = start_hour;
			if (end_hour !== undefined) config.end_hour = end_hour;
			if (wifi_ssid !== undefined) config.wifi_ssid = wifi_ssid;
			await config.save();
		} else {
			config = await OfficeConfig.create({
				latitude: latitude || 0,
				longitude: longitude || 0,
				radius: radius || 100,
				start_hour: start_hour || "09:00",
				end_hour: end_hour || "18:00",
				wifi_ssid: wifi_ssid || null,
			});
		}

		return config;
	}

	static async unbindDevice(userId: string) {
		const user = await User.findByPk(userId);
		if (!user) {
			throw new Error("User not found");
		}

		user.device_uuid = null;
		await user.save();

		// Revoke all sessions for this user
		await RefreshToken.destroy({
			where: {
				user_id: userId,
			},
		});

		return { message: "Device unbind successful" };
	}

	static async exportReport(month: string, year: string) {
		if (!month || !year) {
			throw new Error("Month and Year are required");
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

		return workbook;
	}

	static async addUser(dto: AddUserDTO) {
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
		} = dto;

		const existingUser = await User.findOne({ where: { email } });
		if (existingUser) {
			throw new Error("User already exists");
		}

		const salt = await bcrypt.genSalt(10);
		const password_hash = await bcrypt.hash(password, salt);

		const user = await User.create({
			name,
			email,
			password_hash,
			role: (role as UserRole) || UserRole.USER,
			position: position || null,
			department: department || null,
			date_of_birth: date_of_birth || null,
			phone_number: phone_number || null,
			address: address || null,
			gender: gender ? (gender as Gender) : null,
		});

		return {
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
		};
	}

	static async getUserById(id: string) {
		return await User.findByPk(id, { attributes: ["id", "name", "status", "email", "role", "device_name", "gender", "position", "date_of_birth", "phone_number", "address", "createdAt", "updatedAt"] });
	}

	static async updateUser(id: string, dto: UpdateUserDTO) {
		const user = await User.findByPk(id);
		if (!user) {
			throw new Error("User not found");
		}

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
		} = dto;

		if (email && email !== user.email) {
			const existingUser = await User.findOne({ where: { email } });
			if (existingUser) {
				throw new Error("Email already in use");
			}
			user.email = email;
		}

		if (name) user.name = name;
		if (role) user.role = role as UserRole;
		if (position) user.position = position;
		if (department) user.department = department;
		if (status && Object.values(UserStatus).includes(status as UserStatus)) {
			user.status = status as UserStatus;
		}
		if (date_of_birth) user.date_of_birth = date_of_birth;
		if (phone_number) user.phone_number = phone_number;
		if (address) user.address = address;
		if (gender) user.gender = gender as Gender;

		if (password) {
			const salt = await bcrypt.genSalt(10);
			user.password_hash = await bcrypt.hash(password, salt);
		}

		await user.save();

		return {
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
		};
	}

	static async listUsers() {
		const users = await User.findAll({
			attributes: { exclude: ["password_hash"] },
			order: [["createdAt", "DESC"]],
		});
		return users;
	}

	static async deleteUser(id: string, currentUserId: string) {
		const user = await User.findByPk(id);

		if (!user) {
			throw new Error("User not found");
		}

		// Prevent deleting self
		if (currentUserId === user.id) {
			throw new Error("Cannot delete your own account");
		}

		await user.destroy();
	}

	static async listUserSessions(userId: string) {
		return await listUserSessions(userId);
	}

	static async revokeUserSession(sessionId: string) {
		await RefreshToken.update(
			{ revoked: true },
			{ where: { id: sessionId } }
		);
	}
}