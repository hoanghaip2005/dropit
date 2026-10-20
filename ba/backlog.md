# Backlog sản phẩm — DropIt!

Việc: T-BA-20 (cập nhật sau review lần 1: T-BA-43, T-BA-44; lần 2: T-BA-57, T-BA-59, T-BA-61; lần 3: T-BA-76, T-BA-80; áp D-17…D-26; review mockup 2026-10-19: thêm US-08.10 Must S (T-BA-105), US-03.14 Should S (T-BA-102)). Nguồn: `ba/srs/01-pham-vi.md`, `ba/srs/02-ep01…ep09-*.md`, `ba/srs/04-nfr-rieng-tu.md` (Ánh xạ AWS), `ba/02-so-quyet-dinh.md` (D-01…D-26), Quy trình §12, GĐ1 §7, §8, §10, §11. Không thêm tính năng ngoài nguồn. Ước lượng S/M/L lấy từ từng story (ngoại lệ US-02.10, xem §5.3). MoSCoW theo D-13, D-14, D-15; cột **MoSCoW gốc** giữ mức ghi trong story để truy vết.

## 1. Quy ước và giả định năng lực

- Điểm: **S = 1, M = 2, L = 3**.
- Vai trò phụ trách (gợi ý): **BE** Backend · **FM** Flutter Mobile · **CD** Cloud/DevOps · **WA** Web Admin · **QB** QA/BA. Một người có thể kiêm nhiều vai.
- **Năng lực (D-13, D-17):** 5 người, sprint 2 tuần, ~5 điểm/người/sprint → danh nghĩa 25 điểm/sprint.
  - Sprint 1: ×0,7 (chốt phạm vi, kiến trúc, dựng hạ tầng) → **18**.
  - Sprint 2, 3: **25** mỗi sprint.
  - Sprint 4: ước tính ×0,5 = 12; **D-17 nâng lên 15** (nhóm chấp nhận vượt 3 điểm, gần như không còn dự phòng cho kiểm thử).
  - **Tổng năng lực: 83 điểm** (D-17).

## 2. Tổng hợp điểm

| Hạng mục | Số mục | Điểm |
| --- | --- | --- |
| User story (EP-01…EP-09) | 92 (trong đó 7 Hủy: 4 do D-14, US-07.05 do D-16, US-02.12 do D-21, US-03.13 do D-25) | — |
| Hạng mục kỹ thuật (T-01…T-06) | 6 | 12 (Must) — T-03 tách iOS sang T-06 (D-26) |
| Must theo story gốc + kỹ thuật | 68 US + 6 T | 123 |
| **Must sau D-13…D-26 + mockup** | **44 US + 6 T** | **86** (US-03.09 S→M +1; T-03 M→S + T-06 M = +1; US-08.10 S mới +1; vượt D-17 3 điểm — chờ Q-140) |
| Should | 37 US + 1 mục chưa có story | **62** (+ chưa ước lượng; US-03.13 Hủy −1; US-03.14 mới +1) |
| Could | 2 US | 3 |
| Won't (sau MVP, D-20) | US-04.03, US-04.04 | 3 |

Điểm Must theo sprint:

| Sprint | Năng lực | Must xếp | Chênh |
| --- | --- | --- | --- |
| 1 | 18 | 19 | **+1** |
| 2 | 25 | 25 | 0 |
| 3 | 25 | 26 | **+1** |
| 4 | 15 (D-17) | 16 | **+1** |
| **Tổng** | **83** | **86** | **+3** |

Sprint 1 = 8 (US) + T-01 3 + T-02 3 + T-03 1 + T-04 2 + T-06 2 = 19. Sprint 2 = 25 sau khi US-03.09 thành M (+1) và US-08.08 (S) dời về S4 (−1). Sprint 3 = 26: US-08.10 (S) xếp cùng US-04.05/04.06 vì cần sự kiện thoát + giải trình (S3) và trước US-08.02 (S4) có lối vào AC-08.02.9. Sprint 4 = 16.

