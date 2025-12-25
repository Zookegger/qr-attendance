import { Model, DataTypes, Optional } from "sequelize";
import { sequelize } from "@config/database";

export enum RequestType {
	VACATION = "VACATION",
	SICK = "SICK",
	PERSONAL = "PERSONAL",
	OTHER = "OTHER",
}

export enum RequestStatus {
	PENDING = "PENDING",
	APPROVED = "APPROVED",
	REJECTED = "REJECTED",
}

interface RequestAttributes {
	id: string;
	user_id: string;
	type: RequestType;
	from_date?: Date | null;
	to_date?: Date | null;
	reason: string;
	image_url?: string | null;
	status: RequestStatus;
	reviewed_by?: string | null;
	review_note?: string | null;
}

interface RequestCreationAttributes
	extends Optional<
		RequestAttributes,
		"id" | "status" | "image_url" | "reviewed_by" | "review_note" | "from_date" | "to_date"
	> {}

export class RequestModel
	extends Model<RequestAttributes, RequestCreationAttributes>
	implements RequestAttributes
{
	public declare id: string;
	public declare user_id: string;
	public declare type: RequestType;
	public declare from_date: Date | null;
	public declare to_date: Date | null;
	public declare reason: string;
	public declare image_url: string | null;
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
		image_url: {
			type: DataTypes.STRING,
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
	}
);
