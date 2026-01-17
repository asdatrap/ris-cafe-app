import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> testApi() async {
  try {
    print('🔄 Тест API...');
    final url = 'https://cafe-menu-vercel.vercel.app/api/menu';
    print('📡 Запрос: $url');
    
    final response = await http.get(Uri.parse(url));
    print('📊 Статус: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Данные получены:');
      print(data);
    } else {
      print('❌ Ошибка: ${response.body}');
    }
  } catch (e) {
    print('❌ Исключение: $e');
  }
}

void main() {
  testApi();
}
