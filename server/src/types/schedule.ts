export interface CreateScheduleDTO {
  user_id: string;
  shift_id: number;
  start_date: string;
  end_date?: string | null;
}

export interface UpdateScheduleDTO {
  user_id?: string;
  shift_id?: number;
  start_date?: string;
  end_date?: string | null;
}

export interface ScheduleQuery {
  page?: number | string;
  limit?: number | string;
  user_id?: string;
  shift_id?: number | string;
  start_date?: string;
  end_date?: string;
}
