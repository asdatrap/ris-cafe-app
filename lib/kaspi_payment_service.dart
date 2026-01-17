import 'package:flutter/material.dart';

class KaspiPaymentService {
  // Ваш номер телефона Kaspi (для перевода)
  static const String _kaspiPhone = '+77714465741';
  
  // Генерация ссылки для Kaspi Pay
  static String generateKaspiPayUrl(double amount, String description) {
    // Kaspi Pay URL формат
    return 'https://kaspi.kz/pay/?phone=$_kaspiPhone&amount=${amount.toStringAsFixed(2)}&description=${Uri.encodeComponent(description)}';
  }
  
  // Генерация QR-кода для оплаты
  static String generatePaymentQrData(double amount, String description) {
    // Для Kaspi Pay используем специальный формат
    return 'kaspi://payment?phone=$_kaspiPhone&amount=${amount.toStringAsFixed(2)}&description=${Uri.encodeComponent(description)}';
  }
  
  // Форматирование суммы для отображения
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} ₸';
  }
  
  // Проверка корректности номера телефона
  static bool isValidKaspiPhone(String phone) {
    // Базовая проверка казахстанского номера
    return RegExp(r'^\+7[0-9]{10}$').hasMatch(phone);
  }
  
  // Обновление номера телефона (для настроек)
  static Future<void> updateKaspiPhone(String phone) async {
    // TODO: Сохранение в SharedPreferences
    print('Обновлен номер Kaspi: $phone');
  }
}
