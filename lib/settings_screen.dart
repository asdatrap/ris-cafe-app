import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'google_sheets_service.dart';
import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _spreadsheetController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spreadsheetId = prefs.getString('spreadsheet_id') ?? '';
      final apiKey = prefs.getString('api_key') ?? '';
      
      setState(() {
        _spreadsheetController.text = spreadsheetId;
        _apiKeyController.text = apiKey;
      });
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  Future<void> _testConnection() async {
    if (_spreadsheetController.text.isEmpty || _apiKeyController.text.isEmpty) {
      setState(() {
        _testResult = '❌ Заполните все поля';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final url = 'https://sheets.googleapis.com/v4/spreadsheets/${_spreadsheetController.text}/values/Menu!A2:C?key=${_apiKeyController.text}';
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['values'] != null && data['values'].isNotEmpty) {
          setState(() {
            _testResult = '✅ Подключение успешно! Найдено ${data['values'].length} товаров';
          });
        } else {
          setState(() {
            _testResult = '⚠️ Подключение есть, но лист "Menu" пуст или неверная структура';
          });
        }
      } else {
        setState(() {
          _testResult = '❌ Ошибка HTTP ${response.statusCode}: ${response.body}';
        });
      }
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
    if (_spreadsheetController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await GoogleSheetsService.setConfig(
        _spreadsheetController.text.trim(),
        _apiKeyController.text.trim(),
      );

      // Перезагружаем данные
      if (context.mounted) {
        final provider = context.read<CafeProvider>();
        await provider.refreshMenu();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Конфигурация сохранена!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text("Настройки"),
        backgroundColor: const Color(0xFF2C1810),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Настройка Google Sheets',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      '1. Создайте новую Google Таблицу\n'
                      '2. Назовите первый лист "Menu"\n'
                      '3. В первой строке укажите заголовки: Название | Цена | Описание\n'
                      '4. Начиная со второй строки добавьте ваши блюда',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      '5. Получите API ключ:\n'
                      '   • Перейдите в Google Cloud Console\n'
                      '   • Создайте новый проект\n'
                      '   • Включите Google Sheets API\n'
                      '   • Создайте API ключ\n'
                      '   • Сделайте таблицу публичной',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Конфигурация',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _spreadsheetController,
                      decoration: const InputDecoration(
                        labelText: 'ID таблицы (из URL)',
                        hintText: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.table_chart),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API ключ',
                        hintText: 'AIzaSy...your-api-key',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    
                    if (_testResult != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!.contains('✅') 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testResult!.contains('✅') 
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(_testResult!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTesting ? null : _testConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: _isTesting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Проверить подключение'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C1810),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Сохранить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Пример таблицы:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Название     | Цена  | Описание\n'
                        'Капучино    | 120   | Классический\n'
                        'Латте       | 140   | С молоком\n'
                        'Эспрессо    | 80    | Крепкий\n'
                        'Чай зеленый | 60    | Ароматный',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
