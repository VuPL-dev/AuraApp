const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.productImage.findMany().then(imgs => console.log(imgs)).finally(() => prisma.$disconnect());
