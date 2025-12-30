import { NextFunction, Request, Response } from "express";
import { validationResult } from "express-validator";
import RequestService from "@services/request.service";
import { CreateRequestDTO } from "@my-types/request";

const createRequest = async (
	req: Request,
	res: Response,
	next: NextFunction
) => {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return res.status(400).json({ errors: errors.array() });
		}

		const user = (req as any).user;
		if (!user) return res.status(403).json({ message: "Unauthorized" });

		const dto: CreateRequestDTO = {
			user_id: user.id,
			...req.body,
		};

		// Handle file uploads
		if (req.files && 'files' in req.files) {
			const files = req.files['files'] as Express.Multer.File[];
			if (files && files.length > 0) {
				const paths = files.map(file => file.path);
				dto.attachments = JSON.stringify(paths);
			}
		}

		const created = await RequestService.createRequest(dto);

		return res
			.status(201)
			.json({ message: "Request created", request: created });
	} catch (err) {
		return next(err);
	}
};

export const RequestController = {
	createRequest,
};
