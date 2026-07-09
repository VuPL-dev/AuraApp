import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api'; // Android Emulator alias for host loopback
    }
    return 'http://localhost:5000/api'; // iOS Simulator and others
  }
  
  static const Duration requestTimeout = Duration(seconds: 15);
}
