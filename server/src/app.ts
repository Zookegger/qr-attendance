import express, { Application } from "express";
import cors from "cors";
import routes from "@routes";
import { errorHandler } from "@middlewares/error.middleware";
import logger from "@utils/logger";
import { initCronJobs } from "@services/cron.service";
import { sequelize } from "@config/database";
import dotenv from "dotenv";
import path from "path";

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Server uploads statically
const uploadsPath = path.resolve(__dirname, "../uploads");
app.use(
	"/uploads",
	express.static(uploadsPath, {
		dotfiles: "ignore",
		index: false,
		maxAge: "1d",
		setHeaders: (res, _path) => {
			res.setHeader("X-Content-Type-Options", "nosniff");
			res.setHeader("Cache-Control", "public, max-age=86400");
		},
	})
);

// Routes
app.use("/api", routes);

// Error Handling
app.use(errorHandler);

// Start Server
if (require.main === module) {
	// Sync Database
	sequelize
		.sync({ alter: true })
		.then(() => {
			logger.info("Database synced");
			// Init Cron Jobs
			initCronJobs();

			app.listen(PORT, () => {
				logger.info(`Server running on port ${PORT}`);
			});
		})
		.catch((err) => {
			logger.error("Failed to sync database:", err);
		});
}

export default app;
