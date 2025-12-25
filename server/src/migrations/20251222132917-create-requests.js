'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('requests', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      type: {
        type: Sequelize.ENUM('LEAVE', 'SICK', 'UNPAID', 'LATE_EARLY', 'OVERTIME', 'BUSINESS_TRIP', 'SHIFT_CHANGE', 'REMOTE_WORK', 'ATTENDANCE_CONFIRMATION', 'ATTENDANCE_ADJUSTMENT', 'EXPLANATION', 'OTHER'),
        allowNull: false,
        defaultValue: 'OTHER'
      },
      from_date: {
        type: Sequelize.DATE,
        allowNull: true
      },
      to_date: {
        type: Sequelize.DATE,
        allowNull: true
      },
      reason: {
        type: Sequelize.TEXT,
        allowNull: false
      },
      image_url: {
        type: Sequelize.STRING,
        allowNull: true
      },
      status: {
        type: Sequelize.ENUM('PENDING', 'APPROVED', 'REJECTED'),
        allowNull: false,
        defaultValue: 'PENDING'
      },
      reviewed_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      review_note: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('requests');
  }
};
