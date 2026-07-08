import { Request, Response } from 'express';
import prisma from '../prisma';

// GET /api/notifications - danh sách thông báo của customer (mặc định chỉ lấy chưa đọc)
export const getNotifications = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const unreadOnly = req.query.unread !== 'false';

    const notifications = await prisma.notification.findMany({
      where: { user_id: userId, ...(unreadOnly ? { is_read: false } : {}) },
      orderBy: { created_at: 'desc' },
    });

    res.status(200).json(notifications);
  } catch (error: any) {
    console.error('[Notifications] Error:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// PATCH /api/notifications/:id/read - đánh dấu đã đọc
export const markNotificationRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const notification = await prisma.notification.findUnique({ where: { id: Number(req.params.id) } });

    if (!notification || notification.user_id !== userId) {
      res.status(404).json({ error: 'Không tìm thấy thông báo' });
      return;
    }

    const updated = await prisma.notification.update({
      where: { id: notification.id },
      data: { is_read: true },
    });

    res.status(200).json(updated);
  } catch (error: any) {
    console.error('[Notifications] Error:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// PATCH /api/notifications/read-all - đánh dấu tất cả đã đọc
export const markAllNotificationsRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    await prisma.notification.updateMany({
      where: { user_id: userId, is_read: false },
      data: { is_read: true },
    });

    res.status(200).json({ success: true });
  } catch (error: any) {
    console.error('[Notifications] Error:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};
