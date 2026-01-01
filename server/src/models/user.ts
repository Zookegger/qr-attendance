import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

export enum UserStatus {
	ACTIVE = "ACTIVE",
	INACTIVE = "INACTIVE",
	PENDING = "PENDING",
}

export enum UserRole {
	ADMIN = "ADMIN",
	MANAGER = "MANAGER",
	USER = "USER",
}

export enum Gender {
	MALE = "MALE",
	FEMALE = "FEMALE",
	OTHER = "OTHER",
}

interface UserAttributes {
	id: string;
	name: string;
	email: string;
	status: UserStatus;
	password_hash: string;
	role: UserRole;
	position?: string | null;
	department?: string | null;
	date_of_birth?: Date | null;
	phone_number?: string | null;
	address?: string | null;
	gender?: Gender | null;
	password_reset_token?: string | null;
	password_reset_expires?: Date | null;
}

interface UserCreationAttributes
	extends Optional<
		UserAttributes,
		| "id"
		| "status"
		| "position"
		| "department"
		| "date_of_birth"
		| "phone_number"
		| "address"
		| "gender"
		| "password_reset_token"
		| "password_reset_expires"
	> { }

export default class User
	extends Model<UserAttributes, UserCreationAttributes>
	implements UserAttributes {
	public declare id: string;
	public declare name: string;
	public declare email: string;
	public declare status: UserStatus;
	public declare password_hash: string;
	public declare role: UserRole;
	public declare position: string | null;
	public declare department: string | null;
	public declare date_of_birth: Date | null;
	public declare phone_number: string | null;
	public declare address: string | null;
	public declare gender: Gender | null;

	public declare password_reset_token: string | null;
	public declare password_reset_expires: Date | null;

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
		status: {
			type: DataTypes.ENUM(...Object.values(UserStatus)),
			defaultValue: UserStatus.ACTIVE,
			allowNull: false,
			comment: "Account status for login access and lifecycle management",
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
			type: DataTypes.ENUM(...Object.values(UserRole)),
			defaultValue: UserRole.USER,
			allowNull: false,
		},
		position: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		department: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		date_of_birth: {
			type: DataTypes.DATEONLY,
			allowNull: true,
		},
		phone_number: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		address: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		gender: {
			type: DataTypes.ENUM(...Object.values(Gender)),
			allowNull: true,
		},
		password_reset_token: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		password_reset_expires: {
			type: DataTypes.DATE,
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "users",
		timestamps: true,
	}
);
