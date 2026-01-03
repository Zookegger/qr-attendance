/**
 * Database configuration and Sequelize setup.
 *
 * This module configures the Sequelize ORM instance for MySQL database connection.
 * It handles environment-based configuration, connection pooling, and provides
 * utilities for database operations.
 */

import logger from "@utils/logger";
import { QueryTypes } from "sequelize";
import dotenv from "dotenv";
import { Dialect, Sequelize } from "sequelize";

dotenv.config();

const DB_HOST: string = process.env.DB_HOST || "127.0.0.1";
const DB_PORT: number = Number(process.env.DB_PORT) || 3306;
const DB_USER: string = process.env.DB_USER || "root";
const DB_PASS: string = process.env.DB_PASS || "";
const DB_NAME: string = process.env.DB_NAME || "qr_attendance_db";
const DB_DIALECT: Dialect = (process.env.DB_DIALECT as Dialect) || "mysql";
const DB_LOGGING: boolean = process.env.DB_LOGGING === "true";

const isTest = process.env.NODE_ENV === "test";

const sequelizeConfig = isTest
	? {
			dialect: "sqlite" as Dialect,
			storage: ":memory:",
			logging: false,
	  }
	: {
			host: DB_HOST,
			port: DB_PORT,
			dialect: DB_DIALECT,
			logging: DB_LOGGING,
			pool: {
				max: 10,
				min: 0,
				acquire: 30000,
				idle: 10000,
			},
			define: {
				timestamps: true,
				engine: "InnoDB",
				charset: "utf8mb4",
				collate: "utf8mb4_unicode_ci",
			},
	  };

/**
 * Configured Sequelize instance for database operations.
 *
 * This is the main database connection instance used throughout the application.
 * It is configured with MySQL dialect, connection pooling, and default table options.
 */
export const sequelize = new Sequelize(
	isTest ? "sqlite::memory:" : DB_NAME,
	isTest ? "" : DB_USER,
	isTest ? "" : DB_PASS,
	sequelizeConfig
);

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
		}
	);
};
/**
 * Creates the database if it doesn't exist.
 *
 * This function establishes a temporary connection to the MySQL server
 * (without specifying a database) and creates the application database
 * if it doesn't already exist.
 *
 * @async
 * @returns {Promise<void>} Resolves when database creation is complete
 * @throws {Error} If database creation fails
 */
const created_atabase = async () => {
	const temp_connection = createTempConnection();

	try {
		await temp_connection.authenticate();

		const database = await temp_connection.query("SHOW DATABASES LIKE ?", {
			replacements: [process.env.DB_NAME],
			type: QueryTypes.SELECT,
		});

		if (database.length === 0) {
			await temp_connection.query(
				`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\``,
				{ type: QueryTypes.RAW }
			);
			logger.info(`Database ${process.env.DB_NAME} created successfully`);
		} else {
			logger.debug(`Database ${process.env.DB_NAME} already exist`);
		}
	} catch (err) {
		logger.error(err);
		throw err;
	} finally {
		await temp_connection.close();
	}
};

/**
 * Establishes connection to the database and synchronizes models.
 *
 * This function handles the complete database setup process:
 * - Creates the database if needed
 * - Authenticates the connection
 * - Synchronizes all models with the database schema
 * - Generates default admin account
 *
 * @async
 * @returns {Promise<void>} Resolves when database connection and sync are complete
 * @throws {Error} If connection or synchronization fails
 */
export const connectToDatabase = async (): Promise<void> => {
	try {
		await created_atabase();
		logger.info("Connecting to Database Server...");
		await sequelize.authenticate();
		logger.info("Database connected");
		logger.info("Synchronizing models...");

		await sequelize.sync();

		logger.info("Models synchronized to Database");
	} catch (err) {
		logger.error(err);
		throw err;
	}
};
export default sequelize;
