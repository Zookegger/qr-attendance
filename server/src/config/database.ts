/**
 * Database configuration and Sequelize setup.
 *
 * This module configures the Sequelize ORM instance for MySQL database connection.
 * It handles environment-based configuration, connection pooling, and provides
 * utilities for database operations.
 */

import { Dialect, Sequelize } from "sequelize";

const DB_HOST: string = process.env.DB_HOST || "127.0.0.1";
const DB_PORT: number = Number(process.env.DB_PORT) || 3306;
const DB_USER: string = process.env.DB_USER || "root";
const DB_PASS: string = process.env.DB_PASS || "";
const DB_NAME: string = process.env.DB_NAME || "qr_attendance_db";
const DB_DIALECT: Dialect = (process.env.DB_DIALECT as Dialect) || "mysql";
const DB_LOGGING: boolean = process.env.DB_LOGGING === "true";

/**
 * Configured Sequelize instance for database operations.
 *
 * This is the main database connection instance used throughout the application.
 * It is configured with MySQL dialect, connection pooling, and default table options.
 */
export const sequelize = new Sequelize(DB_NAME, DB_USER, DB_PASS, {
	host: DB_HOST,
	port: DB_PORT,
	dialect: DB_DIALECT,
	logging: DB_LOGGING,

	pool: {
		max: 10, // Maximum number of connections to create
		min: 0, // Minimum number of connections to keep open
		acquire: 30000, // Maximum time (in ms) to get a connection
		idle: 10000, // Maximum time (in ms) a connection can be unused
	},

	define: {
		timestamps: true, // Automatically add created_at and updated_at fields
		engine: "InnoDB",
		charset: "utf8mb4",
		collate: "utf8mb4_unicode_ci",
	},
});

/**
 * Creates a temporary Sequelize connection without specifying a database.
 *
 * This is useful for operations that need to create or drop databases,
 * or perform other operations outside of a specific database context.
 *
 * @returns {Sequelize} A new Sequelize instance without database specification
 */
export const createTempConnection = (): Sequelize => {
	return new Sequelize(
		// @ts-ignore
		null,
		DB_USER,
		DB_PASS,
		{
			host: DB_HOST,
			port: DB_PORT,
			dialect: "mysql",
			logging: false,
		},
	);
};

export default sequelize;