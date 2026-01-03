import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

interface OfficeConfigAttributes {
	id: number;
	name: string;
	latitude: number;
	longitude: number;
	radius: number; // in meters
	wifiSsid?: string | null;
}

interface OfficeConfigCreationAttributes extends Optional<
	OfficeConfigAttributes,
	"id" | "wifiSsid"
> { }

export default class OfficeConfig
	extends Model<OfficeConfigAttributes, OfficeConfigCreationAttributes>
	implements OfficeConfigAttributes {
	declare public id: number;
	declare public name: string;
	declare public latitude: number;
	declare public longitude: number;
	declare public radius: number;
	declare public wifiSsid: string | null;

	declare public readonly createdAt: Date;
	declare public readonly updatedAt: Date;
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
		wifiSsid: {
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
