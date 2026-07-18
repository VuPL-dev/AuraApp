import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/knowledge_base.dart';

/// Service gọi Gemini API với RAG pipeline đơn giản.
///
/// Quy trình 5 bước theo đề bài PRM393:
///   1. Model Class chặt chẽ   → [Product], [ShopInfo] trong `knowledge_base.dart`
///   2. Lọc cục bộ            → [searchRelevantProducts]
///   3. Format context         → [formatProductContext], [formatShopInfoContext]
///   4. System Prompt         → [_systemPrompt]
///   5. Temperature thấp      → `temperature: 0.4` trong payload
///
/// API key lấy từ file `.env` thông qua `flutter_dotenv` để bảo mật.
class GeminiService {
  GeminiService({http.Client? client})
      : _client = client ?? http.Client(),
        _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '',
        _baseUrl = dotenv.env['GEMINI_BASE_URL'] ??
            'https://generativelanguage.googleapis.com/v1beta',
        _model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-flash-lite-latest';

  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;
  final String _model;

  // Bước 4: System Prompt khóa hành vi AI — ngăn bịa thông tin.
  static const String _systemPrompt = '''
Bạn là Aura Assistant, trợ lý tư vấn chuyên nghiệp của cửa hàng phụ kiện thời trang AURA Accessories.
Chỉ được trả lời dựa trên NỘI DUNG CÓ SẴN được cung cấp bên dưới (gồm thông tin sản phẩm và thông tin cửa hàng).
Không được tự suy đoán hoặc bịa thông tin (giá, thông số kỹ thuật, chính sách, tên sản phẩm, v.v.).
Nếu câu hỏi có trong nội dung có sẵn: trả lời ngắn gọn, đúng thông tin, có dẫn chứng cụ thể.
Nếu câu hỏi liên quan đến sản phẩm AURA nhưng thiếu dữ liệu: trả lời rõ "Hiện chưa có thông tin này trong dữ liệu của AURA."
Nếu câu hỏi không liên quan đến phụ kiện thời trang hoặc sản phẩm AURA: từ chối lịch sự.
Ví dụ: "Xin lỗi, tôi chỉ có thể hỗ trợ tư vấn về sản phẩm và dịch vụ tại AURA Accessories."
Khi người dùng hỏi về chính sách đổi trả, vận chuyển, thanh toán hoặc liên hệ: dựa vào phần "Thông tin cửa hàng" trong context.
Luôn trả lời bằng tiếng Việt, ngắn gọn, lịch sự và chuyên nghiệp.
''';

  /// Gửi câu hỏi của người dùng và nhận phản hồi từ Gemini.
  ///
  /// Trả về [String] là câu trả lời từ AI. Trong trường hợp lỗi
  /// (không có key, mất mạng, API trả về lỗi), trả về chuỗi
  /// thông báo lỗi thân thiện bằng tiếng Việt.
  Future<String> sendMessage(String userQuestion) async {
    // Kiểm tra API key
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      return 'Lỗi: Chưa cấu hình API Key.\n\n'
          'Vui lòng tạo file `.env` ở thư mục gốc dự án '
          '(`fe/frontend_mobile/.env`) với nội dung:\n'
          'GEMINI_API_KEY=your_key_here\n\n'
          'Sau đó chạy lại ứng dụng.';
    }

    try {
      // Bước 2: Lọc dữ liệu cục bộ - tìm sản phẩm liên quan
      final relevantProducts = searchRelevantProducts(userQuestion);

      // Bước 3: Định dạng dữ liệu thành văn bản có nhãn rõ ràng
      final productContext = formatProductContext(relevantProducts);
      final shopContext = formatShopInfoContext();

      // Bước 4: Xây dựng prompt đầy đủ
      final fullPrompt = '''
$_systemPrompt

=== THÔNG TIN CỬA HÀNG ===
$shopContext

=== SẢN PHẨM LIÊN QUAN ===
$productContext

=== CÂU HỎI CỦA NGƯỜI DÙNG ===
$userQuestion

=== CÂU TRẢ LỜI ===
''';

      // Bước 5: Gọi Gemini API với temperature thấp để giảm hallucination
      final url = Uri.parse(
        '$_baseUrl/models/$_model:generateContent?key=$_apiKey',
      );

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': fullPrompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.4,
                'topP': 0.9,
                'maxOutputTokens': 800,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
                {
                  'category': 'HARM_CATEGORY_HATE_SPEECH',
                  'threshold': 'BLOCK_ONLY_HIGH',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body);
      }

      // Xử lý lỗi theo status code
      return _parseErrorResponse(response.statusCode, response.body);
    } catch (e) {
      // Phân loại lỗi để hiển thị thông báo thân thiện
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('HandshakeException') ||
          errStr.contains('Connection refused') ||
          errStr.contains('Network is unreachable')) {
        return 'Lỗi kết nối mạng.\n\n'
            'Vui lòng kiểm tra:\n'
            '• Wi-Fi/4G đã bật\n'
            '• Không dùng VPN chặn API Google\n'
            '• Thử lại sau vài giây';
      }
      if (errStr.contains('TimeoutException')) {
        return 'Hết thời gian chờ.\n\n'
            'Gemini API phản hồi chậm. Vui lòng thử lại.';
      }
      return 'Đã xảy ra lỗi không xác định.\n\n$errStr';
    }
  }

  /// Parse response 200 từ Gemini API.
  String _parseSuccessResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return 'Không nhận được phản hồi từ AI. Vui lòng thử lại.';
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'];
      if (content == null) return 'Phản hồi rỗng từ AI.';

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return 'Phản hồi rỗng từ AI.';
      }

      final text = (parts.first as Map<String, dynamic>)['text'];
      if (text == null || text.trim().isEmpty) {
        return 'AI không trả lời được. Vui lòng thử câu hỏi khác.';
      }
      return text;
    } catch (_) {
      return 'Không thể phân tích phản hồi từ AI. Vui lòng thử lại.';
    }
  }

  /// Parse lỗi từ Gemini API.
  String _parseErrorResponse(int statusCode, String body) {
    String? apiMessage;
    try {
      final err = jsonDecode(body) as Map<String, dynamic>;
      apiMessage = err['error']?['message'] as String?;
    } catch (_) {
      // body không phải JSON
    }

    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ (400).\n\n'
            '${apiMessage ?? "Prompt bị từ chối bởi bộ lọc an toàn."}';
      case 401:
      case 403:
        return 'API Key không hợp lệ hoặc đã hết hạn (${statusCode}).\n\n'
            '${apiMessage ?? "Vui lòng kiểm tra lại GEMINI_API_KEY trong file .env"}';
      case 404:
        return 'Model không tồn tại (404).\n\n'
            'Vui lòng kiểm tra GEMINI_MODEL trong file .env. '
            'Các model hợp lệ: gemini-flash-lite-latest, gemini-flash-latest, '
            'gemini-2.0-flash, gemini-2.5-flash.';
      case 429:
        return 'Đã vượt quá giới hạn request (429).\n\n'
            '${apiMessage ?? "Vui lòng đợi 1 phút rồi thử lại."}';
      case 500:
      case 502:
      case 503:
        return 'Gemini API đang gặp sự cố (${statusCode}).\n\n'
            'Vui lòng thử lại sau vài phút.';
      default:
        return 'Lỗi API ($statusCode).\n\n${apiMessage ?? "Lỗi không xác định"}';
    }
  }

  /// Đóng HTTP client (gọi khi service không còn dùng nữa).
  void dispose() => _client.close();
}
