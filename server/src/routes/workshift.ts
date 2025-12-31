import { Router } from 'express';
import { WorkshiftController } from '@controllers/workshift.controller';
import {
	createWorkshiftValidator,
	updateWorkshiftValidator,
	getWorkshiftValidator,
	deleteWorkshiftValidator,
} from '@middlewares/validators/workshift.validator';

const router = Router();

router.get('/workshifts', WorkshiftController.listWorkshifts);
router.get('/workshifts/:id', getWorkshiftValidator, WorkshiftController.getWorkshift);
router.post('/workshifts', createWorkshiftValidator, WorkshiftController.createWorkshift);
router.put('/workshifts/:id', updateWorkshiftValidator, WorkshiftController.updateWorkshift);
router.delete('/workshifts/:id', deleteWorkshiftValidator, WorkshiftController.deleteWorkshift);

export default router;
