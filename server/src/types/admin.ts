export interface AddUserDTO {
	name: string;
	email: string;
	password: string;
	role?: string;
	position?: string;
	department?: string;
	date_of_birth?: Date | string;
	phone_number?: string;
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
	date_of_birth?: Date | string;
	phone_number?: string;
	address?: string;
	gender?: string;
}

export interface AddOfficeConfigDTO {
	name: string;
	latitude: number;
	longitude: number;
	radius?: number;
	wifi_ssid: string;
}

export interface UpdateOfficeConfigDTO {
	name?: string;
	latitude?: number;
	longitude?: number;
	radius?: number;
	wifi_ssid?: string;
}