import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../services/token_storage.dart';
import '../utils/api_constants.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'account_screen.dart';
import 'qr_scanner_screen.dart';
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
  int _unreadCount = 0;
  int _bottomNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Category> _categories = [];

  static const List<IconData> _categoryIcons = [
    Icons.watch_outlined,
    Icons.diamond_outlined,
    Icons.stars_outlined,
    Icons.auto_awesome,
    Icons.workspace_premium_outlined,
    Icons.card_giftcard,
  ];

  static const List<Color> _categoryColors = [
    Color(0xFFE91E8C),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProducts();
    _loadUnreadCount();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.listCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (_) {
      // Giữ danh sách trống, không chặn các phần khác của trang chủ
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final notifications = await NotificationService.getNotifications(unreadOnly: true);
    if (mounted) setState(() => _unreadCount = notifications.length);
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnreadCount();
  }

  void _openSearch([String? query]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(initialSearch: query ?? _searchController.text.trim()),
      ),
    );
  }

  void _openCategory(int categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProductListScreen(initialCategoryId: categoryId.toString())),
    );
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CartScreen(cartItems: CartService.instance.items)),
    );
  }

  void _openProductDetail(dynamic product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    ).then((_) => _loadProducts());
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
                              IconButton(
                                icon: Badge(
                                  label: Text('$_unreadCount'),
                                  isLabelVisible: _unreadCount > 0,
                                  backgroundColor: const Color(0xFFFFD700),
                                  textColor: Colors.black,
                                  child: const Icon(Icons.notifications_outlined, color: Colors.white),
                                ),
                                onPressed: _openNotifications,
                              ),
                              AnimatedBuilder(
                                animation: CartService.instance,
                                builder: (context, _) => IconButton(
                                  icon: Badge(
                                    label: Text('${CartService.instance.count}'),
                                    isLabelVisible: !CartService.instance.isEmpty,
                                    backgroundColor: const Color(0xFFFFD700),
                                    textColor: Colors.black,
                                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                  ),
                                  onPressed: _openCart,
                                ),
                              ),
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
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm sản phẩm...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onSubmitted: (value) => _openSearch(value),
                          ),
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
                  height: 175,
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
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 4),
                          const Text('Giảm đến 30%\nBộ sưu tập mới 2025',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3)),
                          const SizedBox(height: 8),
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
                    _infoCard(
                      Icons.local_shipping_outlined,
                      'Miễn phí\nvận chuyển',
                      const Color(0xFF2196F3),
                      () => _showPolicyDetail(
                        'Miễn phí vận chuyển',
                        'Aura Accessories miễn phí vận chuyển cho tất cả đơn hàng từ 250.000đ trở lên trên toàn quốc. Đơn hàng dưới 250.000đ áp dụng phí ship đồng giá 25.000đ.',
                        Icons.local_shipping_outlined,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _infoCard(
                      Icons.verified_outlined,
                      'Chính hãng\n100%',
                      const Color(0xFF4CAF50),
                      () => _showPolicyDetail(
                        'Cam kết chính hãng 100%',
                        'Tất cả các sản phẩm phụ kiện thời trang tại Aura Accessories đều được thiết kế độc quyền, bảo chứng chất lượng chính hãng 100% và đổi trả nhanh chóng nếu phát hiện lỗi từ khâu sản xuất.',
                        Icons.verified_outlined,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _infoCard(
                      Icons.replay_outlined,
                      'Đổi trả\n30 ngày',
                      const Color(0xFFFF9800),
                      () => _showPolicyDetail(
                        'Đổi trả 30 ngày',
                        'Chúng tôi hỗ trợ đổi sản phẩm mới hoặc hoàn trả tiền trong vòng 30 ngày kể từ ngày nhận hàng nếu phát hiện lỗi kỹ thuật, lỗi đóng gói hoặc sản phẩm không vừa kích cỡ mong muốn.',
                        Icons.replay_outlined,
                        const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _infoCard(
                      Icons.support_agent_outlined,
                      'Hỗ trợ\n24/7',
                      const Color(0xFFC8102E),
                      () => _showPolicyDetail(
                        'Hỗ trợ khách hàng 24/7',
                        'Đội ngũ chăm sóc khách hàng Aura Accessories luôn túc trực hỗ trợ bạn. Vui lòng liên hệ hotline 1900 8888 hoặc gửi phản hồi trực tiếp qua hòm thư hỗ trợ trong ứng dụng.',
                        Icons.support_agent_outlined,
                        const Color(0xFFC8102E),
                      ),
                    ),
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
                  child: _categories.isEmpty
                      ? const Center(
                          child: Text('Chưa có danh mục nào.',
                              style: TextStyle(color: Colors.grey, fontSize: 12)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _categories.length,
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            final icon = _categoryIcons[i % _categoryIcons.length];
                            final color = _categoryColors[i % _categoryColors.length];
                            return GestureDetector(
                              onTap: () => _openCategory(cat.id),
                              child: Container(
                                width: 72,
                                margin: const EdgeInsets.only(right: 8),
                                child: Column(children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        shape: BoxShape.circle),
                                    child: Icon(icon, color: color, size: 26),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(cat.name,
                                      style: const TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center),
                                ]),
                              ),
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

      // ── Floating Action Button (QR Scanner) ───────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 24),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
            );
          },
          backgroundColor: const Color(0xFFC8102E),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
              SizedBox(height: 2),
              Text('Quét QR', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFC8102E),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 2) return; // Middle button is FAB
          if (index == 0) {
            setState(() => _bottomNavIndex = 0);
            return;
          }
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
            return;
          }
          if (index == 3) {
            _openCart();
            return;
          }
          if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
            return;
          }
        },
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
              icon: Icon(Icons.qr_code_scanner, color: Colors.transparent),
              label: ''), // Placeholder for FAB
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

  void _showPolicyDetail(String title, String description, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8102E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }

  Widget _productCard(dynamic product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['image_url'] as String? : null;
    final price    = _formatPrice(product['price']);
    final name     = product['name'] as String? ?? '';

    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(price,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC8102E))),
                  const SizedBox(height: 2),
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
          ),
        ],
      ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 100,
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
