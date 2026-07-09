import { Router } from 'express';
import { getUserOrders, getOrderById, updateOrderStatus } from '../controllers/orderController';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getUserOrders);
router.get('/:id', authenticateToken, getOrderById);
router.patch('/:id/status', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), updateOrderStatus);

export default router;
