import { Request, Response } from 'express';
import prisma from '../prisma';

export const getUserOrders = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.id;

    const orders = await prisma.order.findMany({
      where: { user_id: userId },
      include: {
        items: true,
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
