# [BUG] Rate limit Gemini API gây lỗi khi user gửi nhiều câu liên tiếp

**Labels:** `bug`, `area:chatbot`, `priority:high`
**Status:** 🟡 OPEN
**Type:** Bug — P0
**Created:** 2026-07-18
**Effort:** 1 ngày

---

## 🐛 Mô tả

Khi người dùng gửi nhiều câu hỏi liên tiếp trong < 1 phút, Gemini API trả về HTTP 429 (quota exceeded). Chatbot hiển thị thông báo lỗi OK nhưng user phải đợi 60+ giây để gửi lại.

## 🔄 Steps to Reproduce

1. Mở app → Đăng nhập → WelcomeScreen
2. Bấm icon chat trên appbar (hoặc "AURA AI" ở BottomNav)
3. Liên tục gửi 5-7 câu hỏi trong vòng 30 giây
4. Quan sát câu thứ 6+ sẽ fail với thông báo "đã vượt quá giới hạn"

## ✅ Expected

User nhận thông báo: *"Tôi đang trả lời chậm hơn bình thường, vui lòng đợi vài giây..."* và tự động retry.

## ❌ Actual

User phải tự bấm gửi lại sau khi đợi rate limit reset (60s cho model flash-lite).

## 💡 Giải pháp đề xuất

1. Thêm **debounce 1.5s** ở `_ChatScreenState._onSend` — tránh spam khi user bấm gửi liên tục
2. Implement **exponential backoff retry** trong `GeminiService._client.post()` — 2 lần retry với delay 2s, 4s
3. Cache câu trả lời thường gặp ("Hotline?", "Vận chuyển?") trong `flutter_cache_manager` 5 phút
4. UI: khi nhận 429, hiển thị countdown timer "Vui lòng đợi 45s..." thay vì để user bấm gửi lại

## 📐 Acceptance Criteria

- [ ] Gửi 10 câu liên tiếp trong 30s → tất cả đều có câu trả lời (không cần user retry thủ công)
- [ ] Có countdown timer hiển thị khi đợi rate limit
- [ ] Log warning khi phát hiện rate limit để debug

## 🌍 Environment

- **Model:** `gemini-flash-lite-latest` (30 RPM free tier)
- **Reproduced:** test #7-#10 trong `fe/frontend_mobile/test_e2e.py` fail ở lần chạy đầu

## 🔗 Related

- File: `lib/services/gemini_service.dart:104` (`_parseErrorResponse` case 429)
- File: `lib/screens/chat_screen.dart` (`_onSend`)
- E2E test: `fe/frontend_mobile/test_e2e.py`
