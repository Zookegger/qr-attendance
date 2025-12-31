import User, { UserStatus } from './user';
import Attendance from './attendance';
import OfficeConfig from './officeConfig';
import RefreshToken from './refreshToken';
import RequestModel from './request';
import Workshift from './workshift';
import Schedule from './schedule';

// Define Associations
User.hasMany(Attendance, { foreignKey: 'user_id', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RequestModel, { foreignKey: 'user_id', as: 'requests' });
RequestModel.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Workshift <-> OfficeConfig
OfficeConfig.hasMany(Workshift, { foreignKey: 'office_config_id', as: 'workshifts' });
Workshift.belongsTo(OfficeConfig, { foreignKey: 'office_config_id', as: 'officeConfig' });

// Workshift <-> Schedule
Workshift.hasMany(Schedule, { foreignKey: 'shift_id', as: 'schedules' });
Schedule.belongsTo(Workshift, { foreignKey: 'shift_id', as: 'Shift' });

// Attendance <-> Schedule
Schedule.hasMany(Attendance, { foreignKey: 'schedule_id', as: 'attendances' });
Attendance.belongsTo(Schedule, { foreignKey: 'schedule_id', as: 'Schedule' });

// Attendance <-> Workshift
// Attendance <-> Request
RequestModel.hasMany(Attendance, { foreignKey: 'request_id', as: 'attendances' });
Attendance.belongsTo(RequestModel, { foreignKey: 'request_id', as: 'request' });

export {
  User,
  UserStatus,
  Attendance,
  OfficeConfig,
  RefreshToken,
  RequestModel,
  Workshift,
  Schedule
};
