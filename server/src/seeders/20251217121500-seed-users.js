"use strict";

const bcrypt = require("bcrypt");

module.exports = {
	up: async (queryInterface, Sequelize) => {
		const now = new Date();
		const adminHash = await bcrypt.hash("adminpass123", 10);
		const userHash = await bcrypt.hash("userpass123", 10);

		await queryInterface.bulkInsert(
			"users",
			[
				{
					id: "00000000-0000-0000-0000-000000000001",
					name: "Admin User",
					email: "admin@example.com",
					passwordHash: adminHash,
					role: "ADMIN",
					status: "ACTIVE",
					position: null,
					department: null,
					dateOfBirth: null,
					phoneNumber: null,
					address: null,
					gender: null,
					createdAt: now,
					updatedAt: now,
				},
				{
					id: "00000000-0000-0000-0000-000000000002",
					name: "Regular User",
					email: "user@example.com",
					passwordHash: userHash,
					role: "USER",
					status: "ACTIVE",
					position: null,
					department: null,
					dateOfBirth: null,
					phoneNumber: null,
					address: null,
					gender: null,
					createdAt: now,
					updatedAt: now,
				},
			],
			{}
		);
	},

	down: async (queryInterface, Sequelize) => {
		await queryInterface.bulkDelete(
			"users",
			{ email: ["admin@example.com", "user@example.com"] },
			{}
		);
	},
};
