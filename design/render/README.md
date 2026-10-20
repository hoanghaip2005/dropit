# Sơ đồ Mermaid đã render

Render ngày 2026-10-19 bằng `@mermaid-js/mermaid-cli` 12.0.0 (`npx -y @mermaid-js/mermaid-cli`, Puppeteer cục bộ chạy được, không cần image docker).
Kết quả: **22/22 sơ đồ render thành công, 0 lỗi cú pháp, không phải sửa tệp md nào.**

Cách chạy lại:

```bash
cd design/render
python extract.py            # tách khối ```mermaid -> src/*.mmd
for f in src/*.mmd; do npx -y @mermaid-js/mermaid-cli -q -i "$f" -o "$(basename "$f" .mmd).svg"; done
```

| Sơ đồ (SVG) | Nguồn (tệp:dòng) | Mục | Trạng thái |
| --- | --- | --- | --- |
| [`01-kien-truc-01.svg`](01-kien-truc-01.svg) | `01-kien-truc.md:14` | 1.1 C4 mức 1 — Bối cảnh | OK |
| [`01-kien-truc-02.svg`](01-kien-truc-02.svg) | `01-kien-truc.md:38` | 1.2 C4 mức 2 — Container | OK |
| [`01-kien-truc-03.svg`](01-kien-truc-03.svg) | `01-kien-truc.md:93` | 2.1 Kiểu kiến trúc | OK |
| [`01-kien-truc-04.svg`](01-kien-truc-04.svg) | `01-kien-truc.md:197` | 3.1 Phân lớp | OK |
| [`01-kien-truc-05.svg`](01-kien-truc-05.svg) | `01-kien-truc.md:271` | 4.1 Mạng | OK |
| [`02-du-lieu-01.svg`](02-du-lieu-01.svg) | `02-du-lieu.md:24` | 2. ERD | OK |
| [`04-luong-trang-thai-01.svg`](04-luong-trang-thai-01.svg) | `04-luong-trang-thai.md:18` | 1.1 Cấp PHIÊN (03 §2.1) | OK |
| [`04-luong-trang-thai-02.svg`](04-luong-trang-thai-02.svg) | `04-luong-trang-thai.md:53` | 1.2 Cấp THÀNH VIÊN TRONG PHIÊN (03 §2.2, §3) | OK |
| [`04-luong-trang-thai-03.svg`](04-luong-trang-thai-03.svg) | `04-luong-trang-thai.md:119` | 1.3 NHÓM (03 §Máy trạng thái NHÓM) | OK |
| [`04-luong-trang-thai-04.svg`](04-luong-trang-thai-04.svg) | `04-luong-trang-thai.md:145` | 1.4 KHIẾU NẠI (03 §Máy trạng thái KHIẾU NẠI) | OK |
| [`04-luong-trang-thai-05.svg`](04-luong-trang-thai-05.svg) | `04-luong-trang-thai.md:176` | 2.1 Đăng ký + vào nhóm + đồng ý | OK |
| [`04-luong-trang-thai-06.svg`](04-luong-trang-thai-06.svg) | `04-luong-trang-thai.md:211` | 2.2 Chủ nhóm đặt lịch → mở phiên → đếm ngược | OK |
| [`04-luong-trang-thai-07.svg`](04-luong-trang-thai-07.svg) | `04-luong-trang-thai.md:250` | 2.3 Rời app → khoan hồng 3s → quay lại | OK |
| [`04-luong-trang-thai-08.svg`](04-luong-trang-thai-08.svg) | `04-luong-trang-thai.md:282` | 2.4 Rời app quá 3s → EXITED → MEMBER_EXITED (gộp SESSION_FORFEITED) | OK |
| [`04-luong-trang-thai-09.svg`](04-luong-trang-thai-09.svg) | `04-luong-trang-thai.md:317` | 2.5 Khóa màn hình (không tính rời) | OK |
| [`04-luong-trang-thai-10.svg`](04-luong-trang-thai-10.svg) | `04-luong-trang-thai.md:343` | 2.6 Bấm "Rời phiên" (D-29, BR-118) | OK |
| [`04-luong-trang-thai-11.svg`](04-luong-trang-thai-11.svg) | `04-luong-trang-thai.md:372` | 2.7 Mất mạng → DISCONNECTED → LOST | OK |
| [`04-luong-trang-thai-12.svg`](04-luong-trang-thai-12.svg) | `04-luong-trang-thai.md:401` | 2.8 Sự cố server → hủy phiên | OK |
| [`04-luong-trang-thai-13.svg`](04-luong-trang-thai-13.svg) | `04-luong-trang-thai.md:428` | 2.9 Kết thúc phiên → Coins sổ cái, điểm danh, chuỗi | OK |
| [`04-luong-trang-thai-14.svg`](04-luong-trang-thai-14.svg) | `04-luong-trang-thai.md:458` | 2.10 Giải trình + khiếu nại + miễn trừ | OK |
| [`04-luong-trang-thai-15.svg`](04-luong-trang-thai-15.svg) | `04-luong-trang-thai.md:500` | 2.11 Báo cáo tháng (cron → bản chụp → email SES) | OK |
| [`04-luong-trang-thai-16.svg`](04-luong-trang-thai-16.svg) | `04-luong-trang-thai.md:536` | 2.12 Chủ nhóm xem chi tiết phiên (kéo để làm mới, D-28) | OK |
