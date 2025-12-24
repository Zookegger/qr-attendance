import { Router } from "express";
import { AuthController } from "@controllers/auth.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";

const authRouter = Router();

// --- Auth Routes ---
authRouter.post("/auth/login", AuthController.login, errorHandler);
authRouter.post("/auth/logout", authenticate, AuthController.logout, errorHandler);
authRouter.post("/auth/refresh", authenticate, AuthController.refresh, errorHandler);
authRouter.get("/auth/me", authenticate, AuthController.me, errorHandler);
authRouter.get("/auth/reset-password", AuthController.resetPasswordLanding, errorHandler);
authRouter.post("/auth/reset-password", AuthController.resetPassword, errorHandler);

export default authRouter;
