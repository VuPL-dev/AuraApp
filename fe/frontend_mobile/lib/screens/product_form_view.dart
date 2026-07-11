import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../services/category_service.dart';
import '../services/token_storage.dart';
import '../utils/api_constants.dart';

class ProductFormView extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;

  const ProductFormView({super.key, this.product, required this.onSaved});

  bool get isEdit => product != null;

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p['name']?.toString() ?? '';
      _descCtrl.text = p['description']?.toString() ?? '';
      _priceCtrl.text = p['price']?.toString() ?? '';
      _stockCtrl.text = p['stock_quantity']?.toString() ?? '';
      _skuCtrl.text = p['sku']?.toString() ?? '';
      final cat = p['category'];
      if (cat is Map<String, dynamic>) {
        _selectedCategoryId = (cat['id'] as num?)?.toInt();
      }
      final images = p['images'] as List?;
      if (images != null && images.isNotEmpty) {
        _existingImageUrl = images[0]['image_url']?.toString();
      }
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.listCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh mục: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    super.dispose();
  }

  String _absUrl(String url) {
    if (url.startsWith('http')) return url;
    final base = ApiConstants.baseUrl.endsWith('/api')
        ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 4)
        : ApiConstants.baseUrl;
    return '$base$url';
  }

  String _fmtPrice(String s) {
    final num? n = num.tryParse(s);
    if (n == null) return '';
    final f = n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return f;
  }

  double? _parsePrice(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  MediaType _parseContentType(String mime) {
    final parts = mime.split('/');
    if (parts.length == 2) return MediaType(parts[0], parts[1]);
    return MediaType('image', 'jpeg');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file != null) {
        setState(() {
          _pickedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_pickedImage != null || _existingImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xoá ảnh',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _pickedImage = null;
                    _existingImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    Widget content;
    if (_pickedImage != null) {
      if (kIsWeb) {
        content = Image.network(
          _pickedImage!.path,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } else {
        content = Image.file(
          File(_pickedImage!.path),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      }
    } else if (_existingImageUrl != null) {
      content = Image.network(
        _absUrl(_existingImageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imgPlaceholder(),
      );
    } else {
      content = _imgPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh sản phẩm',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: content,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _showImageSourceSheet,
              icon: const Icon(Icons.image, size: 18),
              label: Text(_pickedImage != null || _existingImageUrl != null
                  ? 'Đổi ảnh'
                  : 'Chọn ảnh từ thiết bị'),
            ),
            if (_pickedImage != null || _existingImageUrl != null) ...[
              const Spacer(),
              Text(
                _pickedImage != null
                    ? 'Ảnh mới đã chọn'
                    : 'Ảnh hiện tại',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _imgPlaceholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 8),
              Text('Chạm để chọn ảnh',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );

  Future<String?> _uploadImage(String token) async {
    if (_pickedImage == null) return null;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/products/upload');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        final bytes = await _pickedImage!.readAsBytes();
        final mime = _pickedImage!.mimeType ?? 'image/jpeg';
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _pickedImage!.name,
          contentType: _parseContentType(mime),
        ));
      } else {
        final mime = _pickedImage!.mimeType ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _pickedImage!.path,
            filename: _pickedImage!.name,
            contentType: _parseContentType(mime),
          ),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url']?.toString();
      }
      throw Exception('Upload lỗi: ${response.body}');
    } catch (e) {
      throw Exception('Upload thất bại: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEdit && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh cho sản phẩm')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('Phiên đăng nhập đã hết');
      }

      List<String> images = [];
      if (_pickedImage != null) {
        final uploadedUrl = await _uploadImage(token);
        if (uploadedUrl != null) images = [uploadedUrl];
      } else if (_existingImageUrl != null) {
        images = [_existingImageUrl!];
      }

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': _parsePrice(_priceCtrl.text) ?? 0,
        'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
        'category_id': _selectedCategoryId,
      };
      if (_skuCtrl.text.trim().isNotEmpty) {
        body['sku'] = _skuCtrl.text.trim();
      }
      if (images.isNotEmpty) {
        body['images'] = images;
      }

      final url = widget.isEdit
          ? '${ApiConstants.baseUrl}/products/${widget.product!['id']}'
          : '${ApiConstants.baseUrl}/products';
      final response = widget.isEdit
          ? await http
              .put(Uri.parse(url), headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15))
          : await http
              .post(Uri.parse(url), headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit
                  ? 'Cập nhật sản phẩm thành công!'
                  : 'Thêm sản phẩm thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved();
        }
      } else {
        if (mounted) {
          final err = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${err['error'] ?? response.body}')),
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
                  Text(
                    widget.isEdit
                        ? 'Sửa sản phẩm #${widget.product!['id']}'
                        : 'Thêm sản phẩm mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên sản phẩm *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Giá (VND)',
                            helperText: 'Nhập số, ví dụ: 100000 → hiển thị 100.000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Bắt buộc';
                            }
                            final n = _parsePrice(val);
                            if (n == null) return 'Không hợp lệ';
                            if (n <= 0) return 'Phải > 0';
                            return null;
                          },
                          onChanged: (val) {
                            if (val.isEmpty) return;
                            final raw = val.replaceAll(RegExp(r'[^\d]'), '');
                            final n = num.tryParse(raw);
                            if (n == null) return;
                            final formatted = _fmtPrice(raw);
                            if (formatted.isNotEmpty && formatted != val) {
                              _priceCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          onEditingComplete: () {
                            final raw =
                                _priceCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                            final formatted = _fmtPrice(raw);
                            if (formatted.isNotEmpty) {
                              _priceCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng kho *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Bắt buộc';
                            final n = int.tryParse(val);
                            if (n == null || n < 0) return 'Không hợp lệ';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SKU (tùy chọn)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _loadingCategories
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      : DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: _categories
                              .map((c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategoryId = val),
                          validator: (val) =>
                              val == null ? 'Vui lòng chọn danh mục' : null,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isLoading ? null : () => widget.onSaved(),
                          icon: const Icon(Icons.close),
                          label: const Text('Huỷ'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(widget.isEdit ? 'Cập nhật' : 'Lưu sản phẩm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF321fdb),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}