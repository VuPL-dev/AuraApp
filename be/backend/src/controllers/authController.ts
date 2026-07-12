import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../prisma';
import nodemailer from 'nodemailer';

// Configure nodemailer transporter
const transporter = nodemailer.createTransport({
  service: 'gmail', // You can change this to any provider
  auth: {
    user: process.env.EMAIL_USER || 'your-email@gmail.com',
    pass: process.env.EMAIL_PASS || 'your-app-password',
  },
});

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, full_name, phone } = req.body;

    if (!email || !EMAIL_REGEX.test(email)) {
      res.status(400).json({ error: 'Email không hợp lệ.' });
      return;
    }

    if (!password || password.length < 8) {
      res.status(400).json({ error: 'Mật khẩu phải có ít nhất 8 ký tự.' });
      return;
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });

    // Nếu email đã đăng ký VÀ đã xác thực -> thông báo lỗi
    if (existingUser && existingUser.is_email_verified) {
      res.status(400).json({ error: 'Email đã được đăng ký và xác thực. Vui lòng đăng nhập.' });
      return;
    }

    let user = existingUser;

    if (existingUser && !existingUser.is_email_verified) {
      // Email tồn tại nhưng chưa xác thực -> cập nhật password và gửi OTP mới
      const password_hash = await bcrypt.hash(password, 10);
      user = await prisma.user.update({
        where: { id: existingUser.id },
        data: { password_hash, full_name, phone },
      });
      // Xóa các OTP cũ chưa dùng
      await prisma.otpCode.deleteMany({
        where: { user_id: existingUser.id, is_used: false, type: 'EMAIL_VERIFY' },
      });
    } else {
      // Email chưa tồn tại -> tạo mới
      const password_hash = await bcrypt.hash(password, 10);
      user = await prisma.user.create({
        data: { email, password_hash, full_name, phone },
      });
    }

    // Generate random 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    await prisma.otpCode.create({
      data: {
        user_id: user!.id,
        otp_code: otp,
        type: 'EMAIL_VERIFY',
        expires_at: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
      },
    });

    // Log OTP for testing
    console.log(`[OTP GENERATED] MÃ OTP CỦA ${email} LÀ: ${otp}`);
    
    // Fire and forget email sending to prevent API timeout
    transporter.sendMail({
      from: `"Aura Accessories" <${process.env.EMAIL_USER || 'no-reply@aura.com'}>`,
      to: email,
      subject: 'Xác thực tài khoản Aura Accessories',
      text: `Mã OTP xác thực tài khoản của bạn là: ${otp}. Mã này sẽ hết hạn trong vòng 10 phút.`,
      html: `<h3>Xin chào!</h3><p>Mã OTP xác thực tài khoản của bạn là: <strong>${otp}</strong>.</p><p>Mã này sẽ hết hạn trong vòng 10 phút.</p>`,
    }).then(() => {
      console.log('Email sent successfully');
    }).catch((mailErr) => {
      console.error('Failed to send email:', mailErr);
    });

    res.status(201).json({ message: 'OTP đã được gửi tới email của bạn.', user_id: user!.id });
  } catch (error: any) {
    console.error(error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
};


export const verifyEmail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, otp_code } = req.body;

    // Tìm user theo email
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(400).json({ error: 'Không tìm thấy tài khoản với email này.' });
      return;
    }

    const otp = await prisma.otpCode.findFirst({
      where: { user_id: user.id, otp_code, is_used: false, type: 'EMAIL_VERIFY' },
    });

    if (!otp || otp.expires_at < new Date()) {
      res.status(400).json({ error: 'Mã OTP không đúng hoặc đã hết hạn.' });
      return;
    }

    await prisma.otpCode.update({ where: { id: otp.id }, data: { is_used: true } });
    await prisma.user.update({ where: { id: user.id }, data: { is_email_verified: true } });

    res.status(200).json({ message: 'Xác thực email thành công! Vui lòng đăng nhập.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
};


export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(401).json({ error: 'Email hoặc mật khẩu không đúng.' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      res.status(401).json({ error: 'Email hoặc mật khẩu không đúng.' });
      return;
    }

    if (!user.is_active) {
      res.status(403).json({ error: 'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ Admin.' });
      return;
    }

    if (!user.is_email_verified) {
      res.status(403).json({ error: 'Tài khoản chưa xác thực email. Vui lòng kiểm tra hộp thư.' });
      return;
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '7d' }
    );

    res.status(200).json({
      success: true,
      token,
      user: { id: user.id, email: user.email, full_name: user.full_name, role: user.role }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
};

export const resendVerification = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(404).json({ error: 'Không tìm thấy tài khoản.' });
      return;
    }

    if (user.is_email_verified) {
      res.status(400).json({ error: 'Email này đã được xác thực rồi.' });
      return;
    }

    // Xóa OTP cũ chưa dùng
    await prisma.otpCode.deleteMany({
      where: { user_id: user.id, is_used: false, type: 'EMAIL_VERIFY' },
    });

    // Tạo OTP mới
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await prisma.otpCode.create({
      data: {
        user_id: user.id,
        otp_code: otp,
        type: 'EMAIL_VERIFY',
        expires_at: new Date(Date.now() + 10 * 60 * 1000),
      },
    });

    console.log(`[OTP RESEND] MÃ OTP MỚI CỦA ${email} LÀ: ${otp}`);

    transporter.sendMail({
      from: `"Aura Accessories" <${process.env.EMAIL_USER || 'no-reply@aura.com'}>`,
      to: email,
      subject: 'Mã OTP mới - Xác thực tài khoản Aura Accessories',
      text: `Mã OTP mới của bạn là: ${otp}. Mã này sẽ hết hạn trong 10 phút.`,
      html: `<h3>Gửi lại mã OTP</h3><p>Mã OTP mới của bạn là: <strong>${otp}</strong>.</p><p>Mã này sẽ hết hạn trong 10 phút.</p>`,
    }).then(() => console.log('Resend email sent'))
      .catch((err) => console.error('Resend email failed:', err));

    res.status(200).json({ message: 'Mã OTP mới đã được gửi tới email của bạn.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
};

