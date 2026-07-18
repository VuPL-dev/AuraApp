/// Model đại diện cho một sản phẩm trong cửa hàng Aura Accessories.
///
/// Dữ liệu dựa trên schema Prisma (`be/backend/prisma/schema.prisma`)
/// và được đồng bộ thủ công với bảng `products` của database SQLite.
/// Trường `suitableFor`, `warnings`, `returnPolicy` là metadata mở rộng
/// (không có trong DB) — bổ sung cho RAG pipeline để chatbot trả lời
/// chính xác hơn về chính sách đổi trả và lưu ý sử dụng.
class Product {
  final int id;
  final String name;
  final String brand;
  final int price; // VND
  final int stockQuantity;
  final String? sku;
  final String category;
  final String description;
  final List<String> tags;
  final String suitableFor;
  final String warnings;
  final String returnPolicy;
  final String usage;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.stockQuantity,
    this.sku,
    required this.category,
    required this.description,
    required this.tags,
    required this.suitableFor,
    required this.warnings,
    required this.returnPolicy,
    required this.usage,
  });
}

/// Thông tin chính sách shop (FAQ dùng cho RAG).
class ShopInfo {
  final String name;
  final String tagline;
  final String hotline;
  final String supportEmail;
  final String returnPolicy;
  final String shippingPolicy;
  final String authenticityPolicy;
  final String promoCurrent;
  final List<String> paymentMethods;

  const ShopInfo({
    required this.name,
    required this.tagline,
    required this.hotline,
    required this.supportEmail,
    required this.returnPolicy,
    required this.shippingPolicy,
    required this.authenticityPolicy,
    required this.promoCurrent,
    required this.paymentMethods,
  });
}

const ShopInfo shopInfo = ShopInfo(
  name: 'AURA Accessories',
  tagline:
      'Thương hiệu phụ kiện thời trang cao cấp Việt Nam, chuyên đồng hồ, '
      'dây chuyền, vòng cổ và phụ kiện nam chính hãng.',
  hotline: '1900 8888',
  supportEmail: 'support@aura-accessories.vn',
  returnPolicy:
      'Đổi sản phẩm mới hoặc hoàn tiền trong vòng 30 ngày kể từ ngày nhận hàng '
      'nếu phát hiện lỗi kỹ thuật, lỗi đóng gói hoặc sản phẩm không vừa kích cỡ. '
      'Sản phẩm đổi trả còn nguyên tem mác, chưa qua sử dụng.',
  shippingPolicy:
      'Miễn phí vận chuyển toàn quốc cho đơn từ 250.000đ. '
      'Đơn dưới 250.000đ áp dụng phí ship đồng giá 25.000đ. '
      'Thời gian giao hàng 2-4 ngày làm việc tùy khu vực.',
  authenticityPolicy:
      'Tất cả sản phẩm phụ kiện thời trang tại Aura được thiết kế độc quyền, '
      'bảo chứng chất lượng chính hãng 100% và đổi trả nhanh chóng nếu phát hiện lỗi '
      'từ khâu sản xuất.',
  promoCurrent:
      'Giảm đến 30% Bộ sưu tập mới 2025. Miễn phí vận chuyển cho đơn từ 250.000đ. '
      'Hỗ trợ trả góp 0% qua PayOS cho đơn từ 500.000đ.',
  paymentMethods: ['PayOS', 'COD (thanh toán khi nhận hàng)'],
);

