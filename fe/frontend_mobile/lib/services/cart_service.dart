import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';
import '../utils/api_constants.dart';

class CartItem {
  final int id; // CartItem ID từ DB
  final int productId;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['image_url'] as String? : null;
    return CartItem(
      id: json['id'],
      productId: product['id'],
      name: product['name'],
      price: double.tryParse(product['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: imageUrl,
      quantity: json['quantity'],
    );
  }
}

class CartService {
  static final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Load giỏ hàng từ DB về khi đăng nhập
  static Future<void> loadCart() async {
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) return;

      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/cart'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['items'] as List? ?? [])
            .map((j) => CartItem.fromJson(j))
            .toList();
        cartNotifier.value = items;
      }
    } catch (e) {
      debugPrint('Load cart error: $e');
    }
  }

  /// Thêm sản phẩm vào giỏ (sync DB)
  static Future<void> addToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/cart/items'),
        headers: headers,
        body: jsonEncode({'product_id': product['id'], 'quantity': quantity}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['items'] as List? ?? [])
            .map((j) => CartItem.fromJson(j))
            .toList();
        cartNotifier.value = items;
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
    }
  }

  /// Cập nhật số lượng (sync DB)
  static Future<void> updateQuantity(int itemId, int quantity) async {
    try {
      final headers = await _authHeaders();
      await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/cart/items/$itemId'),
        headers: headers,
        body: jsonEncode({'quantity': quantity}),
      ).timeout(const Duration(seconds: 10));

      // Update local state
      final items = List<CartItem>.from(cartNotifier.value);
      if (quantity <= 0) {
        items.removeWhere((i) => i.id == itemId);
      } else {
        final idx = items.indexWhere((i) => i.id == itemId);
        if (idx >= 0) items[idx].quantity = quantity;
      }
      cartNotifier.value = items;
    } catch (e) {
      debugPrint('Update quantity error: $e');
    }
  }

  /// Xóa một item (sync DB)
  static Future<void> removeFromCart(int itemId) async {
    try {
      final headers = await _authHeaders();
      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/cart/items/$itemId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      final items = List<CartItem>.from(cartNotifier.value);
      items.removeWhere((i) => i.id == itemId);
      cartNotifier.value = items;
    } catch (e) {
      debugPrint('Remove from cart error: $e');
    }
  }

  /// Xóa toàn bộ giỏ hàng (sync DB)
  static Future<void> clearCart() async {
    try {
      final headers = await _authHeaders();
      await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/cart/clear'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      cartNotifier.value = [];
    } catch (e) {
      debugPrint('Clear cart error: $e');
    }
  }

  static double get totalAmount {
    return cartNotifier.value.fold(
        0, (sum, item) => sum + (item.price * item.quantity));
  }
}
