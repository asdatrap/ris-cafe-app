import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'main.dart';

class ApiService {
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/menu'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to load products');
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  static Future<List<List<Product>>> getOrders() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Convert API response to List<List<Product>>
          final List<dynamic> ordersData = data['data'];
          return ordersData.map((orderData) {
            final List<dynamic> items = orderData['items'] ?? [];
            return items.map((item) => Product(
              name: item['name'] ?? '',
              price: (item['price'] ?? 0).toDouble(),
              quantity: item['quantity'] ?? 1,
            )).toList();
          }).toList();
        }
      }
      throw Exception('Failed to load orders');
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  static Future<void> createOrder(List<Product> cart) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final orderData = {
        'items': cart.map((item) => {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        }).toList(),
        'total': cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }
}
