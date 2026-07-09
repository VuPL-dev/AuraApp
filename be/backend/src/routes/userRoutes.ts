import { Router } from 'express';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';
import prisma from '../prisma';

const router = Router();

// GET /api/users - Admin only
router.get('/', authenticateToken, authorizeRole(['ADMIN']), async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        full_name: true,
        role: true,
        is_active: true,
        created_at: true,
      },
      orderBy: { created_at: 'desc' },
    });
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/users/:id - Chỉnh sửa thông tin/role
router.put('/:id', authenticateToken, authorizeRole(['ADMIN']), async (req, res) => {
  try {
    const { id } = req.params;
    const { full_name, role, is_active } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: Number(id) },
      data: {
        full_name,
        role,
        is_active,
      },
    });

    res.json({ message: 'Cập nhật thành công', user: updatedUser });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/users/:id - Xóa mềm (Vô hiệu hóa) tài khoản
router.delete('/:id', authenticateToken, authorizeRole(['ADMIN']), async (req, res) => {
  try {
    const { id } = req.params;
    
    // Soft delete: is_active = false
    await prisma.user.update({
      where: { id: Number(id) },
      data: { is_active: false },
    });

    res.json({ message: 'Tài khoản đã bị vô hiệu hóa' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
