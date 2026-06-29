import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  bool _isLoading = false;

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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        _goToLogin();
        return;
      }

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
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFC8102E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thêm Sản Phẩm Mới',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC8102E)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockCtrl,
                  decoration: const InputDecoration(labelText: 'Số lượng kho', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Link ảnh (URL)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
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
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8102E),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Thêm Sản Phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
