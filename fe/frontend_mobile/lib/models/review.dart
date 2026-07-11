class ReviewReply {
  final int id;
  final int reviewId;
  final int userId;
  final String userName;
  final String? userRole;
  final String comment;
  final DateTime createdAt;

  const ReviewReply({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userName,
    this.userRole,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?) ?? const {};
    return ReviewReply(
      id: (json['id'] as num).toInt(),
      reviewId: (json['review_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: user['full_name']?.toString() ?? 'Người dùng',
      userRole: user['role']?.toString(),
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isStaff => userRole == 'STAFF' || userRole == 'ADMIN';
}

class Review {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int userId;
  final String userName;
  final String? userEmail;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;
  final DateTime? hiddenAt;
  final List<ReviewReply> replies;

  const Review({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isHidden,
    this.hiddenAt,
    required this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map?) ?? const {};
    final product = (json['product'] as Map?) ?? const {};
    final productImages = (product['images'] as List?) ?? const [];
    String? firstImage;
    if (productImages.isNotEmpty) {
      firstImage = (productImages.first as Map?)?['image_url']?.toString();
    }
    final repliesList = (json['replies'] as List?) ?? const [];
    return Review(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      productName: product['name']?.toString() ?? 'Sản phẩm',
      productImage: firstImage,
      userId: (json['user_id'] as num).toInt(),
      userName: user['full_name']?.toString() ?? 'Khách hàng',
      userEmail: user['email']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isHidden: json['is_hidden'] == true,
      hiddenAt: json['hidden_at'] != null
          ? DateTime.tryParse(json['hidden_at'].toString())
          : null,
      replies: repliesList
          .map((e) => ReviewReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReviewStats {
  final int total;
  final int hidden;
  final int visible;
  final double avgRating;
  final Map<String, int> distribution;

  const ReviewStats({
    required this.total,
    required this.hidden,
    required this.visible,
    required this.avgRating,
    required this.distribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    final dist = (json['distribution'] as Map?) ?? const {};
    return ReviewStats(
      total: (json['total'] as num).toInt(),
      hidden: (json['hidden'] as num).toInt(),
      visible: (json['visible'] as num).toInt(),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      distribution: dist.map((k, v) => MapEntry(
            k.toString(),
            (v as num).toInt(),
          )),
    );
  }
}
