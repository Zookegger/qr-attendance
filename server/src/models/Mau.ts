import { User } from './user';
import { Attendance } from './attendance';
import { Shift } from './shift';
import { UserShift } from './userShift';
import { QrScanLog } from './qrScanLog';
import { ScanLocation } from './scanLocation';
import { Payroll } from './payroll';
import { SystemLog } from './systemLog';

// User - Attendance
User.hasMany(Attendance, { foreignKey: 'user_id', as: 'attendances' });
Attendance.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Shift - Attendance
Shift.hasMany(Attendance, { foreignKey: 'shift_id', as: 'attendances' });
Attendance.belongsTo(Shift, { foreignKey: 'shift_id', as: 'shift' });

// User - Shift (PhanCa)
User.hasMany(UserShift, { foreignKey: 'user_id', as: 'userShifts' });
UserShift.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

Shift.hasMany(UserShift, { foreignKey: 'shift_id', as: 'userShifts' });
UserShift.belongsTo(Shift, { foreignKey: 'shift_id', as: 'shift' });

// QR Scan Log
User.hasMany(QrScanLog, { foreignKey: 'user_id', as: 'qrLogs' });
QrScanLog.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Scan Location
QrScanLog.hasMany(ScanLocation, { foreignKey: 'log_id', as: 'locations' });
ScanLocation.belongsTo(QrScanLog, { foreignKey: 'log_id', as: 'log' });

// Payroll
User.hasMany(Payroll, { foreignKey: 'user_id', as: 'payrolls' });
Payroll.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// System Log
User.hasMany(SystemLog, { foreignKey: 'performed_by', as: 'systemLogs' });
SystemLog.belongsTo(User, { foreignKey: 'performed_by', as: 'user' });

export {
  User,
  Attendance,
  Shift,
  UserShift,
  QrScanLog,
  ScanLocation,
  Payroll,
  SystemLog
};
