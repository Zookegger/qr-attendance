export interface CreateWorkshiftDTO {
  name: string;
  startTime: string;
  endTime: string;
  breakStart: string;
  breakEnd: string;
  gracePeriod?: number;
  workDays?: number[];
  office_config_id?: number | null;
}

export interface UpdateWorkshiftDTO {
  name?: string;
  startTime?: string;
  endTime?: string;
  breakStart?: string;
  breakEnd?: string;
  gracePeriod?: number;
  workDays?: number[];
  office_config_id?: number | null;
}
