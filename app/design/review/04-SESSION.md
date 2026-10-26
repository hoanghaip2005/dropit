# Đợt 04 — Phòng chờ và màn tập trung

Ngày bắt đầu: 23/10/2026. Trạng thái: **ĐÃ TRIỂN KHAI, KIỂM CHÉO SOURCE / CHƯA XÁC MINH HÌNH ẢNH**.

Người dùng yêu cầu tiếp tục các màn khác. Phạm vi kế tiếp là phòng chờ, đếm ngược, tập trung, khoan hồng, mất kết nối và xác nhận rời phiên. Đợt 01/02 vẫn chưa được nghiệm thu hình ảnh.

## Sở hữu và nguồn

- Implementer: `/root/implementation_audit`, chỉ `app/lib/features/session/session_screen.dart` và `app/test/session_screen_design_test.dart`.
- Audit nguồn/app: `/root/design_reference`, [04-SESSION-AUDIT.md](04-SESSION-AUDIT.md).
- Phân xử/verifier độc lập implementer: `/root/design_arbitration`, [04-SESSION-DECISIONS.md](04-SESSION-DECISIONS.md).
- Mockup: `mockup/session_lobby_1/`, `mockup/session_lobby_2/`, `mockup/lockdown_mode/`, `mockup/lockdown_mode_active_focus_1/`, `mockup/n_07_c_nh_b_o_khoan_h_ng_3_gi_y/`.
- Thư viện tham chiếu: `app/design/design-system.html`; yêu cầu/nghiệp vụ ưu tiên hơn sample mockup.

## Checklist bắt buộc

| Vùng | Nội dung / trạng thái cần kiểm |
|---|---|
| Phòng chờ | Tên nhóm, giờ bắt đầu, thời lượng thật hoặc chưa biết, số người/names thật, trạng thái kết nối, quy tắc, thưởng chỉ khi có nguồn đáng tin, rời phòng chờ và hủy xác nhận |
| Countdown | Metadata thật, thời gian server, chưa ghi trước lúc bắt đầu, không nút thao tác thừa, nội dung hẹp/chữ lớn |
| Tập trung | Nền đen tĩnh, recording, ngữ cảnh phiên, thời gian còn lại/kết thúc, forfeited, nút rời, rút đồng ý |
| Khoan hồng | Deadline thật, cảnh báo hệ quả đúng trạng thái, thoát khẩn cấp qua xác nhận; không animation mới |
| Mất mạng / LOST | Phân biệt với EXITED, không giả nhóm mất thưởng vì mất mạng, LOST không dùng đồng hồ nhóm như thời gian còn lại của mình |
| Banners | Tên thật/forfeited/dismiss, không che hết nút; timer không đọc ref sau dispose |
| Các cổng | Connecting/error/cancelled/transitions; lỗi người dùng hiểu được, không lộ tên socket event; giữ quyền/điều hướng |
| Responsive | 320×740, 390×844, 768×1024, text scale1.5, tên dài và cuộn tới thao tác |

## Phạm vi không đổi

- Không sửa controller, backend, heartbeat, timeout, classification hoặc lifecycle.
- Baseline SHA256 controller: `69BF07CF751431ABF5652811ED22ACA2FD08B97D41F7A53C510851FBBDC2E920`.
- Baseline SHA256 lifecycle Dart: `CDE841F09C9C824B938CD2F345B1C471F56173730BE8775E7BE09724C8E2B32A`.
- Không sửa seed hoặc khởi tạo phiên thật chỉ để có ảnh đẹp.
- Kiểm thử layout/source không thay nghiệm thu ảnh browser hoặc hành vi Android thật. Không dùng công cụ khác né giới hạn truy cập UI của phiên.

## Kết quả

- Phòng chờ dùng canvas trung tính, card trắng không outline; thời lượng, giờ, thành viên lấy dữ liệu thật. Không giả 25 phút hoặc hứa mức Coins từ công thức mẫu.
- Countdown, tập trung và khoan hồng giữ nền tối tĩnh; deadline thật không bị chặn trên ở 5/3 giây. Bố cục và dialog cuộn được khi màn hẹp/chữ lớn.
- LOST không hiện đồng hồ còn lại của nhóm như thời gian của mình, không chốt 0 Coins khi chưa có kết quả. Mất kết nối có lớp chặn thao tác phía dưới; banner trong luồng cuộn.
- Xác nhận rời kiểm lại trạng thái sau khi đóng dialog. Phòng chờ chuyển sang active trong lúc xác nhận không gửi yêu cầu rời bằng nội dung cũ. Chặn dialog/yêu cầu trùng; timer có guard sau dispose.
- Hướng dẫn web/native nêu giới hạn nền tảng; lỗi entry/leave không lộ tên socket hoặc chi tiết nội bộ. Hủy do sự cố không hứa kết quả của mọi người đều không bị tính.
- [Kiểm tra độc lập](04-VERIFICATION.md): 5 findings đã đóng ở mức source sau vòng sửa; chưa nghiệm thu hình ảnh.
- 56/56 Flutter tests: `session_screen_design_test`, `widgets_test`, `session_controller_test`, `local_gaps_test`. Sau chỉnh copy sự cố cuối: chạy lại 15/15 tests mới, đạt. Analyze screen và hai file test đã thay đổi: sạch. Diff check sạch.
- Controller và lifecycle giữ nguyên SHA256 baseline nêu trên. Không đổi backend, seed hay dữ liệu thật.
- Chưa có ảnh runtime trước/sau đúng build/trạng thái; **CHƯA XÁC MINH HÌNH ẢNH**. Android lifecycle chưa kiểm trực tiếp trong đợt này.
- Build web release thành công (`API_BASE_URL=http://localhost:3000`), 23/10/2026. Preview HTTP 200, version `e7659d2b3ba1`: http://127.0.0.1:8080/_preview/e7659d2b3ba1/#/home . Backend health HTTP 200.
- SHA256 `build/web/main.dart.js`: `FAA17CCDB482F856E4B691CE0ABF874972C588CBD35ED8786B84FEF02422DEF8`.
- Compiler còn cảnh báo dry-run Wasm trong `socket_io_common` và font Cupertino; bản JavaScript release vẫn build thành công. Chưa có bằng chứng ảnh browser để đóng cổng visual.