**Kết luận:** (1) US-03.09 ước lại S→M (D-20, D-22) → +1 ở S2, đã dời US-08.08 sang S4. (2) D-26: không có Mac → pipeline iOS trên GitHub Actions macOS (ký, provisioning, TestFlight) tách thành T-06 (M); T-03 còn backend + Android (M→S, **giả định**) → +1 ở S1. (3) Review mockup (T-BA-105): thêm US-08.10 chi tiết phiên cho chủ nhóm (Must, S, giả định) → +1 ở S3. Must = 86, vượt D-17 (83) 3 điểm (S1 +1, S3 +1, S4 +1). **Chưa chốt** — phương án ở §5.5 (Q-140, mở rộng). US-04.01, US-08.07 giữ ước lượng M **(giả định)**. Không còn dự phòng; thứ tự cắt nếu trễ ở §5.4.

## 3. Hạng mục kỹ thuật (không phải story)

| Mã | Tên | MoSCoW | Ước lượng | Phụ thuộc | Sprint | Phụ trách | Nguồn |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **T-01** | **Spike phát hiện rời app trên iOS + Android (Flutter): phân biệt khóa/tắt màn hình với rời app, đo độ trễ, thử máy thật cả hai nền tảng. Phần iOS chạy qua bản build CI (T-06) cài TestFlight lên iPhone thật — không có Mac để debug trực tiếp (D-26). Ưu tiên cao nhất.** | Must | L | Android: không; iOS: **T-06** + ≥1 iPhone thật **(giả định, Q-142)** | 1 | FM (+QB thử máy thật) | GĐ1 §10 #1; D-07, D-08, D-26; 01 C-03, C-04 |
| T-02 | Dựng AWS (VPC, EC2+ALB, RDS PostgreSQL, ElastiCache, Cognito, SNS…) theo Ánh xạ AWS; **hạn mức + cảnh báo ngân sách từ ngày đầu** | Must | L | — | 1 | CD | GĐ1 §8; D-04; 01 C-02, C-05; 04 Ánh xạ AWS |
| T-03 | CI/CD: build/test backend, build Flutter **Android**, triển khai lên môi trường thử. Phần iOS tách sang T-06 (D-26) | Must | S (ước lại từ M, **giả định**) | T-02 | 1 | CD | Quy trình §12 S1; D-07, D-26 |
| **T-06** | **Pipeline iOS trên GitHub Actions runner macOS: build Flutter iOS, ký IPA (chứng chỉ + provisioning profile lưu trong GitHub Secrets), đẩy TestFlight; chạy khi cần để tiết kiệm phút macOS (C-10). Làm trước hoặc song song phần iOS của T-01** | Must | M (**giả định**: chưa ai trong nhóm làm ký iOS không có Mac) | Tài khoản Apple Developer (D-26) | 1 | CD (+FM) | D-07, D-18, D-26; 01 C-03, C-10 |
| T-04 | Hợp đồng socket/API (sự kiện phiên, thoát, khoan hồng, mất kết nối; REST nhóm/lịch) — tài liệu chung cho BE và FM | Must | M | — | 1 | BE (+FM, QB duyệt) | Quy trình §11 #4; EP-03 |
| T-05 | Nạp sẵn dữ liệu (danh mục Shop, tài khoản quản trị, thông số Coins/hệ thống cấu hình được) thay giao diện admin ở MVP | Must | S | T-02 | 3 | BE | 01 §4 EP-09 “MVP tối thiểu (seed)”; D-09; C-09 |

## 4. Bảng user story

Cột Sprint: 1–4 = Must đã xếp; “Sau” = Should/Could, làm sau MVP (hoặc S4 nếu còn dư); “Hủy” = gộp vào story khác (D-14), không tính điểm. Story bị gộp không cộng điểm vào story giữ lại vì nội dung trùng (AC của story Hủy chuyển sang story giữ lại khi sửa tệp EP).

