# [FEATURE] Sync sản phẩm realtime từ Prisma DB thay vì hardcode trong knowledge_base.dart

**Labels:** `enhancement`, `area:chatbot`, `area:backend`, `priority:high`
**Status:** 🟡 OPEN
**Type:** Feature — P0
**Created:** 2026-07-18
**Effort:** 2-3 ngày

---

## ✨ Tóm tắt

Hiện tại `knowledge_base.dart` hardcode 5 sản phẩm Aura. Khi admin thêm sản phẩm mới trên web, chatbot không biết → trả lời "chưa có thông tin". Cần sync realtime từ backend SQLite.

## 🎯 Vấn đề

- Admin thêm sản phẩm mới trên dashboard → chatbot trả lời sai (bảo không có)
- Mỗi lần có sp mới phải sửa code Dart + rebuild app → quá cồng kềnh
- Giá/tồn kho trong DB thay đổi → chatbot nói giá cũ

## 💡 Giải pháp đề xuất

1. **Backend mới:** Tạo endpoint `GET /api/chatbot/products` trả về JSON danh sách sản phẩm (chỉ các trường cần thiết: id, name, brand, price, sku, category, description, stock, image_url, warnings, returnPolicy, suitableFor)
2. **Prisma migration:** Bổ sung 3 trường mở rộng `warnings`, `returnPolicy`, `suitableFor` vào schema `Product`
3. **Flutter service:** Tạo `ProductRepository` trong `lib/repositories/` cache lại data, gọi API mỗi 5 phút hoặc khi app foreground
4. **Convert:** Tự động convert `Map<String, dynamic>` từ API → `Product` object
5. **Refactor `GeminiService`:** `searchRelevantProducts()` dùng ProductRepository thay const list
6. **Cleanup:** Bỏ `knowledgeBase` const list (giữ lại `ShopInfo` static content)

## 📐 Acceptance Criteria

- [ ] Admin thêm sản phẩm mới trên web → bấm refresh trong chat (hoặc restart app) → chatbot trả lời đúng
- [ ] Chatbot trả lời giá đúng với giá hiện tại trong DB
- [ ] App không phụ thuộc vào `knowledgeBase` const list nữa
- [ ] Vẫn giữ hardcoded `ShopInfo` (chính sách shop) vì đây là static content
- [ ] Cache TTL ≤ 5 phút

## 🚫 Ngoài phạm vi

- Không cần sync `Review`, `Order` vào knowledge base
- Không cần viết lại backend Express — chỉ thêm 1 route mới

## 📊 Ưu tiên

- [x] P0 — Critical, cần làm trong sprint này

## 🔧 Effort estimate

- Backend route: 0.5d
- Prisma migration: 0.5d
- Flutter ProductRepository: 1d
- Refactor GeminiService: 0.5d
- Test (unit + E2E): 0.5d
- **Tổng:** ~2.5-3 ngày

## 💬 Ghi chú

Có thể dùng `dio` thay cho `http` để có interceptor (retry, cache tự động).
