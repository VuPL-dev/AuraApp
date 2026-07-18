# [CHORE] Setup CI/CD pipeline (GitHub Actions) cho Flutter app

**Labels:** `chore`, `ci-cd`, `priority:medium`
**Status:** 🟡 OPEN
**Type:** Task — P1
**Created:** 2026-07-18
**Effort:** 2-3 giờ

---

## 📝 Tóm tắt

Hiện tại project chưa có CI/CD. Mỗi lần code change phải chạy tay `flutter pub get` + `flutter analyze` + `flutter test`. Cần setup GitHub Actions để tự động.

## 🎯 Lý do

- PR không được verify tự động → dễ merge code lỗi
- Manual test tốn thời gian
- Thiếu lint check → `flutter analyze` 100+ warnings tích lũy

## ✅ Tiêu chí hoàn thành

- [ ] Tạo `.github/workflows/flutter-ci.yml`
- [ ] Workflow chạy mỗi PR và push main:
  - `flutter pub get`
  - `flutter analyze --no-pub` → fail nếu có error
  - `flutter test --no-pub` → fail nếu có test fail
  - `flutter build web --release`
- [ ] Badge hiển thị trong `fe/frontend_mobile/README.md`
- [ ] (Tuỳ chọn) Auto-deploy web lên Firebase Hosting / Vercel khi push main

## 📄 Workflow mẫu

```yaml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.27.0'
      - run: flutter pub get
      - run: flutter analyze --no-pub
      - run: flutter test --no-pub
      - run: flutter build web --release --no-pub
```

## 🔗 Related

- File: `.github/workflows/flutter-ci.yml` (sẽ tạo mới)
- Test đã có: `fe/frontend_mobile/test/widget_test.dart` (15 tests)
- Cache `~/.pub-cache/`, `~/.gradle/` để tăng tốc

## 📊 Ưu tiên

- [x] P1 — Quan trọng, cần sớm

## 🔧 Effort estimate

~2-3 giờ (workflow setup + test chạy)
