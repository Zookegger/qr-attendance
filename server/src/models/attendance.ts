import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";
import User from "./user";
import Schedule from "./schedule";

export interface CheckInOutObject {
	userId: string,
	location: {
		longitude: number,
		latitude: number,
	},
	deviceUuid: string,
	userAgent: string,
	ipAddress: string,
	wifiBssid: string,
}

export enum AttendanceStatus {
	PRESENT = "Present", LATE = "LATE", ABSENT = "ABSENT"
}

export enum AttendanceMethod {
	QR = "QR", MANUAL = "MANUAL", NONE = "NONE",
}

interface AttendanceAttributes {
	id: number;
	userId: string;
	date: Date;
	scheduleId?: number | null;
	requestId?: string | null;
	checkInTime?: Date | null;
	checkOutTime?: Date | null;
	status: AttendanceStatus;
	checkInLocation?: object | null;
	checkOutLocation?: object | null;
	checkInMethod?: AttendanceMethod;
	checkOutMethod?: AttendanceMethod;
}

interface AttendanceCreationAttributes extends Optional<
	AttendanceAttributes,
	| "id"
	| "checkInTime"
	| "checkOutTime"
	| "checkInLocation"
	| "checkOutLocation"
	| "checkInMethod"
	| "checkOutMethod"
> { }

export default class Attendance
	extends Model<AttendanceAttributes, AttendanceCreationAttributes>
	implements AttendanceAttributes {
	declare public id: number;
	declare public userId: string;
	declare public date: Date;
	declare public scheduleId?: number | null;
	declare public requestId?: string | null;
	declare public checkInTime: Date | null;
	declare public checkOutTime: Date | null;
	declare public status: AttendanceStatus;
	declare public checkInLocation: object | null;
	declare public checkOutLocation: object | null;
	declare public checkInMethod: AttendanceMethod;
	declare public checkOutMethod: AttendanceMethod;

	declare public readonly user?: User;
	declare public readonly schedule?: Schedule;
	declare public readonly request?: Request; 

	declare public readonly createdAt: Date;
	declare public readonly updatedAt: Date;
}

Attendance.init(
	{
		id: {
			type: DataTypes.INTEGER.UNSIGNED,
			autoIncrement: true,
			primaryKey: true,
		},
		userId: {
			type: DataTypes.UUID,
			allowNull: false,
			references: {
				model: "users",
				key: "id",
			},
		},
		date: {
			type: DataTypes.DATEONLY,
			allowNull: false,
		},
		scheduleId: {
			type: DataTypes.INTEGER.UNSIGNED,
			allowNull: true,
			references: {
				model: 'schedules',
				key: 'id',
			},
		},
		requestId: {
			type: DataTypes.UUID,
			allowNull: true,
			references: {
				model: 'requests',
				key: 'id',
			},
		},
		checkInTime: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		checkOutTime: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		status: {
			type: DataTypes.ENUM(...Object.values(AttendanceStatus)),
			defaultValue: "Absent",
			allowNull: false,
		},
		checkInLocation: {
			type: DataTypes.JSON,
			allowNull: true,
		},
		checkOutLocation: {
			type: DataTypes.JSON,
			allowNull: true,
		},
		checkInMethod: {
			type: DataTypes.ENUM(...Object.values(AttendanceMethod)),
			allowNull: true,
		},
		checkOutMethod: {
			type: DataTypes.ENUM(...Object.values(AttendanceMethod)),
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "attendances",
		underscored: true,
		timestamps: true,
		indexes: [
			{
				unique: true,
				fields: ["user_id", "date"],
			},
		],
	},
);
