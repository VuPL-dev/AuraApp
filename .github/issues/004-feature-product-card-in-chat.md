# [FEATURE] Đính kèm ảnh sản phẩm vào câu trả lời khi chatbot đề cập

**Labels:** `enhancement`, `area:chatbot`, `ui`, `priority:medium`
**Status:** 🟡 OPEN
**Type:** Feature — P2
**Created:** 2026-07-18
**Effort:** 1-2 ngày

---

## ✨ Tóm tắt

Khi chatbot nhắc đến một sản phẩm cụ thể, message bubble nên hiển thị kèm **ảnh thumbnail + tên + giá** dạng card có thể bấm vào → mở ProductDetailScreen.

## 🎯 Vấn đề

Hiện tại câu trả lời chỉ là text. User muốn xem sản phẩm ngay trong chat phải nhớ tên → thoát chat → tìm trong product list. Friction cao.

## 💡 Giải pháp đề xuất

1. **Markdown-like syntax:** Gemini output định dạng `[[product:1]]` (ID sản phẩm) khi đề cập
2. **Custom renderer trong `ChatScreen`:** Parse `[[product:ID]]` → render thẻ card (ảnh + tên + giá + nút "Xem chi tiết")
3. **Tap vào card** → `Navigator.push` đến `ProductDetailScreen` (đã có)

Ví dụ AI output:
```
Bạn có thể tham khảo sản phẩm [[product:2]] phù hợp với nhu cầu.
```

Được render thành:
```
💬 Bạn có thể tham khảo sản phẩm
[Ảnh đồng hồ] Đồng Hồ Nam Luxury Collection
              10.000đ   [Xem chi tiết]
```

## 📐 Acceptance Criteria

- [ ] AI đề cập sp kèm `[[product:ID]]` khi recommend
- [ ] Card hiển thị ảnh + tên + giá + nút Xem chi tiết
- [ ] Bấm card → mở ProductDetailScreen đúng sản phẩm
- [ ] Fallback: nếu AI quên dùng syntax → hiển thị dạng text bình thường

## 🚫 Ngoài phạm vi

- Không cần multi-product card (slider)
- Không cần "thêm vào giỏ" trực tiếp trong card

## 📊 Ưu tiên

- [ ] P2 — Nice to have

## 🔧 Effort estimate

- Prompt engineering (update system prompt): 0.5d
- Custom widget ChatProductCard: 1d
- Test: 0.5d
- **Tổng:** ~1-2 ngày
