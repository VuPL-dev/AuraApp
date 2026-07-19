import { Request, Response } from 'express';
import prisma from '../prisma';

export const createOrder = async (req: any, res: Response): Promise<void> => {
  try {
    const userId = req.user.id;
    const { address_id, total_amount, payment_method, items } = req.body;

    const newOrder = await prisma.order.create({
      data: {
        user_id: userId,
        address_id,
        total_amount,
        payment_method,
        shipping_address: req.body.shipping_address,
        shipping_lat: req.body.shipping_lat,
        shipping_lng: req.body.shipping_lng,
        status: 'PENDING',
        items: {
          create: items.map((item: any) => ({
            product_id: item.product_id,
            quantity: item.quantity,
            unit_price: item.unit_price,
          })),
        },
      },
    });

    res.status(201).json(newOrder);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
};
