import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './user';
import Workshift from './workshift';

interface ScheduleAttributes {
   id: number;
   userId: string;
   shiftId: number;
   startDate: string;
   endDate?: string | null;
}

interface ScheduleCreationAttributes extends Optional<ScheduleAttributes, 'id'> { }

class Schedule extends Model<ScheduleAttributes, ScheduleCreationAttributes> implements ScheduleAttributes {
   public declare id: number;
   public declare userId: string;
   public declare shiftId: number;
   public declare startDate: string;
   public declare endDate?: string | null;

   // Association mixins
   public declare Shift?: Workshift;
   public declare User?: User;

   public readonly createdAt!: Date;
   public readonly updatedAt!: Date;
}

Schedule.init({
   id: {
      type: DataTypes.INTEGER.UNSIGNED,
      autoIncrement: true,
      primaryKey: true,
   },
   userId: { type: DataTypes.UUID, allowNull: false },
   shiftId: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
   startDate: { type: DataTypes.DATEONLY, allowNull: false },
   endDate: { type: DataTypes.DATEONLY, allowNull: true },
}, {
   sequelize,
   tableName: 'schedules',
   underscored: true,
   timestamps: true,
});

// Setup Associations (defined centrally in models/index.ts)
Schedule.belongsTo(User, { foreignKey: 'userId', as: 'User' });

export default Schedule;