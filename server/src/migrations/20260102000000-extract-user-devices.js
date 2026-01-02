"use strict";

module.exports = {
	async up(queryInterface, Sequelize) {
		// 1. Create the new table
		await queryInterface.createTable("user_devices", {
			id: {
				allowNull: false,
				autoIncrement: true,
				primaryKey: true,
				type: Sequelize.INTEGER,
			},
			user_id: {
				type: Sequelize.UUID,
				allowNull: false,
				references: { model: "users", key: "id" },
				onDelete: "CASCADE",
			},
			device_uuid: { type: Sequelize.STRING, allowNull: false },
			device_name: { type: Sequelize.STRING },
			device_model: { type: Sequelize.STRING },
			device_os_version: { type: Sequelize.STRING },
			last_login: {
				type: Sequelize.DATE,
				defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
			},
			createdAt: {
				allowNull: false,
				type: Sequelize.DATE,
				defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
			},
			updatedAt: {
				allowNull: false,
				type: Sequelize.DATE,
				defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
			},
		});

		// 2. Migrate existing data from users -> user_devices
		await queryInterface.sequelize.query(`
      INSERT INTO user_devices (user_id, device_uuid, device_name, device_model, device_os_version, createdAt, updatedAt)
      SELECT id, device_uuid, device_name, device_model, device_os_version, NOW(), NOW()
      FROM users
      WHERE device_uuid IS NOT NULL;
    `);

		// 3. Remove columns from Users table
		const cols = [
			"device_uuid",
			"device_name",
			"device_model",
			"device_os_version",
		];
		for (const c of cols) {
			// guard: only remove if exists (some DB engines may error)
			try {
				await queryInterface.removeColumn("users", c);
			} catch (e) {
				/* ignore */
			}
		}
	},

	async down(queryInterface, Sequelize) {
		// Rollback logic (add columns back to users, drop user_devices)
		await queryInterface.addColumn("users", "device_uuid", {
			type: Sequelize.STRING,
		});
		await queryInterface.addColumn("users", "device_name", {
			type: Sequelize.STRING,
		});
		await queryInterface.addColumn("users", "device_model", {
			type: Sequelize.STRING,
		});
		await queryInterface.addColumn("users", "device_os_version", {
			type: Sequelize.STRING,
		});

		// Attempt to restore the most recent device per user into users.device_uuid
		await queryInterface.sequelize.query(`
      UPDATE users u
      SET device_uuid = ud.device_uuid,
          device_name = ud.device_name,
          device_model = ud.device_model,
          device_os_version = ud.device_os_version
      FROM (
        SELECT DISTINCT ON (user_id) * FROM user_devices ORDER BY user_id, "updatedAt" DESC
      ) ud
      WHERE u.id = ud.user_id;
    `);

		await queryInterface.dropTable("user_devices");
	},
};
