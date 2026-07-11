require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  const pwd = await bcrypt.hash('123456', 10);
  const u = await prisma.user.upsert({
    where: { email: 'customer1@aura.com' },
    update: { password_hash: pwd, is_email_verified: true },
    create: {
      email: 'customer1@aura.com',
      password_hash: pwd,
      full_name: 'Khách hàng Demo',
      role: 'CUSTOMER',
      is_email_verified: true,
    },
  });
  console.log('Seeded customer:', u.email);
}
main().catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());