/// Knowledge base của Aura Accessories — dữ liệu 5 sản phẩm chính
/// được lấy từ database SQLite (`be/backend/prisma/dev.db`).
/// Mỗi sản phẩm có đầy đủ metadata để Gemini trả lời chính xác.
final List<Product> knowledgeBase = [
  Product(
    id: 1,
    name: 'Đồng Hồ Nam Dây Da Cao Cấp',
    brand: 'AURA',
    price: 10000,
    stockQuantity: 50,
    sku: 'DH-NAM-001',
    category: 'Đồng hồ Nam',
    description:
        'Đồng hồ nam thời trang với dây da sang trọng, mặt kính sapphire chống xước. '
        'Phù hợp đi làm và dự tiệc.',
    tags: const [
      'đồng hồ', 'đồng hồ nam', 'dây da', 'sapphire', 'sang trọng',
      'watch', 'dh-nam-001', 'aura',
    ],
    suitableFor: 'Nam giới công sở, dự tiệc, sự kiện trang trọng',
    warnings:
        'Tránh để đồng hồ tiếp xúc với nước nóng và hóa chất. '
        'Không nên đeo khi chơi thể thao dưới nước. Vệ sinh dây da bằng khăn mềm.',
    returnPolicy:
        'Đổi trả trong 30 ngày nếu lỗi kỹ thuật hoặc đóng gói.',
    usage:
        'Điều chỉnh size dây da tại cửa hàng hoặc điểm bảo hành. Tránh va đập mạnh.',
  ),
  Product(
    id: 2,
    name: 'Đồng Hồ Nam Luxury Collection',
    brand: 'AURA',
    price: 10000,
    stockQuantity: 30,
    sku: 'DH-NAM-002',
    category: 'Đồng hồ Nam',
    description:
        'Bộ sưu tập đồng hồ nam luxury, vỏ thép không gỉ 316L, chống nước 50m. '
        'Thiết kế tinh xảo, đẳng cấp.',
    tags: const [
      'đồng hồ', 'đồng hồ nam', 'luxury', 'thép không gỉ', '316l',
      'chống nước', '50m', 'watch', 'dh-nam-002', 'aura',
    ],
    suitableFor: 'Nam giới yêu thích phong cách sang trọng, quý ông hiện đại',
    warnings:
        'Chống nước 50m — không đeo khi lặn biển. Không bấm nút chỉnh giờ khi ướt. '
        'Bảo dưỡng định kỳ 12 tháng tại trung tâm bảo hành.',
    returnPolicy:
        'Đổi trả trong 30 ngày nếu lỗi kỹ thuật. Bảo hành chính hãng 12 tháng.',
    usage:
        'Vặn núm chỉnh giờ khi đồng hồ ở trạng thái khô. Lau chùi bằng vải mềm.',
  ),
  Product(
    id: 3,
    name: 'Đồng Hồ Nam Sport Edition',
    brand: 'AURA',
    price: 10000,
    stockQuantity: 80,
    sku: 'DH-NAM-003',
    category: 'Đồng hồ Nam',
    description:
        'Đồng hồ thể thao nam, dây silicon bền chắc, tính năng đo nhịp tim và chống nước 100m.',
    tags: const [
      'đồng hồ', 'đồng hồ nam', 'thể thao', 'sport', 'silicone',
      'nhịp tim', 'chống nước', '100m', 'watch', 'dh-nam-003', 'aura',
    ],
    suitableFor: 'Nam giới năng động, chơi thể thao, tập gym, chạy bộ',
    warnings:
        'Chống nước 100m phù hợp bơi lội nhưng không dùng khi lặn sâu. '
        'Sạc pin định kỳ, không để pin cạn kiệt quá 7 ngày.',
    returnPolicy:
        'Đổi trả trong 30 ngày nếu lỗi kỹ thuật. Pin và dây silicon bảo hành 6 tháng.',
    usage:
        'Bật chế độ thể thao trước khi tập. Đồng bộ nhịp tim với điện thoại qua Bluetooth.',
  ),
  Product(
    id: 4,
    name: 'Vòng Cổ Nam Bạc 925',
    brand: 'AURA',
    price: 10000,
    stockQuantity: 120,
    sku: 'VC-NAM-001',
    category: 'Combo phụ kiện',
    description:
        'Dây chuyền vòng cổ nam bạc 925 nguyên chất, thiết kế hiện đại, phong cách. '
        'Không gây dị ứng da.',
    tags: const [
      'vòng cổ', 'dây chuyền', 'bạc', 'bạc 925', 's925',
      'phụ kiện nam', 'necklace', 'vc-nam-001', 'aura',
    ],
    suitableFor: 'Nam giới mọi lứa tuổi, phong cách cá tính hoặc công sở',
    warnings:
        'Tháo trang sức khi tắm, bơi lội hoặc chơi thể thao. '
        'Tránh tiếp xúc với nước hoa, lotion. Bảo quản trong hộp kín khi không dùng.',
    returnPolicy:
        'Đổi trả trong 30 ngày nếu lỗi kỹ thuật. Bạc 925 không bị oxy hóa đổi màu.',
    usage:
        'Đeo hàng ngày hoặc theo dịp. Lau chùi bằng khăn chuyên dụng cho bạc.',
  ),
  Product(
    id: 5,
    name: 'Combo Mắt Kính & Đồng Hồ Nam',
    brand: 'AURA',
    price: 10000,
    stockQuantity: 25,
    sku: 'COMBO-001',
    category: 'Combo phụ kiện',
    description:
        'Bộ combo thời trang nam gồm mắt kính UV400 và đồng hồ cổ điển. '
        'Quà tặng lý tưởng cho nam giới.',
    tags: const [
      'combo', 'mắt kính', 'đồng hồ', 'uv400', 'quà tặng',
      'phụ kiện nam', 'combo-001', 'aura',
    ],
    suitableFor: 'Quà tặng sinh nhật, kỷ niệm, ngày lễ cho nam giới',
    warnings:
        'Mắt kính: không dùng khăn giấy lau tròng kính. '
        'Đồng hồ: tránh va đập và nước nóng. Bảo quản trong hộp kèm theo.',
    returnPolicy:
        'Combo đổi trả trong 30 ngày nếu lỗi kỹ thuật. Cả 2 sản phẩm phải còn nguyên hộp.',
    usage:
        'Sử dụng mắt kính khi ra nắng. Đồng hồ cổ điển phù hợp trang phục công sở.',
  ),
];

