import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  List<Product> _products = [
    Product(name: "Капучино", price: 109),
    Product(name: "Латте", price: 119),
    Product(name: "Эспрессо", price: 60),
    Product(name: "Чай", price: 40),
    Product(name: "Пирожное", price: 70),
  ];
  
  List<Product> _cart = [];
  List<List<Product>> _orders = [];

  List<Product> get products => _products;
  List<Product> get cart => _cart;
  List<List<Product>> get orders => _orders;

  double get cartTotal {
    return _cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  }

  void addToCart(Product product) {
    try {
      final index = _cart.indexWhere((p) => p.name == product.name);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(product.copyWith(quantity: 1));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  void increaseQuantity(Product product) {
    try {
      product.quantity++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error increasing quantity: $e');
    }
  }

  void decreaseQuantity(Product product) {
    try {
      product.quantity--;
      if (product.quantity <= 0) {
        _cart.remove(product);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error decreasing quantity: $e');
    }
  }

  void clearCart() {
    try {
      _cart.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  void placeOrder() {
    try {
      if (_cart.isEmpty) return;
      
      _orders.add(_cart.map((e) => e.copyWith()).toList());
      _cart.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error placing order: $e');
    }
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
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text("🍽 РИС"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A574).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu, size: 100, color: Color(0xFF2C1810)),
            ),
            const SizedBox(height: 40),
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
                    onPressed: () => Navigator.pop(context),
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
                          backgroundColor: const Color(0xFF2C1810),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Оформить заказ", style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          provider.placeOrder();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Заказ оформлен!"),
                              backgroundColor: Color(0xFF2C1810),
                            ),
                          );
                          Navigator.pop(context);
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
