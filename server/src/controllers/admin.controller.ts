import { Request, Response } from "express";
import { OfficeConfig, Attendance, User } from "../models";
import ExcelJS from "exceljs";
import { Op } from "sequelize";

export class AdminController {
	// Generate QR Code Payload
	static async generateQR(req: Request, res: Response) {
		// In a real app, this should be encrypted
		const timestamp = Date.now();
		res.json({ qr_code: timestamp.toString() });
	}

	// Get Office Config
	static async getOfficeConfig(req: Request, res: Response) {
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
			res.json(config);
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}

	// Update Office Config
	static async updateOfficeConfig(req: Request, res: Response) {
		try {
			const {
				latitude,
				longitude,
				radius,
				start_hour,
				end_hour,
				wifi_ssid,
			} = req.body;
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

			res.json({ message: "Configuration updated", config });
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}

	// Export Report
	static async exportReport(req: Request, res: Response) {
		try {
			const { month, year } = req.query;

			if (!month || !year) {
				return res
					.status(400)
					.json({ message: "Month and Year are required" });
			}

			const startDate = new Date(Number(year), Number(month) - 1, 1);
			const endDate = new Date(Number(year), Number(month), 0);

			const attendances = await Attendance.findAll({
				where: {
					date: {
						[Op.between]: [
							startDate.toISOString().split("T")[0],
							endDate.toISOString().split("T")[0],
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
				"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
			);
			res.setHeader(
				"Content-Disposition",
				`attachment; filename=attendance_report_${month}_${year}.xlsx`,
			);

			await workbook.xlsx.write(res);
			res.end();
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}
}
