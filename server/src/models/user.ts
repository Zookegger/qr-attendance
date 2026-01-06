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
	passwordHash: string;
	role: UserRole;
	position?: string | null;
	department?: string | null;
	dateOfBirth?: Date | null;
	phoneNumber?: string | null;
	address?: string | null;
	gender?: Gender | null;
	passwordResetToken?: string | null;
	passwordResetExpires?: Date | null;
}

interface UserCreationAttributes
	extends Optional<
		UserAttributes,
		| "id"
		| "status"
		| "position"
		| "department"
		| "dateOfBirth"
		| "phoneNumber"
		| "address"
		| "gender"
		| "passwordResetToken"
		| "passwordResetExpires"
	> { }

export default class User
	extends Model<UserAttributes, UserCreationAttributes>
	implements UserAttributes {
	public declare id: string;
	public declare name: string;
	public declare email: string;
	public declare status: UserStatus;
	public declare passwordHash: string;
	public declare role: UserRole;
	public declare position: string | null;
	public declare department: string | null;
	public declare dateOfBirth: Date | null;
	public declare phoneNumber: string | null;
	public declare address: string | null;
	public declare gender: Gender | null;

	public declare passwordResetToken: string | null;
	public declare passwordResetExpires: Date | null;

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
		passwordHash: {
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
		dateOfBirth: {
			type: DataTypes.DATEONLY,
			allowNull: true,
		},
		phoneNumber: {
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
		passwordResetToken: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		passwordResetExpires: {
			type: DataTypes.DATE,
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "users",
		underscored: true,
		timestamps: true,
	}
);
