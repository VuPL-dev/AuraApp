# 📋 GitHub Configuration cho AURA Accessories Project

Thư mục này chứa **issue templates** và **issue tracker local** cho dự án.

## 📁 Cấu trúc

```
.github/
├── ISSUE_TEMPLATE/          # Templates cho issue mới (GitHub UI)
│   ├── bug_report.md        # 🐛 Báo lỗi
│   ├── feature_request.md   # ✨ Đề xuất tính năng
│   ├── chore_task.md        # 🧹 Task nội bộ / refactor
│   └── custom.md            # 📋 Format tự do
│
├── issues/                  # Issue tracker local (Markdown)
│   ├── 001-bug-rate-limit-gemini.md
│   ├── 002-bug-gia-hien-thi-dau-phay.md
│   ├── 003-feature-sync-products-from-db.md
│   ├── 004-feature-product-card-in-chat.md
│   ├── 005-chore-migrate-withOpacity.md
│   └── 006-chore-setup-ci-cd.md
│
├── INDEX.md                 # Danh sách tất cả issue (status board)
└── README.md                # File này
```

## 🚀 Cách dùng

### Tạo issue mới trên GitHub
1. Vào tab **Issues** → **New issue**
2. Chọn 1 trong 4 template ở trên
3. Điền form → **Submit new issue**

### Track issue local (khi không push GitHub)
Mỗi issue là 1 file `.md` trong `.github/issues/`. Đặt tên theo pattern:

```
{NNN}-{type}-{short-description}.md

Ví dụ:
007-bug-crash-on-login.md
008-feature-dark-mode.md
```

### Cập nhật status issue
Sửa trực tiếp trong file → đổi `🟡 OPEN` thành:
- 🟢 `DONE` — đã fix xong
- 🟠 `WIP` — đang làm
- ⚪ `WONTFIX` — không làm
- 🔴 `BLOCKED` — bị chặn bởi issue khác

### Tự động sync với GitHub Issues
Nếu muốn 2-way sync với GitHub Issues thật, dùng tool:
- [`github-issue-sync`](https://github.com/marketplace/actions/github-issue-sync)
- Hoặc CLI: [`gh`](https://cli.github.com/) (`gh issue create --template bug_report.md`)

## 🏷️ Quy ước Labels

| Label | Ý nghĩa | Màu |
|---|---|---|
| `bug` | Lỗi làm app sai/crash | 🔴 đỏ |
| `enhancement` | Tính năng mới | 🔵 xanh dương |
| `chore` | Refactor / setup | ⚪ xám |
| `priority:high` | Cần làm sớm | 🔴 đỏ |
| `priority:medium` | Quan trọng vừa | 🟡 vàng |
| `priority:low` | Nice to have | 🟢 xanh lá |
| `area:chatbot` | Liên quan AI chatbot | 🤖 |
| `area:backend` | Liên quan API | ⚙️ |
| `area:ui` | Liên quan UI/UX | 🎨 |
| `needs-triage` | Chưa được review | ❓ |
| `good-first-issue` | Dễ, người mới làm được | 🌱 |
