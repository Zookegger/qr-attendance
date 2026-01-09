import User, { UserStatus } from './user';
import UserDevice from './userDevice';
import Attendance from './attendance';
import OfficeConfig from './officeConfig';
import RefreshToken from './refreshToken';
import RequestModel from './request';
import Workshift from './workshift';
import Schedule from './schedule';

// Define Associations
User.hasMany(Attendance, { foreignKey: 'userId', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'userId', as: 'user' });

User.hasMany(RequestModel, { foreignKey: 'userId', as: 'requests' });
RequestModel.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// Reviewer association: a request may be reviewed by a user (reviewer)
User.hasMany(RequestModel, { foreignKey: 'reviewedBy', as: 'reviewedRequests' });
RequestModel.belongsTo(User, { foreignKey: 'reviewedBy', as: 'reviewer' });

User.hasMany(RefreshToken, { foreignKey: 'userId', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// User <-> UserDevice
User.hasMany(UserDevice, { foreignKey: 'userId', as: 'devices' });
UserDevice.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// Workshift <-> OfficeConfig
OfficeConfig.hasMany(Workshift, { foreignKey: 'officeConfigId', as: 'workshifts' });
Workshift.belongsTo(OfficeConfig, { foreignKey: 'officeConfigId', as: 'officeConfig' });

// Workshift <-> Schedule
Workshift.hasMany(Schedule, { foreignKey: 'shiftId', as: 'schedules' });
Schedule.belongsTo(Workshift, { foreignKey: 'shiftId', as: 'Shift' });

// Attendance <-> Schedule
Schedule.hasMany(Attendance, { foreignKey: 'scheduleId', as: 'attendances' });
Attendance.belongsTo(Schedule, { foreignKey: 'scheduleId', as: 'Schedule' });

// User <-> Schedule
User.hasMany(Schedule, { foreignKey: 'userId', as: 'schedules' });
Schedule.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// Attendance <-> Workshift
// Attendance <-> Request
RequestModel.hasMany(Attendance, { foreignKey: 'requestId', as: 'attendances' });
Attendance.belongsTo(RequestModel, { foreignKey: 'requestId', as: 'request' });

export {
  User,
  UserStatus,
  Attendance,
  OfficeConfig,
  RefreshToken,
  RequestModel,
  Workshift,
  Schedule
  ,
  UserDevice
};
