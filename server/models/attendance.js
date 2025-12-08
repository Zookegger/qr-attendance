const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class Attendance extends Model {
    static associate(models) {
      Attendance.belongsTo(models.User, { foreignKey: 'user_id' });
    }
  }

  Attendance.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    user_id: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    timestamp: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    method: {
      type: DataTypes.ENUM('QR', 'manual'),
      allowNull: false,
    },
    location: {
      type: DataTypes.JSON,
      allowNull: true,
      comment: 'Stores location object (lat, long, etc.)',
    },
  }, {
    sequelize,
    modelName: 'Attendance',
    tableName: 'attendance',
  });

  return Attendance;
};
