import express, { Application } from "express";
import cors from "cors";
import morgan from "morgan";
import routes from "@routes";
import { errorHandler } from "@middlewares/error.middleware";
import dotenv from "dotenv";
import path from "path";

dotenv.config();

const app: Application = express();

// Middleware
app.use(
	cors({
		origin: [
			"http://localhost:5173",
			"http://127.0.0.1:5173",
			"http://localhost:3000",
			"http://127.0.0.1:3000",
		],
		methods: ["GET", "POST", "PUT", "DELETE"],
		credentials: true,
	})
);

// Set up request logging with Morgan in development mode
app.use(
	morgan("dev", {
		stream: {
			write: (message: string) => {
				const currentTime = new Date(Date.now());

				console.log(
					`[SERVER - ${currentTime.toUTCString()}]:`,
					message.trim()
				);
			},
		},
	})
);

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

export default app;