### EP-01 Tài khoản & vai trò

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-01.01 | Đăng ký và đăng nhập | Must | Must | M | T-02 (Cognito) | 1 | BE, FM |
| US-01.02 | Đăng xuất | Must | Must | S | 01.01 | 1 (→ 4 nếu Q-140 PA-A; → 2 nếu PA-C) | FM |
| US-01.03 | Sửa hồ sơ cơ bản (nhận US-07.02) | Must | Must (D-17) | S | 01.01 | 4 | FM, BE |
| US-01.04 | Vai trò theo từng nhóm | Must | Must | M | 01.01 | 1 | BE |
| US-01.05 | Đồng ý minh bạch khi vào nhóm (nhận US-02.05) | Must | Must | M | 02.01, 02.03 | 2 | FM, BE |
| US-01.06 | Đồng ý lại khi điều khoản nhóm thay đổi | Must | Should (D-13) | S | 01.05, 02.02 | Sau | BE, FM |
| US-01.07 | Rút đồng ý và rời nhóm (nhận US-02.07) | Must | Must | M | 01.05 | 3 | BE, FM |
| US-01.08 | Xem “Dữ liệu của tôi” | Must | Must | M | EP-03, EP-05, EP-06 | 4 | FM, BE |
| US-01.09 | Xuất dữ liệu của tôi | Should | Should | M | 01.08 | Sau | BE |
| US-01.10 | Xóa tài khoản | Should | Should | L | 01.08 | Sau | BE |
| US-01.11 | Xem ai đã xem dữ liệu của tôi | Should | Should | M | nhật ký truy cập | Sau | BE, FM |

### EP-02 Nhóm

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-02.01 | Tạo nhóm | Must | Must | M | 01.04 | 1 | BE, FM |
| US-02.02 | Sửa thông tin nhóm | Must | Should (D-13) | S | 02.01 | Sau | BE, FM |
| US-02.03 | Mời bằng mã nhóm | Must | Must | S | 02.01 | 1 | BE, FM |
| US-02.04 | Mời bằng email | Must | Should (D-13) | M | 02.01, SES | Sau | BE |
| US-02.05 | Tham gia nhóm kèm đồng ý minh bạch | Must | Hủy — gộp vào US-01.05 (D-14) | — | — | Hủy | — |
| US-02.06 | Xem nhóm của tôi và danh sách thành viên | Must | Must | S | 02.01 | 2 | FM |
| US-02.07 | Thành viên rời nhóm | Must | Hủy — gộp vào US-01.07 (D-14) | — | — | Hủy | — |
| US-02.08 | Chủ nhóm xóa thành viên | Must | Must | S | 02.06 | 3 | BE, FM |
| US-02.09 | Giải tán nhóm | Must | Should (D-13) | M | 02.01 | Sau | BE |
| US-02.10 | Đặt lịch phiên — **chỉ lịch một lần** ở MVP | Must | Must | M (xem §5.3) | 02.01 | 2 | BE, FM |
| US-02.10b | Đặt lịch phiên lặp lại (tách khỏi US-02.10; BR-113; Q-78) | Should | Should (ngoài nguồn GĐ1) | M | 02.10, 02.11 | Sau | BE, FM |
| US-02.11 | Sửa / hủy lịch phiên | Must | Must | M | 02.10 | 2 | BE, FM |
| US-02.12 | Cảnh báo trùng lịch giữa nhiều nhóm | Should | Hủy — D-21 (TV thuộc tối đa 1 nhóm, không còn trùng lịch chéo nhóm) | — | — | Hủy | — |
| US-02.13 | Báo cáo nhóm hoặc hồ sơ lạm dụng (Q-63, Q-105) | Should | Should | S | 02.06 | Sau | BE, FM |
| US-02.14 | Nhắc thành viên trước giờ phiên (Q-80) | Should | Should | S | 02.10, T-02 (SNS) | Sau | BE |

### EP-03 Phiên & Lockdown

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-03.01 | Vào phòng chờ phiên theo lịch | Must | Must | M | 02.10, T-04 | 2 | BE, FM |
| US-03.02 | Đếm ngược 5 giây và bắt đầu phiên | Must | Must | M | 03.01 | 2 | FM, BE |
| US-03.03 | Giao diện tối tĩnh, chỉ báo “Phiên đang được ghi” | Must | Must | S | 03.02 | 2 | FM |
| US-03.04 | Phát hiện rời app (khóa màn hình không tính) | Must | Must | L | **T-01** | 2 | FM, QB |
| US-03.05 | Khoan hồng 3 giây | Must | Must | M | 03.04 | 2 | FM, BE |
| US-03.06 | Tạm dừng có lý do | Must | Should (D-13) | M | 03.04 | Sau | FM, BE |
| US-03.07 | Mất kết nối giữa phiên | Must | Must | L | 03.02, T-04 | 3 | BE, FM |
| US-03.08 | Ghi nhận mất thưởng tập thể khi có người thoát | Must | Must | M | 03.05 | 2 | BE |
| US-03.09 | Thông báo mất thưởng tập thể, **có tên người thoát** (D-22; nhận US-04.02) — gửi cả nhóm + người trong phiên, 2 kênh (D-20) | Must | Must | **M** (ước lại từ S, T-BA) | 03.08 | 2 | BE, FM |
| US-03.10 | Kết thúc phiên và xem kết quả | Must | Must | M | 03.08 | 2 | FM, BE |
| US-03.11 | Vào muộn và vắng mặt | Must | Should (D-13) | M | 03.01 | Sau | BE |
| US-03.12 | Phiên bị hủy do sự cố server | Must | Should (D-13) | M | 03.07 | Sau | BE |
| US-03.13 | Chủ nhóm tham gia phiên của nhóm mình | Must | Hủy — D-25 (chủ nhóm không tham gia phiên) | — | — | Hủy | — |
| US-03.14 | Lịch sử phiên của tôi (BR-119; mockup S10, T-BA-102) | Should (giả định) | Should | S (giả định) | 03.10 | Sau | FM, BE |

