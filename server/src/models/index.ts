import User, { UserStatus } from './user';
import Attendance from './attendance';
import OfficeConfig from './officeConfig';
import RefreshToken from './refreshToken';
import RequestModel from './request';

// Define Associations
User.hasMany(Attendance, { foreignKey: 'user_id', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RequestModel, { foreignKey: 'user_id', as: 'requests' });
RequestModel.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

export {
  User,
  UserStatus,
  Attendance,
  OfficeConfig,
  RefreshToken,
  RequestModel
};
