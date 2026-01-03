import { Model, DataTypes } from "sequelize";
import { sequelize } from "@config/database";

export default class UserDevice extends Model {
   public declare id: number;
   public declare user_id: string;
   public declare device_uuid: string;
   public declare device_name: string | null;
   public declare device_model: string | null;
   public declare device_os_version: string | null;
   public declare fcm_token: string | null;
   public declare last_login: Date;

   public declare readonly created_at: Date;
   public declare readonly updated_at: Date;
}

UserDevice.init(
   {
      id: {
         type: DataTypes.INTEGER,
         autoIncrement: true,
         primaryKey: true,
      },
      user_id: {
         type: DataTypes.UUID,
         allowNull: false,
      },
      device_uuid: {
         type: DataTypes.STRING,
         allowNull: false,
      },
      device_name: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      device_model: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      device_os_version: {
         type: DataTypes.STRING,
         allowNull: true,
      },
      fcm_token: {
         type: DataTypes.STRING,
         allowNull: true,
         comment: "FCM token associated with this device (migrated from users.fcm_token)",
      },
      last_login: {
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
