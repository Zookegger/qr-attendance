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
	public id!: string;
	public name!: string;
	public email!: string;
	public password_hash!: string;
	public role!: "admin" | "user";
	public device_uuid!: string | null;
	public position!: string | null;
	public department!: string | null;

	public readonly createdAt!: Date;
	public readonly updatedAt!: Date;
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
