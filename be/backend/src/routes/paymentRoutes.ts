import { Router } from 'express';
import { createOrder } from '../controllers/paymentController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

router.post('/create-order', authenticateToken, createOrder);

export default router;
