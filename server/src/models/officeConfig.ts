import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

export type Point = { latitude: number, longitude: number };

export type GeofenceConfig = {
	included: Point[][];
	excluded: Point[][];
};

interface OfficeConfigAttributes {
	id: number;
	name: string;
	latitude: number;
	longitude: number;
	radius: number; // in meters
	wifiSsid?: string | null;
	geofence?: GeofenceConfig | null;
}

interface OfficeConfigCreationAttributes extends Optional<
	OfficeConfigAttributes,
	"id" | "wifiSsid" | "geofence"
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
	declare public geofence: GeofenceConfig | null;

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
			type: DataTypes.FLOAT,
			allowNull: false,
		},
		wifiSsid: {
			type: DataTypes.STRING,
			allowNull: true,
		},
		geofence: {
			type: DataTypes.JSON,
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
