import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import User from './user';
import Workshift from './workshift';

interface ScheduleAttributes {
   id: string;
   user_id: string;
   shift_id: string;
   start_date: string;
   end_date?: string | null;
}

interface ScheduleCreationAttributes extends Optional<ScheduleAttributes, 'id'> { }

class Schedule extends Model<ScheduleAttributes, ScheduleCreationAttributes> implements ScheduleAttributes {
   public declare id: string;
   public declare user_id: string;
   public declare shift_id: string;
   public declare start_date: string;
   public declare end_date?: string | null;

   // Association mixins (để TypeScript hiểu khi include)
   public declare Shift?: Workshift;
   public declare User?: User;

   public readonly created_at!: Date;
   public readonly updated_at!: Date;
}

Schedule.init({
   id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
   },
   user_id: { type: DataTypes.UUID, allowNull: false },
   shift_id: { type: DataTypes.UUID, allowNull: false },
   start_date: { type: DataTypes.DATEONLY, allowNull: false },
   end_date: { type: DataTypes.DATEONLY, allowNull: true },
}, {
   sequelize,
   tableName: 'schedules',
   underscored: true,
   timestamps: true,
});

// Setup Associations (Quan trọng)
Schedule.belongsTo(Workshift, { foreignKey: 'shift_id', as: 'Shift' });
Schedule.belongsTo(User, { foreignKey: 'user_id', as: 'User' });

export default Schedule;