'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Drop affected tables if they exist (order matters due to FKs)
    try {
      await queryInterface.dropTable('schedules');
    } catch (e) {}
    try {
      await queryInterface.dropTable('shifts');
    } catch (e) {}
    try {
      await queryInterface.dropTable('attendances');
    } catch (e) {}
    try {
      await queryInterface.dropTable('office_configs');
    } catch (e) {}

    // Recreate office_configs with integer unsigned auto-increment id
    await queryInterface.createTable('office_configs', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.INTEGER.UNSIGNED,
        autoIncrement: true,
      },
      name: { type: Sequelize.STRING, allowNull: false },
      latitude: { type: Sequelize.FLOAT, allowNull: false },
      longitude: { type: Sequelize.FLOAT, allowNull: false },
      radius: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 100 },
      wifi_ssid: { type: Sequelize.STRING, allowNull: true },
      createdAt: { allowNull: false, type: Sequelize.DATE },
      updatedAt: { allowNull: false, type: Sequelize.DATE },
    });

    // Recreate shifts (workshifts)
    await queryInterface.createTable('shifts', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.INTEGER.UNSIGNED,
        autoIncrement: true,
      },
      name: { type: Sequelize.STRING, allowNull: false },
      startTime: { type: Sequelize.TIME, allowNull: false },
      endTime: { type: Sequelize.TIME, allowNull: false },
      breakStart: { type: Sequelize.TIME, allowNull: true },
      breakEnd: { type: Sequelize.TIME, allowNull: true },
      gracePeriod: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 15 },
      workDays: { type: Sequelize.JSON, allowNull: false, defaultValue: [] },
      office_config_id: {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: true,
        references: { model: 'office_configs', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      createdAt: { allowNull: false, type: Sequelize.DATE },
      updatedAt: { allowNull: false, type: Sequelize.DATE },
    });

    // Recreate schedules
    await queryInterface.createTable('schedules', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.INTEGER.UNSIGNED,
        autoIncrement: true,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      shift_id: {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        references: { model: 'shifts', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      start_date: { type: Sequelize.DATEONLY, allowNull: false },
      end_date: { type: Sequelize.DATEONLY, allowNull: true },
      createdAt: { allowNull: false, type: Sequelize.DATE },
      updatedAt: { allowNull: false, type: Sequelize.DATE },
    });

    // Recreate attendances
    await queryInterface.createTable('attendances', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.INTEGER.UNSIGNED,
        autoIncrement: true,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      date: { type: Sequelize.DATEONLY, allowNull: false },
      check_in_time: { type: Sequelize.DATE, allowNull: true },
      check_out_time: { type: Sequelize.DATE, allowNull: true },
      status: { type: Sequelize.ENUM('Present', 'LATE', 'ABSENT'), allowNull: false, defaultValue: 'ABSENT' },
      check_in_location: { type: Sequelize.JSON, allowNull: true },
      check_out_location: { type: Sequelize.JSON, allowNull: true },
      check_in_method: { type: Sequelize.ENUM('QR', 'MANUAL', 'NONE'), allowNull: true },
      check_out_method: { type: Sequelize.ENUM('QR', 'MANUAL', 'NONE'), allowNull: true },
      createdAt: { allowNull: false, type: Sequelize.DATE },
      updatedAt: { allowNull: false, type: Sequelize.DATE },
    });

    // Index for attendances unique constraint
    await queryInterface.addIndex('attendances', ['user_id', 'date'], { unique: true, name: 'attendances_user_date_unique' });
  },

  async down(queryInterface, Sequelize) {
    // Reverse: drop created tables
    try {
      await queryInterface.dropTable('attendances');
    } catch (e) {}
    try {
      await queryInterface.dropTable('schedules');
    } catch (e) {}
    try {
      await queryInterface.dropTable('shifts');
    } catch (e) {}
    try {
      await queryInterface.dropTable('office_configs');
    } catch (e) {}
  },
};
