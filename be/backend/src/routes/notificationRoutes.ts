import { Router } from 'express';
import {
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
} from '../controllers/notificationController';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

router.get('/', authenticateToken, getNotifications);
router.patch('/read-all', authenticateToken, markAllNotificationsRead);
router.patch('/:id/read', authenticateToken, markNotificationRead);

export default router;
