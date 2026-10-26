# Đợt 09 — push thông báo iOS / Android

Ngày 25/10/2026. Yêu cầu triển khai thông báo ngoài app; từ chối quyền là lựa chọn người dùng. Scope UI chỉ card quyền tại `/notifications`; scope domain: đăng ký thiết bị và pipeline push của notifications hiện có.

## Nguồn và trách nhiệm

Audit: `09-PUSH-AUDIT.md`; phân xử: `09-PUSH-DECISIONS.md`; kiểm độc lập: `09-VERIFICATION.md`. Nguồn chính yêu cầu người dùng và hợp đồng notifications hiện có; không tạo màn settings hay redesign toàn inbox. Card ngoài AsyncBody để lỗi/rỗng vẫn thao tác được.

Root sở hữu Flutter push/main/auth/API và platform; implementation_audit sở hữu embed profile_screens.dart + permission widget tests; design_reference sở hữu backend/migration/SNS/tests; design_arbitration phân xử và kiểm source cuối khác implementer. Không AWS provisioning, không đọc/ghi credential.

## Diff

- PushClient injectable, Firebase Messaging cho Android/iOS, explicit opt-in, đọc lại quyền khi resume, token refresh và đăng ký serialize.
- Foreground snackbar generic, tap/cold-start tới inbox sau login. Inbox tải nội dung theo auth server; không tin payload URL. Không mở thẳng mọi event tới chi tiết.
- Auth logout hook unlink installation bằng bearer cũ; chờ pending registration, guard generation. Offline logout vẫn dùng được; stale generic notification có thể còn, không thu hồi OS message đã gửi.
- Android permission/channel `dropit_events`; iOS background mode và entitlement Debug development, Release/Profile production; Firebase client config public qua dart defines/native default, thiếu cấu hình không block app. Web push chưa nằm scope.
- Backend authenticated registration, token ownership/rotation, SNS FCM v1 generic lockscreen, durable inbox/outbox worker, bounded retry và invalid endpoint cleanup. Sự kiện phải đi qua notification service hiện có, không tự bảo đảm mọi mutation đều phát push.

## Kiểm tra / vòng sửa

Flutter toàn suite 185 đạt, 1 integration skip ở vòng đầu. Sau sửa độc lập: 13 push tests +10 auth tests đạt, analyze toàn app sạch. V09-01 giữ permission dù backend lỗi, V09-02 dirty rerun rotation, V09-03 entitlement theo config, V09-04 cleanup/version guard; verifier ghi riêng kết quả source.

Android build thử bị lỗi Gradle wrapper cũ “No build receipt resource found”. Thay wrapper từ official Gradle v9.1.0 (SHA256 `76805E32C009C0CF0DD5D206BDDC9FB22EA42E84DB904B764F3047DE095493F3`); thử lại dừng tại `java.io.IOException: Unable to establish loopback connection`. Chưa biên dịch native Android thành công. Windows không kiểm build iOS/Xcode. Không kết luận push native hoạt động.

## Bằng chứng còn mở

**CHƯA XÁC MINH HÌNH ẢNH / PUSH TRÊN THIẾT BỊ THẬT.** Chưa có Firebase/APNs/SNS cấu hình hoặc ảnh runtime đúng build. Không dùng công cụ khác để né giới hạn UI trước đó. Các bài widget không chứng minh delivery background/terminated. Cần cấu hình và kiểm thiết bị theo `app/docs/PUSH-SETUP.md`, backend theo `backend/PUSH_SETUP.md`. Chi phí SNS/Apple và vận hành phải tính trước launch; chưa phát sinh AWS từ đợt này.

## Kết quả backend cuối

85 tests đạt (unit + integration push + groups), typecheck sạch. Push worker độc lập single-flight không chặn domain tick, shutdown chờ worker. V09-05/06 đã được sửa và kiểm lại source. Giới hạn cùng-user relogin với DELETE cũ có thể cần đăng ký lại được ghi trong setup, chưa coi lifecycle production hoàn chỉnh.
`nBuild web cuối HTTP200: http://127.0.0.1:8080/_preview/b0c194639330/#/notifications ; main.dart.js SHA256 81AEA8B16CADF1B8E1E9B4FC80345952B4BB76BAE80A2080B5990A82239CF4D3. Backend bổ sung session/appeals12tests đạt, tổng các suite đã chạy97tests. Build JavaScript đạt; cảnh báo dry-run Wasm socket_io_common và font Cupertino còn từ dependency/cấu hình, không xác nhận Wasm.
