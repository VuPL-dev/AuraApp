import { Router } from 'express';
import { createPayosPayment, handlePayosWebhook, handleMockPayosCheckout, handlePayosReturn } from '../controllers/payosController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

router.post('/create-payos', authenticateToken, createPayosPayment);
router.post('/payos-webhook', handlePayosWebhook);
router.get('/mock-payos-checkout', handleMockPayosCheckout);
router.get('/payos-return', handlePayosReturn);
router.get('/payos-cancel', handlePayosReturn);

export default router;
