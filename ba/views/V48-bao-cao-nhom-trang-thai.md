# V-48 Báo cáo nhóm — trạng thái và mục đích (bổ sung mockup)

Story: US-08.01 (Must), US-08.02 (Must), US-08.08 (Must), US-08.09 (Should, phần trạng thái) · Quy tắc: BR-53, BR-55, BR-56, BR-57, BR-58, BR-59, BR-60, BR-61, BR-101, BR-102, BR-103, BR-115 · Quyết định: D-03, D-10, D-11, D-12, D-21, D-24, D-25 · NFR: NFR-P07, NFR-P09, NFR-P10 · Token: DESIGN.md
Bổ sung cho `mockup/manager_analytics_report` (đã sửa đợt 2). Tệp này thắng khi lệch.

## Mục đích
Đặc tả phần mockup chưa vẽ: khối mục đích ở đầu, chọn nhóm/kỳ, các trạng thái chưa có báo cáo / không dữ liệu / lỗi, và ràng buộc thứ tự dòng.

## Vai trò
Chủ nhóm hiện tại của nhóm (BR-103). Thành viên xem dòng của mình ở V-34.

## Lối vào / lối ra
- Vào: V-40, V-41 chạm "Báo cáo"; link email V-50 (sau đăng nhập).
- Ra: chạm thành viên → V-49; chạm phiên → V-46; "Tải PDF" chỉ khi US-08.06 (Should) trong phạm vi.

## Thành phần

| Phần tử | Dữ liệu | Nguồn BR / API (giả định) |
| --- | --- | --- |
| Chọn nhóm | Một nhóm mỗi lần; không có mục "Mọi nhóm" | AC-08.02.10, D-21 |
| Chọn kỳ | Tháng dương lịch, trong 13 tháng | BR-55, BR-103 |
| Khối mục đích (V-35) | Nguyên văn mục đích lúc tạo báo cáo, đứng đầu màn | US-08.08, AC-08.08.1, .2, .3 |
| Tổng nhóm | Số phiên đã diễn ra, tỉ lệ hoàn thành phiên, tỉ lệ hoàn thành có thưởng, số phiên mất thưởng tập thể, so với tháng trước | §Báo cáo §3, D-11 |
| Bảng dòng thành viên | Theo §Báo cáo §2; sắp tên A→Z; nhãn "vào ngày dd/mm" / "rời ngày dd/mm" | BR-59, BR-60, BR-115 |
| Danh sách phiên trong kỳ | Ngày, tên lịch, nhãn "Mất thưởng" nếu có; chạm → V-46 | AC-08.02.9 |
| Nhãn giải trình mới | "Thêm sau khi tạo báo cáo" | BR-102 |
| Dòng "Tạo lúc" | "Báo cáo tạo lúc 02:00 dd/mm — số liệu không đổi sau khi tạo" | BR-56 |

API: `GET /groups/{gid}/reports/{yyyy-mm}`; mỗi lần mở ghi nhật ký truy cập (AC-08.02.4). Tham số sắp theo chỉ số bị bỏ qua (AC-08.02.12).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Khối mục đích + tổng nhóm + bảng + danh sách phiên |
| Chưa có báo cáo đầu tiên | "Báo cáo đầu tiên sẽ có vào 01/mm." (AC-08.09.3); khối mục đích vẫn hiện mục đích hiện hành |
| Kỳ hiện tại (chưa hết tháng) | "Báo cáo tháng này sẽ có vào 02:00 ngày 01/mm." |
| Kỳ không có phiên | "Kỳ này chưa có phiên nào"; hai tỉ lệ "không có dữ liệu", không hiện 0% (AC-08.09.1, .2) |
| Biên — có phiên, 0 hoàn thành | Báo cáo đầy đủ, tỉ lệ 0,0% (AC-08.09.4) |
| Đang tạo / tạo lỗi đang chạy lại | "Báo cáo đang được tạo. Vui lòng quay lại sau 06:00." (BR-101) |
| Thiếu mục đích (dữ liệu cũ) | "Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo" (AC-08.08.3) |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa tải được báo cáo." + "Thử lại" |
| Lỗi quyền (403) | "Bạn không có quyền xem báo cáo nhóm này." (AC-08.02.5) |
| Mất mạng | Bản đã lưu + "Chưa cập nhật"; không có bản lưu → "Cần kết nối mạng để xem." |

## Câu chữ chính
- "Mục đích sử dụng báo cáo: ‹nguyên văn›"
- "Báo cáo đầu tiên sẽ có vào 01/11."
- "Kỳ này chưa có phiên nào."
- "Số liệu không đổi sau khi tạo."

## Điều cấm
- Không Coins, chuỗi, tên app (AC-08.02.6, AC-08.01.11).
- Không dòng chủ nhóm (BR-60, AC-08.02.7).
- Không sắp/lọc theo cột chỉ số, không huy chương/top/tô màu cao-thấp, không số thứ tự hạng (BR-115, AC-08.02.12).
- Không gộp số liệu nhiều nhóm (AC-08.02.10).
- Không giờ tập trung cấp người dùng, "Session Efficiency" (BR-59, T-BA-89).

## AC liên quan
AC-08.01.1 … .11 (hiển thị kết quả); AC-08.02.1 … .12; AC-08.08.1, .2, .3; AC-08.09.1 … .4.
