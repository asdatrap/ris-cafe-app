import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'kaspi_payment_service.dart';
import 'main.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Оплата", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C1810),
        foregroundColor: Colors.white,
      ),
      body: Consumer<CafeProvider>(
        builder: (context, provider, child) {
          if (provider.cart.isEmpty) {
            return const Center(
              child: Text(
                "Корзина пуста",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final total = provider.cartTotal;
          final orderDescription = "Заказ РИС #${DateTime.now().millisecondsSinceEpoch}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Информация о заказе
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ваш заказ:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...provider.cart.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item.name} x${item.quantity}"),
                              Text(KaspiPaymentService.formatAmount(item.price * item.quantity)),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Итого:",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              KaspiPaymentService.formatAmount(total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C1810),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // QR-код
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Отсканируйте QR-код",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "для оплаты через Kaspi Pay",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: QrImageView(
                            data: KaspiPaymentService.generatePaymentQrData(total, orderDescription),
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "1. Otkryte prilozhenie Kaspi\n2. Nazhmite \"Oplatit po QR-kodu\"\n3. Navedite kameru na kod",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка подтверждения
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showPaymentConfirmation(context, provider, total);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Я оплатил(а)",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка отмены
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Назад в корзину",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context, CafeProvider provider, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Подтверждение оплаты"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Вы действительно оплатили заказ?"),
            const SizedBox(height: 8),
            Text(
              "Сумма: ${KaspiPaymentService.formatAmount(total)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Нет"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.placeOrder();
              Navigator.pop(context); // Закрыть диалог
              Navigator.pop(context); // Вернуться на главный экран
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Заказ успешно оформлен!"),
                  backgroundColor: Color(0xFF2C1810),
                ),
              );
            },
            child: const Text("Да, оплатил(а)"),
          ),
        ],
      ),
    );
  }
}
