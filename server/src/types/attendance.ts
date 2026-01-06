export interface CheckInOutDTO {
  userId: string;
  code: string;
  latitude: number;
  longitude: number;
  officeId?: number;
}

export interface CodeGenerationResponseDTO {
  code: string;
  refreshAt: number; // seconds until next rotation
}
