import { Model, DataTypes, Optional } from 'sequelize';
import { sequelize } from '@config/database';

interface RequestAttributes {
  id: string;
  user_id: string;
  type: string;
  from_date?: Date | null;
  to_date?: Date | null;
  reason?: string | null;
  image_url?: string | null;
  status: 'pending' | 'approved' | 'rejected';
}

interface RequestCreationAttributes extends Optional<RequestAttributes, 'id' | 'status'> {}

export class RequestModel extends Model<RequestAttributes, RequestCreationAttributes> implements RequestAttributes {
  declare public id: string;
  declare public user_id: string;
  declare public type: string;
  declare public from_date: Date | null;
  declare public to_date: Date | null;
  declare public reason: string | null;
  declare public image_url: string | null;
  declare public status: 'pending'|'approved'|'rejected';

  declare public readonly createdAt: Date;
  declare public readonly updatedAt: Date;
}

RequestModel.init({
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  from_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  to_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  reason: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  image_url: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('pending','approved','rejected'),
    allowNull: false,
    defaultValue: 'pending',
  },
}, {
  sequelize,
  tableName: 'requests',
});