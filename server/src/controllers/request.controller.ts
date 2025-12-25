import { NextFunction, Request, Response } from "express";
import { validationResult } from "express-validator";
import { RequestService } from "@services/request.service";
import { CreateRequestDTO } from "@my-types/request";

export async function createRequest(
	req: Request,
	res: Response,
	next: NextFunction
) {
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

		const created = await RequestService.createRequest(dto);

		return res
			.status(201)
			.json({ message: "Request created", request: created });
	} catch (err) {
		return next(err);
	}
}
