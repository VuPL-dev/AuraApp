# AURA Assistant — AI Chatbot

Chatbot tư vấn sản phẩm sử dụng **Gemini API** với **RAG pipeline** (Retrieval-Augmented Generation), tích hợp vào app Flutter AURA Accessories.

## ✨ Tính năng

- 🤖 Trả lời câu hỏi về sản phẩm, giá cả, chính sách đổi trả, vận chuyển
- 🔒 **Không bịa thông tin** — chỉ trả lời dựa trên dữ liệu có sẵn trong app
- 🎨 Theme đồng nhất với AURA (đỏ rượu vang + vàng kim)
- 📱 Hiển thị typing indicator khi chờ AI, xử lý lỗi mạng/API thân thiện
- 🔑 API key bảo mật qua file `.env` (không commit lên git)
- 🌡️ Temperature thấp (0.4) để giảm hallucination

## 📁 Cấu trúc

```
lib/
├── data/
│   └── knowledge_base.dart       # RAG corpus (5 sản phẩm + chính sách shop)
├── models/
│   └── chat_message.dart          # Model tin nhắn
├── services/
│   └── gemini_service.dart        # Gọi Gemini API với RAG pipeline
└── screens/
    └── chat_screen.dart           # UI chat
```

## 🛠️ Cài đặt

### 1. Thêm dependency (đã có trong `pubspec.yaml`)

```yaml
dependencies:
  flutter_dotenv: ^5.2.1
```

```yaml
flutter:
  assets:
    - .env
```

### 2. Tạo file `.env`

Copy từ `.env.example` và điền key:

```bash
cp .env.example .env
```

Hoặc tạo file `fe/frontend_mobile/.env`:

```dotenv
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-flash-lite-latest
```

Lấy key miễn phí tại: https://aistudio.google.com/apikey

### 3. Chạy app

```bash
flutter pub get
flutter run
```

## 🧠 RAG Pipeline (5 bước)

| Bước | Mô tả | File |
|---|---|---|
| 1️⃣ | Định nghĩa Model Class chặt chẽ | `data/knowledge_base.dart` (`Product`, `ShopInfo`) |
| 2️⃣ | Lọc dữ liệu cục bộ (Local Filtering & Scoring) | `searchRelevantProducts()` |
| 3️⃣ | Định dạng context có nhãn rõ ràng | `formatProductContext()`, `formatShopInfoContext()` |
| 4️⃣ | System Prompt khóa hành vi AI | `_systemPrompt` trong `gemini_service.dart` |
| 5️⃣ | Temperature thấp (0.4) | `generationConfig` trong payload |

## 📊 Knowledge Base hiện tại

Lấy từ database SQLite của backend (`be/backend/prisma/dev.db`):

1. **Đồng Hồ Nam Dây Da Cao Cấp** (DH-NAM-001)
2. **Đồng Hồ Nam Luxury Collection** (DH-NAM-002)
3. **Đồng Hồ Nam Sport Edition** (DH-NAM-003)
4. **Vòng Cổ Nam Bạc 925** (VC-NAM-001)
5. **Combo Mắt Kính & Đồng Hồ Nam** (COMBO-001)

Cùng với thông tin shop:
- Hotline, email hỗ trợ
- Chính sách đổi trả (30 ngày)
- Chính sách vận chuyển (miễn phí từ 250k)
- Cam kết chính hãng
- Khuyến mãi hiện tại (giảm 30%)
- Phương thức thanh toán (PayOS, COD)

## 🧪 Test case bắt buộc

| # | Câu hỏi | Kết quả mong đợi |
|---|---|---|
| 1 | "Có những đồng hồ nào đang bán?" | Liệt kê 3 sản phẩm đồng hồ với giá |
| 2 | "Đồng hồ Luxury giá bao nhiêu?" | "10.000 VND" |
| 3 | "Chính sách đổi trả như thế nào?" | "Đổi sản phẩm mới hoặc hoàn tiền trong vòng 30 ngày..." |
| 4 | "Combo quà tặng có gì hot?" | Mô tả combo Mắt Kính & Đồng Hồ |
| 5 | "Vòng cổ bạc 925 có phù hợp không?" | Mô tả phù hợp, lưu ý |
| 6 | "Viết bài thơ cho tôi" | Từ chối lịch sự (ngoài phạm vi) |
| 7 | "Shop mở cửa mấy giờ?" | "Hiện chưa có thông tin này trong dữ liệu của AURA." |
| 8 | "Có hỗ trợ trả góp không?" | Đề cập PayOS trả góp 0% cho đơn từ 500k |

## 🔧 Cách cập nhật Knowledge Base

Khi backend có sản phẩm mới, sync vào `knowledge_base.dart`:

```dart
final List<Product> knowledgeBase = [
  // ... existing
  Product(
    id: 6,
    name: 'Sản phẩm mới',
    brand: 'AURA',
    price: 500000,
    // ... các trường khác
    tags: const ['từ khóa 1', 'từ khóa 2'],  // Quan trọng cho search
    suitableFor: '...',
    warnings: '...',
    returnPolicy: '...',
    usage: '...',
  ),
];
```

**Lưu ý:** Tags phải đa dạng và khớp với cách người dùng hỏi. Ví dụ: cho sản phẩm đồng hồ thêm `['đồng hồ', 'watch', 'dh-...']`.

## 🌐 Model Gemini được hỗ trợ

| Model | Tốc độ | Chất lượng | Free tier |
|---|---|---|---|
| `gemini-flash-lite-latest` | ⚡⚡⚡ | ⭐⭐⭐ | 30 RPM |
| `gemini-flash-latest` | ⚡⚡ | ⭐⭐⭐⭐ | 15 RPM |
| `gemini-2.0-flash` | ⚡⚡ | ⭐⭐⭐⭐ | 15 RPM |
| `gemini-2.5-flash` | ⚡ | ⭐⭐⭐⭐⭐ | 10 RPM |

Đổi trong `.env`:
```dotenv
GEMINI_MODEL=gemini-flash-latest
```

## ⚠️ Bảo mật

- **KHÔNG** commit file `.env` lên git (đã được `.gitignore` chặn)
- **KHÔNG** hard-code API key trong source code
- Key có giới hạn request — xem [Google AI rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)
- Nếu key bị lộ, vào [AI Studio](https://aistudio.google.com/apikey) để rotate

## 📝 Logs phục vụ debug

Trong `gemini_service.dart`, các lỗi được phân loại rõ ràng:

- `SocketException` → "Lỗi kết nối mạng"
- `TimeoutException` → "Hết thời gian chờ"
- HTTP 400 → Prompt bị filter an toàn
- HTTP 401/403 → API key sai/hết hạn
- HTTP 404 → Model không tồn tại
- HTTP 429 → Vượt rate limit
- HTTP 5xx → Gemini API lỗi server
