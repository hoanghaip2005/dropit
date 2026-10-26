# Đợt 02 — Chi tiết phiên và gửi/sửa giải trình

Trạng thái: **ĐÃ TRIỂN KHAI / CHƯA XÁC MINH HÌNH ẢNH**. Người dùng yêu cầu chuyển tiếp sang chi tiết phiên và giải trình; không coi đợt 01 đã nghiệm thu hình ảnh.

## Kết quả triển khai

- Bản web bàn giao ngày 23/10/2026: http://127.0.0.1:8080/_preview/7f14cfb0368c/#/history . Build release thành công; preview HTTP 200, backend `/health` 200 sau bật lại dịch vụ.
- `X-Preview-Version=7f14cfb0368c`; SHA256 `main.dart.js=9F8B6A82C0A0364A5A9A68598184C00494D7566D70C83B250977FD21FC0B17A4`. URL prefix không thay content hash tại lần kiểm.
- Build JavaScript có cảnh báo dry-run Wasm/socket và font Cupertino như trước, không chặn build này. Chưa chạy Wasm hoặc xác minh browser hình ảnh.

- Phân xử nguồn và nghiệp vụ: [02-DETAIL-EXPLANATION-DECISIONS.md](02-DETAIL-EXPLANATION-DECISIONS.md). Kiểm độc lập: [02-VERIFICATION.md](02-VERIFICATION.md).
- Implementer chi tiết phiên: `/root/implementation_audit`; implementer giải trình: `/root/design_reference`; verifier độc lập cả hai: `/root/design_arbitration`; tích hợp/API: `/root`.
- Chi tiết phiên dùng nền trung tính, card trắng, mode và trạng thái riêng; thời lượng thực theo giây; giờ vào/rời/kết thúc từ server, lịch dự kiến ghi rõ. Giữ phân biệt trạng thái, quyền khiếu nại, luồng quay lại và về trang chủ.
- Giải trình mở editor sau khi tải đủ quyền; hạn gửi/sửa từ server, hết hạn chỉ đọc, 500 Unicode code points cùng backend. Gửi thất bại giữ draft, chặn gửi đôi, xác nhận khi đóng nội dung chưa lưu; xem bản cũ và ngày sửa đầy đủ.
- Hành động xem giải trình còn tồn tại sau hạn gửi khi đã có bản. Chuỗi được ghi là hiện tại; không bịa snapshot của phiên cũ. Giải trình riêng tư giữa chính người gửi và chủ nhóm.
- Core/API: thêm metadata deadline/cap/has_explanation, version + If-Match; PUT trả cùng quyền/hạn/bản cũ như GET. OpenAPI cập nhật và parse YAML đạt (53 paths).
- Root chạy 6 file Flutter test liên quan: 63/63 đạt. Analyze 8 file sạch. Backend typecheck đạt; 9 integration tests đạt, gồm quyền/hạn gửi/sửa, stale If-Match và lịch sử revisions. Không thay seed người dùng.
- Kiểm thử legacy sửa cách cuộn tới card trước khi assert, vì PageList lazy đã bỏ card ngoài viewport; giữ assert ngày giờ thật, không bỏ tiêu chí.
- Chưa có ảnh runtime đúng build để đối chiếu hoặc kiểm keyboard thực. Những mục ở dưới là kế hoạch/baseline; không được suy thành visual pass.

## Phạm vi

- Route `/session/:sid/result`, `/history/:sid`; vai trò thành viên.
- Nguồn: `mockup/n_09_k_t_qu_r_i_phi_n_s_m/code.html`, `app/design/design-system.html`.
- Mã: `app/lib/features/session/result_screen.dart`; chỉ mở rộng file khác khi ghi tác động.
- Tham chiếu hai audit và D08–D12 trong `DECISIONS.md`.

## Các lô

1. Chụp baseline EXITED và LOST ở cả hai đường vào; ghi build/hash/viewport và dữ liệu thật. Chưa có bằng chứng runtime hiện tại.
2. Phân xử từng phần: tiêu đề, thông tin thời gian, thưởng, tác động nhóm, giải trình/khiếu nại và điều hướng. Nội dung mẫu Stitch không quyết định nghiệp vụ.
3. Implementer sửa bố cục riêng theo quyết định; không đổi lifecycle, timeout, tính thưởng hoặc quyền gửi giải trình.
4. Verifier khác implementer kiểm hình ảnh và thao tác; trả findings để sửa lại đến khi đủ bằng chứng.

## Tiêu chí đóng

- EXITED không bị trình bày như LOST; không khẳng định tác động nhóm hoặc thời điểm rời nếu dữ liệu không hỗ trợ.
- Giữ `canExplain`, `canAppeal`, luồng mở từ lịch sử và hành động hợp lệ theo trạng thái.
- Kiểm tên dài, chữ lớn, màn hẹp; không overflow; thao tác chính rõ ràng.
- Ảnh trước/sau cùng trạng thái, cùng viewport, build xác định; verifier ghi kết luận độc lập.

Chưa phân công implementer/verifier cho vòng sửa. Chưa có ảnh runtime, chưa nghiệm thu. Dùng `VIEW_TEMPLATE.md` bổ sung metadata, bảng findings và vòng kiểm khi bắt đầu.
