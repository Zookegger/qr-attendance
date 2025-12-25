import { User } from "@models";
import { RequestModel } from "@models/request";
import { UserRole } from "@models/user";
import { CreateRequestDTO, ReviewRequestDTO, RequestResponse } from "@my-types/request";

export class RequestService {
	static async createRequest(
		dto: CreateRequestDTO
	): Promise<RequestResponse> {
		const request = await RequestModel.create({
			user_id: dto.user_id,
			type: dto.type,
			from_date: dto.from_date ? new Date(dto.from_date) : null,
			to_date: dto.to_date ? new Date(dto.to_date) : null,
			reason: dto.reason,
			image_url: dto.image_url ?? null,
		});

		return request.toJSON() as RequestResponse;
	}

	static async listRequests(): Promise<RequestModel[]> {
		return await RequestModel.findAll();
	}

	static async getRequestById(id: string): Promise<RequestModel | null> {
		return await RequestModel.findByPk(id);
	}

	static async reviewRequest(
		id: string,
		dto: ReviewRequestDTO,
		reviewer_id: string
	): Promise<RequestModel> {
		// Find and verify if user is authorized
		const user = await User.findByPk(reviewer_id);
		if (!user) {
			throw { status: 404, message: "Reviewer not found" };
		}

		if (user.role === UserRole.USER) {
			throw { status: 403, message: "Unauthorized: Only admins and managers can review requests" };
		}

		// Get Request
		const request = await RequestModel.findByPk(id);
		if (!request) {
			throw { status: 404, message: "Request not found" };
		}

		// Update the request
		const result = await request.update({
			status: dto.status,
			review_note: dto.review_note ?? null,
			reviewed_by: reviewer_id,
		});

		if (!result) {
			throw { status: 500, message: "Failed to update request" };
		}

		return result;
	}
}
