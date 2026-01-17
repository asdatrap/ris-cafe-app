import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSheetsService {
  static const String _spreadsheetId = '1oGxxrZku1IJjxcTDAWh_SAbRr-of6WKruJVWrtBKLPE';
  static const String _apiKey = 'AIzaSyDysiVykID5Mia3JvLaU1C-06HZHwO-1IU';
  
  // Кэширование данных
  static List<Map<String, dynamic>>? _cachedProducts;
  static DateTime? _lastUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Получение продуктов из Google Sheets
  static Future<List<Map<String, dynamic>>> getProducts({bool forceRefresh = false}) async {
    // Если принудительное обновление, очищаем кэш
    if (forceRefresh) {
      _cachedProducts = null;
      _lastUpdate = null;
    }
    
    // Проверяем кэш
    if (_cachedProducts != null && 
        _lastUpdate != null && 
        DateTime.now().difference(_lastUpdate!) < _cacheTimeout) {
      print('📦 Используем кэшированные данные');
      return _cachedProducts!;
    }

    try {
      print('🔄 Загрузка меню из Google Sheets...');
      
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId/values/Menu!A2:C?key=$_apiKey';
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['values'] != null) {
          final List<Map<String, dynamic>> products = [];
          
          for (final row in data['values']) {
            if (row.length >= 2 && row[0].toString().trim().isNotEmpty) {
              try {
                products.add({
                  'name': row[0].toString().trim(),
                  'price': double.parse(row[1].toString().replaceAll(',', '.')),
                  'description': row.length > 2 ? row[2].toString().trim() : '',
                });
              } catch (e) {
                print('⚠️ Пропускаем некорректную строку: $row');
              }
            }
          }
          
          // Сохраняем в кэш
          _cachedProducts = products;
          _lastUpdate = DateTime.now();
          
          // Сохраняем локально для оффлайн режима
          await _saveProductsLocally(products);
          
          print('✅ Загружено ${products.length} продуктов из Google Sheets');
          return products;
        }
      }
      
      throw Exception('Не удалось загрузить данные из Google Sheets');
      
    } catch (e) {
      print('❌ Ошибка загрузки из Google Sheets: $e');
      
      // Пробуем загрузить локальные данные
      final localProducts = await _loadLocalProducts();
      if (localProducts.isNotEmpty) {
        print('📱 Используем локальные данные');
        return localProducts;
      }
      
      // Возвращаем данные по умолчанию
      return _getDefaultProducts();
    }
  }

  // Сохранение продуктов локально
  static Future<void> _saveProductsLocally(List<Map<String, dynamic>> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_products', json.encode(products));
      await prefs.setString('last_update', DateTime.now().toIso8601String());
    } catch (e) {
      print('⚠️ Ошибка сохранения локальных данных: $e');
    }
  }

  // Загрузка локальных продуктов
  static Future<List<Map<String, dynamic>>> _loadLocalProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString('cached_products');
      
      if (productsJson != null) {
        final List<dynamic> data = json.decode(productsJson);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('⚠️ Ошибка загрузки локальных данных: $e');
    }
    
    return [];
  }

  // Продукты по умолчанию
  static List<Map<String, dynamic>> _getDefaultProducts() {
    return [
      {'name': 'Капучино', 'price': 109, 'description': ''},
      {'name': 'Латте', 'price': 119, 'description': ''},
      {'name': 'Эспрессо', 'price': 60, 'description': ''},
      {'name': 'Чай', 'price': 40, 'description': ''},
      {'name': 'Пирожное', 'price': 70, 'description': ''},
    ];
  }

  // Принудительное обновление (игнорируя кэш)
  static Future<List<Map<String, dynamic>>> refreshProducts() async {
    _cachedProducts = null;
    _lastUpdate = null;
    return await getProducts();
  }

  // Проверка доступности Google Sheets
  static Future<bool> isAvailable() async {
    try {
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/$_spreadsheetId?key=$_apiKey';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
