import { Model, DataTypes, Optional } from 'sequelize';
import { sequelize } from '../config/database';

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
  public id!: string;
  public user_id!: string;
  public start_date!: string;
  public end_date!: string;
  public type!: 'Late' | 'Day Off' | 'Sick' | 'Vacation';
  public reason!: string;
  public status!: 'Pending' | 'Approved' | 'Rejected';
  public admin_comment!: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
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
