import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/api_constants.dart';
import '../services/token_storage.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'product_list_view.dart';
import 'product_form_view.dart';
import 'staff_comments_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _currentView = 'DASHBOARD'; // DASHBOARD, ORDERS, PRODUCTS, PRODUCT_FORM, COMMENTS
  Map<String, dynamic>? _editingProduct;

  // Orders
  List<dynamic> _allOrders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    _goToLogin();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        _goToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _allOrders = data;
            _isLoadingOrders = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingOrders = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật đơn hàng #$orderId thành $status')),
          );
          _loadOrders();
        }
      }
    } catch (e) {
      debugPrint('Update status error: $e');
    }
  }

  Future<void> _generateDeliveryQr(Map<String, dynamic> order) async {
    final orderId = order['id'];
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/delivery-qr'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final qrData = data['qrData'];

        if (mounted) {
          _showQrPrintDialog(order, qrData);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể tạo mã QR: ${jsonDecode(response.body)['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lấy mã QR: $e')),
        );
      }
    }
  }

  void _showQrPrintDialog(Map<String, dynamic> order, String qrData) {
    final GlobalKey boundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhãn Giao Hàng', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AURA APP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                Text('Order #${order['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Divider(color: Colors.black),
                const SizedBox(height: 10),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.black),
                Text('Total: ${order['total_amount']} VND', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('Scan to confirm delivery', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () => _captureAndDownloadQr(boundaryKey, order['id']),
            icon: const Icon(Icons.download),
            label: const Text('Tải xuống & In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3399ff),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndDownloadQr(GlobalKey boundaryKey, int orderId) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null && kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Aura_Order_$orderId.png")
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tải nhãn mã QR thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng tải file chỉ hỗ trợ trên nền tảng Web hiện tại.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi lưu mã QR.')),
        );
      }
    }
  }

  // Analytics
  int get _totalOrders => _allOrders.length;
  int get _paidOrders => _allOrders.where((o) => o['status'] == 'PAID').length;
  int get _inTransitOrders => _allOrders.where((o) => o['status'] == 'IN_TRANSIT').length;
  int get _deliveredOrders => _allOrders.where((o) => o['status'] == 'DELIVERED').length;

  void _navigateToProducts() {
    setState(() {
      _currentView = 'PRODUCTS';
      _editingProduct = null;
    });
  }

  void _navigateToAddProduct() {
    setState(() {
      _currentView = 'PRODUCT_FORM';
      _editingProduct = null;
    });
  }

  void _handleProductEdit(Map<String, dynamic> product) {
    setState(() {
      _currentView = 'PRODUCT_FORM';
      _editingProduct = product;
    });
  }

  void _handleProductSaved() {
    setState(() {
      _currentView = 'PRODUCTS';
      _editingProduct = null;
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF3c4b64),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: const Color(0xFF303c54),
            padding: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.bottomCenter,
            child: const Text(
              'Aura Staff',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white70),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentView = 'DASHBOARD';
                _editingProduct = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.white70),
            title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentView = 'ORDERS';
                _editingProduct = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2, color: Colors.white70),
            title: const Text('Quản lý Sản phẩm', style: TextStyle(color: Colors.white)),
            onTap: _navigateToProducts,
          ),
          ListTile(
            leading: const Icon(Icons.rate_review, color: Colors.white70),
            title: const Text('Quản lý Đánh giá', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() {
                _currentView = 'COMMENTS';
                _editingProduct = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.white70),
            title: const Text('Thêm Sản phẩm', style: TextStyle(color: Colors.white)),
            onTap: _navigateToAddProduct,
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(top: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 24),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Tổng Đơn', _totalOrders.toString(), const Color(0xFF321fdb), Icons.shopping_cart),
              const SizedBox(width: 16),
              _buildStatCard('Đã thanh toán', _paidOrders.toString(), const Color(0xFF2eb85c), Icons.payment),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Đang giao', _inTransitOrders.toString(), const Color(0xFFf9b115), Icons.local_shipping),
              const SizedBox(width: 16),
              _buildStatCard('Thành công', _deliveredOrders.toString(), const Color(0xFF3399ff), Icons.check_circle),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF321fdb),
                child: Icon(Icons.inventory_2, color: Colors.white),
              ),
              title: const Text('Quản lý sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Thêm, sửa, xoá sản phẩm trong cửa hàng'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _navigateToProducts,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFf9b115),
                child: Icon(Icons.rate_review, color: Colors.white),
              ),
              title: const Text('Quản lý Đánh giá',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Duyệt, ẩn, xoá và phản hồi bình luận'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => setState(() {
                _currentView = 'COMMENTS';
                _editingProduct = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
            ),
            child: const Text('Danh sách Đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : _allOrders.isEmpty
                  ? const Center(child: Text('Không có đơn hàng nào.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: _allOrders.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final order = _allOrders[index];
                        final status = order['status'];

                        Color statusColor;
                        if (status == 'PAID') statusColor = const Color(0xFF2eb85c);
                        else if (status == 'IN_TRANSIT') statusColor = const Color(0xFFf9b115);
                        else if (status == 'DELIVERED') statusColor = const Color(0xFF3399ff);
                        else if (status == 'PENDING') statusColor = const Color(0xFF9da5b1);
                        else statusColor = const Color(0xFFe55353);

                        bool canGenerateQr = (status == 'PAID' || status == 'IN_TRANSIT' || status == 'PENDING');

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Đơn hàng #${order['id']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                                      child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Tổng: ${order['total_amount']} VND', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (canGenerateQr)
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.qr_code, size: 16),
                                        label: const Text('Mã QR'),
                                        onPressed: () => _generateDeliveryQr(order),
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
                                      ),
                                    if (canGenerateQr) const SizedBox(width: 8),
                                    if (status != 'DELIVERED' && status != 'CANCELLED')
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Đã giao'),
                                        onPressed: () => _updateOrderStatus(order['id'], 'DELIVERED'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: Size.zero),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentView) {
      case 'ORDERS':
        currentBody = _buildOrdersView();
        break;
      case 'PRODUCTS':
        currentBody = ProductListView(
          onEdit: _handleProductEdit,
          onChanged: () => setState(() {}),
        );
        break;
      case 'PRODUCT_FORM':
        currentBody = ProductFormView(
          product: _editingProduct,
          onSaved: _handleProductSaved,
        );
        break;
      case 'COMMENTS':
        currentBody = const StaffCommentsScreen();
        break;
      case 'DASHBOARD':
      default:
        currentBody = _buildDashboardView();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: _buildDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _currentView == 'PRODUCTS'
              ? 'Quản lý sản phẩm'
              : _currentView == 'PRODUCT_FORM'
                  ? (_editingProduct != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm')
                  : _currentView == 'COMMENTS'
                      ? 'Quản lý Đánh giá'
                      : 'Staff Dashboard',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_currentView == 'PRODUCT_FORM')
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              tooltip: 'Đóng',
              onPressed: () => setState(() {
                _currentView = 'PRODUCTS';
                _editingProduct = null;
              }),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              tooltip: 'Tải lại',
              onPressed: () {
                if (_currentView == 'ORDERS') {
                  _loadOrders();
                } else if (_currentView == 'DASHBOARD') {
                  _loadOrders();
                }
                // COMMENTS tự refresh nội bộ; nếu cần thì reload cả dashboard
              },
            ),
        ],
      ),
      body: currentBody,
      floatingActionButton: _currentView == 'PRODUCTS'
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddProduct,
              backgroundColor: const Color(0xFF321fdb),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Thêm sản phẩm',
                  style: TextStyle(color: Colors.white)),
            )
          : (_currentView == 'DASHBOARD' || _currentView == 'ORDERS')
              ? FloatingActionButton(
                  onPressed: _navigateToAddProduct,
                  backgroundColor: const Color(0xFF321fdb),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
    );
  }
}