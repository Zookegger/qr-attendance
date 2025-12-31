import { Router } from 'express';
import { ScheduleController } from '@controllers/schedule.controller';
import {
	createScheduleValidator,
	updateScheduleValidator,
	getScheduleValidator,
	deleteScheduleValidator,
	searchScheduleValidator,
} from '@middlewares/validators/schedule.validator';

const router = Router();

router.get('/schedules', ScheduleController.listSchedules);
router.get('/schedules/search', searchScheduleValidator, ScheduleController.searchSchedules);
router.get('/schedules/:id', getScheduleValidator, ScheduleController.getSchedule);
router.post('/schedules', createScheduleValidator, ScheduleController.createSchedule);
router.put('/schedules/:id', updateScheduleValidator, ScheduleController.updateSchedule);
router.delete('/schedules/:id', deleteScheduleValidator, ScheduleController.deleteSchedule);

export default router;
