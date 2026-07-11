import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class StaffCommentsScreen extends StatefulWidget {
  const StaffCommentsScreen({super.key});

  @override
  State<StaffCommentsScreen> createState() => _StaffCommentsScreenState();
}

class _StaffCommentsScreenState extends State<StaffCommentsScreen> {
  static const Color _primary = Color(0xFF321fdb);
  static const Color _bg = Color(0xFFF5F6FA);

  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  String? _error;

  // Filter
  int? _ratingFilter;
  String _searchQuery = '';
  String _visibilityFilter = 'all'; // all | visible | hidden

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hiddenOnly =
          _visibilityFilter == 'hidden' ? true : (_visibilityFilter == 'visible' ? false : null);
      final reviews = await ReviewService.getAllReviews(
        rating: _ratingFilter,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        hiddenOnly: hiddenOnly,
      );
      ReviewStats? stats;
      try {
        stats = await ReviewService.getStats();
      } catch (_) {
        // thống kê không load được thì bỏ qua
      }
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHidden(Review r) async {
    try {
      await ReviewService.setHidden(r.id, !r.isHidden);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r.isHidden ? 'Đã hiện đánh giá' : 'Đã ẩn đánh giá'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteReview(Review r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        content: Text(
            'Bạn có chắc muốn xóa đánh giá của ${r.userName}? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ReviewService.deleteReview(r.id);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa đánh giá'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showReplyDialog(Review r) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Phản hồi ${r.userName}'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung phản hồi...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (result == null || result.isEmpty) return;
    try {
      await ReviewService.staffReply(r.id, result);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi phản hồi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editReply(Review r, ReviewReply reply) async {
    final ctrl = TextEditingController(text: reply.comment);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa phản hồi'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (result == null || result.isEmpty) return;
    try {
      await ReviewService.updateReply(reply.id, result);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật phản hồi'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteReply(Review r, ReviewReply reply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa phản hồi?'),
        content: Text('Xóa phản hồi của ${reply.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ReviewService.deleteReply(reply.id);
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRepliesSheet(Review r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.forum, color: _primary),
                    const SizedBox(width: 8),
                    const Text('Phản hồi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReplyDialog(r);
                      },
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('Phản hồi'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: r.replies.isEmpty
                    ? const Center(
                        child: Text('Chưa có phản hồi nào.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: r.replies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final reply = r.replies[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: reply.isStaff
                                  ? const Color(0xFFE8F0FE)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: reply.isStaff
                                      ? _primary.withOpacity(0.3)
                                      : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: reply.isStaff
                                          ? _primary
                                          : Colors.grey.shade400,
                                      child: Text(
                                        reply.userName.isNotEmpty
                                            ? reply.userName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(reply.userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    if (reply.isStaff)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('STAFF',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          size: 18, color: Colors.black54),
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          Navigator.pop(ctx);
                                          _editReply(r, reply);
                                        } else if (v == 'delete') {
                                          Navigator.pop(ctx);
                                          _deleteReply(r, reply);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'edit', child: Text('Sửa')),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Xóa',
                                                style:
                                                    TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(reply.comment),
                                const SizedBox(height: 4),
                                Text(_formatDate(reply.createdAt),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: const Color(0xFFF9B115),
        );
      }),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm nội dung bình luận...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadAll();
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (v) {
              setState(() => _searchQuery = v);
              _loadAll();
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', null, _ratingFilter == null),
                const SizedBox(width: 6),
                ...[5, 4, 3, 2, 1].map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _filterChip('$r ★', r, _ratingFilter == r),
                    )),
                Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                _filterChip('Hiện', 'visible', _visibilityFilter == 'visible'),
                const SizedBox(width: 6),
                _filterChip('Ẩn', 'hidden', _visibilityFilter == 'hidden'),
                const SizedBox(width: 6),
                _filterChip('Tất cả trạng thái', 'all', _visibilityFilter == 'all'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(dynamic label, dynamic value, bool selected) {
    return FilterChip(
      label: Text(label.toString(), style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (value is int?) {
            _ratingFilter = value;
          } else if (value is String?) {
            _visibilityFilter = value ?? 'all';
          }
        });
        _loadAll();
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: _primary.withOpacity(0.15),
      checkmarkColor: _primary,
      side: BorderSide(
        color: selected ? _primary : Colors.grey.shade300,
        width: selected ? 1.2 : 0.6,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildReviewCard(Review r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: r.isHidden ? Colors.red.shade300 : Colors.grey.shade200,
          width: r.isHidden ? 1.2 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (r.productImage != null && r.productImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      r.productImage!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            size: 20, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      _buildStars(r.rating),
                    ],
                  ),
                ),
                if (r.isHidden)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text('Đã ẩn',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text(
                    r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(width: 6),
                Text(r.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                const Spacer(),
                Text(_formatDate(r.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            if (r.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.comment, style: const TextStyle(fontSize: 13)),
              ),
            ],
            if (r.replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showRepliesSheet(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.forum, size: 14, color: _primary),
                      const SizedBox(width: 4),
                      Text('${r.replies.length} phản hồi',
                          style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showReplyDialog(r),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Phản hồi'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleHidden(r),
                  icon: Icon(
                    r.isHidden ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: r.isHidden ? Colors.green : Colors.orange,
                  ),
                  label: Text(r.isHidden ? 'Hiện' : 'Ẩn',
                      style: TextStyle(
                          color: r.isHidden ? Colors.green : Colors.orange)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteReview(r),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  tooltip: 'Xóa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_stats != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatChip('Tổng', '${_stats!.total}', _primary),
                  const SizedBox(width: 8),
                  _buildStatChip('Hiển thị', '${_stats!.visible}', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip('Đã ẩn', '${_stats!.hidden}', Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'TB sao',
                      _stats!.avgRating.toStringAsFixed(1),
                      const Color(0xFFF9B115)),
                ],
              ),
            ),
          ),
        _buildFilters(),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 56, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadAll,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _reviews.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 56, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Chưa có đánh giá nào.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAll,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _reviews.length,
                            itemBuilder: (_, i) => _buildReviewCard(_reviews[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}