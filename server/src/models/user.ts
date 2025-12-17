import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

interface UserAttributes {
	id: string;
	name: string;
	email: string;
	password_hash: string;
	role: "admin" | "user";
	device_uuid?: string | null;
	device_name?: string | null;
	device_model?: string | null;
	device_os_version?: string | null;
	position?: string | null;
	department?: string | null;
	fcm_token?: string | null;
}

interface UserCreationAttributes
	extends Optional<
		UserAttributes,
		"id" | "device_uuid" | "device_name" | "device_model" | "device_os_version" | "position" | "department"
	> {}

export class User
	extends Model<UserAttributes, UserCreationAttributes>
	implements UserAttributes
{
	public declare id: string;
	public declare name: string;
	public declare email: string;
	public declare password_hash: string;
	public declare role: "admin" | "user";
	public declare device_uuid: string | null;
	public declare device_name: string | null;
	public declare device_model: string | null;
	public declare device_os_version: string | null;
	public declare position: string | null;
	public declare department: string | null;
	public declare fcm_token: string | null;

	public declare readonly createdAt: Date;
	public declare readonly updatedAt: Date;
}

User.init(
	{
		id: {
			type: DataTypes.UUID,
			defaultValue: DataTypes.UUIDV4,
			primaryKey: true,
		},
		name: {
			type: DataTypes.STRING,
			allowNull: false,
		},
		email: {
			type: DataTypes.STRING,
			allowNull: false,
			unique: true,
			validate: {
				isEmail: true,
			},
		},
		password_hash: {
			type: DataTypes.STRING,
			allowNull: false,
		},
		role: {
			type: DataTypes.ENUM("admin", "user"),
			defaultValue: "user",
			allowNull: false,
		},
		device_uuid: {
			type: DataTypes.STRING,
			allowNull: true,
			comment: "Unique device ID for device binding",
		},
		device_name: {
			type: DataTypes.STRING,
			allowNull: true,
			comment: "Device name (e.g. John's iPhone)",
		},
		device_model: {
			type: DataTypes.STRING,
			allowNull: true,
			comment: "Device model (e.g. iPhone 13)",
		},
		device_os_version: {
			type: DataTypes.STRING,
			allowNull: true,
			comment: "Device OS version (e.g. iOS 15.0)",
		},
		fcm_token: {
			type: DataTypes.STRING,
			allowNull: true,
			comment: "Firebase Cloud Messaging Token for Push Notifications",
		},
		position: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		department: {
			type: DataTypes.STRING,
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "users",
	}
);
