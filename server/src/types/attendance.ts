export interface CheckInOutDTO {
  user_id: string;
  code: string;
  latitude: number;
  longitude: number;
  office_id?: number;
}

export interface CodeGenerationResponseDTO {
  code: string;
  refreshAt: number; // seconds until next rotation
}
