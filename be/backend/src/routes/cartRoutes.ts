import { Router } from 'express';
import prisma from '../prisma';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

// Lấy giỏ hàng của user hiện tại
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const userId = req.user.id;
    let cart = await prisma.cart.findUnique({
      where: { user_id: userId },
      include: {
        items: {
          include: {
            product: { include: { images: true } },
          },
        },
      },
    });
    if (!cart) {
      cart = await prisma.cart.create({
        data: { user_id: userId },
        include: {
          items: { include: { product: { include: { images: true } } } },
        },
      });
    }
    res.json(cart);
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Thêm hoặc cập nhật sản phẩm vào giỏ
router.post('/items', authenticateToken, async (req: any, res) => {
  try {
    const userId = req.user.id;
    const { product_id, quantity = 1 } = req.body;

    let cart = await prisma.cart.findUnique({ where: { user_id: userId } });
    if (!cart) {
      cart = await prisma.cart.create({ data: { user_id: userId } });
    }

    const existing = await prisma.cartItem.findFirst({
      where: { cart_id: cart.id, product_id: Number(product_id) },
    });

    if (existing) {
      await prisma.cartItem.update({
        where: { id: existing.id },
        data: { quantity: existing.quantity + Number(quantity) },
      });
    } else {
      await prisma.cartItem.create({
        data: {
          cart_id: cart.id,
          product_id: Number(product_id),
          quantity: Number(quantity),
        },
      });
    }

    // Trả về cart mới nhất
    const updated = await prisma.cart.findUnique({
      where: { user_id: userId },
      include: {
        items: { include: { product: { include: { images: true } } } },
      },
    });
    res.json(updated);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'Server error' });
  }
});

// Cập nhật số lượng một item
router.patch('/items/:itemId', authenticateToken, async (req: any, res) => {
  try {
    const { quantity } = req.body;
    if (Number(quantity) <= 0) {
      await prisma.cartItem.delete({ where: { id: Number(req.params.itemId) } });
    } else {
      await prisma.cartItem.update({
        where: { id: Number(req.params.itemId) },
        data: { quantity: Number(quantity) },
      });
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Xóa một item khỏi giỏ
router.delete('/items/:itemId', authenticateToken, async (req: any, res) => {
  try {
    await prisma.cartItem.delete({ where: { id: Number(req.params.itemId) } });
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Xóa toàn bộ giỏ hàng
router.delete('/clear', authenticateToken, async (req: any, res) => {
  try {
    const userId = req.user.id;
    const cart = await prisma.cart.findUnique({ where: { user_id: userId } });
    if (cart) {
      await prisma.cartItem.deleteMany({ where: { cart_id: cart.id } });
    }
    res.json({ success: true });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
