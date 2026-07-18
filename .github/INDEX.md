# 📊 Issues Index — AURA Accessories

Tổng hợp tất cả issue được track trong repo này. Cập nhật lần cuối: **2026-07-18**.

---

## 🟡 OPEN (6)

| # | Tiêu đề | Type | Priority | Area | Labels |
|---|---|---|---|---|---|
| [#001](./issues/001-bug-rate-limit-gemini.md) | Rate limit Gemini API gây lỗi khi gửi nhiều câu liên tiếp | 🐛 bug | 🔴 high | chatbot | `bug`, `area:chatbot`, `priority:high` |
| [#002](./issues/002-bug-gia-hien-thi-dau-phay.md) | AI trả lời giá với dấu phẩy thay vì dấu chấm | 🐛 bug | 🟢 low | chatbot, ui | `bug`, `area:chatbot`, `ui`, `priority:low` |
| [#003](./issues/003-feature-sync-products-from-db.md) | Sync sản phẩm realtime từ Prisma DB | ✨ feature | 🔴 high | chatbot, backend | `enhancement`, `area:chatbot`, `area:backend`, `priority:high` |
| [#004](./issues/004-feature-product-card-in-chat.md) | Đính kèm ảnh sản phẩm vào câu trả lời chatbot | ✨ feature | 🟡 medium | chatbot, ui | `enhancement`, `area:chatbot`, `ui`, `priority:medium` |
| [#005](./issues/005-chore-migrate-withOpacity.md) | Migrate từ `withOpacity()` deprecated sang `withValues()` | 🧹 chore | 🟢 low | tech-debt | `chore`, `tech-debt`, `priority:low` |
| [#006](./issues/006-chore-setup-ci-cd.md) | Setup CI/CD pipeline (GitHub Actions) | 🧹 chore | 🟡 medium | ci-cd | `chore`, `ci-cd`, `priority:medium` |

---

## 🟢 DONE (0)

_Chưa có_

---

## 📈 Thống kê

- **Tổng:** 6 issues
- **Theo type:**
  - 🐛 Bug: 2 (33%)
  - ✨ Feature: 2 (33%)
  - 🧹 Chore: 2 (33%)
- **Theo priority:**
  - 🔴 High: 2 (33%)
  - 🟡 Medium: 2 (33%)
  - 🟢 Low: 2 (33%)
- **Theo area:**
  - 🤖 Chatbot: 4 (67%)
  - 🎨 UI: 2 (33%)
  - ⚙️ Backend: 1 (17%)
  - 🧹 CI/CD: 1 (17%)

---

## 🎯 Sprint 1 (đề xuất)

Tuần này ưu tiên làm theo thứ tự:

1. **#003** Sync products from DB (2-3d) — critical cho bot hoạt động đúng khi sp mới
2. **#001** Rate limit handling (1d) — UX quan trọng
3. **#006** Setup CI (2-3h) — đầu tư 1 lần, lợi lâu dài
4. **#002** Fix giá hiển thị (30 phút) — quick win
5. Backlog: #004, #005

---

## 🔗 Liên kết nhanh

- [Tạo issue mới](./README.md#tạo-issue-mới-trên-github)
- [Xem templates](./ISSUE_TEMPLATE/)
- [Quy ước labels](./README.md#-quy-ước-labels)
