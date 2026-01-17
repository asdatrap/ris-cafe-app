import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_sheets_service.dart';
import 'payment_screen.dart';
import 'stripe_payment_screen.dart';

void main() {
  runApp(const CafeApp());
}

// --------------------------- Модель продукта ---------------------------
class Product {
  final String name;
  final double price;
  int quantity;

  Product({
    required this.name,
    required this.price,
    this.quantity = 0,
  });

  Product.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        price = (json['price'] ?? 0).toDouble(),
        quantity = 0;

  Product copyWith({int? quantity}) {
    return Product(
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

// --------------------------- State Management ---------------------------
class CafeProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _cart = [];
  List<List<Product>> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get cart => _cart;
  List<List<Product>> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cartTotal {
    return _cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  }

  CafeProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await Future.wait([
        _loadProducts(),
        _loadOrders(),
      ]);
      
      // Запускаем периодическое обновление
      _startPeriodicUpdates();
    } catch (e) {
      _error = 'Ошибка загрузки данных: $e';
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    try {
      print('🔄 Загрузка продуктов...');
      // Принудительно загружаем свежие данные при первом запуске
      final products = await GoogleSheetsService.getProducts(forceRefresh: true);
      print('✅ Получено продуктов: ${products.length}');
      _products = products.map((json) { 
        print('📦 Продукт: ${json['name']} - ${json['price']}₽'); 
        return Product.fromJson(json); 
      }).toList();
      print('🎯 Всего продуктов в списке: ${_products.length}');
      notifyListeners();
      print('✅ Продукты загружены успешно!');
    } catch (e) {
      print('❌ Ошибка загрузки продуктов: $e');
      // Если ошибка, используем локальные данные
      if (_products.isEmpty) {
        print('🔄 Используем локальные данные...');
        _products = [
          Product(name: 'Капучино', price: 109),
          Product(name: 'Латте', price: 119),
          Product(name: 'Эспрессо', price: 60),
          Product(name: 'Чай', price: 40),
          Product(name: 'Пирожное', price: 70),
        ];
        notifyListeners();
      }
    }
  }

  Future<void> _loadOrders() async {
    try {
      debugPrint('Loading orders from local storage...');
      // Пока загружаем заказы локально, можно добавить синхронизацию позже
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('orders');
      
      if (ordersJson != null) {
        final List<dynamic> ordersData = json.decode(ordersJson);
        _orders = ordersData.map((orderData) {
          final List<dynamic> items = orderData['items'] ?? [];
          return items.map((item) => Product(
            name: item['name'] ?? '',
            price: (item['price'] ?? 0).toDouble(),
            quantity: item['quantity'] ?? 1,
          )).toList();
        }).toList();
      }
      
      debugPrint('Loaded ${_orders.length} orders');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  void _startPeriodicUpdates() {
    // Обновляем меню каждые 5 минут
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadProducts();
    });
  }

  Future<void> refreshMenu() async {
    await _loadProducts();
  }

  void addToCart(Product product) {
    final index = _cart.indexWhere((p) => p.name == product.name);
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(product.copyWith(quantity: 1));
    }
    notifyListeners();
  }

  void increaseQuantity(Product product) {
    product.quantity++;
    notifyListeners();
  }

  void decreaseQuantity(Product product) {
    product.quantity--;
    if (product.quantity <= 0) {
      _cart.remove(product);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> placeOrder() async {
    if (_cart.isEmpty) return;
    
    _orders.add(List.from(_cart));
    
    // Сохраняем заказы локально
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersData = _orders.map((order) => {
        'items': order.map((item) => {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
        }).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      }).toList();
      await prefs.setString('orders', json.encode(ordersData));
    } catch (e) {
      debugPrint('Error saving orders: $e');
    }
    
    _cart.clear();
    notifyListeners();
  }

  int getCartQuantity(Product product) {
    final index = _cart.indexWhere((p) => p.name == product.name);
    return index >= 0 ? _cart[index].quantity : 0;
  }

  double getOrderTotal(List<Product> order) {
    return order.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  }
}

// --------------------------- Приложение -------------------------------
class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CafeProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'РИС',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          scaffoldBackgroundColor: const Color(0xFFF5F5DC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2C1810),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A574),
              foregroundColor: Colors.black,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// --------------------------- Главный экран -----------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("РИС", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Consumer<CafeProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: provider.isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: () async {
                  await provider.refreshMenu();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Меню обновлено"),
                        backgroundColor: Color(0xFF2C1810),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            _menuButton(context, "Меню", const MenuScreen(), Icons.restaurant_menu),
            const SizedBox(height: 16),
            _menuButton(context, "Корзина", const CartScreen(), Icons.shopping_cart),
            const SizedBox(height: 16),
            _menuButton(context, "Мои заказы", const OrdersScreen(), Icons.receipt),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext context, String title, Widget screen, IconData icon) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// --------------------------- Экран меню --------------------------------
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Меню"),
      ),
      body: Consumer<CafeProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.products.length,
            itemBuilder: (_, index) {
              final product = provider.products[index];
              final quantity = provider.getCartQuantity(product);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${product.price.toStringAsFixed(0)} ₸",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (quantity > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "В корзине: $quantity",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A574),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text("Добавить"),
                        onPressed: () {
                          provider.addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${product.name} добавлен в корзину"),
                              duration: const Duration(seconds: 1),
                              backgroundColor: const Color(0xFF2C1810),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --------------------------- Экран корзины -----------------------------
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Корзина"),
      ),
      body: Consumer<CafeProvider>(
        builder: (context, provider, _) {
          if (provider.cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Корзина пуста",
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                    child: const Text("Перейти в меню"),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cart.length,
                  itemBuilder: (_, index) {
                    final item = provider.cart[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${item.price.toStringAsFixed(0)} ₸ за шт.",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => provider.decreaseQuantity(item),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => provider.increaseQuantity(item),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "${(item.price * item.quantity).toStringAsFixed(0)} ₸",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C1810),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Итого:",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${provider.cartTotal.toStringAsFixed(0)} ₸",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A574),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Оплатить", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _showPaymentMethodDialog(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выберите способ оплаты"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code, color: Color(0xFFD4A574)),
              title: const Text("Kaspi QR-код"),
              subtitle: const Text("Отсканируйте через Kaspi приложение"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFFD4A574)),
              title: const Text("Банковская карта"),
              subtitle: const Text("Visa, Mastercard, Kaspi (тестовый режим)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StripePaymentScreen()),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
        ],
      ),
    );
  }
}

// --------------------------- Экран заказов -----------------------------
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Мои заказы"),
      ),
      body: Consumer<CafeProvider>(
        builder: (context, provider, _) {
          if (provider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "Пока нет заказов",
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.orders.length,
            itemBuilder: (_, index) {
              final order = provider.orders[index];
              final total = provider.getOrderTotal(order);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    "Заказ №${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${order.length} ${order.length == 1 ? 'товар' : order.length < 4 ? 'товара' : 'товаров'}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    "${total.toStringAsFixed(0)} ₸",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C1810),
                      fontSize: 16,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: order.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${item.name} x${item.quantity}"),
                                Text("${(item.price * item.quantity).toStringAsFixed(0)} ₸"),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
