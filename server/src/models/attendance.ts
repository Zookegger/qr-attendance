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
	user_id: string;
	date: Date;
	schedule_id?: number | null;
	request_id?: string | null;
	check_in_time?: Date | null;
	check_out_time?: Date | null;
	status: AttendanceStatus;
	check_in_location?: object | null;
	check_out_location?: object | null;
	check_in_method?: AttendanceMethod;
	check_out_method?: AttendanceMethod;
}

interface AttendanceCreationAttributes extends Optional<
	AttendanceAttributes,
	| "id"
	| "check_in_time"
	| "check_out_time"
	| "check_in_location"
	| "check_out_location"
	| "check_in_method"
	| "check_out_method"
> { }

export default class Attendance
	extends Model<AttendanceAttributes, AttendanceCreationAttributes>
	implements AttendanceAttributes {
	declare public id: number;
	declare public user_id: string;
	declare public date: Date;
	declare public schedule_id?: number | null;
	declare public request_id?: string | null;
	declare public check_in_time: Date | null;
	declare public check_out_time: Date | null;
	declare public status: AttendanceStatus;
	declare public check_in_location: object | null;
	declare public check_out_location: object | null;
	declare public check_in_method: AttendanceMethod;
	declare public check_out_method: AttendanceMethod;

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
		user_id: {
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
		schedule_id: {
			type: DataTypes.INTEGER.UNSIGNED,
			allowNull: true,
			references: {
				model: 'schedules',
				key: 'id',
			},
		},
		request_id: {
			type: DataTypes.UUID,
			allowNull: true,
			references: {
				model: 'requests',
				key: 'id',
			},
		},
		check_in_time: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		check_out_time: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		status: {
			type: DataTypes.ENUM(...Object.values(AttendanceStatus)),
			defaultValue: "Absent",
			allowNull: false,
		},
		check_in_location: {
			type: DataTypes.JSON,
			allowNull: true,
		},
		check_out_location: {
			type: DataTypes.JSON,
			allowNull: true,
		},
		check_in_method: {
			type: DataTypes.ENUM(...Object.values(AttendanceMethod)),
			allowNull: true,
		},
		check_out_method: {
			type: DataTypes.ENUM(...Object.values(AttendanceMethod)),
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "attendances",
		timestamps: true,
		indexes: [
			{
				unique: true,
				fields: ["user_id", "date"],
			},
		],
	},
);
