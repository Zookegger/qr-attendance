import { NextFunction, Request, Response } from "express";
import { validationResult } from "express-validator";
import RequestService from "@services/request.service";
import { CreateRequestDTO } from "@my-types/request";
import { ReviewRequestDTO } from "@my-types/request";
import fs from "fs";
import path from "path";
import logger from "@utils/logger";

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

		const user = req.user;
		if (!user) return res.status(403).json({ message: "Unauthorized" });

		const dto: CreateRequestDTO = {
			userId: user.id,
			type: req.body.type,
			fromDate: req.body.from_date,
			toDate: req.body.to_date,
			reason: req.body.reason,
		};

		// Handle file uploads (support array('attachments') and fields/object formats)
		let uploadedFiles: Express.Multer.File[] = [];

		if (Array.isArray(req.files)) {
			uploadedFiles = req.files as Express.Multer.File[];
		} else if (req.files && 'attachments' in req.files) {
			uploadedFiles = req.files['attachments'] as Express.Multer.File[] || [];
		} else if (req.files && 'files' in req.files) {
			uploadedFiles = req.files['files'] as Express.Multer.File[] || [];
		}
		
		logger.debug(uploadedFiles);

		if (uploadedFiles.length > 0) {
			// Safety: enforce reasonable max (multer should already enforce)
			if (uploadedFiles.length > 10) {
				return res.status(400).json({ message: "Too many attachment files" });
			}

			const paths = uploadedFiles.map(file => file.path);
			dto.attachments = JSON.stringify(paths);
		}

		const created = await RequestService.createRequest(dto);

				// --- Gửi notification tới admin ---
		return res
			.status(201)
			.json({ message: "Request created", request: created });
	} catch (err) {
		return next(err);
	}
};

const listRequests = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = req.user;
		if (!user) return res.status(401).json({ message: "Unauthorized" });

		const filters = {
			status: req.query.status as string,
			type: req.query.type as string,
			fromDate: req.query.from_date as string,
			userId: req.query.user_id as string,
		};
		const results = await RequestService.listRequests(user, filters);

		return res.status(200).json({ requests: results });
	} catch (err) {
		return next(err);
	}
};

const getRequest = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = req.user;
		if (!user) return res.status(401).json({ message: "Unauthorized" });

		const { id } = req.params;
		if (!id) return res.status(400).json({ message: "Request id is required" });
		
		const result = await RequestService.findById(id, user);
		return res.status(200).json({ request: result });
	} catch (err) {
		return next(err);
	}
};

const reviewRequest = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return res.status(400).json({ errors: errors.array() });
		}

		const reviewer = req.user;
		if (!reviewer) return res.status(401).json({ message: "Unauthorized" });

		const { id } = req.params;
		if (!id) return res.status(400).json({ message: "Request id is required" });

		const dto: ReviewRequestDTO = {
			status: req.body.status,
			reviewNote: req.body.review_note,
			reviewedBy: reviewer.id,
		};

		const updated = await RequestService.reviewRequest(id, dto, reviewer.id);
		return res.status(200).json({ message: "Request reviewed", request: updated });
	} catch (err) {
		return next(err);
	}
};

const cancelRequest = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = req.user;
		if (!user) return res.status(401).json({ message: "Unauthorized" });

		const { id } = req.params;

		if (!id) return res.status(400).json({ message: "Request id is required" });

		const result = await RequestService.cancel(id, user.id);
		return res.status(200).json(result);
	} catch (err) {
		return next(err);
	}
};

const updateRequest = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) {
			return res.status(400).json({ errors: errors.array() });
		}

		const user = req.user;
		if (!user) return res.status(401).json({ message: "Unauthorized" });

		// Prefer id from params (route: /requests/:id)
		const { id } = req.params as { id?: string };
		if (!id) return res.status(400).json({ message: "Request id is required" });

		// Fetch existing request (this will enforce authorization for normal users)
		const existing = await RequestService.findById(id, user);

		const dto: Partial<CreateRequestDTO> = {};
		if (req.body.type) dto.type = req.body.type;
		if (req.body.from_date) dto.fromDate = req.body.from_date;
		if (req.body.to_date) dto.toDate = req.body.to_date;
		if (req.body.reason) dto.reason = req.body.reason;

		// If there are uploaded files for update, handle them and delete old ones safely
		let uploadedForUpdate: Express.Multer.File[] = [];

		

		if (Array.isArray(req.files)) {
			uploadedForUpdate = req.files as Express.Multer.File[];
		} else if (req.files && 'attachments' in req.files) {
			uploadedForUpdate = (req.files as any)['attachments'] as Express.Multer.File[] || [];
		} else if (req.files && 'files' in req.files) {
			uploadedForUpdate = (req.files as any)['files'] as Express.Multer.File[] || [];
		}

		logger.debug(uploadedForUpdate);

		if (uploadedForUpdate.length > 0) {
			if (uploadedForUpdate.length > 10) {
				return res.status(400).json({ message: "Too many attachment files" });
			}

			dto.attachments = JSON.stringify(uploadedForUpdate.map(f => f.path));

			if (existing && existing.attachments) {
				try {
					const old: string[] = JSON.parse(existing.attachments);
					const baseUploadDir = path.resolve(__dirname, "..", "..", "uploads");
					for (const relOrAbs of old) {
						try {
							const abs = path.resolve(relOrAbs);
							if (abs.startsWith(baseUploadDir) && fs.existsSync(abs)) {
								await fs.promises.unlink(abs);
							} else {
								logger.warn(`Skipping deletion of suspicious attachment path: ${abs}`);
							}
						} catch (e) {
							logger.warn(`Failed to delete old attachment ${relOrAbs}: ${e}`);
						}
					}
				} catch (e) {
					logger.warn(`Unable to parse old attachments for request ${id}: ${e}`);
				}
			}
		}

		const updated = await RequestService.updateRequest(id, user.id, dto);
		return res.status(200).json({ message: "Request updated", request: updated });
	} catch (err) {
		return next(err);
	}
};

export const RequestController = {
	createRequest,
	listRequests,
	getRequest,
	reviewRequest,
	cancelRequest,
	updateRequest,
};
