import { Router } from 'express';
import prisma from '../prisma';
import { authenticateToken } from '../middlewares/authMiddleware';

const router = Router();

// POST /api/reviews - Gửi đánh giá sản phẩm
router.post('/', authenticateToken, async (req: any, res) => {
  try {
    const { product_id, rating, comment } = req.body;
    const user_id = req.user.id;

    if (!product_id || !rating) {
      return res.status(400).json({ error: 'Thiếu thông tin product_id hoặc rating' });
    }

    const review = await prisma.review.create({
      data: {
        product_id: Number(product_id),
        user_id,
        rating: Number(rating),
        comment: comment || '',
      },
    });

    res.status(201).json(review);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/reviews/product/:productId - Lấy danh sách đánh giá của sản phẩm kèm câu trả lời
router.get('/product/:productId', async (req, res) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { product_id: Number(req.params.productId) },
      include: {
        user: { select: { full_name: true } },
        replies: {
          include: {
            user: { select: { full_name: true } }
          },
          orderBy: { created_at: 'asc' }
        }
      },
      orderBy: { created_at: 'desc' },
    });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/reviews/:id/reply - Trả lời một đánh giá
router.post('/:id/reply', authenticateToken, async (req: any, res) => {
  try {
    const { comment } = req.body;
    const review_id = Number(req.params.id);
    const user_id = req.user.id;

    if (!comment) {
      return res.status(400).json({ error: 'Nội dung trả lời không được để trống' });
    }

    const reply = await prisma.reviewReply.create({
      data: {
        review_id,
        user_id,
        comment,
      },
      include: {
        user: { select: { full_name: true } }
      }
    });

    res.status(201).json(reply);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;

export default router;
