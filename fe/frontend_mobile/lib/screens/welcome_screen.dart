import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../utils/api_constants.dart';
import 'login_screen.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _email = '';
  List<dynamic> _products = [];
  bool _loadingProducts = true;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.watch_outlined,              'label': 'Đồng hồ',    'color': Color(0xFFE91E8C)},
    {'icon': Icons.diamond_outlined,            'label': 'Nhẫn',       'color': Color(0xFF9C27B0)},
    {'icon': Icons.stars_outlined,              'label': 'Dây chuyền', 'color': Color(0xFFFF9800)},
    {'icon': Icons.auto_awesome,                'label': 'Bông tai',   'color': Color(0xFF2196F3)},
    {'icon': Icons.workspace_premium_outlined,  'label': 'Cao cấp',    'color': Color(0xFF4CAF50)},
    {'icon': Icons.card_giftcard,               'label': 'Quà tặng',   'color': Color(0xFFFF5722)},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProducts();
  }

  Future<void> _loadUserInfo() async {
    final email = await TokenStorage.getEmail();
    if (mounted) setState(() => _email = email ?? '');
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/products/bestsellers'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) setState(() { _products = data; _loadingProducts = false; });
      } else {
        if (mounted) setState(() => _loadingProducts = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  String _formatPrice(dynamic price) {
    final num p = num.tryParse(price.toString()) ?? 0;
    final formatted = p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${formatted}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFC8102E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC8102E), Color(0xFF8B0000)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo
                            Row(children: [
                              const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 26),
                              const SizedBox(width: 6),
                              const Text('AURA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4)),
                            ]),
                            // Action icons
                            Row(children: [
                              IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.shopping_cart_outlined,  color: Colors.white), onPressed: () {}),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                onPressed: _handleLogout,
                                tooltip: 'Đăng xuất',
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Search bar
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [
                            SizedBox(width: 12),
                            Icon(Icons.search, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Tìm kiếm sản phẩm...',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC8102E), Color(0xFF8B0000)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFFFD700),
                      child: Icon(Icons.person, color: Color(0xFFC8102E), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Xin chào 👋',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_email,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                ),

                // ── Banner ────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(12),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Stack(children: [
                    Positioned(
                        right: -20, top: -20,
                        child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFD700).withOpacity(0.1)))),
                    Positioned(
                        right: 40, bottom: -30,
                        child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFC8102E).withOpacity(0.2)))),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('ƯU ĐÃI ĐẶC BIỆT',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E))),
                          ),
                          const SizedBox(height: 8),
                          const Text('Giảm đến 30%\nBộ sưu tập mới 2025',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ProductListScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFC8102E),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text('Mua ngay',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),

                // ── Info cards ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    _infoCard(Icons.local_shipping_outlined, 'Miễn phí\nvận chuyển', const Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    _infoCard(Icons.verified_outlined,       'Chính hãng\n100%',       const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    _infoCard(Icons.replay_outlined,         'Đổi trả\n30 ngày',       const Color(0xFFFF9800)),
                    const SizedBox(width: 8),
                    _infoCard(Icons.support_agent_outlined,  'Hỗ trợ\n24/7',           const Color(0xFFC8102E)),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Categories ───────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Danh mục',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      return Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                                color: (cat['color'] as Color).withOpacity(0.15),
                                shape: BoxShape.circle),
                            child: Icon(cat['icon'] as IconData,
                                color: cat['color'] as Color, size: 26),
                          ),
                          const SizedBox(height: 6),
                          Text(cat['label'] as String,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center),
                        ]),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Featured products from API ────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nổi bật hôm nay',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProductListScreen())),
                        child: const Text('Xem tất cả ›',
                            style: TextStyle(
                                color: Color(0xFFC8102E),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Loading / products grid
                _loadingProducts
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFC8102E))))
                    : _products.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('Chưa có sản phẩm nào.')))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, i) =>
                                _productCard(_products[i]),
                          ),

                const SizedBox(height: 20),

                // ── About AURA ────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.diamond, color: Color(0xFFFFD700), size: 24),
                        SizedBox(width: 8),
                        Text('Về AURA Shop',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                      ]),
                      const SizedBox(height: 12),
                      const Text(
                        'AURA là thương hiệu phụ kiện thời trang cao cấp Việt Nam, '
                        'chuyên cung cấp đồng hồ, dây chuyền, vòng cổ và các phụ kiện '
                        'nam nữ chính hãng với chất lượng vượt trội và phong cách hiện đại.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        _statItem('10.000+', 'Khách hàng'),
                        _divider(),
                        _statItem('${_products.length}+', 'Sản phẩm'),
                        _divider(),
                        _statItem('4.9★', 'Đánh giá'),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC8102E),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Danh mục'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Yêu thích'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Giỏ hàng'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản'),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────

  Widget _infoCard(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _productCard(dynamic product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['image_url'] as String? : null;
    final price    = _formatPrice(product['price']);
    final name     = product['name'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(price,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC8102E))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 12),
                  const Text(' 4.9',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('Còn ${product['stock_quantity'] ?? 0}',
                      style:
                          const TextStyle(fontSize: 9, color: Colors.grey)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 130,
      color: const Color(0xFFF5F5F5),
      child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC8102E))),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: Colors.grey.shade200);
}
