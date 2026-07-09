import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../utils/secure_print.dart';
import 'token_storage.dart';

class NotificationService {
  static Future<List<dynamic>> getNotifications({bool unreadOnly = true}) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications?unread=$unreadOnly'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      return [];
    } catch (e) {
      SecurePrint.log('Get notifications error: $e');
      return [];
    }
  }

  static Future<bool> markRead(int notificationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      SecurePrint.log('Mark notification read error: $e');
      return false;
    }
  }

  static Future<bool> markAllRead() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConstants.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      SecurePrint.log('Mark all notifications read error: $e');
      return false;
    }
  }
}
