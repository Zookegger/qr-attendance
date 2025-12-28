import { Router } from "express";
import { createRequest } from "@controllers/request.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { createRequestValidator } from "@middlewares/validators/request.validator";
import { createUploadMiddleware } from "@middlewares/upload.middleware";

const requestRouter = Router();

const imageUpload = createUploadMiddleware("requests");

requestRouter.post(
	"/requests",
	authenticate,
	createRequestValidator,
	imageUpload.fields([{ name: 'files', maxCount: 10 }]),
	createRequest,
	errorHandler
);

export default requestRouter;
