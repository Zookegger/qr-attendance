'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn('office_configs', 'latitude', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('office_configs', 'longitude', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
    await queryInterface.changeColumn('office_configs', 'radius', {
      type: Sequelize.DOUBLE,
      allowNull: false,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.changeColumn('office_configs', 'latitude', {
      type: Sequelize.FLOAT,
      allowNull: false,
    });
    await queryInterface.changeColumn('office_configs', 'longitude', {
      type: Sequelize.FLOAT,
      allowNull: false,
    });
    await queryInterface.changeColumn('office_configs', 'radius', {
      type: Sequelize.FLOAT,
      allowNull: false,
    });
  },
};