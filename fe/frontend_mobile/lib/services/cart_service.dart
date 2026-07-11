import 'package:flutter/foundation.dart';

// Giỏ hàng dùng chung cho toàn bộ app (Trang chủ, Danh sách sản phẩm, Giỏ hàng)
// để các màn hình không bị mất đồng bộ trạng thái giỏ hàng.
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<dynamic> _items = [];

  List<dynamic> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  void add(dynamic product) {
    _items.add(product);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Ghi đè toàn bộ giỏ hàng (dùng khi CartScreen cập nhật số lượng/xoá sản phẩm)
  void replaceAll(List<dynamic> newItems) {
    _items
      ..clear()
      ..addAll(newItems);
    notifyListeners();
  }
}
