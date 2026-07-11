import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Bắt đầu seed dữ liệu...');

  const passwordHash = await bcrypt.hash('123456', 10);

  // 1. Tạo Users
  const admin = await prisma.user.upsert({
    where: { email: 'admin@aura.com' },
    update: { password_hash: passwordHash, role: 'ADMIN', is_email_verified: true },
    create: {
      email: 'admin@aura.com',
      password_hash: passwordHash,
      full_name: 'Quản trị viên Aura',
      role: 'ADMIN',
      is_email_verified: true,
    },
  });

  const staff = await prisma.user.upsert({
    where: { email: 'staff@aura.com' },
    update: { password_hash: passwordHash, role: 'STAFF', is_email_verified: true },
    create: {
      email: 'staff@aura.com',
      password_hash: passwordHash,
      full_name: 'Nhân viên Aura',
      role: 'STAFF',
      is_email_verified: true,
    },
  });

  const customer = await prisma.user.upsert({
    where: { email: 'customer@aura.com' },
    update: { password_hash: passwordHash, role: 'CUSTOMER', is_email_verified: true },
    create: {
      email: 'customer@aura.com',
      password_hash: passwordHash,
      full_name: 'Khách hàng VIP',
      role: 'CUSTOMER',
      is_email_verified: true,
    },
  });

  console.log('Đã tạo 3 tài khoản (admin, staff, customer) với pass: 123456');

  // 2. Tạo Category
  const category = await prisma.category.upsert({
    where: { id: 1 },
    update: { name: 'Trang sức' },
    create: {
      id: 1,
      name: 'Trang sức',
      description: 'Các loại trang sức',
    },
  });

  // 3. Tạo Product
  const product = await prisma.product.upsert({
    where: { id: 1 },
    update: { name: 'Dây chuyền Aura Vàng' },
    create: {
      id: 1,
      category_id: category.id,
      name: 'Dây chuyền Aura Vàng',
      description: 'Dây chuyền vàng cực đẹp',
      price: 1500000,
      stock_quantity: 100,
    },
  });

  // 4. Tạo UserAddress
  await prisma.userAddress.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      user_id: customer.id,
      address_line: '123 Đường Mẫu, Hà Nội',
      is_default: true,
    },
  });

  console.log('Seed dữ liệu hoàn tất!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
