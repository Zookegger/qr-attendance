export interface CreateWorkshiftDTO {
  name: string;
  startTime: Date;
  endTime: Date;
  breakStart: Date;
  breakEnd: Date;
  gracePeriod: number;
  workDays: number[];
  officeConfigId: number;
}

export interface UpdateWorkshiftDTO {
  name?: string;
  startTime?: Date;
  endTime?: Date;
  breakStart?: Date;
  breakEnd?: Date;
  gracePeriod?: number;
  workDays?: number[];
  officeConfigId?: number | null;
}
