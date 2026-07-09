import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyEmail = 'user_email';

  static Future<void> saveTokens(String? accessToken, String? refreshToken, {String? email}) async {
    if (kIsWeb) {
      if (accessToken != null) html.window.localStorage[_keyAccessToken] = accessToken;
      if (refreshToken != null) html.window.localStorage[_keyRefreshToken] = refreshToken;
      if (email != null) html.window.localStorage[_keyEmail] = email;
    } else {
      if (accessToken != null) await _storage.write(key: _keyAccessToken, value: accessToken);
      if (refreshToken != null) await _storage.write(key: _keyRefreshToken, value: refreshToken);
      if (email != null) await _storage.write(key: _keyEmail, value: email);
    }
  }

  static Future<String?> getAccessToken() async {
    if (kIsWeb) return html.window.localStorage[_keyAccessToken];
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) return html.window.localStorage[_keyRefreshToken];
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<String?> getEmail() async {
    if (kIsWeb) return html.window.localStorage[_keyEmail];
    return await _storage.read(key: _keyEmail);
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_keyAccessToken);
      html.window.localStorage.remove(_keyRefreshToken);
      html.window.localStorage.remove(_keyEmail);
    } else {
      await _storage.deleteAll();
    }
  }
}