/// ──────────────────────────────────────────────────────────────────────
/// Bước 2: Lọc dữ liệu cục bộ (Local Filtering & Scoring).
/// Tìm kiếm và trả về tối đa 5 sản phẩm liên quan nhất dựa trên câu hỏi.
/// ──────────────────────────────────────────────────────────────────────
List<Product> searchRelevantProducts(String query) {
  final queryLower = query.toLowerCase();
  final queryWords = queryLower
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1)
      .toList();

  if (queryWords.isEmpty) {
    // Không có từ khóa rõ ràng → trả về toàn bộ để AI trả lời chung
    return knowledgeBase.take(5).toList();
  }

  final scored = <MapEntry<Product, int>>[];

  for (final product in knowledgeBase) {
    int score = 0;

    for (final word in queryWords) {
      // Tên sản phẩm (trọng số cao nhất)
      if (product.name.toLowerCase().contains(word)) score += 3;
      // Thương hiệu
      if (product.brand.toLowerCase().contains(word)) score += 3;
      // SKU
      if ((product.sku ?? '').toLowerCase().contains(word)) score += 4;
      // Danh mục
      if (product.category.toLowerCase().contains(word)) score += 2;
      // Tags
      for (final tag in product.tags) {
        if (tag.toLowerCase().contains(word)) score += 2;
      }
      // Mô tả
      if (product.description.toLowerCase().contains(word)) score += 1;
      // Cảnh báo / chính sách
      if (product.warnings.toLowerCase().contains(word)) score += 1;
      if (product.returnPolicy.toLowerCase().contains(word)) score += 1;
    }

    if (score > 0) {
      scored.add(MapEntry(product, score));
    }
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  return scored.take(5).map((e) => e.key).toList();
}

/// ──────────────────────────────────────────────────────────────────────
/// Bước 3: Định dạng dữ liệu thành văn bản có nhãn rõ ràng (Context Formatting).
/// Chuyển danh sách sản phẩm thành chuỗi text để gửi cho Gemini.
/// ──────────────────────────────────────────────────────────────────────
String formatProductContext(List<Product> products) {
  if (products.isEmpty) {
    return 'Không tìm thấy sản phẩm liên quan trong kho dữ liệu.';
  }

  final buffer = StringBuffer();
  for (int i = 0; i < products.length; i++) {
    final p = products[i];
    buffer.writeln('--- Sản phẩm ${i + 1} (ID: ${p.id}) ---');
    buffer.writeln('Tên: ${p.name}');
    buffer.writeln('Thương hiệu: ${p.brand}');
    if (p.sku != null) buffer.writeln('Mã SKU: ${p.sku}');
    buffer.writeln('Danh mục: ${p.category}');
    buffer.writeln('Giá: ${_formatPrice(p.price)}');
    buffer.writeln('Tồn kho: ${p.stockQuantity} sản phẩm');
    buffer.writeln('Mô tả: ${p.description}');
    buffer.writeln('Phù hợp cho: ${p.suitableFor}');
    buffer.writeln('Cách sử dụng: ${p.usage}');
    buffer.writeln('Chính sách đổi trả: ${p.returnPolicy}');
    buffer.writeln('Lưu ý: ${p.warnings}');
    buffer.writeln();
  }
  return buffer.toString();
}

/// Format thông tin shop dưới dạng context cho Gemini.
String formatShopInfoContext() {
  final buffer = StringBuffer();
  buffer.writeln('--- Thông tin cửa hàng ---');
  buffer.writeln('Tên: ${shopInfo.name}');
  buffer.writeln('Mô tả: ${shopInfo.tagline}');
  buffer.writeln('Hotline: ${shopInfo.hotline}');
  buffer.writeln('Email hỗ trợ: ${shopInfo.supportEmail}');
  buffer.writeln('Chính sách đổi trả: ${shopInfo.returnPolicy}');
  buffer.writeln('Chính sách vận chuyển: ${shopInfo.shippingPolicy}');
  buffer.writeln('Cam kết chính hãng: ${shopInfo.authenticityPolicy}');
  buffer.writeln('Khuyến mãi hiện tại: ${shopInfo.promoCurrent}');
  buffer.writeln(
      'Phương thức thanh toán: ${shopInfo.paymentMethods.join(', ')}');
  return buffer.toString();
}

/// Format giá tiền VND (hỗ trợ số >= 1000).
String _formatPrice(int price) {
  final str = price.toString();
  if (str.length <= 3) return '$str VND';

  final buffer = StringBuffer();
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i > 0) {
      buffer.write('.');
    }
  }
  return '${buffer.toString().split('').reversed.join()} VND';
}
