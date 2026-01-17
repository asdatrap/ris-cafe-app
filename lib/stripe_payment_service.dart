import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentService {
  // Тестовые ключи Stripe (бесплатно)
  static const String _publishableKey = 'pk_test_51234567890abcdef'; // Тестовый ключ
  
  // Инициализация Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }
  
  // Создание платежного намерения (Payment Intent)
  static Future<String> createPaymentIntent(double amount, String currency) async {
    // В реальном приложении здесь будет запрос к вашему бэкенду
    // Сейчас симулируем ответ сервера
    
    try {
      // Тестовые данные для платежа
      final paymentIntentData = {
        'client_secret': 'pi_test_${DateTime.now().millisecondsSinceEpoch}_secret_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(), // Stripe работает в центах
        'currency': currency.toLowerCase(),
      };
      
      return paymentIntentData['client_secret'] as String;
    } catch (e) {
      print('Ошибка создания платежа: $e');
      rethrow;
    }
  }
  
  // Обработка платежа
  static Future<bool> processPayment(double amount, {String currency = 'usd'}) async {
    try {
      // 1. Создаем Payment Intent
      final clientSecret = await createPaymentIntent(amount, currency);
      
      // 2. Для теста просто симулируем успешную оплату
      // В реальном приложении здесь будет интеграция с PaymentSheet
      await Future.delayed(const Duration(seconds: 2)); // Симуляция обработки
      
      // 3. Симулируем успешный платеж
      print('Платеж успешно обработан: $amount $currency');
      return true;
      
    } catch (e) {
      print('Ошибка обработки платежа: $e');
      return false; // Платеж не удался
    }
  }
  
  // Тестовые карты для разработки
  static List<Map<String, String>> getTestCards() {
    return [
      {
        'number': '4242424242424242',
        'expiry': '12/25',
        'cvv': '123',
        'description': 'Успешная оплата (Visa)',
      },
      {
        'number': '5555555555554444',
        'expiry': '12/25',
        'cvv': '123',
        'description': 'Успешная оплата (Mastercard)',
      },
      {
        'number': '4000000000000002',
        'expiry': '12/25',
        'cvv': '123',
        'description': 'Карта отклонена',
      },
    ];
  }
  
  // Форматирование суммы для Stripe
  static int formatAmountForStripe(double amount) {
    return (amount * 100).toInt(); // В центах
  }
  
  // Форматирование суммы для отображения
  static String formatAmountForDisplay(double amount, {String currency = '₸'}) {
    return '${amount.toStringAsFixed(0)} $currency';
  }
}
