require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  const adminPassword = await bcrypt.hash('123456', 10);
  const staffPassword = await bcrypt.hash('123456', 10);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@aura.com' },
    update: {
      password_hash: adminPassword,
      role: 'ADMIN',
      is_email_verified: true,
    },
    create: {
      email: 'admin@aura.com',
      password_hash: adminPassword,
      full_name: 'Admin User',
      role: 'ADMIN',
      is_email_verified: true,
    },
  });

  const staff = await prisma.user.upsert({
    where: { email: 'staff@aura.com' },
    update: {
      password_hash: staffPassword,
      role: 'STAFF',
      is_email_verified: true,
    },
    create: {
      email: 'staff@aura.com',
      password_hash: staffPassword,
      full_name: 'Staff User',
      role: 'STAFF',
      is_email_verified: true,
    },
  });

  console.log('Seeded Admin:', admin.email);
  console.log('Seeded Staff:', staff.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
