'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Rename columns for shifts table
    await queryInterface.renameColumn('shifts', 'startTime', 'start_time');
    await queryInterface.renameColumn('shifts', 'endTime', 'end_time');
    await queryInterface.renameColumn('shifts', 'breakStart', 'break_start');
    await queryInterface.renameColumn('shifts', 'breakEnd', 'break_end');
    await queryInterface.renameColumn('shifts', 'gracePeriod', 'grace_period');
    await queryInterface.renameColumn('shifts', 'workDays', 'work_days');
    await queryInterface.renameColumn('shifts', 'createdAt', 'created_at');
    await queryInterface.renameColumn('shifts', 'updatedAt', 'updated_at');

    // Rename columns for user_devices table
    await queryInterface.renameColumn('user_devices', 'deviceUuid', 'device_uuid');
    await queryInterface.renameColumn('user_devices', 'deviceName', 'device_name');
    await queryInterface.renameColumn('user_devices', 'deviceModel', 'device_model');
    await queryInterface.renameColumn('user_devices', 'deviceOsVersion', 'device_os_version');
    await queryInterface.renameColumn('user_devices', 'fcmToken', 'fcm_token');
    await queryInterface.renameColumn('user_devices', 'lastLogin', 'last_login');
    await queryInterface.renameColumn('user_devices', 'createdAt', 'created_at');
    await queryInterface.renameColumn('user_devices', 'updatedAt', 'updated_at');

    // Rename columns for attendances table
    await queryInterface.renameColumn('attendances', 'checkInTime', 'check_in_time');
    await queryInterface.renameColumn('attendances', 'checkOutTime', 'check_out_time');
    await queryInterface.renameColumn('attendances', 'checkInLocation', 'check_in_location');
    await queryInterface.renameColumn('attendances', 'checkOutLocation', 'check_out_location');
    await queryInterface.renameColumn('attendances', 'checkInMethod', 'check_in_method');
    await queryInterface.renameColumn('attendances', 'checkOutMethod', 'check_out_method');
    await queryInterface.renameColumn('attendances', 'createdAt', 'created_at');
    await queryInterface.renameColumn('attendances', 'updatedAt', 'updated_at');

    // Rename columns for office_configs table
    await queryInterface.renameColumn('office_configs', 'createdAt', 'created_at');
    await queryInterface.renameColumn('office_configs', 'updatedAt', 'updated_at');

    // Rename columns for requests table
    await queryInterface.renameColumn('requests', 'fromDate', 'from_date');
    await queryInterface.renameColumn('requests', 'toDate', 'to_date');
    await queryInterface.renameColumn('requests', 'reviewedBy', 'reviewed_by');
    await queryInterface.renameColumn('requests', 'reviewNote', 'review_note');
    await queryInterface.renameColumn('requests', 'reviewDate', 'review_date');
    await queryInterface.renameColumn('requests', 'createdAt', 'created_at');
    await queryInterface.renameColumn('requests', 'updatedAt', 'updated_at');

    // Rename columns for users table
    await queryInterface.renameColumn('users', 'dateOfBirth', 'date_of_birth');
    await queryInterface.renameColumn('users', 'phoneNumber', 'phone_number');
    await queryInterface.renameColumn('users', 'passwordHash', 'password_hash');
    await queryInterface.renameColumn('users', 'passwordResetToken', 'password_reset_token');
    await queryInterface.renameColumn('users', 'passwordResetExpires', 'password_reset_expires');
    await queryInterface.renameColumn('users', 'createdAt', 'created_at');
    await queryInterface.renameColumn('users', 'updatedAt', 'updated_at');

    // Rename columns for schedules table
    await queryInterface.renameColumn('schedules', 'startDate', 'start_date');
    await queryInterface.renameColumn('schedules', 'endDate', 'end_date');
    await queryInterface.renameColumn('schedules', 'createdAt', 'created_at');
    await queryInterface.renameColumn('schedules', 'updatedAt', 'updated_at');

    // Rename columns for refresh_tokens table
    await queryInterface.renameColumn('refresh_tokens', 'userId', 'user_id');
    await queryInterface.renameColumn('refresh_tokens', 'tokenHash', 'token_hash');
    await queryInterface.renameColumn('refresh_tokens', 'expiresAt', 'expires_at');
    await queryInterface.renameColumn('refresh_tokens', 'createdAt', 'created_at');
    await queryInterface.renameColumn('refresh_tokens', 'updatedAt', 'updated_at');
  },

  async down(queryInterface, Sequelize) {
    // Reverse the renames
    await queryInterface.renameColumn('shifts', 'start_time', 'startTime');
    await queryInterface.renameColumn('shifts', 'end_time', 'endTime');
    await queryInterface.renameColumn('shifts', 'break_start', 'breakStart');
    await queryInterface.renameColumn('shifts', 'break_end', 'breakEnd');
    await queryInterface.renameColumn('shifts', 'grace_period', 'gracePeriod');
    await queryInterface.renameColumn('shifts', 'work_days', 'workDays');
    await queryInterface.renameColumn('shifts', 'created_at', 'createdAt');
    await queryInterface.renameColumn('shifts', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('user_devices', 'device_uuid', 'deviceUuid');
    await queryInterface.renameColumn('user_devices', 'device_name', 'deviceName');
    await queryInterface.renameColumn('user_devices', 'device_model', 'deviceModel');
    await queryInterface.renameColumn('user_devices', 'device_os_version', 'deviceOsVersion');
    await queryInterface.renameColumn('user_devices', 'fcm_token', 'fcmToken');
    await queryInterface.renameColumn('user_devices', 'last_login', 'lastLogin');
    await queryInterface.renameColumn('user_devices', 'created_at', 'createdAt');
    await queryInterface.renameColumn('user_devices', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('attendances', 'check_in_time', 'checkInTime');
    await queryInterface.renameColumn('attendances', 'check_out_time', 'checkOutTime');
    await queryInterface.renameColumn('attendances', 'check_in_location', 'checkInLocation');
    await queryInterface.renameColumn('attendances', 'check_out_location', 'checkOutLocation');
    await queryInterface.renameColumn('attendances', 'check_in_method', 'checkInMethod');
    await queryInterface.renameColumn('attendances', 'check_out_method', 'checkOutMethod');
    await queryInterface.renameColumn('attendances', 'created_at', 'createdAt');
    await queryInterface.renameColumn('attendances', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('office_configs', 'created_at', 'createdAt');
    await queryInterface.renameColumn('office_configs', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('requests', 'from_date', 'fromDate');
    await queryInterface.renameColumn('requests', 'to_date', 'toDate');
    await queryInterface.renameColumn('requests', 'reviewed_by', 'reviewedBy');
    await queryInterface.renameColumn('requests', 'review_note', 'reviewNote');
    await queryInterface.renameColumn('requests', 'review_date', 'reviewDate');
    await queryInterface.renameColumn('requests', 'created_at', 'createdAt');
    await queryInterface.renameColumn('requests', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('users', 'date_of_birth', 'dateOfBirth');
    await queryInterface.renameColumn('users', 'phone_number', 'phoneNumber');
    await queryInterface.renameColumn('users', 'password_hash', 'passwordHash');
    await queryInterface.renameColumn('users', 'password_reset_token', 'passwordResetToken');
    await queryInterface.renameColumn('users', 'password_reset_expires', 'passwordResetExpires');
    await queryInterface.renameColumn('users', 'created_at', 'createdAt');
    await queryInterface.renameColumn('users', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('schedules', 'start_date', 'startDate');
    await queryInterface.renameColumn('schedules', 'end_date', 'endDate');
    await queryInterface.renameColumn('schedules', 'created_at', 'createdAt');
    await queryInterface.renameColumn('schedules', 'updated_at', 'updatedAt');

    await queryInterface.renameColumn('refresh_tokens', 'user_id', 'userId');
    await queryInterface.renameColumn('refresh_tokens', 'token_hash', 'tokenHash');
    await queryInterface.renameColumn('refresh_tokens', 'expires_at', 'expiresAt');
    await queryInterface.renameColumn('refresh_tokens', 'created_at', 'createdAt');
    await queryInterface.renameColumn('refresh_tokens', 'updated_at', 'updatedAt');
  }
};