import { User, UserStatus } from './user';
import { Attendance } from './attendance';
import { LeaveRequest } from './leaveRequest';
import { OfficeConfig } from './officeConfig';
import { RefreshToken } from './refreshToken';

// Define Associations
User.hasMany(Attendance, { foreignKey: 'user_id', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(LeaveRequest, { foreignKey: 'user_id', as: 'leaveRequests' });
LeaveRequest.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

export {
  User,
  UserStatus,
  Attendance,
  LeaveRequest,
  OfficeConfig,
  RefreshToken
};
