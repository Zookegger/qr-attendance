import { Router } from 'express';
import { WorkshiftController } from '@controllers/workshift.controller';
import {
	createWorkshiftValidator,
	updateWorkshiftValidator,
	getWorkshiftValidator,
	deleteWorkshiftValidator,
} from '@middlewares/validators/workshift.validator';

const workshiftRouter = Router();

workshiftRouter.get('/workshifts', WorkshiftController.listWorkshifts);
workshiftRouter.get('/workshifts/:id', getWorkshiftValidator, WorkshiftController.getWorkshift);
workshiftRouter.post('/workshifts', createWorkshiftValidator, WorkshiftController.createWorkshift);
workshiftRouter.put('/workshifts/:id', updateWorkshiftValidator, WorkshiftController.updateWorkshift);
workshiftRouter.delete('/workshifts/:id', deleteWorkshiftValidator, WorkshiftController.deleteWorkshift);

export default workshiftRouter;
