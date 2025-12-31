"use strict";

module.exports = {
	up: async (queryInterface, Sequelize) => {
		// 1) Ensure users.role enum includes MANAGER
		try {
			const users = await queryInterface.describeTable("users");
			if (users.role) {
				await queryInterface.changeColumn("users", "role", {
					type: Sequelize.ENUM("ADMIN", "MANAGER", "USER"),
					allowNull: false,
					defaultValue: "USER",
				});
			}
		} catch (e) {
			// ignore if users table doesn't exist yet
		}

		// 2) Rename requests.image_url -> requests.attachments (safe, preserve data)
		try {
			const reqTable = await queryInterface.describeTable("requests");

			if (reqTable && reqTable.image_url && !reqTable.attachments) {
				// add attachments column
				await queryInterface.addColumn("requests", "attachments", {
					type: Sequelize.TEXT,
					allowNull: true,
					comment: "JSON array of file paths",
				});

				// migrate existing image_url values into a single-element JSON array
				// Works for MySQL: wrap existing string into JSON_ARRAY
				try {
					await queryInterface.sequelize.query(
						"UPDATE `requests` SET `attachments` = JSON_ARRAY(`image_url`) WHERE `image_url` IS NOT NULL AND `image_url` != '';"
					);
				} catch (e) {
					// best-effort: ignore if DB does not support JSON_ARRAY
					await queryInterface.sequelize.query(
						"UPDATE `requests` SET `attachments` = `image_url` WHERE `image_url` IS NOT NULL AND `image_url` != '';"
					);
				}

				// drop old column
				await queryInterface.removeColumn("requests", "image_url");
			} else if (reqTable && !reqTable.attachments) {
				await queryInterface.addColumn("requests", "attachments", {
					type: Sequelize.TEXT,
					allowNull: true,
					comment: "JSON array of file paths",
				});
			}
		} catch (e) {
			// ignore if requests table missing
		}

		// 3) Create refresh_tokens table if it doesn't exist
		try {
			const rt = await queryInterface.describeTable("refresh_tokens");
			// table exists, skip
		} catch (e) {
			// create table
			await queryInterface.createTable("refresh_tokens", {
				id: {
					allowNull: false,
					primaryKey: true,
					type: Sequelize.UUID,
					defaultValue: Sequelize.UUIDV4,
				},
				user_id: {
					type: Sequelize.UUID,
					allowNull: false,
					references: { model: "users", key: "id" },
					onUpdate: "CASCADE",
					onDelete: "CASCADE",
				},
				token_hash: { type: Sequelize.STRING, allowNull: false },
				device_uuid: { type: Sequelize.STRING, allowNull: true },
				revoked: {
					type: Sequelize.BOOLEAN,
					allowNull: false,
					defaultValue: false,
				},
				expires_at: { type: Sequelize.DATE, allowNull: false },
				created_at: { allowNull: false, type: Sequelize.DATE },
				updated_at: { allowNull: false, type: Sequelize.DATE },
			});
		}

		// 4) Handle legacy singular `attendance` table: rename to preserve data if present
		try {
			const legacy = await queryInterface.describeTable("attendance");
			// if legacy exists, rename it to attendance_legacy to avoid collision with `attendances`
			try {
				await queryInterface.renameTable(
					"attendance",
					"attendance_legacy"
				);
			} catch (e) {
				// ignore rename failures
			}
		} catch (e) {
			// no legacy table
		}
	},

	down: async (queryInterface, Sequelize) => {
		// 1) Revert requests.attachments -> image_url where possible
		try {
			const reqTable = await queryInterface.describeTable("requests");
			if (reqTable && reqTable.attachments && !reqTable.image_url) {
				// add image_url back
				await queryInterface.addColumn("requests", "image_url", {
					type: Sequelize.STRING,
					allowNull: true,
				});

				// try to extract first element from JSON array to image_url (MySQL)
				try {
					await queryInterface.sequelize.query(
						"UPDATE `requests` SET `image_url` = JSON_UNQUOTE(JSON_EXTRACT(`attachments`, '$[0]')) WHERE `attachments` IS NOT NULL AND `attachments` != '';"
					);
				} catch (e) {
					// fallback: copy raw attachments
					await queryInterface.sequelize.query(
						"UPDATE `requests` SET `image_url` = `attachments` WHERE `attachments` IS NOT NULL AND `attachments` != '';"
					);
				}

				await queryInterface.removeColumn("requests", "attachments");
			}
		} catch (e) {}

		// 2) Drop refresh_tokens table if exists
		try {
			await queryInterface.dropTable("refresh_tokens");
		} catch (e) {}

		// 3) Revert users.role enum to ADMIN,USER (convert MANAGER -> USER to be safe)
		try {
			const users = await queryInterface.describeTable("users");
			if (users.role) {
				// convert MANAGER to USER to avoid invalid enum value
				await queryInterface.sequelize.query(
					"UPDATE `users` SET `role` = 'USER' WHERE `role` = 'MANAGER';"
				);
				await queryInterface.changeColumn("users", "role", {
					type: Sequelize.ENUM("ADMIN", "USER"),
					allowNull: false,
					defaultValue: "USER",
				});
			}
		} catch (e) {}

		// 4) Attempt to rename attendance_legacy back to attendance if present
		try {
			const legacy = await queryInterface.describeTable(
				"attendance_legacy"
			);
			try {
				await queryInterface.renameTable(
					"attendance_legacy",
					"attendance"
				);
			} catch (e) {}
		} catch (e) {}
	},
};
