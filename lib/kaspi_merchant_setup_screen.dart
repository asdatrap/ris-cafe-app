import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kaspi_merchant_service.dart';

class KaspiMerchantSetupScreen extends StatefulWidget {
  const KaspiMerchantSetupScreen({super.key});

  @override
  State<KaspiMerchantSetupScreen> createState() => _KaspiMerchantSetupScreenState();
}

class _KaspiMerchantSetupScreenState extends State<KaspiMerchantSetupScreen> {
  final _merchantIdController = TextEditingController();
  final _secretKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    try {
      await KaspiMerchantService.initialize();
      final credentials = KaspiMerchantService.credentials;
      
      if (credentials['merchantId'] != null && credentials['secretKey'] != null) {
        setState(() {
          _merchantIdController.text = credentials['merchantId']!;
          _secretKeyController.text = credentials['secretKey']!;
          _isConfigured = true;
        });
      }
    } catch (e) {
      print('Ошибка загрузки конфигурации: $e');
    }
  }

  Future<void> _testConnection() async {
    if (_merchantIdController.text.isEmpty || _secretKeyController.text.isEmpty) {
      setState(() {
        _testResult = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      // Временно сохраняем учетные данные для теста
      await KaspiMerchantService.saveCredentials(
        _merchantIdController.text,
        _secretKeyController.text,
      );

      // Тестовый запрос к API
      // В реальном приложении здесь будет проверка соединения с Kaspi API
      await Future.delayed(const Duration(seconds: 2)); // Симуляция запроса

      setState(() {
        _testResult = '✅ Подключение успешно! Kaspi Merchant готов к работе';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Ошибка подключения: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_merchantIdController.text.isEmpty || _secretKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await KaspiMerchantService.saveCredentials(
        _merchantIdController.text,
        _secretKeyController.text,
      );

      setState(() {
        _isConfigured = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Конфигурация Kaspi Merchant сохранена'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройка Kaspi Merchant"),
        backgroundColor: const Color(0xFF2C1810),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информационная карточка
            Card(
              color: const Color(0xFFD4A574).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Color(0xFFD4A574)),
                        SizedBox(width: 8),
                        Text(
                          "Kaspi Merchant",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Для приема платежей через карты нужно зарегистрироваться в Kaspi Merchant и получить API ключи.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Инструкция по получению ключей
            const Text(
              "Как получить API ключи:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Откройте Kaspi Business\n"
                      "2. Перейдите в 'Платежи'\n"
                      "3. Выберите 'Kaspi Merchant'\n"
                      "4. Заполните заявку на подключение\n"
                      "5. Получите Merchant ID и Secret Key\n"
                      "6. Введите их в форму ниже",
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Форма настройки
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Настройка API",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _merchantIdController,
                      decoration: const InputDecoration(
                        labelText: "Merchant ID",
                        hintText: "Ваш Merchant ID от Kaspi",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _secretKeyController,
                      decoration: const InputDecoration(
                        labelText: "Secret Key",
                        hintText: "Ваш секретный ключ от Kaspi",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Кнопка тестирования
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTesting ? null : _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: _isTesting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text("Проверка..."),
                                ],
                              )
                            : const Text("Проверить подключение"),
                      ),
                    ),
                    
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!.startsWith('✅') 
                              ? Colors.green.shade50 
                              : Colors.red.shade50,
                          border: Border.all(
                            color: _testResult!.startsWith('✅') 
                                ? Colors.green.shade200 
                                : Colors.red.shade200,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testResult!.startsWith('✅') 
                                ? Colors.green.shade700 
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Кнопки сохранения
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A574),
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading
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
                              Text("Сохранение..."),
                            ],
                          )
                        : Text(_isConfigured ? "Обновить" : "Сохранить"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Отмена"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
