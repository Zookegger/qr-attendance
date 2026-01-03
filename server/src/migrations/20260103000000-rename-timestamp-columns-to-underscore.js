'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Rename columns for shifts table
    await queryInterface.renameColumn('shifts', 'createdAt', 'created_at');
    await queryInterface.renameColumn('shifts', 'updatedAt', 'updated_at');

    // Rename columns for user_devices table
    await queryInterface.renameColumn('user_devices', 'createdAt', 'created_at');
    await queryInterface.renameColumn('user_devices', 'updatedAt', 'updated_at');

    // Rename columns for attendances table
    await queryInterface.renameColumn('attendances', 'createdAt', 'created_at');
    await queryInterface.renameColumn('attendances', 'updatedAt', 'updated_at');

    // Rename columns for office_configs table
    await queryInterface.renameColumn('office_configs', 'createdAt', 'created_at');
    await queryInterface.renameColumn('office_configs', 'updatedAt', 'updated_at');

    // Rename columns for requests table
    await queryInterface.renameColumn('requests', 'createdAt', 'created_at');
    await queryInterface.renameColumn('requests', 'updatedAt', 'updated_at');

    // Rename columns for users table
    await queryInterface.renameColumn('users', 'createdAt', 'created_at');
    await queryInterface.renameColumn('users', 'updatedAt', 'updated_at');
  },

  async down(queryInterface, Sequelize) {
    // Reverse the renames
    await queryInterface.renameColumn('shifts', 'created_at', 'createdAt');
    await queryInterface.renameColumn('shifts', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('user_devices', 'created_at', 'createdAt');
    await queryInterface.renameColumn('user_devices', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('attendances', 'created_at', 'createdAt');
    await queryInterface.renameColumn('attendances', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('office_configs', 'created_at', 'createdAt');
    await queryInterface.renameColumn('office_configs', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('requests', 'created_at', 'createdAt');
    await queryInterface.renameColumn('requests', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('users', 'created_at', 'createdAt');
    await queryInterface.renameColumn('users', 'updated_at', 'updatedAt');
  }
};