### EP-04 Thông báo thoát

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-04.01 | Push **ngay** cho cả nhóm và mọi người trong phiên khi có người thoát (D-20) | Must | Must | M | 03.05, T-02 (SNS) | 2 | BE, CD, FM |
| US-04.02 | Thành viên được báo khi phiên mất thưởng tập thể | Must | Hủy — gộp vào US-03.09 (D-14) | — | — | Hủy | — |
| US-04.03 | Chủ nhóm chọn chế độ báo (ngay / gộp) | Should | **Won't (D-20, sau MVP)** | S | 04.04 | Sau MVP | BE, FM |
| US-04.04 | Bản gộp cuối phiên cho chủ nhóm | Should | **Won't (D-20, sau MVP)** | M | 03.10 | Sau MVP | BE |
| US-04.05 | Thành viên giải trình sự kiện thoát | Must | Must | S | 03.08 | 3 | FM, BE |
| US-04.06 | Chủ nhóm xem giải trình kèm sự kiện thoát | Must | Must | S | 04.05 | 3 | FM |
| US-04.07 | Thành viên khiếu nại sự kiện thoát bị ghi nhầm | Should | Should | M | 03.08 | Sau | BE, FM |
| US-04.08 | Chủ nhóm xử lý khiếu nại (miễn trừ / bác) | Should | Should | L | 04.07, 06.01 | Sau | BE, FM |
| US-04.09 | Thông báo phiên bị hủy | Must | Should (D-13) | S | 03.12 | Sau | BE |

### EP-05 Thành tích

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-05.01 | Ghi điểm danh ngày | Must | Must | S | 03.10 | 3 | BE |
| US-05.02 | Xem điểm danh của tôi | Must | Should (D-13) | M | 05.01 | Sau | FM |
| US-05.03 | Cập nhật chuỗi ngày sau mỗi phiên | Must | Must | M | 05.01, 03.08 | 3 | BE |
| US-05.04 | Xem chuỗi hiện tại và chuỗi dài nhất | Must | Must | S | 05.03 | 3 | FM |
| US-05.05 | Nhận huy hiệu theo mốc | Must | Must | M | 05.03 | 4 | BE, FM |
| US-05.06 | Xem bộ sưu tập huy hiệu, chọn hiển thị trên hồ sơ | Must | Should (D-13; nhận US-07.05, D-16) | S | 05.05 | Sau | FM |
| US-05.07 | Thông báo ngắt chuỗi | Must | Should (D-13) | M | 05.03 | Sau | BE, FM |
| US-05.08 | Lịch sử thành tích | Must | Should (D-13) | M | 05.05 | Sau | FM |
| US-05.09 | Chủ nhóm xem điểm danh của thành viên trong nhóm mình (**không gồm chuỗi**, D-12) | Must | Should (D-13) | S | 05.01 | Sau | FM |

### EP-06 Coins & Shop

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-06.01 | Nhận Coins sau phiên (hoàn thành có thưởng, D-11) | Must | Must | M | 03.10, T-05 | 3 | BE |
| US-06.02 | Xem số dư và lịch sử Coins | Must | Must (D-17) — **Should nếu Q-140 chọn PA-A (đề xuất)** | S | 06.01 | 4 | FM |
| US-06.03 | Duyệt Shop | Must | Must | M | T-05 (S3+CloudFront) | 3 | FM, CD |
| US-06.04 | Mua đồ trong Shop | Must | Must | M | 06.01, 06.03 | 3 | BE, FM |
| US-06.05 | Trang bị và gỡ đồ | Must | Must | S | 06.04 | 3 | FM |
| US-06.06 | Danh hiệu trong Shop | Could | Could | S | 06.04 | Sau | BE, FM |

