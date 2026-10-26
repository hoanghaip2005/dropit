# Đợt 04 — kiểm tra độc lập mã nguồn

Ngày 23/10/2026. Người kiểm tra: `design_arbitration`, khác agent triển khai. Đã đối chiếu `04-SESSION-DECISIONS.md`, 18 phát hiện trong `04-SESSION-AUDIT.md`, `session_screen.dart` và controller. Không chạy Flutter trong vòng này. **CHƯA XÁC MINH HÌNH ẢNH**.

## Phát hiện và kết quả kiểm tra lại

| ID | Mức | Vấn đề / yêu cầu | Kết quả |
|---|---|---|---|
| V04-01 | P1 | Dialog giữ ngữ cảnh phòng chờ trước khi chờ xác nhận. Nếu phiên đã bắt đầu, xác nhận có thể áp hậu quả rời phiên thay vì ghi vắng như nội dung vừa đọc. | ĐÓNG QUA KIỂM TRA MÃ NGUỒN: kiểm `mounted`, `current.canLeave`, `current.leaving`; ngữ cảnh thay đổi thì thông báo và không rời. Đã đọc test chuyển `waiting` sang `focusing`, xác nhận có `leaveCalls == 0`. |
| V04-02 | P2 | Countdown giới hạn 1–5, grace giới hạn 0–3 có thể sai khi cấu hình khác hoặc hết hạn. Nội dung 3 giây / 1 lượt chưa có dữ liệu chính sách từ API. | ĐÓNG QUA KIỂM TRA MÃ NGUỒN: dùng `math.max(0, ...)`, bỏ giới hạn trên; countdown bằng 0 thông báo đồng bộ. Nội dung dùng thời hạn khoan hồng chung. Đã đọc test thời hạn khác mặc định. |
| V04-03 | P2 | Lớp mất kết nối chưa cuộn được khi màn thấp hoặc chữ lớn. | ĐÓNG QUA KIỂM TRA MÃ NGUỒN: nền `ColoredBox` toàn màn, nội dung dùng `Center` và `SingleChildScrollView`. Đã đọc test chạm không gọi hành động rời phía dưới. Bố cục runtime vẫn cần kiểm tra. |
| V04-04 | P2 | Cam kết khóa màn hình không tính là rời chưa đúng với mọi thiết bị hoặc thứ tự tín hiệu. Lỗi metadata HTTP không chứng minh socket vẫn kết nối. | ĐÓNG QUA KIỂM TRA MÃ NGUỒN: nêu giới hạn thiết bị tương thích; lỗi metadata tách khỏi trạng thái kết nối. Có test không lộ thông báo kỹ thuật. |
| V04-05 | P2 | Snackbar hiển thị trực tiếp `v.leaveError`, có thể chứa thông báo kỹ thuật từ ACK. | ĐÓNG QUA KIỂM TRA MÃ NGUỒN: dùng thông báo trung tính; giữ `clearLeaveError()`, không sửa controller. |

## Những phần đã xác nhận từ mã nguồn

- Phòng chờ không còn mặc định 25 phút hoặc suy thưởng 10/25 Coins từ thời lượng. Đồng hồ có nhãn “Bắt đầu sau”; số người chưa biết khác số 0. Không tạo nút sẵn sàng, tổng người hoặc avatar giả.
- Lỗi vào phiên được ánh xạ từ mã lỗi. Bản web nêu giới hạn phân biệt khóa màn hình và ẩn trang. Active, countdown và grace giữ nền tối tĩnh; LOST không hiển thị đồng hồ đang chạy, trạng thái đang ghi hoặc kết quả 0 Coins suy đoán.
- Banner nằm trong luồng cuộn; chỉ hiển thị tên, thời điểm, trạng thái mất thưởng và số thông báo. Lớp kết nối lại phủ toàn màn, chặn thao tác xuyên xuống nội dung phía dưới.
- Dialog có bảo vệ mở trùng, kiểm tra vòng đời widget và đọc lại trạng thái sau xác nhận. Controller giữ nguyên hash so với audit ban đầu; không sửa lifecycle hoặc backend.
- Countdown, active, grace và mất kết nối có hỗ trợ cuộn. Chính sách nút Back giữ nguyên; không thêm nút rời ở countdown hoặc LOST, không đổi cơ chế nối lại phiên.

## Thay đổi bổ sung S17

Đã đọc lại nội dung `SERVER_OUTAGE`: “Kết quả sẽ được chốt theo trạng thái tham gia của bạn”, thay cam kết mọi kết quả đều không bị tính. Cách diễn đạt tránh suy kết quả cá nhân từ lý do hủy phiên. S17 được đóng trong phạm vi kiểm tra mã nguồn.

## Snapshot cuối sau S17

| File | SHA256 |
|---|---|
| `app/lib/features/session/session_screen.dart` | `156849C8179A574CA687AE90DC66B5094C0F337ED61A1E2DB34DA9CBF999F2F6` |
| `app/test/session_screen_design_test.dart` | `E4CA1E77CEC1A7677B43402C4AA39981892095B82255A3DA46272DED038DE06D` |
| `app/lib/features/session/session_controller.dart` | `69BF07CF751431ABF5652811ED22ACA2FD08B97D41F7A53C510851FBBDC2E920` |

Snapshot thay các hash trước lint và trước S17. Kết quả do agent triển khai và root cung cấp: bộ 56/56 test đạt trước sửa câu chữ S17; sau S17 chạy lại 15/15 test mới đạt; analyze 3 file (màn phiên, test mới, test cũ) sạch. Verifier không chạy lại; root sẽ bổ sung thông tin build riêng.

## Cổng nghiệm thu còn mở

- Đã đọc trực tiếp các sửa đổi và test; cả 5 phát hiện được đóng trong phạm vi kiểm tra mã nguồn. Kết quả thực thi do agent triển khai và root cung cấp đã ghi ở trên; verifier không chạy lại Flutter. Chưa phát hiện lỗi mới trong phạm vi sửa.
- Cần ảnh runtime đúng build, vai trò và trạng thái ở chiều rộng 320/390/768 px; kiểm tra chữ lớn, vùng cuộn và SafeArea trước khi nghiệm thu thị giác.
- Kiểm chứng lifecycle Android khác kiểm tra giao diện web. Widget test và hash mã nguồn không thay thế bằng chứng trên thiết bị hoặc ảnh runtime. Chưa có kết luận đạt về hình ảnh.
