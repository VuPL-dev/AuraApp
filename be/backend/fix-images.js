const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixImages() {
  const images = await prisma.productImage.findMany();
  for (const img of images) {
    if (img.image_url.includes('localhost')) {
      const newUrl = img.image_url.replace('localhost', '10.0.2.2');
      await prisma.productImage.update({
        where: { id: img.id },
        data: { image_url: newUrl }
      });
      console.log(`Updated ID ${img.id}: ${newUrl}`);
    }
  }
}

fixImages()
  .then(() => console.log("Done fixing images"))
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
