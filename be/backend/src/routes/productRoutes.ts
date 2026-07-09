import { Router } from 'express';
import prisma from '../prisma';
import { authenticateToken, authorizeRole } from '../middlewares/authMiddleware';

const router = Router();

// GET /api/products - Tất cả sản phẩm, hỗ trợ lọc (category_id, brand, min_price, max_price, search) và sắp xếp (sort)
router.get('/', async (req, res) => {
  try {
    const { category_id, brand, min_price, max_price, search, sort } = req.query;

    const where: any = {};
    if (category_id) where.category_id = Number(category_id);
    if (brand) where.brand = { equals: String(brand) };
    if (search) where.name = { contains: String(search) };
    if (min_price || max_price) {
      where.price = {};
      if (min_price) where.price.gte = Number(min_price);
      if (max_price) where.price.lte = Number(max_price);
    }

    let orderBy: any = { created_at: 'desc' };
    if (sort === 'price_asc') orderBy = { price: 'asc' };
    else if (sort === 'price_desc') orderBy = { price: 'desc' };
    else if (sort === 'name_asc') orderBy = { name: 'asc' };

    const products = await prisma.product.findMany({
      where,
      include: { images: true, category: true },
      orderBy,
    });
    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/products/bestsellers - Sản phẩm bán chạy nhất
router.get('/bestsellers', async (req, res) => {
  try {
    const products = await prisma.product.findMany({
      include: {
        images: true,
        category: true,
        order_items: true,
      },
    });

    // Đếm số lượng đã bán cho từng sản phẩm
    const withSales = products.map((p) => ({
      ...p,
      totalSold: p.order_items.reduce((sum: number, item: any) => sum + item.quantity, 0),
    }));

    // Lấy giá trị bán cao nhất
    const maxSold = Math.max(...withSales.map((p) => p.totalSold));
    const minSold = Math.min(...withSales.map((p) => p.totalSold));

    let result;
    if (maxSold === minSold) {
      // Tất cả bằng nhau → trả về hết
      result = withSales;
    } else {
      // Sắp xếp giảm dần, lấy top 4
      result = withSales.sort((a, b) => b.totalSold - a.totalSold).slice(0, 4);
    }

    // Bỏ field order_items khỏi response
    const clean = result.map(({ order_items, ...rest }) => rest);
    res.json(clean);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/products/:id - Chi tiết sản phẩm
router.get('/:id', async (req, res) => {
  try {
    const product = await prisma.product.findUnique({
      where: { id: Number(req.params.id) },
      include: { images: true, category: true, reviews: true },
    });
    if (!product) {
      res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
      return;
    }
    res.json(product);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/products - Thêm sản phẩm mới (Staff, Admin)
router.post('/', authenticateToken, authorizeRole(['ADMIN', 'STAFF']), async (req, res) => {
  try {
    const { name, description, price, stock_quantity, category_id, sku, brand, images } = req.body;
    
    // images is expected to be an array of strings (URLs)
    const newProduct = await prisma.product.create({
      data: {
        name,
        description,
        price,
        stock_quantity: stock_quantity || 0,
        category_id,
        sku,
        brand,
        images: {
          create: (images || []).map((url: string, index: number) => ({
            image_url: url,
            is_primary: index === 0,
          })),
        },
      },
      include: { images: true },
    });

    res.status(201).json(newProduct);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Server error' });
  }
});

export default router;
