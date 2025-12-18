import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '@middlewares/auth.middleware';
import { errorHandler } from '@middlewares/error.middleware';

const authRouter = Router();

// --- Auth Routes ---
authRouter.post('/auth/login', AuthController.login, errorHandler);
authRouter.get('/auth/me', authenticate, AuthController.me, errorHandler);

export default authRouter;