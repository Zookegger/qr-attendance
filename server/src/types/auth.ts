import { UserRole } from "@models/user";

export interface RegisterDTO {
	name: string;
	email: string;
	password: string;
	role: UserRole;
	position?: string;
	department?: string;
}

export interface LoginDTO {
	email: string;
	password: string;
	device_uuid?: string;
}

export interface AuthResponse {
	accessToken: string;
	refreshToken: string;
	user: {
		id: string;
		name: string;
		email: string;
		role: UserRole;
		device_uuid?: string | null;
	};
}
