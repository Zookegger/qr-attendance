// seeders/xxxxxx-01-init-admin.js
const bcrypt = require("bcrypt");

/** @type {import('sequelize-cli').Migration} */
module.exports = {
	async up(queryInterface, Sequelize) {
		// 1. Hash the password (salt rounds: 10)
		const salt = bcrypt.genSaltSync(10);
		const hashedPassword = bcrypt.hashSync("admin123", salt);

		// 2. Insert the Admin
		return queryInterface.bulkInsert("Users", [
			{
				full_name: "Super Admin",
				email: "admin@company.com",
				password: hashedPassword,
				role: "ADMIN", // Ensure this matches your Enum or String logic
				device_uuid: null, // Admin doesn't need a bound device
				createdAt: new Date(),
				updatedAt: new Date(),
			},
		]);
	},

	async down(queryInterface, Sequelize) {
		// This runs if you undo the seed
		return queryInterface.bulkDelete(
			"Users",
			{ email: "admin@company.com" },
			{}
		);
	},
};
