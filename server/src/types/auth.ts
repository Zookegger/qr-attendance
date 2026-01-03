import { UserRole } from "@models/user";

export interface LoginRequestDTO {
	email: string;
	password: string;
	deviceUuid: string;
	deviceName: string;
	deviceModel: string;
	deviceOsVersion: string;
	fcmToken?: string;
}

export interface AuthResponse {
	accessToken: string;
	refreshToken: string;
	user: {
		id: string;
		name: string;
		email: string;
		role: UserRole;
		deviceUuid?: string | null;
	};
}

export interface LogoutRequestDTO {
	refreshToken: string;
}

export interface RefreshRequestDTO {
	refreshToken: string;
	deviceUuid: string;
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

