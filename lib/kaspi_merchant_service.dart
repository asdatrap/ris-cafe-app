import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KaspiMerchantService {
  // Kaspi Merchant API конфигурация
  static const String _baseUrl = 'https://kaspi.kz/merchant/api';
  static String? _merchantId;
  static String? _secretKey;
  
  // Инициализация сервиса
  static Future<void> initialize() async {
    await _loadCredentials();
  }
  
  // Загрузка учетных данных
  static Future<void> _loadCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _merchantId = prefs.getString('kaspi_merchant_id');
      _secretKey = prefs.getString('kaspi_secret_key');
    } catch (e) {
      print('Ошибка загрузки учетных данных Kaspi: $e');
    }
  }
  
  // Сохранение учетных данных
  static Future<void> saveCredentials(String merchantId, String secretKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kaspi_merchant_id', merchantId);
      await prefs.setString('kaspi_secret_key', secretKey);
      
      _merchantId = merchantId;
      _secretKey = secretKey;
      
      print('Учетные данные Kaspi сохранены');
    } catch (e) {
      print('Ошибка сохранения учетных данных Kaspi: $e');
    }
  }
  
  // Создание платежа
  static Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String description,
    required String customerPhone,
    String? customerEmail,
  }) async {
    if (_merchantId == null || _secretKey == null) {
      throw Exception('Kaspi Merchant не настроен');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
          'X-Merchant-Id': _merchantId!,
        },
        body: json.encode({
          'amount': amount,
          'currency': 'KZT',
          'description': description,
          'customer': {
            'phone': customerPhone,
            'email': customerEmail,
          },
          'return_url': 'ris://payment-success',
          'cancel_url': 'ris://payment-cancel',
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка создания платежа: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка запроса к Kaspi API: $e');
    }
  }
  
  // Привязка карты клиента
  static Future<Map<String, dynamic>> bindCard({
    required String customerId,
    required String cardToken,
  }) async {
    if (_merchantId == null || _secretKey == null) {
      throw Exception('Kaspi Merchant не настроен');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/$customerId/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
          'X-Merchant-Id': _merchantId!,
        },
        body: json.encode({
          'card_token': cardToken,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка привязки карты: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка запроса к Kaspi API: $e');
    }
  }
  
  // Оплата привязанной картой
  static Future<Map<String, dynamic>> payWithSavedCard({
    required String customerId,
    required String cardId,
    required double amount,
    required String description,
  }) async {
    if (_merchantId == null || _secretKey == null) {
      throw Exception('Kaspi Merchant не настроен');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/$customerId/cards/$cardId/charge'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_secretKey',
          'X-Merchant-Id': _merchantId!,
        },
        body: json.encode({
          'amount': amount,
          'currency': 'KZT',
          'description': description,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка оплаты картой: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка запроса к Kaspi API: $e');
    }
  }
  
  // Получение списка привязанных карт
  static Future<List<Map<String, dynamic>>> getCustomerCards(String customerId) async {
    if (_merchantId == null || _secretKey == null) {
      throw Exception('Kaspi Merchant не настроен');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customers/$customerId/cards'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'X-Merchant-Id': _merchantId!,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['cards'] ?? []);
      } else {
        throw Exception('Ошибка получения карт: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка запроса к Kaspi API: $e');
    }
  }
  
  // Проверка статуса платежа
  static Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    if (_merchantId == null || _secretKey == null) {
      throw Exception('Kaspi Merchant не настроен');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'X-Merchant-Id': _merchantId!,
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка проверки статуса: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка запроса к Kaspi API: $e');
    }
  }
  
  // Форматирование суммы
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} ₸';
  }
  
  // Проверка настроенности
  static bool get isConfigured => _merchantId != null && _secretKey != null;
  
  // Получение информации о мерчанте
  static Map<String, String?> get credentials => {
    'merchantId': _merchantId,
    'secretKey': _secretKey,
  };
}
