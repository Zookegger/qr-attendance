import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

interface OfficeConfigAttributes {
	id: string;
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
	declare public id: string;
	declare public name: string;
	declare public latitude: number;
	declare public longitude: number;
	declare public radius: number;
	declare public wifi_ssid: string | null;

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
		timestamps: true,
	},
);
