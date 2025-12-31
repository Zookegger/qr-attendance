import { UserRole } from "@models/user";

export interface LoginRequestDTO {
	email: string;
	password: string;
	device_uuid: string;
	device_name: string;
	device_model: string;
	device_os_version: string;
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

export interface ChangePasswordRequestDTO {
	currentPassword: string;
	newPassword: string;
	confirmNewPassword: string;
}

