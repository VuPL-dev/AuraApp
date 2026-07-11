import { Router } from 'express';
import prisma from '../prisma';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';

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

// GET /api/reviews/product/:productId - Lấy danh sách đánh giá của sản phẩm (public, ẩn review is_hidden)
router.get('/product/:productId', async (req, res) => {
  try {
    const reviews = await prisma.review.findMany({
      where: { product_id: Number(req.params.productId), is_hidden: false },
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

// ========== STAFF/ADMIN ==========
// Tất cả route phía dưới yêu cầu đăng nhập + role ADMIN hoặc STAFF

// GET /api/reviews/staff/all - Lấy tất cả đánh giá cho staff (kèm cả review đã ẩn)
router.get('/staff/all', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const { rating, productId, userId, search, hiddenOnly } = req.query as Record<string, string>;
    const where: any = {};
    if (rating) where.rating = Number(rating);
    if (productId) where.product_id = Number(productId);
    if (userId) where.user_id = Number(userId);
    if (hiddenOnly === 'true') where.is_hidden = true;
    else if (hiddenOnly === 'false') where.is_hidden = false;
    if (search) where.comment = { contains: search };

    const reviews = await prisma.review.findMany({
      where,
      include: {
        user: { select: { id: true, full_name: true, email: true } },
        product: {
          select: {
            id: true,
            name: true,
            images: {
          take: 1,
          orderBy: { id: 'asc' },
          select: { image_url: true }
        }
          }
        },
        replies: {
          include: { user: { select: { id: true, full_name: true } } },
          orderBy: { created_at: 'asc' }
        }
      },
      orderBy: { created_at: 'desc' },
    });
    res.json(reviews);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/reviews/staff/stats - Thống kê review cho staff dashboard
router.get('/staff/stats', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (_req, res) => {
  try {
    const [total, hidden, avgRatingResult] = await Promise.all([
      prisma.review.count(),
      prisma.review.count({ where: { is_hidden: true } }),
      prisma.review.aggregate({ _avg: { rating: true } }),
    ]);

    // Phân bố rating 1-5 sao
    const distribution = await Promise.all(
      [1, 2, 3, 4, 5].map((r) => prisma.review.count({ where: { rating: r } }))
    );

    res.json({
      total,
      hidden,
      visible: total - hidden,
      avgRating: avgRatingResult._avg.rating || 0,
      distribution: {
        '1': distribution[0], '2': distribution[1], '3': distribution[2],
        '4': distribution[3], '5': distribution[4],
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /api/reviews/:id/hide - Ẩn/hiện review (staff)
router.patch('/:id/hide', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { hidden } = req.body; // boolean
    const review = await prisma.review.update({
      where: { id },
      data: {
        is_hidden: Boolean(hidden),
        hidden_at: hidden ? new Date() : null,
      }
    });
    res.json(review);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/reviews/:id - Xóa review (staff)
router.delete('/:id', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const id = Number(req.params.id);
    // cascade sẽ xóa luôn replies
    await prisma.review.delete({ where: { id } });
    res.json({ ok: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/reviews/replies/:replyId - Xóa reply (staff)
router.delete('/replies/:replyId', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const replyId = Number(req.params.replyId);
    await prisma.reviewReply.delete({ where: { id: replyId } });
    res.json({ ok: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/reviews/:id/staff-reply - Staff phản hồi một review
router.post('/:id/staff-reply', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req: any, res) => {
  try {
    const { comment } = req.body;
    const review_id = Number(req.params.id);
    const user_id = req.user.id;

    if (!comment || !comment.trim()) {
      return res.status(400).json({ error: 'Nội dung phản hồi không được để trống' });
    }

    const review = await prisma.review.findUnique({ where: { id: review_id } });
    if (!review) return res.status(404).json({ error: 'Không tìm thấy đánh giá' });

    const reply = await prisma.reviewReply.create({
      data: { review_id, user_id, comment: comment.trim() },
      include: { user: { select: { id: true, full_name: true, role: true } } }
    });
    res.status(201).json(reply);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /api/reviews/replies/:replyId - Sửa reply (staff)
router.patch('/replies/:replyId', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const replyId = Number(req.params.replyId);
    const { comment } = req.body;
    if (!comment || !comment.trim()) {
      return res.status(400).json({ error: 'Nội dung phản hồi không được để trống' });
    }
    const reply = await prisma.reviewReply.update({
      where: { id: replyId },
      data: { comment: comment.trim() },
      include: { user: { select: { id: true, full_name: true } } }
    });
    res.json(reply);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
