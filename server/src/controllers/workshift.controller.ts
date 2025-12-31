import { NextFunction, Request, Response } from 'express';
import WorkshiftService from '@services/workshift.service';
import { CreateWorkshiftDTO, UpdateWorkshiftDTO } from '@my-types/workshift';

const createWorkshift = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const payload: CreateWorkshiftDTO = req.body;
      const created = await WorkshiftService.createWorkshift(payload);
      return res.status(201).json({ message: 'Workshift created', workshift: created });
   } catch (err) {
      return next(err);
   }
};

const listWorkshifts = async (_req: Request, res: Response, next: NextFunction) => {
   try {
      const items = await WorkshiftService.listWorkshifts();
      return res.json(items);
   } catch (err) {
      return next(err);
   }
};

const getWorkshift = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const id = Number(req.params.id);
      const item = await WorkshiftService.getWorkshiftById(id);
      if (!item) return res.status(404).json({ message: 'Workshift not found' });
      return res.json(item);
   } catch (err) {
      return next(err);
   }
};

const updateWorkshift = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const id = Number(req.params.id);
      const payload: UpdateWorkshiftDTO = req.body;
      const updated = await WorkshiftService.updateWorkshift(id, payload);
      if (!updated) return res.status(404).json({ message: 'Workshift not found' });
      return res.json({ message: 'Workshift updated', workshift: updated });
   } catch (err) {
      return next(err);
   }
};

const deleteWorkshift = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const id = Number(req.params.id);
      const ok = await WorkshiftService.deleteWorkshift(id);
      if (!ok) return res.status(404).json({ message: 'Workshift not found' });
      return res.json({ message: 'Workshift deleted' });
   } catch (err) {
      return next(err);
   }
};

export const WorkshiftController = {
   createWorkshift,
   listWorkshifts,
   getWorkshift,
   updateWorkshift,
   deleteWorkshift,
};
