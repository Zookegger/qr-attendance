import { Model, DataTypes } from "sequelize";
import { sequelize } from "@config/database";

export default class UserDevice extends Model {
   public declare id: number;
   public declare userId: string;
   public declare deviceUuid: string;
   public declare deviceName: string | null;
   public declare deviceModel: string | null;
   public declare deviceOsVersion: string | null;
   public declare fcmToken: string | null;
   public declare lastLogin: Date;

   public declare readonly createdAt: Date;
   public declare readonly updatedAt: Date;
}

UserDevice.init(
   {
      id: {
         type: DataTypes.INTEGER,
         autoIncrement: true,
         primaryKey: true,
      },
      userId: {
         type: DataTypes.UUID,
         allowNull: false,
      },
      deviceUuid: {
         type: DataTypes.STRING,
         allowNull: false,
      },
      deviceName: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      deviceModel: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      deviceOsVersion: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      fcmToken: {
         type: DataTypes.STRING,
         allowNull: true,
         comment: "FCM token associated with this device (migrated from users.fcm_token)",
      },
      lastLogin: {
         type: DataTypes.DATE,
         allowNull: true,
         defaultValue: DataTypes.NOW,
      },
   },
   {
      sequelize,
      tableName: "user_devices",
      underscored: true,
      timestamps: true,
      indexes: [
         {
            unique: true,
            fields: ["user_id", "device_uuid"],
         },
      ],
   }
);
