import { Router } from "express";
import { RequestController } from "@controllers/request.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import {
	createRequestValidator,
	listRequestsValidator,
	reviewRequestValidator,
	requestIdParamValidator,
    updateRequestValidator,
} from "@middlewares/validators/request.validator";
import { createUploadMiddleware } from "@middlewares/upload.middleware";

const requestRouter = Router();

const upload_attachments = createUploadMiddleware("requests");

requestRouter.post(
	"/requests",
	authenticate,
	createRequestValidator,
	upload_attachments.array('attachments', 5),
	RequestController.createRequest,
	errorHandler
);

requestRouter.put(
	"/requests/:id",
	authenticate,
	updateRequestValidator,
	upload_attachments.array('attachments', 5),
	RequestController.updateRequest,
	errorHandler
);

requestRouter.get(
	"/requests",
	authenticate,
	listRequestsValidator,
	RequestController.listRequests,
	errorHandler
);

requestRouter.get(
	"/requests/:id",
	authenticate,
	requestIdParamValidator,
	RequestController.getRequest,
	errorHandler
);

requestRouter.post(
	"/requests/:id/review",
	authenticate,
	reviewRequestValidator,
	RequestController.reviewRequest,
	errorHandler
);

requestRouter.delete(
	"/requests/:id",
	authenticate,
	requestIdParamValidator,
	RequestController.cancelRequest,
	errorHandler
);

export default requestRouter;
