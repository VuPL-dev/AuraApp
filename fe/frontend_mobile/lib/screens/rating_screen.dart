import 'package:flutter/material.dart';
import '../services/review_service.dart';

const _kPrimary = Color(0xFFC8102E);

class RatingScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const RatingScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;
  int _charCount = 0;

  final List<String> _suggestions = [
    "Sản phẩm rất đẹp",
    "Chất lượng tuyệt vời",
    "Đóng gói cẩn thận",
    "Giao hàng cực nhanh",
    "Sẽ ủng hộ shop lần sau"
  ];

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() => _charCount = _commentController.text.length);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    
    final success = await ReviewService.submitReview(
      productId: widget.productId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại sau.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm', style: TextStyle(color: Colors.white)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              widget.productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bạn thấy sản phẩm này như thế nào?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 48,
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text(
              _rating == 5 ? 'Tuyệt vời' : _rating == 4 ? 'Hài lòng' : _rating == 3 ? 'Bình thường' : _rating == 2 ? 'Kém' : 'Rất kém',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
            ),
            const SizedBox(height: 30),
            // Gợi ý bình luận
            Wrap(
              spacing: 8,
              children: _suggestions.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  _commentController.text = _commentController.text.isEmpty ? s : "${_commentController.text}, $s";
                },
              )).toList(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung đánh giá của bạn...',
                counterText: '$_charCount/250 ký tự',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gửi đánh giá', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
