import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'token_storage.dart';

class ReviewService {
  static Future<bool> submitReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'rating': rating,
          'comment': comment,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reviews/product/$productId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  static Future<bool> submitReply({
    required int reviewId,
    required String comment,
  }) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reviews/$reviewId/reply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'comment': comment,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting reply: $e');
      return false;
    }
  }
}
