export interface CreateScheduleDTO {
  userId: string;
  shiftId: number;
  startDate: string;
  endDate?: string | null;
}

export interface UpdateScheduleDTO {
  userId?: string;
  shiftId?: number;
  startDate?: string;
  endDate?: string | null;
}

export interface ScheduleQuery {
  page?: number | string;
  limit?: number | string;
  userId?: string;
  shiftId?: number | string;
  startDate?: string;
  endDate?: string;
  from?: string;
  to?: string;
}
