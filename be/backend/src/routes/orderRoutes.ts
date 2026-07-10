import { Router } from 'express';
import { getUserOrders, getOrderById, updateOrderStatus, confirmDelivery, generateDeliveryQr, confirmDeliveryByToken } from '../controllers/orderController';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getUserOrders);
router.get('/:id', authenticateToken, getOrderById);
router.patch('/:id/status', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), updateOrderStatus);
router.patch('/:id/confirm-delivery', authenticateToken, confirmDelivery);

// Tạo QR (dành cho STAFF/ADMIN)
router.get('/:id/delivery-qr', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), generateDeliveryQr);

// API khi khách hàng quét mã (public, bảo mật qua token)
router.post('/confirm-delivery', confirmDeliveryByToken);

export default router;
