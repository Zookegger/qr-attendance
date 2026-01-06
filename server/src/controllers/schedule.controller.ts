import { NextFunction, Request, Response } from 'express';
import ScheduleService from '@services/schedule.service';
import { CreateScheduleDTO, UpdateScheduleDTO, ScheduleQuery } from '@my-types/schedule';

const createSchedule = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const payload: CreateScheduleDTO = {
      userId: req.body.user_id,
      shiftId: req.body.shift_id,
      startDate: req.body.start_date,
      endDate: req.body.end_date,
    };
    const created = await ScheduleService.createSchedule(payload);
    return res.status(201).json({ message: 'Schedule created', schedule: created });
  } catch (err) {
    return next(err);
  }
};

const listSchedules = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page = '1', limit = '50' } = req.query as any;
    const result = await ScheduleService.listSchedules(page, limit);
    return res.json(result);
  } catch (err) {
    return next(err);
  }
};

const getSchedule = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const item = await ScheduleService.getScheduleById(id);
    if (!item) return res.status(404).json({ message: 'Schedule not found' });
    return res.json(item);
  } catch (err) {
    return next(err);
  }
};

const updateSchedule = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const payload: UpdateScheduleDTO = {
      userId: req.body.user_id,
      shiftId: req.body.shift_id,
      startDate: req.body.start_date,
      endDate: req.body.end_date,
    };
    const updated = await ScheduleService.updateSchedule(id, payload);
    if (!updated) return res.status(404).json({ message: 'Schedule not found' });
    return res.json({ message: 'Schedule updated', schedule: updated });
  } catch (err) {
    return next(err);
  }
};

const deleteSchedule = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const ok = await ScheduleService.deleteSchedule(id);
    if (!ok) return res.status(404).json({ message: 'Schedule not found' });
    return res.json({ message: 'Schedule deleted' });
  } catch (err) {
    return next(err);
  }
};

const searchSchedules = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const query: ScheduleQuery = req.query as any;
    const items = await ScheduleService.searchSchedules(query);
    return res.json(items);
  } catch (err) {
    return next(err);
  }
};

export const ScheduleController = {
  createSchedule,
  listSchedules,
  getSchedule,
  updateSchedule,
  deleteSchedule,
  searchSchedules,
};
