import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

export enum RequestType {
	// Standard Leaves
	LEAVE = "LEAVE", // General/Annual leave
	SICK = "SICK", // Sick leave
	UNPAID = "UNPAID", // Unpaid leave

	// Time & Attendance Specifics
	LATE_EARLY = "LATE_EARLY", // Late arrival / early leave
	OVERTIME = "OVERTIME", // Overtime request (OT)
	BUSINESS_TRIP = "BUSINESS_TRIP", // Business trip
	SHIFT_CHANGE = "SHIFT_CHANGE", // Shift change request
	REMOTE_WORK = "REMOTE_WORK", // Remote work request

	// Corrections & Admin
	ATTENDANCE_CONFIRMATION = "ATTENDANCE_CONFIRMATION",
	ATTENDANCE_ADJUSTMENT = "ATTENDANCE_ADJUSTMENT",
	EXPLANATION = "EXPLANATION", // Explaining a missing check-in

	// Fallback
	OTHER = "OTHER",
}

export const RequestTypeLabels: Record<RequestType, string> = {
	[RequestType.LEAVE]: "Leave Request",
	[RequestType.SICK]: "Sick Leave",
	[RequestType.UNPAID]: "Unpaid Leave",
	[RequestType.LATE_EARLY]: "Late Arrival / Early Leave",
	[RequestType.OVERTIME]: "Overtime (OT)",
	[RequestType.BUSINESS_TRIP]: "Business Trip",
	[RequestType.SHIFT_CHANGE]: "Shift Change",
	[RequestType.REMOTE_WORK]: "Remote Work",
	[RequestType.ATTENDANCE_CONFIRMATION]: "Attendance Confirmation",
	[RequestType.ATTENDANCE_ADJUSTMENT]: "Attendance Adjustment",
	[RequestType.EXPLANATION]: "Explanation",
	[RequestType.OTHER]: "Other",
};

export enum RequestStatus {
	PENDING = "PENDING",
	APPROVED = "APPROVED",
	REJECTED = "REJECTED",
}

export const RequestStatusLabels: Record<RequestStatus, string> = {
	[RequestStatus.APPROVED]: "Approved",
	[RequestStatus.PENDING]: "Pending",
	[RequestStatus.REJECTED]: "Rejected",
};

interface RequestAttributes {
	id: string;
	user_id: string;
	type: RequestType;
	from_date?: Date | null;
	to_date?: Date | null;
	reason: string;
	attachments?: string | null; // JSON array of file paths
	status: RequestStatus;
	reviewed_by?: string | null;
	review_note?: string | null;
}

interface RequestCreationAttributes
	extends Optional<
		RequestAttributes,
		"id" | "status" | "attachments" | "reviewed_by" | "review_note" | "from_date" | "to_date"
	> {}

export default class RequestModel
	extends Model<RequestAttributes, RequestCreationAttributes>
	implements RequestAttributes
{
	public declare id: string;
	public declare user_id: string;
	public declare type: RequestType;
	public declare from_date: Date | null;
	public declare to_date: Date | null;
	public declare reason: string;
	public declare attachments: string | null;
	public declare status: RequestStatus;
	public declare reviewed_by: string | null;
	public declare review_note: string | null;

	public declare readonly createdAt: Date;
	public declare readonly updatedAt: Date;
}

RequestModel.init(
	{
		id: {
			type: DataTypes.UUID,
			defaultValue: DataTypes.UUIDV4,
			primaryKey: true,
		},
		user_id: {
			type: DataTypes.UUID,
			allowNull: false,
		},
		type: {
			type: DataTypes.ENUM(...Object.values(RequestType)),
			allowNull: false,
			defaultValue: RequestType.OTHER,
		},
		from_date: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		to_date: {
			type: DataTypes.DATE,
			allowNull: true,
		},
		reason: {
			type: DataTypes.TEXT,
			allowNull: false,
		},
		attachments: {
			type: DataTypes.TEXT, // JSON array of file paths
			allowNull: true,
		},
		status: {
			type: DataTypes.ENUM(...Object.values(RequestStatus)),
			allowNull: false,
			defaultValue: RequestStatus.PENDING,
		},
		reviewed_by: {
			type: DataTypes.UUID,
			allowNull: true,
		},
		review_note: {
			type: DataTypes.TEXT,
			allowNull: true,
		},
	},
	{
		sequelize,
		tableName: "requests",
		timestamps: true,
	}
);
