import { RequestType, RequestStatus } from "@models/request";

export interface CreateRequestDTO {
	user_id: string;
	type: RequestType;
	from_date?: string;
	to_date?: string;
	reason: string;
	attachments?: string | null;
}

export interface RequestResponse {
	id: string;
	user_id: string;
	type: RequestType;
	from_date: Date | null;
	to_date: Date | null;
	reason: string;
	attachments: string | null;
	status: RequestStatus;
	reviewed_by: string | null;
	review_note: string | null;
	createdAt: Date;
	updatedAt: Date;
}

export interface ReviewRequestDTO {
	status: RequestStatus;
	review_note?: string | null;
	reviewed_by: string;
}
