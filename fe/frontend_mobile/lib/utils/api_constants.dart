import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    // Đã đổi sang IP máy tính để có thể test trên điện thoại cùng mạng Wi-Fi
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.88.51:5000/api';
    }
    return 'http://192.168.88.51:5000/api';
  }
  
  static const Duration requestTimeout = Duration(seconds: 15);
}