### EP-07 Hồ sơ & Nhật ký

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-07.01 | Xem hồ sơ của tôi | Must | Must | S | 01.03 | 4 | FM |
| US-07.02 | Sửa tên hiển thị | Must | Hủy — gộp vào US-01.03 (D-14) | — | — | Hủy | — |
| US-07.03 | Đổi ảnh avatar (S3) | Must | Should (D-13) | M | 07.01 | Sau | FM, CD |
| US-07.04 | Hiển thị khung và hình nền đang trang bị | Must | Must (D-17) — **Should nếu Q-140 chọn PA-A (đề xuất, Q-140)** | S | 06.05, 07.01 | 4 | FM |
| US-07.05 | Chọn thành tích hiển thị công khai | Should | Hủy — gộp vào US-05.06 (D-16) | — | — | Hủy | — |
| US-07.06 | Xem hồ sơ công khai của người cùng nhóm | Must | Should (D-13) | S | 07.01 | Sau | FM, BE |
| US-07.07 | Viết nhật ký hằng ngày | Must | **Must (D-15)** | M | 01.01 | 4 | FM, BE |
| US-07.08 | Xem lại và sửa nhật ký | Must | Should (D-15) | S | 07.07 | Sau | FM |
| US-07.09 | Xóa mục nhật ký | Must | Should (D-15) | S | 07.07 | Sau | FM, BE |
| US-07.10 | Nhật ký riêng tư: chủ nhóm, người khác và quản trị không xem được trong app (BR-100) | Must | **Must (D-15)** | M | 07.07 | 4 | BE, QB |

### EP-08 Báo cáo tháng

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-08.01 | Tạo báo cáo tháng tự động (EventBridge + Lambda) | Must | Must | L | 03.10, 05.01 | 3 | BE, CD |
| US-08.02 | Chủ nhóm xem báo cáo của từng nhóm | Must | Must | M | 08.01 | 4 | FM, BE |
| US-08.03 | Thành viên xem dòng của chính mình | Must | Must | S | 08.01 | 4 | FM |
| US-08.04 | Thành viên xem tổng nhóm (≥5 thành viên) | Should | Should | S | 08.01 | Sau | FM |
| US-08.05 | So sánh với tháng trước | Should | Should | S | 08.01 | Sau | BE |
| US-08.06 | Tải báo cáo PDF trong app | Must | Should (D-13, D-24) | M | 08.01 | Sau | BE |
| US-08.07 | Gửi email **tóm tắt** báo cáo cho chủ nhóm (SES), không kèm PDF, có lối vào app (D-24) — **không phụ thuộc US-08.06** (T-BA-57) | Must | Must | M | 08.01, T-02 | 3 | BE, CD |
| US-08.08 | Thông báo mục đích sử dụng báo cáo | Must | Must | S | 02.01 | 4 (dời từ S2 để S2 = 25 sau khi US-03.09 thành M) | FM |
| US-08.09 | Nhóm chưa có dữ liệu trong kỳ | Must | Should (D-13) | S | 08.01 | Sau | BE |
| US-08.10 | Chủ nhóm xem chi tiết phiên đã kết thúc — chỉ đọc, không thời gian thực, không can thiệp (BR-116; Q-144, Q-146; T-BA-105) | Must | Must | S (giả định) | 03.10, 04.05 | 3 | FM, BE |

### EP-09 Quản trị (Should — MVP dùng T-05)

