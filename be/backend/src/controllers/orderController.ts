import { Request, Response } from 'express';
import prisma from '../prisma';

const ORDER_STATUSES = ['PENDING', 'SUCCESS', 'SHIPPING', 'DELIVERED', 'CANCELLED'];

export const getUserOrders = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const orders = await prisma.order.findMany({
      where: { user_id: userId },
      include: {
        items: { include: { product: { include: { images: true } } } },
        payments: true,
      },
      orderBy: { created_at: 'desc' },
    });

    res.status(200).json(orders);
  } catch (error: any) {
    console.error('[Orders] Error:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};

export const getOrderById = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;
    const order = await prisma.order.findUnique({
      where: { id: Number(req.params.id) },
      include: {
        items: { include: { product: { include: { images: true } } } },
        payments: true,
      },
    });

    if (!order || order.user_id !== userId) {
      res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
      return;
    }

    res.status(200).json(order);
  } catch (error: any) {
    console.error('[Orders] Error:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};

// Cập nhật trạng thái đơn hàng (Staff/Admin). Khi chuyển sang DELIVERED,
// tự động tạo Notification nhắc Customer đánh giá sản phẩm vừa nhận.
export const updateOrderStatus = async (req: Request, res: Response) => {
  try {
    const orderId = Number(req.params.id);
    const { status } = req.body;

    if (!status || !ORDER_STATUSES.includes(status)) {
      res.status(400).json({ error: `Trạng thái không hợp lệ. Hợp lệ: ${ORDER_STATUSES.join(', ')}` });
      return;
    }

    const existingOrder = await prisma.order.findUnique({
      where: { id: orderId },
      include: { items: { include: { product: true } } },
    });

    if (!existingOrder) {
      res.status(404).json({ error: 'Không tìm thấy đơn hàng' });
      return;
    }

    const updatedOrder = await prisma.order.update({
      where: { id: orderId },
      data: { status },
    });

    if (status === 'DELIVERED' && existingOrder.status !== 'DELIVERED' && existingOrder.user_id) {
      const productNames = existingOrder.items
        .map((item) => item.product?.name)
        .filter(Boolean)
        .join(', ');

      await prisma.notification.create({
        data: {
          user_id: existingOrder.user_id,
          title: 'Nhắc đánh giá sản phẩm',
          message: `Vui lòng đánh giá sản phẩm ${productNames || `trong đơn hàng #${orderId}`} bạn vừa nhận.`,
        },
      });
    }

    res.status(200).json(updatedOrder);
  } catch (error: any) {
    console.error('[Orders] Error updating status:', error.message);
    res.status(500).json({ error: 'Server error' });
  }
};
