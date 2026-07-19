import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review.dart';
import '../utils/api_constants.dart';
import 'token_storage.dart';

class ReviewService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ===== Public (customer) =====

  /// Lấy review theo sản phẩm (kèm replies) - public
  static Future<List<dynamic>> getProductReviews(dynamic productId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/product/$productId');
    final res = await http
        .get(uri)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List;
    }
    return [];
  }

  /// Khách gửi review mới
  static Future<bool> submitReview({
    required dynamic productId,
    required int rating,
    required String comment,
  }) async {
    final headers = await _headers();
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/reviews'),
          headers: headers,
          body: jsonEncode({
            'product_id': productId,
            'rating': rating,
            'comment': comment,
          }),
        )
        .timeout(_timeout);
    return res.statusCode == 201;
  }

  /// Khách trả lời 1 review
  static Future<bool> submitReply({
    required int reviewId,
    required String comment,
  }) async {
    final headers = await _headers();
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId/reply'),
          headers: headers,
          body: jsonEncode({'comment': comment}),
        )
        .timeout(_timeout);
    return res.statusCode == 201;
  }

  // ===== Staff =====

  /// Lấy tất cả review cho staff dashboard.
  /// [hiddenOnly] = true: chỉ review đã ẩn; false/null: tất cả
  static Future<List<Review>> getAllReviews({
    int? rating,
    int? productId,
    String? search,
    bool? hiddenOnly,
  }) async {
    final query = <String, String>{};
    if (rating != null) query['rating'] = rating.toString();
    if (productId != null) query['productId'] = productId.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (hiddenOnly != null) {
      query['hiddenOnly'] = hiddenOnly.toString();
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/staff/all')
        .replace(queryParameters: query.isEmpty ? null : query);
    final headers = await _headers();
    final res = await http.get(uri, headers: headers).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return data
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Không thể tải danh sách đánh giá (HTTP ${res.statusCode})');
  }

  static Future<ReviewStats> getStats() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/staff/stats');
    final headers = await _headers();
    final res = await http.get(uri, headers: headers).timeout(_timeout);

    if (res.statusCode == 200) {
      return ReviewStats.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Không thể tải thống kê (HTTP ${res.statusCode})');
  }

  static Future<void> setHidden(int reviewId, bool hidden) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId/hide');
    final headers = await _headers();
    final res = await http
        .patch(
          uri,
          headers: headers,
          body: jsonEncode({'hidden': hidden}),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Cập nhật thất bại (HTTP ${res.statusCode})');
    }
  }

  static Future<void> deleteReview(int reviewId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId');
    final headers = await _headers();
    final res = await http.delete(uri, headers: headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Xóa thất bại (HTTP ${res.statusCode})');
    }
  }

  static Future<ReviewReply> staffReply(int reviewId, String comment) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId/staff-reply');
    final headers = await _headers();
    final res = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'comment': comment}),
        )
        .timeout(_timeout);

    if (res.statusCode == 201) {
      return ReviewReply.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Gửi phản hồi thất bại (HTTP ${res.statusCode})');
  }

  static Future<ReviewReply> updateReply(int replyId, String comment) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/reviews/replies/$replyId');
    final headers = await _headers();
    final res = await http
        .patch(
          uri,
          headers: headers,
          body: jsonEncode({'comment': comment}),
        )
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return ReviewReply.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Cập nhật phản hồi thất bại (HTTP ${res.statusCode})');
  }

  static Future<void> deleteReply(int replyId) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/reviews/replies/$replyId');
    final headers = await _headers();
    final res = await http.delete(uri, headers: headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Xóa phản hồi thất bại (HTTP ${res.statusCode})');
    }
  }
}
