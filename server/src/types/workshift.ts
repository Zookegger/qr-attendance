export interface CreateWorkshiftDTO {
  name: string;
  startTime: string;
  endTime: string;
  breakStart: string;
  breakEnd: string;
  gracePeriod?: number;
  workDays?: number[];
  officeConfigId?: number | null;
}

export interface UpdateWorkshiftDTO {
  name?: string;
  startTime?: string;
  endTime?: string;
  breakStart?: string;
  breakEnd?: string;
  gracePeriod?: number;
  workDays?: number[];
  officeConfigId?: number | null;
}
