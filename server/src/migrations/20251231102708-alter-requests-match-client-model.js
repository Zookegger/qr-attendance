'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('requests', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },

      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onDelete: 'CASCADE',
      },

      type: {
        type: Sequelize.STRING, // ✅ STRING
        allowNull: false,
      },

      from_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },

      to_date: {
        type: Sequelize.DATE,
        allowNull: true,
      },

      reason: {
        type: Sequelize.TEXT,
        allowNull: true, // ✅ khớp Flutter
      },

      attachments: {
        type: Sequelize.TEXT, // JSON string
        allowNull: true,
      },

      status: {
        type: Sequelize.STRING, // pending / approved / rejected
        allowNull: false,
        defaultValue: 'pending',
      },

      createdAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.fn('NOW'),
      },

      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE,
        defaultValue: Sequelize.fn('NOW'),
      },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('requests');
  },
};
