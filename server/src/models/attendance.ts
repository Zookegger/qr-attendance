import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "../config/database";
import { User } from "./user";

interface AttendanceAttributes {
	id: string;
	user_id: string;
	date: string; // YYYY-MM-DD
	check_in_time?: Date | null;
	check_out_time?: Date | null;
	status: "Present" | "Late" | "Absent";
	check_in_location?: object | null;
	check_out_location?: object | null;
	check_in_method?: "QR" | "Manual" | null;
	check_out_method?: "QR" | "Manual" | null;
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
> {}

export class Attendance
	extends Model<AttendanceAttributes, AttendanceCreationAttributes>
	implements AttendanceAttributes
{
	public id!: string;
	public user_id!: string;
	public date!: string;
	public check_in_time!: Date | null;
	public check_out_time!: Date | null;
	public status!: "Present" | "Late" | "Absent";
	public check_in_location!: object | null;
	public check_out_location!: object | null;
	public check_in_method!: "QR" | "Manual" | null;
	public check_out_method!: "QR" | "Manual" | null;

	public readonly user?: User;

	public readonly createdAt!: Date;
	public readonly updatedAt!: Date;
}

Attendance.init(
	{
		id: {
			type: DataTypes.UUID,
			defaultValue: DataTypes.UUIDV4,
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
		check_in_time: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		check_out_time: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		status: {
			type: DataTypes.ENUM("Present", "Late", "Absent"),
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
			type: DataTypes.ENUM("QR", "Manual"),
			allowNull: true,
		},
		check_out_method: {
			type: DataTypes.ENUM("QR", "Manual"),
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "attendance",
		indexes: [
			{
				unique: true,
				fields: ["user_id", "date"],
			},
		],
	},
);
