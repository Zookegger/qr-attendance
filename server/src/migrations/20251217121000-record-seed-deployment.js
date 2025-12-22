"use strict";

module.exports = {
	up: async (queryInterface, Sequelize) => {
		// Add any remaining user columns not already added by prior migrations.
		const tableInfo = await queryInterface.describeTable("users");

		if (!tableInfo.date_of_birth) {
			await queryInterface.addColumn("users", "date_of_birth", {
				type: Sequelize.DATEONLY,
				allowNull: true,
			});
		}

		if (!tableInfo.phone_number) {
			await queryInterface.addColumn("users", "phone_number", {
				type: Sequelize.STRING,
				allowNull: true,
			});
		}

		if (!tableInfo.address) {
			await queryInterface.addColumn("users", "address", {
				type: Sequelize.STRING,
				allowNull: true,
			});
		}

		if (!tableInfo.gender) {
			await queryInterface.addColumn("users", "gender", {
				type: Sequelize.ENUM("MALE", "FEMALE", "OTHER"),
				allowNull: true,
			});
		}

		// Ensure `status` column exists (matches model enum values)
		if (!tableInfo.status) {
			await queryInterface.addColumn('users', 'status', {
				type: Sequelize.ENUM('ACTIVE', 'INACTIVE', 'PENDING'),
				allowNull: false,
				defaultValue: 'ACTIVE',
				comment: 'Account status for login access and lifecycle management',
			});
		}

		// Normalize existing role text to uppercase to fit new enum values
		await queryInterface.sequelize.query("UPDATE `users` SET `role` = UPPER(`role`) WHERE `role` IS NOT NULL;");

		// Change role enum to match application model (`ADMIN`, `USER`)
		await queryInterface.changeColumn('users', 'role', {
			type: Sequelize.ENUM('ADMIN', 'USER'),
			defaultValue: 'USER',
			allowNull: false,
		});
	},

	down: async (queryInterface, Sequelize) => {
		const tableInfo = await queryInterface.describeTable("users");

		if (tableInfo.gender)
			await queryInterface.removeColumn("users", "gender");
		if (tableInfo.address)
			await queryInterface.removeColumn("users", "address");
		if (tableInfo.phone_number)
			await queryInterface.removeColumn("users", "phone_number");
		if (tableInfo.date_of_birth)
			await queryInterface.removeColumn("users", "date_of_birth");
		// Revert role enum to lowercase values used previously, converting values back
		if (tableInfo.role) {
			await queryInterface.sequelize.query("UPDATE `users` SET `role` = LOWER(`role`) WHERE `role` IS NOT NULL;");
			await queryInterface.changeColumn('users', 'role', {
				type: Sequelize.ENUM('admin', 'user'),
				defaultValue: 'user',
				allowNull: false,
			});
		}

		if (tableInfo.status) {
			await queryInterface.removeColumn('users', 'status');
		}
	},
};
