import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/order_history_screen.dart';
import 'services/token_storage.dart';
import 'services/notification_service.dart';
import 'services/cart_service.dart';
import 'utils/api_constants.dart';
import 'utils/custom_snackbar.dart';
import 'screens/cart_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load biến môi trường từ file .env (Gemini API key cho chatbot)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Nếu thiếu .env, app vẫn chạy nhưng chatbot sẽ báo lỗi hướng dẫn
  }
  await CartService.loadCart();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Accessories',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC8102E)),
        useMaterial3: true,
        fontFamily: 'Arial',
        textTheme: const TextTheme().apply(fontFamily: 'Arial'),
      ),
      home: const LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product List Screen  (trang 2 – "Xem tất cả")
// ─────────────────────────────────────────────────────────────────────────────
class ProductListScreen extends StatefulWidget {
  final String? initialCategoryName;
  final String? initialSearch;
  final String? initialCategoryId;
  
  const ProductListScreen({super.key, this.initialCategoryName, this.initialSearch, this.initialCategoryId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> _products = [];
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _sort = 'newest';
  List<Map<String, dynamic>> _categoryOptions = [];
  Timer? _notificationTimer;
  int _lastNotificationId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) _searchController.text = widget.initialSearch!;
    _selectedCategoryId = widget.initialCategoryId;
    _loadProducts();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    // Kiểm tra thông báo mới mỗi 10 giây
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final notifications = await NotificationService.getNotifications(unreadOnly: true);
      if (notifications.isNotEmpty) {
        final latest = notifications.first;
        final latestId = latest['id'] as int;

        // Khởi tạo ID lần đầu để tránh hiện thông báo cũ khi vừa mở app
        if (_lastNotificationId == 0) {
          _lastNotificationId = latestId;
          return;
        }

        // Nếu là thông báo mới (ID lớn hơn ID cũ)
        if (latestId > _lastNotificationId) {
          _lastNotificationId = latestId;
          if (mounted) {
            _showInAppNotification(latest['title'], latest['message']);
          }
        }
      }
    });
  }

  void _showInAppNotification(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  Text(message, 
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC8102E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        action: SnackBarAction(
          label: 'ĐÁNH GIÁ',
          textColor: Colors.amber,
          onPressed: () {
            // Chuyển sang trang lịch sử đơn hàng để khách hàng đánh giá
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_searchController.text.trim().isNotEmpty) {
        params['search'] = _searchController.text.trim();
      }
      if (_selectedCategoryId != null) params['category_id'] = _selectedCategoryId!;
      if (_sort == 'price_asc') params['sort'] = 'price_asc';
      if (_sort == 'price_desc') params['sort'] = 'price_desc';

      final uri = Uri.parse('${ApiConstants.baseUrl}/products')
          .replace(queryParameters: params.isEmpty ? null : params);

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _products = data;
            _loading = false;
            if (_categoryOptions.isEmpty) {
              final seen = <String>{};
              _categoryOptions = data
                  .map((p) => p['category'])
                  .where((c) => c != null && seen.add(c['id'].toString()))
                  .map<Map<String, dynamic>>(
                      (c) => {'id': c['id'].toString(), 'name': c['name']})
                  .toList();
                  
              if (widget.initialCategoryName != null && _selectedCategoryId == null) {
                final match = _categoryOptions.firstWhere(
                  (c) => (c['name'] as String).toLowerCase() == widget.initialCategoryName!.toLowerCase(), 
                  orElse: () => <String, dynamic>{}
                );
                if (match.isNotEmpty) {
                  _selectedCategoryId = match['id'] as String;
                  // Re-fetch products with the matched category filter
                  WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
                }
              }
            }
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (_) => _loadProducts(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('Tất cả', _selectedCategoryId == null,
                    () => setState(() { _selectedCategoryId = null; _loadProducts(); })),
                ..._categoryOptions.map((c) => _filterChip(
                    c['name'] as String,
                    _selectedCategoryId == c['id'],
                    () => setState(() { _selectedCategoryId = c['id'] as String; _loadProducts(); }))),
                const SizedBox(width: 4),
                _sortChip('Mới nhất', 'newest'),
                _sortChip('Giá tăng', 'price_asc'),
                _sortChip('Giá giảm', 'price_desc'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        selectedColor: const Color(0xFFC8102E),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    return _filterChip(label, _sort == value,
        () => setState(() { _sort = value; _loadProducts(); }));
  }

  String _formatPrice(dynamic price) {
    final num p = num.tryParse(price.toString()) ?? 0;
    final formatted = p.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${formatted}đ';
  }

  void _addToCart(dynamic product) {
    CartService.addToCart(product as Map<String, dynamic>);
    CustomSnackBar.showSuccessDialog(
      context: context,
      productName: product['name'] ?? '',
      onGoToCart: _openCart,
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CartScreen(cartItems: CartService.cartNotifier.value.map((c) => <String, dynamic>{ 'id': c.productId, 'name': c.name, 'price': c.price, 'images': c.imageUrl != null ? [{'image_url': c.imageUrl}] : [] }).toList())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
          SizedBox(width: 8),
          Text('AURA Shop',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        backgroundColor: const Color(0xFFC8102E),
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartService.cartNotifier,
            builder: (context, cart, child) => IconButton(
              icon: Badge(
                label: Text(cart.length.toString()),
                isLabelVisible: cart.isNotEmpty,
                backgroundColor: const Color(0xFFFFD700),
                textColor: Colors.black,
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              onPressed: _openCart,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC8102E)))
                : _products.isEmpty
                    ? const Center(child: Text('Chưa có sản phẩm nào.'))
                    : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final images = product['images'] as List? ?? [];
                    final imageUrl = images.isNotEmpty
                        ? images[0]['image_url'] as String?
                        : null;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phần trên (ảnh): tap → detail
                          Expanded(
                            flex: 5,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                ).then((_) => _loadProducts());
                              },
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: imageUrl != null
                                    ? Image.network(imageUrl,
                                        height: double.infinity,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imgPlaceholder(100))
                                    : _imgPlaceholder(100),
                              ),
                            ),
                          ),
                          // Phần dưới (tên + giá + nút): tap vào tên → detail
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                              product: product),
                                        ),
                                      ).then((_) => _loadProducts());
                                    },
                                    child: Text(
                                        product['name'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_formatPrice(product['price']),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC8102E))),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () => _addToCart(product),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFC8102E),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Thêm vào giỏ',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(double h) => Container(
        height: h,
        color: const Color(0xFFF5F5F5),
        child: const Center(
            child: Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
      );
}
