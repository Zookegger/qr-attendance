import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

interface OfficeConfigAttributes {
	id: number;
	name: string;
	latitude: number;
	longitude: number;
	radius: number; // in meters
	wifi_ssid?: string | null;
}

interface OfficeConfigCreationAttributes extends Optional<
	OfficeConfigAttributes,
	"id" | "wifi_ssid"
> { }

export default class OfficeConfig
	extends Model<OfficeConfigAttributes, OfficeConfigCreationAttributes>
	implements OfficeConfigAttributes {
	declare public id: number;
	declare public name: string;
	declare public latitude: number;
	declare public longitude: number;
	declare public radius: number;
	declare public wifi_ssid: string | null;

	declare public readonly created_at: Date;
	declare public readonly updated_at: Date;
}

OfficeConfig.init(
	{
		id: {
			type: DataTypes.INTEGER.UNSIGNED,
			autoIncrement: true,
			primaryKey: true,
		},
		name: {
			type: DataTypes.STRING,
			allowNull: false,
		},
		latitude: {
			type: DataTypes.FLOAT,
			allowNull: false,
		},
		longitude: {
			type: DataTypes.FLOAT,
			allowNull: false,
		},
		radius: {
			type: DataTypes.INTEGER,
			allowNull: false,
			defaultValue: 100,
		},
		wifi_ssid: {
			type: DataTypes.STRING,
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "office_configs", 
		underscored: true,
		timestamps: true,
	},
);
