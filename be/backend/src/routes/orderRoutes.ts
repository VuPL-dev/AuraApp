import { Router } from 'express';
import { getUserOrders, getOrderById, updateOrderStatus, confirmDelivery } from '../controllers/orderController';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getUserOrders);
router.get('/:id', authenticateToken, getOrderById);
router.patch('/:id/status', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), updateOrderStatus);
router.patch('/:id/confirm-delivery', authenticateToken, confirmDelivery);

export default router;
