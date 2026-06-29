import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../utils/api_constants.dart';
import '../utils/secure_print.dart';
import 'token_storage.dart';

class AuthService {
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      SecurePrint.log('Calling login API for: ${request.email}');
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return LoginResponse(
            success: false, message: data['message'] ?? 'Login failed');
      }
    } catch (e) {
      SecurePrint.log('Login error: $e');
      return LoginResponse(
          success: false, message: 'Connection error or timeout');
    }
  }

  static Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      SecurePrint.log('Calling register API for: ${request.email}');
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RegisterResponse.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return RegisterResponse(
            success: false, message: data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      SecurePrint.log('Register error: $e');
      return RegisterResponse(
          success: false, message: 'Connection error or timeout');
    }
  }

  static Future<bool> verifyEmail(VerifyEmailRequest request) async {
    try {
      SecurePrint.log('Calling verify-email API for: ${request.email}');
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/verify-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      SecurePrint.log('Verify Email error: $e');
      return false;
    }
  }

  static Future<bool> resendVerifyEmail(String email) async {
    try {
      SecurePrint.log('Calling resend-verify-email API for: $email');
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/resend-verification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      SecurePrint.log('Resend verify email error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(ApiConstants.requestTimeout);
      }
    } catch (e) {
      SecurePrint.log('Logout error: $e');
    } finally {
      await TokenStorage.clearAll();
    }
  }
}
