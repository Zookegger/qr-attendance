import { UserRole } from "@models/user";

// TODO: Move this to Admin instead
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

export interface LoginRequestDTO {
	email: string;
	password: string;
	device_uuid?: string;
}

export interface LogoutDTO {
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

export interface LogoutRequestDTO {
	refreshToken: string;
}

export interface RefreshRequestDTO {
	refreshToken: string;
}

export interface ForgotPasswordRequestDTO {
	email: string;
}

export interface ResetPasswordRequestDTO {
	email: string;
	token: string;
	newPassword: string;
}

export interface ChangePasswordDTO {
	currentPassword: string;
	newPassword: string;
	confirmNewPassword: string;
}

