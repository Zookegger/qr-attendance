import { Model, DataTypes, Optional } from 'sequelize';
import { sequelize } from '@config/database';

interface LeaveRequestAttributes {
  id: string;
  user_id: string;
  start_date: string;
  end_date: string;
  type: 'Late' | 'Day Off' | 'Sick' | 'Vacation';
  reason: string;
  status: 'Pending' | 'Approved' | 'Rejected';
  admin_comment?: string | null;
}

interface LeaveRequestCreationAttributes extends Optional<LeaveRequestAttributes, 'id' | 'admin_comment'> {}

export class LeaveRequest extends Model<LeaveRequestAttributes, LeaveRequestCreationAttributes> implements LeaveRequestAttributes {
  declare public id: string;
  declare public user_id: string;
  declare public start_date: string;
  declare public end_date: string;
  declare public type: 'Late' | 'Day Off' | 'Sick' | 'Vacation';
  declare public reason: string;
  declare public status: 'Pending' | 'Approved' | 'Rejected';
  declare public admin_comment: string | null;

  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

LeaveRequest.init(
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
        model: 'users',
        key: 'id',
      },
    },
    start_date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    end_date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM('Late', 'Day Off', 'Sick', 'Vacation'),
      allowNull: false,
    },
    reason: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'),
      defaultValue: 'Pending',
      allowNull: false,
    },
    admin_comment: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
  },
  {
    sequelize,
    tableName: 'leave_requests',
  }
);
