import { Router } from 'express';
import { register, login, verifyEmail, resendVerification } from '../controllers/authController';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerification);

export default router;
