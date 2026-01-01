"use strict";

module.exports = {
	up: async (queryInterface, Sequelize) => {
		// 1. Insert existing fcm_token values into user_devices as a migrated device row
		// Use a deterministic device_uuid so we can revert the change if needed
		await queryInterface.sequelize.query(`
			INSERT INTO user_devices (user_id, device_uuid, device_name, device_model, device_os_version, fcm_token, last_login, "createdAt", "updatedAt")
			SELECT id, ('migrated-fcm-' || id)::text, NULL, NULL, NULL, fcm_token, NOW(), NOW(), NOW()
			FROM users
			WHERE fcm_token IS NOT NULL;
		`);

		// 2. Remove fcm_token column from users (if exists)
		const tableInfo = await queryInterface.describeTable('users');
		if (tableInfo && tableInfo.fcm_token) {
			await queryInterface.removeColumn('users', 'fcm_token');
		}
	},

	down: async (queryInterface, Sequelize) => {
		// 1. Add fcm_token column back to users if missing
		const tableInfo = await queryInterface.describeTable('users');
		if (!tableInfo.fcm_token) {
			await queryInterface.addColumn('users', 'fcm_token', {
				type: Sequelize.DataTypes.STRING,
				allowNull: true,
			});
		}

		// 2. Restore fcm_token from migrated user_devices rows (if any)
		await queryInterface.sequelize.query(`
			UPDATE users u
			SET fcm_token = ud.fcm_token
			FROM (
				SELECT user_id, fcm_token
				FROM user_devices
				WHERE device_uuid LIKE 'migrated-fcm-%'
			) ud
			WHERE u.id = ud.user_id;
		`);

		// 3. Remove the migrated user_devices rows
		await queryInterface.sequelize.query(`
			DELETE FROM user_devices WHERE device_uuid LIKE 'migrated-fcm-%';
		`);
	},
};
