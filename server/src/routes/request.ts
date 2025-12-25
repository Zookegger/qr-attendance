import { Router } from "express";
import { createRequest } from "@controllers/request.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { createRequestValidator } from "@middlewares/validators/request.validator";

const requestRouter = Router();

requestRouter.post(
	"/requests",
	authenticate,
	createRequestValidator,
	createRequest,
	errorHandler
);

export default requestRouter;
