import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "../config/database";

interface OfficeConfigAttributes {
	id: string;
	latitude: number;
	longitude: number;
	radius: number; // in meters
	wifi_ssid?: string | null;
	start_hour: string; // e.g., "09:00"
	end_hour: string; // e.g., "18:00"
}

interface OfficeConfigCreationAttributes extends Optional<
	OfficeConfigAttributes,
	"id" | "wifi_ssid"
> {}

export class OfficeConfig
	extends Model<OfficeConfigAttributes, OfficeConfigCreationAttributes>
	implements OfficeConfigAttributes
{
	declare public id: string;
	declare public latitude: number;
	declare public longitude: number;
	declare public radius: number;
	declare public wifi_ssid: string | null;
	declare public start_hour: string;
	declare public end_hour: string;

	declare public readonly createdAt: Date;
	declare public readonly updatedAt: Date;
}

OfficeConfig.init(
	{
		id: {
			type: DataTypes.UUID,
			defaultValue: DataTypes.UUIDV4,
			primaryKey: true,
		},
		latitude: {
			type: DataTypes.DECIMAL(10, 8),
			allowNull: false,
		},
		longitude: {
			type: DataTypes.DECIMAL(11, 8),
			allowNull: false,
		},
		radius: {
			type: DataTypes.INTEGER,
			allowNull: false,
			defaultValue: 100, // 100 meters default
		},
		wifi_ssid: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		start_hour: {
			type: DataTypes.STRING,
			allowNull: false,
			defaultValue: "09:00",
		},
		end_hour: {
			type: DataTypes.STRING,
			allowNull: false,
			defaultValue: "18:00",
		},
	},
	{
		sequelize,
		tableName: "office_config",
	},
);
