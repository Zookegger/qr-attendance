export interface AddUserDTO {
	name: string;
	email: string;
	password: string;
	role?: string;
	position?: string;
	department?: string;
	date_of_birth?: string;
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
	date_of_birth?: string;
	phone_number?: string;
	address?: string;
	gender?: string;
}

export interface OfficeConfigDTO {
	latitude?: number;
	longitude?: number;
	radius?: number;
	start_hour?: string;
	end_hour?: string;
	wifi_ssid?: string;
}