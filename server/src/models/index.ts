import { User } from './user';
import { Attendance } from './attendance';
import { LeaveRequest } from './leaveRequest';
import { OfficeConfig } from './officeConfig';

// Define Associations
User.hasMany(Attendance, { foreignKey: 'user_id', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

User.hasMany(LeaveRequest, { foreignKey: 'user_id', as: 'leaveRequests' });
LeaveRequest.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

export {
  User,
  Attendance,
  LeaveRequest,
  OfficeConfig
};
