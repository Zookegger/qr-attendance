import { DataTypes, Model, Optional } from "sequelize";
import sequelize from "@config/database";

interface RefreshTokenAttributes {
	id: string;
	user_id: string;
	token_hash: string;
	device_uuid?: string | null;
	revoked: boolean;
	expires_at: Date;
	created_at: Date;
	updated_at: Date;
}

interface RefreshTokenCreationAttributes extends Optional<
	RefreshTokenAttributes,
	"id" | "device_uuid" | "created_at" | "updated_at"
> {}

export class RefreshToken
	extends Model<RefreshTokenAttributes | RefreshTokenCreationAttributes>
	implements RefreshTokenAttributes
{
	declare public id: string;
	declare public user_id: string;
	declare public token_hash: string;
	declare public device_uuid?: string | null | undefined;
	declare public revoked: boolean;
	declare public expires_at: Date;

	declare public readonly created_at: Date;
	declare public readonly updated_at: Date;
}

RefreshToken.init(
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
		token_hash: {
			type: DataTypes.STRING,
			allowNull: false,
			get() {},
		},
		device_uuid: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		revoked: {
			type: DataTypes.BOOLEAN,
			defaultValue: false,
		},
		expires_at: {
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
