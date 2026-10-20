# V-35 Khối "Mục đích sử dụng báo cáo" (thành phần dùng chung)

Story: US-08.08 (Must) · Quy tắc: BR-56, BR-61, BR-71, BR-105 · Q: Q-12 · NFR: NFR-P09 · Rủi ro: R-P03 · Token: DESIGN.md

## Mục đích
Hiện nguyên văn mục đích chủ nhóm khai khi tạo nhóm, ở **đầu** mọi nơi hiển thị báo cáo, để thành viên biết số liệu của mình được dùng vào việc gì.

## Vai trò
Mọi người xem báo cáo: thành viên (V-34), chủ nhóm (V-48, V-49), người nhận email (V-50), PDF (US-08.06, Should). Cũng dùng trên màn đồng ý V-05 (04 §2 mục 7).

## Vị trí bắt buộc

| Nơi | Vị trí |
| --- | --- |
| V-05 Đồng ý minh bạch | Mục 7 của nội dung đồng ý |
| V-34 Báo cáo của tôi | Ngay dưới tiêu đề, trước mọi số |
| V-48 Báo cáo nhóm (mockup/manager_analytics_report) | Ngay dưới tiêu đề (mockup đợt 2 đã đặt ở đầu — giữ) |
| V-49 Chi tiết dòng thành viên (mockup/t_11) | Ngay dưới tiêu đề — **cần thêm** vào mockup |
| V-50 Email | Khối đầu thân thư |
| PDF *(Should)* | Đầu trang 1 |

## Thành phần

| Phần tử | Dữ liệu | Nguồn |
| --- | --- | --- |
| Thẻ | Nền `#FFF1EC`, bo 24px, không đóng/ẩn được | DESIGN.md |
| Nhãn | "Mục đích sử dụng báo cáo" (`label-md`, `#B02F00`) | — |
| Nội dung | Nguyên văn chủ nhóm nhập, không cắt bớt (xuống dòng nếu dài) | NFR-P09, AC-08.08.1 |
| Dòng nguồn | "Do chủ nhóm ‹Tên› khai báo lúc tạo nhóm." (`body-sm`, `#6C6C70`) | — |
| Dòng phiên bản (chỉ trên báo cáo đã tạo) | "Mục đích tại thời điểm tạo báo cáo ‹dd/mm/yyyy›." | BR-56, AC-08.08.2 |
| Dòng chung | "DropIt! không quyết định việc báo cáo được dùng để đánh giá hay kỷ luật; đó là quyết định của nơi bạn làm việc." | Q-12 (đề xuất) |

Dữ liệu: báo cáo đã tạo lấy `purpose` trong bản chụp; màn đồng ý lấy `purpose` của phiên bản đồng ý hiện hành (BR-71).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Nguyên văn mục đích |
| Thiếu trường (dữ liệu cũ) | "Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo." (AC-08.08.3, giả định); không chặn báo cáo |
| Mục đích đã đổi sau khi tạo báo cáo | Báo cáo cũ vẫn hiện mục đích cũ (AC-08.08.2) |
| Đang tải / lỗi / mất mạng | Theo màn chứa; khối không bao giờ bị bỏ qua khi phần số liệu đã hiện |

## Câu chữ chính
- "Mục đích sử dụng báo cáo"
- "Do chủ nhóm ‹Tên› khai báo lúc tạo nhóm."
- "Chưa khai báo mục đích — báo cáo chỉ mang tính tham khảo."

## Điều cấm
- Không đặt khối ở cuối, trong chữ nhỏ, hay sau nút "Xem thêm".
- Không cho chủ nhóm ẩn khối trên một báo cáo cụ thể.
- Không sửa mục đích trong báo cáo đã tạo (bản chụp).
- Không câu khẳng định thay công ty ("báo cáo không dùng để kỷ luật") — app không kiểm soát được (Q-12).

## AC liên quan
AC-08.08.1, .2, .3; AC-08.06.1 (PDF, Should); AC-01.05.1 (mục 7).
