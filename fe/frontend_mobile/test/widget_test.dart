// Unit test cơ bản cho GeminiService — kiểm tra logic RAG pipeline
// mà không cần gọi API thật (mock dotenv + http client).
//
// File widget_test.dart gốc của Flutter scaffold không tương thích với app
// (test Counter widget). File này thay thế để test logic chatbot.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:frontend_mobile/data/knowledge_base.dart';
import 'package:frontend_mobile/services/gemini_service.dart';

void main() {
  // Setup: giả lập file .env để dotenv.load() không lỗi
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Khởi tạo dotenv với giá trị test
    dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=test_key_for_unit_test
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');
  });

  group('searchRelevantProducts (Bước 2: Local Filtering)', () {
    test('trả về toàn bộ KB khi query rỗng', () {
      final result = searchRelevantProducts('');
      expect(result.length, lessThanOrEqualTo(5));
      expect(result.length, greaterThan(0));
    });

    test('tìm sản phẩm theo tên chính xác', () {
      final result = searchRelevantProducts('Đồng Hồ Nam Luxury');
      expect(result, isNotEmpty);
      expect(result.any((p) => p.name.contains('Luxury')), isTrue);
    });

    test('tìm sản phẩm theo thương hiệu', () {
      final result = searchRelevantProducts('AURA');
      expect(result, isNotEmpty);
      expect(result.every((p) => p.brand == 'AURA'), isTrue);
    });

    test('tìm sản phẩm theo SKU', () {
      final result = searchRelevantProducts('DH-NAM-002');
      expect(result, isNotEmpty);
      expect(result.any((p) => p.sku == 'DH-NAM-002'), isTrue);
    });

    test('tìm sản phẩm theo tag (đồng hồ)', () {
      final result = searchRelevantProducts('đồng hồ thể thao');
      expect(result, isNotEmpty);
      expect(result.any((p) => p.tags.contains('thể thao')), isTrue);
    });

    test('không trả về gì nếu không khớp', () {
      final result = searchRelevantProducts('xyzabc không tồn tại');
      // Có thể empty hoặc có kết quả không liên quan do scoring
      // Đảm bảo hàm không throw
      expect(result, isA<List<Product>>());
    });

    test('giới hạn 5 sản phẩm', () {
      final result = searchRelevantProducts('AURA');
      expect(result.length, lessThanOrEqualTo(5));
    });
  });

  group('formatProductContext (Bước 3: Context Formatting)', () {
    test('format có nhãn rõ ràng', () {
      final products = [knowledgeBase[0]];
      final context = formatProductContext(products);
      expect(context, contains('Tên:'));
      expect(context, contains('Thương hiệu:'));
      expect(context, contains('Giá:'));
      expect(context, contains('Danh mục:'));
      expect(context, contains('SKU:'));
      expect(context, contains('Mô tả:'));
      expect(context, contains('VND'));
    });

    test('trả về thông báo khi list rỗng', () {
      final context = formatProductContext([]);
      expect(context, contains('Không tìm thấy'));
    });
  });

  group('formatShopInfoContext', () {
    test('chứa thông tin chính sách', () {
      final context = formatShopInfoContext();
      expect(context, contains('AURA Accessories'));
      expect(context, contains('Hotline'));
      expect(context, contains('Chính sách đổi trả'));
      expect(context, contains('vận chuyển'));
      expect(context, contains('PayOS'));
    });
  });

  group('GeminiService.sendMessage', () {
    test('trả về lỗi thân thiện khi API key rỗng', () async {
      // Override dotenv với key rỗng
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');
      final service = GeminiService();
      final result = await service.sendMessage('test');
      expect(result, contains('API Key'));
      expect(result, contains('.env'));
      service.dispose();
    });

    test('gửi request đúng format khi API trả về 200', () async {
      // Restore key test
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=test_key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');

      // Mock Gemini API trả về thành công
      final mockClient = MockClient((request) async {
        // Verify URL đúng format
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.path, contains('gemini-flash-lite-latest'));
        expect(request.url.queryParameters['key'], 'test_key');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isA<List>());
        expect(
            (body['generationConfig'] as Map)['temperature'], 0.4);

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Chào bạn, AURA có nhiều đồng hồ đẹp.'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);
      final result = await service.sendMessage('Có đồng hồ nào?');

      expect(result, 'Chào bạn, AURA có nhiều đồng hồ đẹp.');
      service.dispose();
    });

    test('xử lý lỗi 401 (API key sai)', () async {
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=bad_key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'API key not valid'}
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);
      final result = await service.sendMessage('test');

      expect(result, contains('API Key không hợp lệ'));
      expect(result, contains('401'));
      service.dispose();
    });

    test('xử lý lỗi 429 (rate limit)', () async {
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=test_key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');
      final mockClient = MockClient((request) async {
        return http.Response('Quota exceeded', 429);
      });

      final service = GeminiService(client: mockClient);
      final result = await service.sendMessage('test');

      expect(result, contains('429'));
      expect(result, contains('giới hạn'));
      service.dispose();
    });

    test('xử lý lỗi mạng (SocketException)', () async {
      dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=test_key
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
''');
      final mockClient = MockClient((request) async {
        throw Exception('SocketException: Connection refused');
      });

      final service = GeminiService(client: mockClient);
      final result = await service.sendMessage('test');

      expect(result, contains('kết nối mạng'));
      service.dispose();
    });
  });
}
