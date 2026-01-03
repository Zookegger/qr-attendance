import { DataTypes, Model, Optional } from "sequelize";
import sequelize from "@config/database";

interface WorkshiftAttributes {
   id: number;
   name: string;
   startTime: Date;
   endTime: Date;
   gracePeriod: number;
   breakStart: Date;
   breakEnd: Date;
   workDays: number[];
   office_config_id?: number | null;
}

interface WorkshifCreationAttributes extends Optional<WorkshiftAttributes, 'id'> { }

export default class Workshift extends Model<WorkshiftAttributes, WorkshifCreationAttributes> implements WorkshiftAttributes {
   declare public id: number;
   declare public name: string;
   declare public startTime: Date;
   declare public endTime: Date;
   declare public gracePeriod: number;
   declare public breakStart: Date;
   declare public breakEnd: Date;
   declare public workDays: number[];
   declare public office_config_id?: number | null;

   declare public readonly created_at: Date;
   declare public readonly updated_at: Date;
}

Workshift.init({
   id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
   },
   name: {
      type: DataTypes.STRING,
      allowNull: false,
   },
   startTime: {
      type: DataTypes.TIME,
      allowNull: false,
   },
   endTime: {
      type: DataTypes.TIME,
      allowNull: false,
   },
   breakStart: {
      type: DataTypes.TIME,
      allowNull: false,
   },
   breakEnd: {
      type: DataTypes.TIME,
      allowNull: false,
   },
   gracePeriod: {
      type: DataTypes.INTEGER,
      defaultValue: 15,
   },
   workDays: {
      type: DataTypes.JSON,
      defaultValue: [],
   },
   office_config_id: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: true,
      references: {
         model: 'office_configs',
         key: 'id',
      },
   }
}, {
   sequelize,
   tableName: 'shifts',
   underscored: true,
   timestamps: true
});