# DropIt! — Harness tài liệu Business Analyst

Dự án: **DropIt!** (nhóm Bá Khí, 5 người, 4 sprint, bắt buộc ≥3 dịch vụ AWS).
Giai đoạn hiện tại: **2 – Yêu cầu** (đầu ra: SRS, User Story, Quy tắc nghiệp vụ, Product Backlog).

## Thứ tự ưu tiên nguồn (khi mâu thuẫn, nguồn trên thắng)

1. `ba/02-so-quyet-dinh.md` — quyết định đã chốt (D-xx)
2. `DropIt! — Giai đoạn 1_ Ý tưởng (bản văn phòng).md` — phạm vi nghiệp vụ bản 1.1
3. `ba/srs/05-tham-chieu-ky-thuat.md` — chỉ dùng làm **tham khảo kỹ thuật** (phát hiện rời app, socket, dữ liệu, AWS, heartbeat, ca kiểm thử), không phải yêu cầu. Mọi thứ về *cược điểm, nổ phòng, Host/Guest, phòng 2–6 người* đã **bị bỏ** ở bản 1.1.
4. `Tài liệu tổng quát_ Quy trình làm một ứng dụng.md` — phương pháp, mẫu, DoD, MoSCoW.

## Quy ước mã định danh

| Tiền tố | Loại | Ví dụ |
| --- | --- | --- |
| `EP-` | Epic | EP-03 Phiên tập trung |
| `US-` | User story | US-03.02 |
| `FR-` | Yêu cầu chức năng | FR-05 |
| `BR-` | Quy tắc nghiệp vụ | BR-12 |
| `NFR-` | Yêu cầu phi chức năng | NFR-04 |
| `Q-` | Câu hỏi mở | Q-01 |
| `D-` | Quyết định đã chốt | D-01 |
| `R-` | Rủi ro | R-01 |
| `T-BA-` | Việc BA | T-BA-07 |

Không đổi số đã cấp; mục bị bỏ ghi `(Hủy — lý do)`.

## Luật viết

- Tiếng Việt, câu ngắn, mỗi yêu cầu **kiểm tra được**.
- Mọi suy luận chưa xác nhận gắn **(giả định)**; đề xuất gắn **(đề xuất)** và tạo `Q-` tương ứng.
- User story theo mẫu `ba/mau/user-story.md`, luôn có ca bình thường **và** ca lỗi.
- Ưu tiên MoSCoW; MVP = chỉ Must.
- Không tự chốt câu hỏi mở — chỉ đề xuất, ghi vào `ba/02-so-quyet-dinh.md` trạng thái `Chờ`.
- Mỗi FR/US phải truy được về nguồn (mục tài liệu GĐ1 hoặc D-xx) trong `ba/03-truy-vet.md`.
- Quyền riêng tư (GĐ1 mục 6) là ràng buộc cứng: không yêu cầu nào được đọc nội dung điện thoại hay ghi dữ liệu ngoài phiên.

## Cách chạy harness

Xem `ba/00-dieu-phoi.md`. Tóm tắt: điều phối viên (agent chính) giao việc theo từng luồng cho các agent trong `.claude/agents/ba-*.md`, rồi chạy `ba-reviewer` trước mỗi cổng.
