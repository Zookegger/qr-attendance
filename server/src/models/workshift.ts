import { DataTypes, Model, Optional } from "sequelize";
import sequelize from "@config/database";

interface WorkshiftAttributes {
   id: string;
   name: string;
   startTime: Date;
   endTime: Date;
   gracePeriod: number;
   breakStart: Date;
   breakEnd: Date;
   workDays: number[];
}

interface WorkshifCreationAttributes extends Optional<WorkshiftAttributes, 'id'> { }

export default class Workshift extends Model<WorkshiftAttributes, WorkshifCreationAttributes> implements WorkshiftAttributes {
   declare public id: string;
   declare public name: string;
   declare public startTime: Date;
   declare public endTime: Date;
   declare public gracePeriod: number;
   declare public breakStart: Date;
   declare public breakEnd: Date;
   declare public workDays: number[];

   declare public readonly createdAt: Date;
   declare public readonly updatedAt: Date;
}

Workshift.init({
   id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
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
   }
}, {
   sequelize,
   tableName: 'shifts',
   timestamps: true
});