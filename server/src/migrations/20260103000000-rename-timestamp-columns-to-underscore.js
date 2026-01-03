'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Rename columns for shifts table
    await queryInterface.renameColumn('shifts', 'createdAt', 'created_at');
    await queryInterface.renameColumn('shifts', 'updatedAt', 'updated_at');

    // Rename columns for user_devices table
    await queryInterface.renameColumn('user_devices', 'createdAt', 'created_at');
    await queryInterface.renameColumn('user_devices', 'updatedAt', 'updated_at');
  },

  async down(queryInterface, Sequelize) {
    // Reverse the renames
    await queryInterface.renameColumn('shifts', 'created_at', 'createdAt');
    await queryInterface.renameColumn('shifts', 'updated_at', 'updatedAt');
    await queryInterface.renameColumn('user_devices', 'created_at', 'createdAt');
    await queryInterface.renameColumn('user_devices', 'updated_at', 'updatedAt');
  }
};