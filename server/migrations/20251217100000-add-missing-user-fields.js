'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('users');

    if (!tableInfo.device_uuid) {
      await queryInterface.addColumn('users', 'device_uuid', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: "Unique device ID for device binding"
      });
    }
    if (!tableInfo.fcm_token) {
      await queryInterface.addColumn('users', 'fcm_token', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: "Firebase Cloud Messaging Token for Push Notifications"
      });
    }
    if (!tableInfo.position) {
      await queryInterface.addColumn('users', 'position', {
        type: Sequelize.STRING,
        allowNull: true
      });
    }
    if (!tableInfo.department) {
      await queryInterface.addColumn('users', 'department', {
        type: Sequelize.STRING,
        allowNull: true
      });
    }
    if (!tableInfo.device_name) {
      await queryInterface.addColumn('users', 'device_name', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: "Device name (e.g. John's iPhone)"
      });
    }
    if (!tableInfo.device_model) {
      await queryInterface.addColumn('users', 'device_model', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: "Device model (e.g. iPhone 13)"
      });
    }
    if (!tableInfo.device_os_version) {
      await queryInterface.addColumn('users', 'device_os_version', {
        type: Sequelize.STRING,
        allowNull: true,
        comment: "Device OS version (e.g. iOS 15.0)"
      });
    }
  },

  async down(queryInterface, Sequelize) {
    const tableInfo = await queryInterface.describeTable('users');

    if (tableInfo.device_os_version) await queryInterface.removeColumn('users', 'device_os_version');
    if (tableInfo.device_model) await queryInterface.removeColumn('users', 'device_model');
    if (tableInfo.device_name) await queryInterface.removeColumn('users', 'device_name');
    if (tableInfo.department) await queryInterface.removeColumn('users', 'department');
    if (tableInfo.position) await queryInterface.removeColumn('users', 'position');
    if (tableInfo.fcm_token) await queryInterface.removeColumn('users', 'fcm_token');
    if (tableInfo.device_uuid) await queryInterface.removeColumn('users', 'device_uuid');
  }
};
