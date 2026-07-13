import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../services/cart_service.dart';
import '../utils/custom_snackbar.dart';
import 'cart_screen.dart';

const _kPrimary = Color(0xFFC8102E);

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    final reviews = await ReviewService.getProductReviews(widget.product['id']);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    final num p = num.tryParse(price.toString()) ?? 0;
    final formatted = p.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '${formatted}đ';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0]['image_url'] as String? : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product['name'] ?? 'Chi tiết sản phẩm', style: const TextStyle(color: Colors.white)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.contain)
                  : const Icon(Icons.image_outlined, size: 100, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product['price']),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mô tả sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(product['description'] ?? 'Không có mô tả cho sản phẩm này.', style: const TextStyle(color: Colors.black87)),
                  const Divider(height: 40),
                  
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đánh giá từ khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (!_loadingReviews) Text('${_reviews.length} đánh giá', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator(color: _kPrimary))
                  else if (_reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Chưa có đánh giá nào cho sản phẩm này.', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final r = _reviews[index];
                        final user = r['user'] ?? {};
                        final rating = r['rating'] as int? ?? 5;
                        final replies = r['replies'] as List? ?? [];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(user['full_name'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(5, (i) => Icon(
                                      i < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(r['comment'] ?? '', style: const TextStyle(fontSize: 14)),
                              Text(
                                _formatDate(r['created_at']),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              // Display replies
                              if (replies.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(left: 20, top: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: replies.map((reply) {
                                      final replyUser = reply['user'] ?? {};
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(replyUser['full_name'] ?? 'Quản trị viên', 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(reply['comment'] ?? '', style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: () {
            CartService.addToCart(product);
            CustomSnackBar.showSuccessDialog(
              context: context,
              productName: product['name'] ?? '',
              onGoToCart: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      cartItems: CartService.cartNotifier.value.map((c) => <String, dynamic>{
                        'id': c.productId,
                        'name': c.name,
                        'price': c.price,
                        'images': c.imageUrl != null ? [{'image_url': c.imageUrl}] : []
                      }).toList(),
                    ),
                  ),
                );
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Thêm vào giỏ hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _formatDate(dynamic isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate.toString());
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