| Mã | Tên | MoSCoW gốc | MoSCoW | Ước | Phụ thuộc | Sprint | Phụ trách |
| --- | --- | --- | --- | --- | --- | --- | --- |
| US-09.01 | Đăng nhập Web Admin | Should | Should | S | T-02 (Cognito nhóm admin) | Sau | WA |
| US-09.02 | Khóa / mở tài khoản | Should | Should | M | 09.01 | Sau | WA, BE |
| US-09.03 | Quản lý danh mục Shop | Should | Should | M | 09.01 | Sau | WA, BE |
| US-09.04 | Điều chỉnh Coins có kiểm toán | Should | Should | M | 09.01, 06.01 | Sau | WA, BE |
| US-09.05 | Xử lý khiếu nại / lỗi chuyển lên quản trị | Should | Should | L | 04.08 | Sau | WA, BE |
| US-09.06 | Xử lý báo cáo lạm dụng nhóm | Should | Should | M | 09.02, US-02.13 | Sau | WA, BE |
| US-09.07 | Xem nhật ký truy cập | Should | Should | M | 09.01 | Sau | WA, BE |
| US-09.08 | Cấu hình thông số hệ thống (giao diện) | Could | Could (MVP cấu hình bằng T-05, đáp ứng C-09) | M | 09.01 | Sau | WA, BE |

Ghi chú: người phụ trách Web Admin trong MVP làm T-05, hỗ trợ QA và CI/CD; có thể nhận EP-09 nếu S4 còn dư.

## 5. Quyết định áp dụng và đề xuất còn mở

### 5.1 Gộp story trùng — D-14 (bớt 7 điểm)

| Giữ | Hủy (gộp vào story giữ) | Điểm bớt |
| --- | --- | --- |
| US-01.05 Đồng ý minh bạch | US-02.05 | 2 |
| US-01.07 Rút đồng ý và rời nhóm | US-02.07 | 2 |
| US-01.03 Sửa hồ sơ cơ bản | US-07.02 | 1 |
| US-03.09 Thông báo mất thưởng tập thể, có tên người thoát (D-22) | US-04.02 | 2 |

Không cộng điểm vào story giữ lại: các cặp cùng nội dung, AC hợp nhất không thêm luồng mới.

### 5.2 Hạ Must → Should — D-13, D-15

- D-13: US-01.06, 02.02, 02.04, 02.09, 03.06, 03.12, 04.09, 05.02, 05.06, 05.07, 05.08, 05.09, 07.03, 07.06, 08.06, 08.09 (25 điểm) và US-03.11 (2 điểm). US-03.13 trước đây hạ Should theo D-13, nay Hủy theo D-25 (không tính điểm).
- D-15: US-07.08, 07.09 Should (2 điểm); **US-07.07, 07.10 giữ Must** (4 điểm, xếp Sprint 4).

### 5.3 Tách lịch lặp khỏi US-02.10 (T-BA-43)

Lịch lặp lại (Q-78) không có trong GĐ1 → Should (01 §5). US-02.10 ở MVP chỉ đặt lịch một lần; ước lượng hạ từ L xuống M (−1 điểm), phần lặp là US-02.10b (M theo story, Should; giới hạn chuỗi theo BR-113).

### 5.4 Năng lực Sprint 4 — D-17 (Q-133 đã chốt)

Người dùng chọn **giữ 83 điểm Must**, Sprint 4 = 15. US-01.03, US-06.02, US-07.04 giữ Must ở Sprint 4.

Thứ tự cắt nếu Sprint 4 trễ (đề xuất, không chạm 4 tiêu chí demo GĐ1 §11 và ràng buộc riêng tư): US-07.04 → US-06.02 → US-01.03 → US-07.01 → US-05.05 (giữ nguyên EP-03 lõi, US-04.01, US-08.01, US-08.07, US-01.05, US-01.07, US-01.08, US-07.10).

### 5.5 Vượt 2 điểm: US-03.09 ước lại + pipeline iOS (Q-140, Chờ)

