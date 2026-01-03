import { User } from "@models";
import RequestModel, { RequestStatus } from "@models/request";
import { UserRole } from "@models/user";
import { CreateRequestDTO, ReviewRequestDTO, RequestResponse } from "@my-types/request";
import { Op } from "sequelize";

interface RequestFilters {
	status?: string;
	type?: string;
	fromDate?: string;
	userId?: string; // Admin can filter by user
}
export default class RequestService {
	static async createRequest(
		dto: CreateRequestDTO
	): Promise<RequestResponse> {
		const request = await RequestModel.create({
			userId: dto.userId,
			type: dto.type,
			fromDate: dto.fromDate ? new Date(dto.fromDate) : null,
			toDate: dto.toDate ? new Date(dto.toDate) : null,
			reason: dto.reason,
			attachments: dto.attachments ?? null,
			status: RequestStatus.PENDING
		});

		return request.toJSON() as RequestResponse;
	}

	static async updateRequest(
      id: string, 
      userId: string, 
      dto: Partial<CreateRequestDTO>
   ): Promise<RequestModel> {
      const request = await RequestModel.findByPk(id);
      
      if (!request) throw { status: 404, message: "Request not found" };

      // 1. Ownership Check
      if (request.userId !== userId) {
         throw { status: 403, message: "Unauthorized: You can only edit your own requests" };
      }

      // 2. Status Check
      if (request.status !== RequestStatus.PENDING) {
         throw { status: 400, message: "Cannot edit a request that has already been processed" };
      }

      // 3. Update 
      const updatedRequest = await request.update({
         type: dto.type ?? request.type,
         fromDate: dto.fromDate ? new Date(dto.fromDate) : request.fromDate,
         toDate: dto.toDate ? new Date(dto.toDate) : request.toDate,
         reason: dto.reason ?? request.reason,
         attachments: dto.attachments ?? request.attachments,
      });

      return updatedRequest;
   }

	static async listRequests(currentUser: User, filters: RequestFilters): Promise<RequestModel[]> {
		const where: any = {};

		// 1. SECURITY: If USER, force them to only see their own requests
		if (currentUser.role === UserRole.USER) {
			where.userId = currentUser.id;
		}
		// 2. ADMIN/MANAGER: Can see all, but can optionally filter by a specific user_id
		else if (filters.userId) {
			where.userId = filters.userId;
		}

		// 3. General Filters
		if (filters.status) where.status = filters.status;
		if (filters.type) where.type = filters.type;

		// 4. Date range filtering
		if (filters.fromDate) where.fromDate = { [Op.gte]: new Date(filters.fromDate) };

		return await RequestModel.findAll({
			where,
			order: [['createdAt', 'DESC']],
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
		if (currentUser.role === UserRole.USER && request.userId !== currentUser.id) {
			throw new Error("Unauthorized access to this request");
		}

		return request;
	}

	static async reviewRequest(
		id: string,
		dto: ReviewRequestDTO,
		reviewerId: string
	): Promise<RequestModel> {
		// Find and verify if user is authorized
		const user = await User.findByPk(reviewerId);
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
			reviewNote: dto.reviewNote ?? null,
			reviewedBy: reviewerId,
		});

		return result;
	}

	static async cancel(id: string, userId: string) {
		const request = await RequestModel.findByPk(id);
		if (!request) throw new Error("Request not found");

		if (request.userId !== userId) {
			throw new Error("Unauthorized");
		}

		if (request.status !== RequestStatus.PENDING) {
			throw new Error("Cannot cancel a processed request");
		}

		await request.destroy();
		return { message: "Request cancelled successfully" };
	}
}
