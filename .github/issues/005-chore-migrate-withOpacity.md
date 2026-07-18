# [CHORE] Migrate từ `withOpacity()` deprecated sang `withValues()`

**Labels:** `chore`, `tech-debt`, `priority:low`
**Status:** 🟡 OPEN
**Type:** Refactor — P2
**Created:** 2026-07-18
**Effort:** 30 phút

---

## 📝 Tóm tắt

Toàn bộ codebase (14 file, ~100 chỗ) dùng `Color.withOpacity(x)` đã bị Flutter 3.27+ đánh dấu deprecated. Cần chuyển sang `Color.withValues(alpha: x)`.

## 🎯 Lý do

- IDE warning mỗi khi save file
- Flutter có thể remove API trong 4.x → app sẽ crash
- Code smell — dùng API đã deprecated

## 📁 Files affected

```
lib/main.dart                     (5 chỗ)
lib/screens/chat_screen.dart      (16 chỗ)
lib/screens/welcome_screen.dart   (12 chỗ)
lib/screens/account_screen.dart   (3 chỗ)
lib/screens/admin_dashboard_screen.dart (8 chỗ)
lib/screens/login_screen.dart     (3 chỗ)
lib/screens/notifications_screen.dart (2 chỗ)
lib/screens/order_history_screen.dart (3 chỗ)
lib/screens/product_list_view.dart (2 chỗ)
lib/screens/qr_scanner_screen.dart (1 chỗ)
lib/screens/register_screen.dart  (2 chỗ)
lib/screens/staff_comments_screen.dart (6 chỗ)
lib/screens/staff_dashboard_screen.dart (1 chỗ)
lib/screens/verify_email_screen.dart (3 chỗ)
```

## ✅ Tiêu chí hoàn thành

- [ ] Chạy `flutter analyze` → 0 issues
- [ ] Không có warning `deprecated_member_use`
- [ ] UI trông giống hệt cũ (visual regression test)
- [ ] Không thay đổi behavior

## 🔧 Cách làm

Tìm và replace bằng script (PowerShell):

```powershell
rg "withOpacity\(" lib/ -l | ForEach-Object {
    (Get-Content $_) -replace '\.withOpacity\(([\d.]+)\)', '.withValues(alpha: $1)' |
    Set-Content $_
}
```

Sau đó manual review vì có vài chỗ dùng pattern đặc biệt.

## 📊 Ưu tiên

- [ ] P2 — Nice to have, làm khi rảnh

## 🔧 Effort estimate

~30 phút (chủ yếu chạy script + verify)

## 💬 Ghi chú

Có thể tận dụng PR review bot (`dart format` + `dart fix --apply`) để tự động fix một số.
