import { OfficeConfig, Attendance, User, UserStatus, RefreshToken, UserDevice } from "@models";
import redis from "@config/redis";
import { getIo } from "@utils/socket";
import crypto from "crypto";
import ExcelJS from "exceljs";
import { Op } from "sequelize";
import { startOfMonth, endOfMonth, format } from "date-fns";
import bcrypt from "bcrypt";
import { Gender, UserRole } from "@models/user";
import { AddUserDTO, UpdateUserDTO } from "@my-types/admin";
import RefreshTokenService from "./refreshToken.service";

export default class AdminService {
	static async generateQR(officeId?: number): Promise<{ code: string; refreshAt: number; officeId: number }> {
		// generate 4-digit code, store in redis, emit to socket room
		const num = crypto.randomInt(0, 10000);
		const code = num.toString().padStart(4, "0");

		let office = officeId ? await OfficeConfig.findByPk(officeId) : await OfficeConfig.findOne();
		
		if (!office) {
			throw new Error("No office configuration found. Please create one first.");
		}

		const idToUse = office.id;
		const ttlSeconds = 45;
		const key = `checkin:office:${idToUse}:code:${code}`;

		await redis.set(key, "1", "EX", ttlSeconds);

		try {
			const io = getIo();
			io.to(`office_${idToUse}`).emit("qr:update", { code, refreshAt: 30, officeId: idToUse });
		} catch (err) {
			// ignore if socket not initialized
		}

		return { code, refreshAt: 30, officeId: idToUse };
	}



	static async unbindDevice(userId: string) {
		const user = await User.findByPk(userId);
		if (!user) {
			throw new Error("User not found");
		}

		// Remove all device bindings for this user
		await UserDevice.destroy({ where: { userId: userId } });

		// Revoke all sessions for this user
		await RefreshToken.destroy({
			where: {
				userId: userId,
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
				check_in: record.checkInTime
					? new Date(record.checkInTime).toLocaleTimeString()
					: "-",
				check_out: record.checkOutTime
					? new Date(record.checkOutTime).toLocaleTimeString()
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
			dateOfBirth,
			phoneNumber,
			address,
			gender,
		} = dto;

		const existingUser = await User.findOne({ where: { email } });
		if (existingUser) {
			throw new Error("User already exists");
		}

		const salt = await bcrypt.genSalt(10);
		const passwordHash = await bcrypt.hash(password, salt);

		const user = await User.create({
			name,
			email,
			passwordHash,
			role: (role as UserRole) || UserRole.USER,
			position: position || null,
			department: department || null,
			dateOfBirth: (typeof dateOfBirth === 'string') ? new Date(dateOfBirth) : dateOfBirth || null,
			phoneNumber: phoneNumber || null,
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
			dateOfBirth: user.dateOfBirth,
			phoneNumber: user.phoneNumber,
			address: user.address,
			gender: user.gender,
		};
	}

	static async getUserById(id: string) {
		return await User.findByPk(id, { attributes: ["id", "name", "status", "email", "role", "gender", "position", "dateOfBirth", "phoneNumber", "address", "createdAt", "updatedAt"] });
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
			dateOfBirth,
			phoneNumber,
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
		if (dateOfBirth) user.dateOfBirth = (typeof dateOfBirth === 'string') ? new Date(dateOfBirth) : dateOfBirth;
		if (phoneNumber) user.phoneNumber = phoneNumber;
		if (address) user.address = address;
		if (gender) user.gender = gender as Gender;

		if (password) {
			const salt = await bcrypt.genSalt(10);
			user.passwordHash = await bcrypt.hash(password, salt);
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
			dateOfBirth: user.dateOfBirth,
			phoneNumber: user.phoneNumber,
			address: user.address,
			gender: user.gender,
		};
	}

	static async listUsers() {
		const users = await User.findAll({
			attributes: { exclude: ["passwordHash"] },
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
		return await RefreshTokenService.listUserSessions(userId);
	}
}