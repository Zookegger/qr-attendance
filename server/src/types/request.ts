import { RequestType, RequestStatus } from "@models/request";

export interface CreateRequestDTO {
	userId: string;
	type: RequestType;
	fromDate?: string;
	toDate?: string;
	reason: string;
	attachments?: string | null;
}

export interface RequestResponse {
	id: string;
	userId: string;
	type: RequestType;
	fromDate: Date | null;
	toDate: Date | null;
	reason: string;
	attachments: string | null;
	status: RequestStatus;
	reviewedBy: string | null;
	reviewNote: string | null;
	createdAt: Date;
	updatedAt: Date;
}

export interface ReviewRequestDTO {
	status: RequestStatus;
	reviewNote?: string | null;
	reviewedBy: string;
}
