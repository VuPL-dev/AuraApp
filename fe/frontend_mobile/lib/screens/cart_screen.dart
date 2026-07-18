import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/token_storage.dart';
import '../services/cart_service.dart';
import '../utils/api_constants.dart';

class CartScreen extends StatefulWidget {
  final List<dynamic> cartItems;
  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _selectMode = false;
  final Set<int> _selectedIds = {}; // Stores CartItem.id
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fmt(double p) {
    final f = p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${f}đ';
  }

  void _increase(CartItem item) {
    CartService.updateQuantity(item.id, item.quantity + 1);
  }

  void _decrease(CartItem item) async {
    if (item.quantity <= 1) {
      final confirm = await _confirmRemove(item.name);
      if (confirm == true) {
        CartService.removeFromCart(item.id);
        setState(() {
          _selectedIds.remove(item.id);
        });
      }
    } else {
      CartService.updateQuantity(item.id, item.quantity - 1);
    }
  }

  void _removeItem(CartItem item) async {
    final confirm = await _confirmRemove(item.name);
    if (confirm == true) {
      CartService.removeFromCart(item.id);
      setState(() {
        _selectedIds.remove(item.id);
      });
    }
  }

  Future<bool?> _confirmRemove(String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá sản phẩm?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xoá "$name" khỏi giỏ hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8102E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá sản phẩm đã chọn?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xoá ${_selectedIds.length} sản phẩm đã chọn khỏi giỏ hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8102E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (final id in _selectedIds) {
          await CartService.removeFromCart(id);
        }
        setState(() {
          _selectedIds.clear();
          _selectMode = false;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAll(List<CartItem> filteredItems) async {
    if (filteredItems.isEmpty) return;
    final isSearching = _searchQuery.isNotEmpty;
    final message = isSearching
        ? 'Bạn có chắc muốn xoá ${filteredItems.length} sản phẩm đang tìm kiếm này khỏi giỏ hàng không?'
        : 'Bạn có chắc muốn xoá toàn bộ giỏ hàng không?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isSearching ? 'Xoá kết quả tìm kiếm?' : 'Xoá tất cả?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8102E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (isSearching) {
          for (final item in filteredItems) {
            await CartService.removeFromCart(item.id);
          }
        } else {
          await CartService.clearCart();
        }
        setState(() {
          _selectedIds.clear();
          _selectMode = false;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkoutPayos() async {
    final items = CartService.cartNotifier.value;
    if (items.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final orderItems = items.map((e) {
        return {
          'product_id': e.productId,
          'quantity': e.quantity,
          'unit_price': e.price,
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
          "total_amount": CartService.totalAmount,
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
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (orderId != null) _waitForPaymentSuccess(orderId as int, token);
          } catch (_) {
            try {
              await launchUrl(uri, mode: LaunchMode.platformDefault);
              if (orderId != null) _waitForPaymentSuccess(orderId as int, token);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể mở link: $e')));
              }
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
          if (order['status'] == 'PAID') {
            CartService.cartNotifier.value = [];
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
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: CartService.cartNotifier,
      builder: (context, cartItems, child) {
        final totalItems = cartItems.fold<int>(0, (s, e) => s + e.quantity);
        final filteredItems = cartItems
            .where((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          appBar: AppBar(
            title: Text(
              _selectMode
                  ? 'Đã chọn ${_selectedIds.length}'
                  : (cartItems.isEmpty ? 'Giỏ hàng' : 'Giỏ hàng ($totalItems sản phẩm)'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFC8102E),
            foregroundColor: Colors.white,
            leading: _selectMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectMode = false;
                      _selectedIds.clear();
                    }),
                  )
                : null,
            actions: [
              if (cartItems.isNotEmpty && _selectMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Xoá sản phẩm đã chọn',
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                ),
              if (cartItems.isNotEmpty && !_selectMode)
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Chọn nhiều sản phẩm',
                  onPressed: () => setState(() => _selectMode = true),
                ),
              if (cartItems.isNotEmpty && !_selectMode)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Xoá tất cả',
                  onPressed: () => _clearAll(filteredItems),
                ),
            ],
          ),
          body: cartItems.isEmpty
              ? const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Giỏ hàng trống',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]))
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm trong giỏ...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.2), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFC8102E), width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),

                    // Items List
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy sản phẩm phù hợp',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, i) {
                                final item = filteredItems[i];
                                final id = item.id;
                                final imageUrl = item.imageUrl;
                                final price = item.price;
                                final qty = item.quantity;

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
                                    if (_selectMode)
                                      Checkbox(
                                        value: _selectedIds.contains(id),
                                        activeColor: const Color(0xFFC8102E),
                                        onChanged: (checked) => setState(() {
                                          if (checked == true) {
                                            _selectedIds.add(id);
                                          } else {
                                            _selectedIds.remove(id);
                                          }
                                        }),
                                      ),
                                    // Image
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
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name,
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
                                                  fontSize: 11,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!_selectMode)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        tooltip: 'Xoá sản phẩm',
                                        onPressed: () => _removeItem(item),
                                      ),
                                    // Quantity Selector
                                    Column(
                                      children: [
                                        _qtyBtn(
                                            icon: Icons.add,
                                            color: const Color(0xFFC8102E),
                                            onTap: () => _increase(item)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Text('$qty',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        _qtyBtn(
                                            icon: Icons.remove,
                                            color: qty <= 1
                                                ? Colors.red
                                                : Colors.grey[600]!,
                                            onTap: () => _decrease(item)),
                                      ],
                                    ),
                                  ]),
                                );
                              },
                            ),
                    ),

                    // Checkout bar
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
                                Text(_fmt(CartService.totalAmount),
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
                  ],
                ),
        );
      },
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
