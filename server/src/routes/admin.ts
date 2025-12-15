import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { authenticate, authorize } from '@middlewares/auth.middleware';

const adminRouter = Router();

// --- Admin Routes ---
adminRouter.get('/admin/qr', authenticate, authorize(['admin']), AdminController.generateQR);
adminRouter.get('/admin/config', authenticate, authorize(['admin']), AdminController.getOfficeConfig);
adminRouter.put('/admin/config', authenticate, authorize(['admin']), AdminController.updateOfficeConfig);
adminRouter.get('/admin/report', authenticate, authorize(['admin']), AdminController.exportReport);

export default adminRouter;