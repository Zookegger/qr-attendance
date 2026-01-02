import { Router } from 'express';
import { ScheduleController } from '@controllers/schedule.controller';
import {
	createScheduleValidator,
	updateScheduleValidator,
	getScheduleValidator,
	deleteScheduleValidator,
	searchScheduleValidator,
} from '@middlewares/validators/schedule.validator';

const scheduleRouter = Router();

scheduleRouter.get('/schedules', ScheduleController.listSchedules);
scheduleRouter.get('/schedules/search', searchScheduleValidator, ScheduleController.searchSchedules);
scheduleRouter.get('/schedules/:id', getScheduleValidator, ScheduleController.getSchedule);
scheduleRouter.post('/schedules', createScheduleValidator, ScheduleController.createSchedule);
scheduleRouter.put('/schedules/:id', updateScheduleValidator, ScheduleController.updateSchedule);
scheduleRouter.delete('/schedules/:id', deleteScheduleValidator, ScheduleController.deleteSchedule);

export default scheduleRouter;
