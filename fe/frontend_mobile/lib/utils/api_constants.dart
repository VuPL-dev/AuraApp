import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    // Đã đổi sang IP máy tính để có thể test trên điện thoại cùng mạng Wi-Fi
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:5000/api';
      }
      // Nếu truy cập qua localtunnel (HTTPS), dùng tunnel API để tránh lỗi mixed content
      if (host.contains('loca.lt')) {
        return 'https://auraapi.loca.lt/api';
      }
      // Nếu truy cập từ thiết bị khác trong LAN (IP có thể thay đổi)
      // Tự động lấy đúng IP mà trình duyệt đang truy cập để gọi API
      return 'http://${Uri.base.host}:5000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }
  
  static const Duration requestTimeout = Duration(seconds: 15);
}
