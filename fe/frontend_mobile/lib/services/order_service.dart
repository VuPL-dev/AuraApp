import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../utils/secure_print.dart';
import 'token_storage.dart';

class OrderService {
  static Future<List<dynamic>> getOrders() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      return [];
    } catch (e) {
      SecurePrint.log('Get orders error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      SecurePrint.log('Get order by id error: $e');
      return null;
    }
  }
}
