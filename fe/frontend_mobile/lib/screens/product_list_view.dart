import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/token_storage.dart';
import '../utils/api_constants.dart';

class ProductListView extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onEdit;
  final VoidCallback onChanged;

  const ProductListView({super.key, required this.onEdit, required this.onChanged});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  List<dynamic> _products = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _stockFilter = 'all'; // all, in_stock, out_of_stock

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _absUrl(String url) {
    if (url.startsWith('http')) return url;
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 4)
        : ApiConstants.baseUrl;
    return '$base$url';
  }

  String _fmtPrice(dynamic price) {
    final num p = num.tryParse(price.toString()) ?? 0;
    final f = p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$fđ';
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_searchQuery.trim().isNotEmpty) {
        params['search'] = _searchQuery.trim();
      }
      final uri = Uri.parse('${ApiConstants.baseUrl}/products')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _products = data;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    if (_stockFilter == 'all') return _products;
    if (_stockFilter == 'in_stock') {
      return _products
          .where((p) => (num.tryParse(p['stock_quantity'].toString()) ?? 0) > 0)
          .toList();
    }
    return _products
        .where((p) => (num.tryParse(p['stock_quantity'].toString()) ?? 0) == 0)
        .toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Xác nhận xoá'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xoá sản phẩm này?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${product['name']}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Hành động này không thể hoàn tác. Tất cả dữ liệu liên quan (đơn hàng, đánh giá) cũng sẽ bị xoá.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Xoá'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _deleteProduct(product);
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập đã hết');
      }
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/products/${product['id']}'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xoá "${product['name']}"'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onChanged();
          await _loadProducts();
        }
      } else {
        if (mounted) {
          final err = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi khi xoá: ${err['error'] ?? response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    }
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên sản phẩm...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              _loadProducts();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _loadProducts();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _loadProducts,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF321fdb),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                tooltip: 'Tải lại',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text('Lọc kho: ',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              _filterPill('Tất cả', _stockFilter == 'all'),
              _filterPill('Còn hàng', _stockFilter == 'in_stock'),
              _filterPill('Hết hàng', _stockFilter == 'out_of_stock'),
              Text(
                ' (${_filteredProducts.length} sản phẩm)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: const Color(0xFF321fdb),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        onSelected: (_) {
          String next;
          if (label == 'Tất cả') {
            next = 'all';
          } else if (label == 'Còn hàng') {
            next = 'in_stock';
          } else {
            next = 'out_of_stock';
          }
          setState(() => _stockFilter = next);
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    const style =
        TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: const [
          SizedBox(width: 50, child: Text('Ảnh', style: style)),
          Expanded(flex: 3, child: Text('Tên sản phẩm', style: style)),
          Expanded(flex: 2, child: Text('Giá', style: style)),
          SizedBox(width: 70, child: Text('Kho', style: style)),
          Expanded(flex: 2, child: Text('Danh mục', style: style)),
          SizedBox(width: 90, child: Text('Hành động', style: style)),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty
        ? images[0]['image_url']?.toString()
        : null;
    final stock = num.tryParse(product['stock_quantity'].toString()) ?? 0;
    final outOfStock = stock == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: outOfStock ? const Color(0xFFFAF8F5) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl != null
                  ? Image.network(
                      _absUrl(imageUrl),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product['description'] != null &&
                      product['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        product['description'].toString(),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (product['sku'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'SKU: ${product['sku']}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtPrice(product['price']),
              style: const TextStyle(
                color: Color(0xFFC8102E),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: outOfStock ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stock.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: outOfStock ? Colors.red : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              product['category']?['name']?.toString() ?? '—',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF321fdb)),
                  tooltip: 'Sửa',
                  onPressed: () => widget.onEdit(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: 'Xoá',
                  onPressed: () => _confirmDelete(product),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 50,
        height: 50,
        color: Colors.grey.shade200,
        child: Icon(Icons.image_outlined,
            size: 22, color: Colors.grey.shade500),
      );

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2, color: Color(0xFF321fdb)),
                SizedBox(width: 8),
                Text('Danh sách sản phẩm',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          _buildFilterBar(),
          _buildHeaderRow(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Không có sản phẩm nào',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _buildProductRow(filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}