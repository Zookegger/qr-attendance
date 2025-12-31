import { User } from "@models";
import RequestModel, { RequestStatus } from "@models/request";
import { UserRole } from "@models/user";
import { CreateRequestDTO, ReviewRequestDTO, RequestResponse } from "@my-types/request";
import { Op } from "sequelize";

interface RequestFilters {
	status?: string;
	type?: string;
	from_date?: string;
	user_id?: string; // Admin can filter by user
}
export default class RequestService {
	static async createRequest(
		dto: CreateRequestDTO
	): Promise<RequestResponse> {
		const request = await RequestModel.create({
			user_id: dto.user_id,
			type: dto.type,
			from_date: dto.from_date ? new Date(dto.from_date) : null,
			to_date: dto.to_date ? new Date(dto.to_date) : null,
			reason: dto.reason,
			attachments: dto.attachments ?? null,
			status: RequestStatus.PENDING
		});

		return request.toJSON() as RequestResponse;
	}

	static async listRequests(currentUser: User, filters: RequestFilters): Promise<RequestModel[]> {
		const where: any = {};

		// 1. SECURITY: If USER, force them to only see their own requests
		if (currentUser.role === UserRole.USER) {
			where.user_id = currentUser.id;
		}
		// 2. ADMIN/MANAGER: Can see all, but can optionally filter by a specific user_id
		else if (filters.user_id) {
			where.user_id = filters.user_id;
		}

		// 3. General Filters
		if (filters.status) where.status = filters.status;
		if (filters.type) where.type = filters.type;

		// 4. Date range filtering
		if (filters.from_date) where.from_date = { [Op.gte]: new Date(filters.from_date) };

		return await RequestModel.findAll({
			where,
			order: [['created_at', 'DESC']], 
			include: [
				{
					model: User,
					as: 'user',
					attributes: ['id', 'name', 'email', 'department', 'position']
				},
				{
					model: User,
					as: 'reviewer',
					attributes: ['id', 'name']
				}
			]
		});
	}

	static async findById(id: string, currentUser: User) {
		const request = await RequestModel.findByPk(id, {
			include: [{ model: User, as: 'user' }]
		});

		if (!request) throw new Error("Request not found");

		// SECURITY: Users can only view their own
		if (currentUser.role === UserRole.USER && request.user_id !== currentUser.id) {
			throw new Error("Unauthorized access to this request");
		}

		return request;
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

		return result;
	}

	static async cancel(id: string, userId: string) {
		const request = await RequestModel.findByPk(id);
		if (!request) throw new Error("Request not found");

		if (request.user_id !== userId) {
			throw new Error("Unauthorized");
		}

		if (request.status !== RequestStatus.PENDING) {
			throw new Error("Cannot cancel a processed request");
		}

		await request.destroy();
		return { message: "Request cancelled successfully" };
	}
}
