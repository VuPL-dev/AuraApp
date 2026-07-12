import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';
import prisma from '../prisma';

const router = Router();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// POST /api/users - Admin tạo tài khoản mới trực tiếp (bỏ qua xác thực OTP)
router.post('/', authenticateToken, authorizeRole(['ADMIN']), async (req, res) => {
  try {
    const { email, password, full_name, phone, role } = req.body;

    if (!email || !EMAIL_REGEX.test(email)) {
      res.status(400).json({ error: 'Email không hợp lệ.' });
      return;
    }
    if (!password || password.length < 8) {
      res.status(400).json({ error: 'Mật khẩu phải có ít nhất 8 ký tự.' });
      return;
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      res.status(400).json({ error: 'Email đã được sử dụng.' });
      return;
    }

    const password_hash = await bcrypt.hash(password, 10);
    const newUser = await prisma.user.create({
      data: {
        email,
        password_hash,
        full_name,
        phone,
        role: role || 'CUSTOMER',
        is_email_verified: true,
      },
      select: {
        id: true,
        email: true,
        full_name: true,
        role: true,
        is_active: true,
        created_at: true,
      },
    });

    res.status(201).json({ message: 'Tạo tài khoản thành công', user: newUser });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

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
