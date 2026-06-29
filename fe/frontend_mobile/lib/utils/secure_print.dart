import 'package:flutter/foundation.dart';

class SecurePrint {
  static void log(String message) {
    if (kReleaseMode) {
      // Don't print in release mode at all, or print very minimally
      return;
    }
    
    // Simple masking for demonstration. In a real app, you'd use more robust regex or logic.
    String maskedMessage = message
        .replaceAll(RegExp(r'password":"[^"]+"'), 'password":"***"')
        .replaceAll(RegExp(r'token":"[^"]+"'), 'token":"***"');
        
    debugPrint(maskedMessage);
  }
}
