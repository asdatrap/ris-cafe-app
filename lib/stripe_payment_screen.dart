import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stripe_payment_service.dart';
import 'main.dart';

class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({super.key});

  @override
  State<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      await StripePaymentService.initialize();
      print('Stripe инициализирован');
    } catch (e) {
      print('Ошибка инициализации Stripe: $e');
    }
  }

  Future<void> _processPayment() async {
    final provider = context.read<CafeProvider>();
    final total = provider.cartTotal;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await StripePaymentService.processPayment(total, currency: 'kzt');
      
      if (success) {
        setState(() {
          _paymentSuccess = true;
        });
        
        // Оформляем заказ после успешной оплаты
        provider.placeOrder();
        
        // Показываем успех
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Оплата успешно завершена!"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Возвращаемся на главный экран через 2 секунды
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка оплаты: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Оплата картой", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

          if (_paymentSuccess) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    "Оплата успешна!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Заказ оформлен",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

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
                              Text(StripePaymentService.formatAmountForDisplay(item.price * item.quantity)),
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
                              StripePaymentService.formatAmountForDisplay(provider.cartTotal),
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
                
                // Информация о платеже
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.credit_card, size: 48, color: Color(0xFFD4A574)),
                        const SizedBox(height: 16),
                        const Text(
                          "Безопасная оплата",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Все данные карт защищены Stripe",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Принимаем:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text("Visa", style: TextStyle(fontSize: 14)),
                            Text("Mastercard", style: TextStyle(fontSize: 14)),
                            Text("Kaspi", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Тестовые карты (для разработки)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🧪 Тестовые карты:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...StripePaymentService.getTestCards().map((card) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card['description']!,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "Номер: ${card['number']}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                "Срок: ${card['expiry']} CVV: ${card['cvv']}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка оплаты
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text("Обработка..."),
                            ],
                          )
                        : Consumer<CafeProvider>(
                            builder: (context, provider, _) => Text(
                              "Оплатить ${StripePaymentService.formatAmountForDisplay(provider.cartTotal)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка отмены
                TextButton(
                  onPressed: _isProcessing ? null : () {
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
}
