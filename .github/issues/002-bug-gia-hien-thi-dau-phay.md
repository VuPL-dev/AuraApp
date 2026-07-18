# [BUG] AI trả lời giá sản phẩm với dấu phẩy thay vì dấu chấm

**Labels:** `bug`, `area:chatbot`, `ui`, `priority:low`
**Status:** 🟡 OPEN
**Type:** Bug (cosmetic) — P2
**Created:** 2026-07-18
**Effort:** 30 phút

---

## 🐛 Mô tả

Gemini API trả về giá theo chuẩn quốc tế: `10,000 VND`. UI hiển thị nguyên text này gây khó chịu vì:
- Toàn bộ app AURA dùng `10.000đ` (dấu chấm) ở mọi nơi (product_list, cart,...)
- Sự không nhất quán làm người dùng nghi ngờ giá khác nhau

## 🔄 Steps to Reproduce

1. Mở chat → gõ "Đồng Hồ Luxury giá bao nhiêu?"
2. Đọc câu trả lời

## ✅ Expected

AI trả lời: `10.000 VND` hoặc `10000 VND` (đồng nhất với UI)

## ❌ Actual

AI trả lời: `10,000 VND`

## 💡 Proposed Solution

**Option A (nhanh):** Post-process trong `ChatScreen._buildBubble` để replace `,` → `.` trong các số tiền.

**Option B (tốt hơn):** Thêm instruction vào system prompt:
```
Khi viết giá tiền VND, dùng dấu CHẤM làm phân cách hàng nghìn (10.000đ, 250.000đ) 
theo chuẩn Việt Nam, KHÔNG dùng dấu phẩy.
```

Recommend **Option B** (fix ở layer AI, không cần xử lý regex).

## 📐 Acceptance Criteria

- [ ] Test case "Đồng Hồ Luxury giá bao nhiêu?" → trả lời chứa `10.000`
- [ ] Test case "Combo Mắt Kính giá?" → trả lời chứa `10.000`

## 🔗 Related

- File: `lib/services/gemini_service.dart:16` (`_systemPrompt`)
- File: `lib/data/knowledge_base.dart:33` (giá lưu dạng `10000` int)
