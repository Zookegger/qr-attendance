export interface AddUserDTO {
	name: string;
	email: string;
	password: string;
	role?: string;
	position?: string;
	department?: string;
	dateOfBirth?: Date | string;
	phoneNumber?: string;
	address?: string;
	gender?: string;
}

export interface UpdateUserDTO {
	name?: string;
	email?: string;
	password?: string;
	role?: string;
	position?: string;
	department?: string;
	status?: string;
	dateOfBirth?: Date | string;
	phoneNumber?: string;
	address?: string;
	gender?: string;
}

export interface AddOfficeConfigDTO {
	name: string;
	latitude: number;
	longitude: number;
	radius?: number;
	wifiSsid: string;
}

export interface UpdateOfficeConfigDTO {
	name?: string;
	latitude?: number;
	longitude?: number;
	radius?: number;
	wifiSsid?: string;
}