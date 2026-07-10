import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
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

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _currentView = 'DASHBOARD'; // DASHBOARD, ADD_PRODUCT, ORDERS

  // Product Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  bool _isLoadingProduct = false;
  
  // Orders
  List<dynamic> _allOrders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoadingProduct = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final body = {
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
        'images': _imageUrlCtrl.text.isNotEmpty ? [_imageUrlCtrl.text] : [],
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm sản phẩm thành công!'), backgroundColor: Colors.green),
          );
          _formKey.currentState!.reset();
          _nameCtrl.clear();
          _descCtrl.clear();
          _priceCtrl.clear();
          _stockCtrl.clear();
          _imageUrlCtrl.clear();
          setState(() => _currentView = 'DASHBOARD');
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${response.body}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingProduct = false);
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
        final anchor = html.AnchorElement(href: url)
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
  int get _pendingOrders => _allOrders.where((o) => o['status'] == 'PENDING').length;
  int get _paidOrders => _allOrders.where((o) => o['status'] == 'PAID').length;
  int get _inTransitOrders => _allOrders.where((o) => o['status'] == 'IN_TRANSIT').length;
  int get _deliveredOrders => _allOrders.where((o) => o['status'] == 'DELIVERED').length;

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
              setState(() => _currentView = 'DASHBOARD');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.white70),
            title: const Text('Quản lý Đơn hàng', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _currentView = 'ORDERS');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.white70),
            title: const Text('Thêm Sản phẩm', style: TextStyle(color: Colors.white)),
            onTap: () {
              setState(() => _currentView = 'ADD_PRODUCT');
              Navigator.pop(context);
            },
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
        ],
      ),
    );
  }

  Widget _buildAddProductView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm Sản Phẩm Mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockCtrl,
                    decoration: const InputDecoration(labelText: 'Số lượng kho', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Link ảnh (URL)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoadingProduct ? null : _submitProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF321fdb),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoadingProduct 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Lưu Sản Phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                        if (status == 'PAID') statusColor = const Color(0xFF2eb85c); // Success
                        else if (status == 'IN_TRANSIT') statusColor = const Color(0xFFf9b115); // Warning
                        else if (status == 'DELIVERED') statusColor = const Color(0xFF3399ff); // Info
                        else if (status == 'PENDING') statusColor = const Color(0xFF9da5b1); // Secondary
                        else statusColor = const Color(0xFFe55353); // Danger (CANCELLED)

                        bool canGenerateQr = (status == 'PAID' || status == 'IN_TRANSIT' || status == 'PENDING');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.receipt_long, color: Colors.black54),
                          ),
                          title: Text(
                            'Đơn hàng #${order['id']}', 
                            style: const TextStyle(fontWeight: FontWeight.w600)
                          ),
                          subtitle: Text('Tổng: ${order['total_amount']} VND', style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (canGenerateQr)
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: Colors.black87),
                                  tooltip: 'Tạo Mã QR Giao Hàng',
                                  onPressed: () => _generateDeliveryQr(order),
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

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentView) {
      case 'ADD_PRODUCT':
        currentBody = _buildAddProductView();
        break;
      case 'ORDERS':
        currentBody = _buildOrdersView();
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
        title: const Text('Staff Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: currentBody,
      floatingActionButton: _currentView == 'DASHBOARD' || _currentView == 'ORDERS'
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _currentView = 'ADD_PRODUCT');
              },
              backgroundColor: const Color(0xFF321fdb),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
