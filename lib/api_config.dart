import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String? _cachedBaseUrl;
  
  // Получение базового URL
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('server_url');
      
      // Если есть сохраненный URL, используем его
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _cachedBaseUrl = savedUrl;
        return _cachedBaseUrl!;
      }
      
      // Пробуем облачный сервер первым
      final cloudUrls = [
        'https://cafe-menu-vercel.vercel.app/api',  // Ваш реальный Vercel URL
        'http://localhost:3001/api',  // Локальный сервер меню
      ];
      
      // Проверяем облачные URL
      for (String url in cloudUrls) {
        if (await _testConnection(url)) {
          _cachedBaseUrl = url;
          await prefs.setString('server_url', url);
          return _cachedBaseUrl!;
        }
      }
      
      // Если облако не работает, пробуем локальные IP
      final localIPs = [
        'http://192.168.0.106:3000/api',  // Ваш текущий IP
        'http://192.168.1.100:3000/api',  // Домашний
        'http://localhost:3000/api',       // Локальный
      ];
      
      for (String url in localIPs) {
        if (await _testConnection(url)) {
          _cachedBaseUrl = url;
          await prefs.setString('server_url', url);
          return _cachedBaseUrl!;
        }
      }
      
      // Fallback
      _cachedBaseUrl = 'https://cafe-api.onrender.com/api';
      return _cachedBaseUrl!;
      
    } catch (e) {
      _cachedBaseUrl = 'https://cafe-api.onrender.com/api';
      return _cachedBaseUrl!;
    }
  }
  
  // Проверка подключения к URL
  static Future<bool> _testConnection(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$url/menu'));
      request.headers.set('Connection', 'close');
      final response = await request.close().timeout(Duration(seconds: 3));
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Установка кастомного URL
  static Future<void> setCustomUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', url);
      clearCache();
    } catch (e) {
      print('Error saving custom URL: $e');
    }
  }
  
  // Очистка кэша
  static void clearCache() {
    _cachedBaseUrl = null;
  }
}
