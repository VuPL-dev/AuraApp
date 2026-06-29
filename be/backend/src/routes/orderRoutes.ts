import { Router } from 'express';
import { getUserOrders } from '../controllers/orderController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getUserOrders);

export default router;
