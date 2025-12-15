import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '@middlewares/auth.middleware';

const authRouter = Router();

// --- Auth Routes ---
authRouter.post('/auth/register', AuthController.register);
authRouter.post('/auth/login', AuthController.login);
authRouter.get('/auth/me', authenticate, AuthController.me);

export default authRouter;