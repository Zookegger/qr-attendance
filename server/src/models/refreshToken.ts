import { DataTypes, Model, Optional } from "sequelize";
import sequelize from "@config/database";

interface RefreshTokenAttributes {
	id: string;
	userId: string;
	tokenHash: string;
	deviceUuid?: string | null;
	revoked: boolean;
	expiresAt: Date;
	createdAt: Date;
	updatedAt: Date;
}

interface RefreshTokenCreationAttributes
	extends Optional<
		RefreshTokenAttributes,
		"id" | "deviceUuid" | "createdAt" | "updatedAt"
	> {}

export default class RefreshToken
	extends Model<RefreshTokenAttributes | RefreshTokenCreationAttributes>
	implements RefreshTokenAttributes
{
	public declare id: string;
	public declare userId: string;
	public declare tokenHash: string;
	public declare deviceUuid?: string | null;
	public declare revoked: boolean;
	public declare expiresAt: Date;

	public declare readonly createdAt: Date;
	public declare readonly updatedAt: Date;
}

RefreshToken.init(
	{
		id: {
			type: DataTypes.UUID,
			defaultValue: DataTypes.UUIDV4,
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
		tokenHash: {
			type: DataTypes.STRING,
			allowNull: false,
		},
		deviceUuid: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		revoked: {
			type: DataTypes.BOOLEAN,
			defaultValue: false,
		},
		expiresAt: {
			type: DataTypes.DATE,
			allowNull: false,
		},
	},
	{
		sequelize,
		tableName: "refresh_tokens",
		underscored: true,
		timestamps: true,
	}
);
