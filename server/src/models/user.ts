import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

interface UserAttributes {
	id: string;
	name: string;
	email: string;
	password_hash: string;
	role: "admin" | "user";
	device_uuid?: string | null;
	position?: string | null;
	department?: string | null;
}

interface UserCreationAttributes extends Optional<
	UserAttributes,
	"id" | "device_uuid" | "position" | "department"
> {}

export class User
	extends Model<UserAttributes, UserCreationAttributes>
	implements UserAttributes
{
	declare public id: string;
	declare public name: string;
	declare public email: string;
	declare public password_hash: string;
	declare public role: "admin" | "user";
	declare public device_uuid: string | null;
	declare public position: string | null;
	declare public department: string | null;

	declare public readonly createdAt: Date;
	declare public readonly updatedAt: Date;
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
	},
);
