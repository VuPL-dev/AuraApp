import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'screens/login_screen.dart';
import 'services/token_storage.dart';
import 'utils/api_constants.dart';

void main() {
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
      ),
      home: const LoginScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product List Screen  (trang 2 – "Xem tất cả")
// ─────────────────────────────────────────────────────────────────────────────
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> _products = [];
  bool _loading = true;
  final List<dynamic> _cart = [];

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _sort = 'newest';
  List<Map<String, dynamic>> _categoryOptions = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    setState(() => _cart.add(product));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${product['name']} đã thêm vào giỏ!'),
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0xFFC8102E),
    ));
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CartScreen(cartItems: _cart)),
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
          IconButton(
            icon: Badge(
              label: Text(_cart.length.toString()),
              isLabelVisible: _cart.isNotEmpty,
              backgroundColor: const Color(0xFFFFD700),
              textColor: Colors.black,
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            onPressed: _openCart,
          )
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
                    childAspectRatio: 0.72,
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
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: imageUrl != null
                                ? Image.network(imageUrl,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        _imgPlaceholder(140))
                                : _imgPlaceholder(140),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
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
                                        backgroundColor: const Color(0xFFC8102E),
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

// ─────────────────────────────────────────────────────────────────────────────
// Cart Screen
// ─────────────────────────────────────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  final List<dynamic> cartItems;
  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  // Map<productId, {product, qty}>
  late final Map<int, Map<String, dynamic>> _itemMap;

  @override
  void initState() {
    super.initState();
    _itemMap = {};
    for (final item in widget.cartItems) {
      final id = item['id'] as int;
      if (_itemMap.containsKey(id)) {
        _itemMap[id]!['qty'] = (_itemMap[id]!['qty'] as int) + 1;
      } else {
        _itemMap[id] = {'product': item, 'qty': 1};
      }
    }
  }

  List<Map<String, dynamic>> get _entries => _itemMap.values.toList();

  double get _totalPrice => _itemMap.values.fold(0.0, (sum, e) {
        final price =
            (num.tryParse(e['product']['price'].toString()) ?? 0).toDouble();
        return sum + price * (e['qty'] as int);
      });

  int get _totalItems =>
      _itemMap.values.fold(0, (s, e) => s + (e['qty'] as int));

  String _fmt(double p) {
    final f = p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${f}đ';
  }

  void _increase(int id) => setState(() => _itemMap[id]!['qty']++);

  void _decrease(int id) async {
    final qty = _itemMap[id]!['qty'] as int;
    if (qty <= 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xoá sản phẩm?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
              'Bạn có chắc muốn xoá "${_itemMap[id]!['product']['name']}" khỏi giỏ hàng không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8102E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá'),
            ),
          ],
        ),
      );
      if (confirm == true) setState(() => _itemMap.remove(id));
    } else {
      setState(() => _itemMap[id]!['qty'] = qty - 1);
    }
  }

  Future<void> _checkoutPayos() async {
    if (_itemMap.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final orderItems = _itemMap.values.map((e) {
        final product = e['product'];
        return {
          'product_id': product['id'],
          'quantity': e['qty'],
          'unit_price':
              (num.tryParse(product['price'].toString()) ?? 0).toDouble(),
        };
      }).toList();

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Vui lòng đăng nhập để thanh toán')));
        }
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/payment/create-payos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "address_id": null,
          "total_amount": _totalPrice,
          "payment_method": "PAYOS",
          "items": orderItems,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final checkoutUrl = data['checkoutUrl'];
        final orderId = data['order_id'];
        if (checkoutUrl != null) {
          final uri = Uri.parse(checkoutUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (orderId != null) _waitForPaymentSuccess(orderId as int, token);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Không thể mở link thanh toán')));
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${response.body}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bắt sự kiện thanh toán thành công (theo dõi trạng thái đơn hàng sau khi
  // người dùng thanh toán qua trình duyệt PayOS) và tự động chuyển về Trang chủ.
  Future<void> _waitForPaymentSuccess(int orderId, String token) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đang chờ xác nhận thanh toán...'),
        duration: Duration(seconds: 3),
      ));
    }

    for (int attempt = 0; attempt < 20; attempt++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      try {
        final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final order = jsonDecode(response.body);
          if (order['status'] == 'SUCCESS') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Thanh toán thành công!'),
                backgroundColor: Color(0xFF4CAF50),
              ));
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
            return;
          }
        }
      } catch (_) {
        // Bỏ qua lỗi tạm thời, tiếp tục thử lại
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: Text(
          _itemMap.isEmpty ? 'Giỏ hàng' : 'Giỏ hàng ($_totalItems sản phẩm)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC8102E),
        foregroundColor: Colors.white,
      ),
      body: _itemMap.isEmpty
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Giỏ hàng trống',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]))
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final entry = _entries[i];
                    final product = entry['product'];
                    final qty = entry['qty'] as int;
                    final id = product['id'] as int;
                    final images = product['images'] as List? ?? [];
                    final imageUrl = images.isNotEmpty
                        ? images[0]['image_url'] as String?
                        : null;
                    final price =
                        (num.tryParse(product['price'].toString()) ?? 0)
                            .toDouble();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(children: [
                        // Ảnh
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl != null
                              ? Image.network(imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _thumb())
                              : _thumb(),
                        ),
                        const SizedBox(width: 12),
                        // Tên + giá + subtotal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'] as String? ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_fmt(price),
                                  style: const TextStyle(
                                      color: Color(0xFFC8102E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('Tổng: ${_fmt(price * qty)}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút − số lượng +
                        Column(
                          children: [
                            _qtyBtn(
                                icon: Icons.add,
                                color: const Color(0xFFC8102E),
                                onTap: () => _increase(id)),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('$qty',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            _qtyBtn(
                                icon: Icons.remove,
                                color: qty <= 1 ? Colors.red : Colors.grey[600]!,
                                onTap: () => _decrease(id)),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
              ),
              // Thanh tổng + checkout
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, -2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng tiền',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(_fmt(_totalPrice),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC8102E))),
                        ]),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkoutPayos,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.payment, size: 18),
                      label: const Text('Thanh toán PayOS',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8102E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _qtyBtn(
          {required IconData icon,
          required Color color,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );

  Widget _thumb() => Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.image_outlined, color: Colors.grey));
}