- US-03.09 S→M (+1) → dời US-08.08 (S) từ S2 sang S4; S4 = 16.
- D-26 (không có Mac): T-03 M→S, thêm T-06 M → +1 ở S1; S1 = 19. Không dời T-06 sang S2 được: phần iOS của T-01 (rủi ro #1, phải xong S1–2) phụ thuộc T-06.
- Review mockup (T-BA-105): US-08.10 Must S mới ở S3 → S3 = 26.
- Must = 86 > 83 (D-17), vượt 3 điểm.

| Phương án | Nội dung | S1/S2/S3/S4 | Must | Ảnh hưởng |
| --- | --- | --- | --- | --- |
| **PA-A (đề xuất, Q-140, cập nhật sau US-08.10)** | Như cũ: hạ **US-07.04** và **US-06.02** xuống Should; dời **US-01.02** S1→S4. **Thêm:** gộp **US-04.06** (S, chủ nhóm xem giải trình) vào **US-08.10** — AC-04.06.1 đã hiển thị giải trình trên màn "Chi tiết phiên", nên trùng nội dung, theo cách D-14 (không cộng điểm) — cần ba-stories xác nhận | 18/25/25/15 | 83 | Giữ đúng D-17. Không mất tính năng nào ngoài US-07.04, US-06.02 (như PA-A cũ). Không chạm GĐ1 §11. |
| PA-A2 (dự phòng nếu không gộp được US-04.06) | PA-A cũ + dời **US-02.08** (S) S3→S4 + hạ **US-01.03** (S, mục thứ 3 trong thứ tự cắt §5.4) xuống Should | 18/25/25/15 | 83 | Mất thêm sửa hồ sơ cơ bản ở MVP (tên hiển thị lấy từ đăng ký — **giả định**). |
| PA-B | Giữ 86 Must | 19/25/26/16 | 86 | S1 vượt hệ số 0,7; S3 vượt 1; S4 vượt ước tính 12 tới 4 điểm. Cần sửa D-17. |
| PA-C (phụ thuộc T-BA-69) | Nếu US-03.09 ước lại về S: dời US-01.02 S1→S2; hạ US-07.04 xuống Should; gộp US-04.06 vào US-08.10 như PA-A | 18/25/25/15 | 83 | Cần ba-stories xác nhận T-BA-69 và việc gộp. |

Bảng §2 và §4 đang phản ánh PA-B (trạng thái hiện tại, chưa cắt) cho đến khi Q-140 được chốt. Lưu ý: US-08.08 dời về S4 làm tách khỏi luồng tạo nhóm ở S2 (§6).

## 6. Mục tiêu demo mỗi sprint

| Sprint | Trọng tâm (Quy trình §12) | Demo cuối sprint | Tiêu chí GĐ1 §11 |
| --- | --- | --- | --- |
| 1 | Chốt phạm vi, kiến trúc, hạ tầng, thử rủi ro cao nhất | PoC T-01 chạy trên **máy thật iOS và Android** (iOS: bản TestFlight từ GitHub Actions, D-26; iPhone thật — Q-142): khóa màn hình không tính, rời app được ghi; đăng nhập Cognito; tạo nhóm, mời bằng mã; AWS có cảnh báo ngân sách; CI build Android (T-03) và IPA ký + TestFlight (T-06) | Nền cho “≥3 dịch vụ AWS có vai trò” |
| 2 | Luồng chính end-to-end | Một chủ nhóm tạo và quản lý **2 nhóm** (chủ nhóm không tham gia phiên, D-25; mỗi thành viên chỉ ở 1 nhóm, D-21), đặt lịch 25’ cho từng nhóm; thành viên đồng ý, vào phiên, úp máy; một người rời app >3s → **chủ nhóm, cả nhóm và người trong phiên nhận push trong vài giây, có tên người thoát** (D-20, D-22), cả phiên mất thưởng, phiên vẫn chạy đến hết | §11 #1, #2 |
| 3 | Tính năng phụ, cloud còn lại | Coins/chuỗi/điểm danh sau phiên; Shop mua và trang bị; giải trình; mất kết nối; báo cáo tháng tạo bằng EventBridge + Lambda và **gửi email tóm tắt qua SES** (không PDF, D-24) | §11 #3, #4 |
| 4 | Kiểm thử, sửa lỗi, tài liệu, phát hành bản thử | Bản phát hành thử; thông báo mục đích báo cáo (US-08.08); hồ sơ, huy hiệu, nhật ký riêng tư, “Dữ liệu của tôi”, xem báo cáo trong app; báo cáo và slide giải thích vai trò từng dịch vụ AWS | Toàn bộ §11 |

Sprint 2: US-08.08 (S) trước đây chuyển từ S4 lên S2; nay dời lại S4 để S2 = 25 sau khi US-03.09 thành M (§5.5).

## 7. Should / Could để sau MVP

| Nhóm | Mục | Điểm |
| --- | --- | --- |
| Should gốc | US-01.09 (2), 01.10 (3), 01.11 (2), 04.07 (2), 04.08 (3), 08.04 (1), 08.05 (1), 09.01 (1), 09.02–09.04 (6), 09.05 (3), 09.06–09.07 (4) (T-BA-61: tính lại; bỏ 02.12 Hủy D-21, 04.03/04.04 Won't D-20; US-07.05 Hủy D-16) | 28 |
| Should do D-13 | US-01.06, 02.02, 02.04, 02.09, 03.06, 03.11, 03.12, 04.09, 05.02, 05.06, 05.07, 05.08, 05.09, 07.03, 07.06, 08.06, 08.09 (US-03.13 Hủy — D-25) | 27 |
| Should do D-15 | US-07.08, 07.09 | 2 |
| Should bổ sung (T-BA-43, T-BA-44) | US-02.10b lịch lặp lại (M, BR-113, Q-78); US-02.13 báo cáo lạm dụng nhóm/hồ sơ (S, Q-63, Q-105); US-02.14 nhắc trước giờ phiên (S, Q-80) | 4 |
| Should **chưa có story** (T-BA-44) | Phiên tự do cá nhân, tính Coins, không báo ai (01 §5, A-11, Q-02) | chưa ước lượng |
| Should bổ sung (review mockup, T-BA-102) | US-03.14 lịch sử phiên của tôi (S, giả định; BR-119) | 1 |
| **Tổng Should** | 37 US (14 + 17 + 2 + 3 + 1) | **62** (+ phiên tự do chưa ước lượng; PA-A Q-140 thêm US-07.04, 06.02 → 64) |
| Hủy (không tính điểm) | US-02.05, 02.07, 04.02, 07.02 (D-14); US-07.05 (D-16); US-02.12 (D-21); US-03.13 (D-25) | — |
| Could | US-06.06, US-09.08 | 3 |
| Won't (sau MVP) | US-04.03, US-04.04 (D-20) | 3 |

Thứ tự ưu tiên gợi ý nếu dư năng lực: US-03.06 tạm dừng và US-04.07/04.08 khiếu nại (giảm báo oan, GĐ1 §10 #3, quan trọng vì D-05 phạt cả phiên) → US-07.08/07.09 → US-08.06 PDF → EP-09.

## 8. Câu hỏi

| Mã | Câu hỏi | Phương án đề xuất | Trạng thái |
| --- | --- | --- | --- |
| Q-128 | Hạ 16 story Must + 03.11, 03.13 xuống Should | Đồng ý | Đã chốt — D-13 |
| Q-129 | Gộp 4 cặp story trùng | Đồng ý | Đã chốt — D-14 |
| Q-130 | Nhật ký riêng tư có ở MVP | 07.07, 07.10 Must; 07.08, 07.09 Should | Đã chốt — D-15 |
| Q-133 | Must 83 > 80: hạ 3 story hay Sprint 4 = 15? | Hạ 3 story | Đã chốt — D-17 (giữ 83, Sprint 4 = 15) |
| Q-03, Q-33 | Chế độ báo ngay/gộp | Ngay, gộp Should | Đã chốt — D-20 (chỉ báo ngay, cả nhóm + phiên; gộp Won't) |
| Q-04 | Một người ở nhiều nhóm? | Nhiều nhóm | Đã chốt — D-21 (TV tối đa 1 nhóm) |
| Q-64, Q-36 | Email báo cáo Must? PDF? | Email Must kèm PDF | Đã chốt — D-24 (email tóm tắt Must, PDF Should) |
| Q-19, Q-135, Q-139 | Chủ nhóm có tham gia phiên? | — | Đã chốt — D-25 (không tham gia; US-03.13 Hủy) |
| Q-140 | (Mở rộng sau D-26 và review mockup) US-03.09 S→M, T-06 pipeline iOS, US-08.10 Must mới → Must 86 > 83 (D-17). PA-A: hạ US-07.04, US-06.02, dời US-01.02 sang S4, gộp US-04.06 vào US-08.10; PA-A2: thay gộp bằng dời US-02.08 sang S4 + hạ US-01.03; PA-B: giữ 86, sửa D-17; PA-C: theo T-BA-69 | PA-A (đề xuất) — xem §5.5 | Chờ |
| Q-146 | US-05.09 giữ Should; lối vào chính cho dữ liệu phiên của CN là US-08.10 (04 §3 đã sửa) | Giữ Should | Chờ |
| Q-141 | Sĩ số 4–10 có gồm chủ nhóm? | Không gồm | Chờ |
| Q-142 | Nhóm có ≥1 iPhone thật cho spike T-01 iOS? | Cần có | Chờ (chặn phần iOS của T-01) |
