# Push iOS / Android — SNS → FCM → thiết bị

Ngày 25/10/2026. Đã nối mã nguồn; chưa có Firebase project/SNS credentials/APNs hoặc kiểm delivery thật. Không yêu cầu quyền để dùng app. Web push không nằm trong đợt này.

## Luồng

App đăng nhập → đọc quyền hiện tại → nếu đã cho phép thì lấy FCM token, PUT đăng ký theo installation UUID. Chỉ thao tác “Bật thông báo” mới gọi hộp thoại OS. Từ chối không chặn app, không hỏi lặp; hộp thông báo vẫn dùng được. Android phân biệt lần đầu và đã hỏi bằng preference, trạng thái OS vẫn là nguồn chính.

Backend ghi inbox/outbox, worker SNS gửi FCM v1 cho Android và iOS. Firebase dùng APNs của Apple để giao tới iOS. Không gửi dữ liệu riêng lên màn hình khóa: chỉ “Bạn có thông báo mới”. Khi bấm, app mở inbox sau đăng nhập và tải dữ liệu theo quyền server; không mở URL/route do payload gửi. Đây là lựa chọn bảo vệ quyền riêng tư; chưa mở thẳng mọi loại sự kiện tới màn chi tiết.

Foreground hiện snackbar “Xem”; background/terminated do notification payload OS hiển thị. Resume đọc lại quyền, refresh token đăng ký lại, lời gọi đồng thời được serialize/rerun. Logout đợi request đăng ký đang chạy trước unlink, timeout để không kẹt logout; cleanup cũ có guard tránh phiên mới. Không xóa FCM token bằng cleanup async vì có thể ảnh hưởng login mới. Offline unlink vẫn có thể để lại thông báo chung; nội dung inbox luôn cần xác thực. Push OS đã giao không thu hồi được.

## Cấu hình ngoài mã nguồn

1. Tạo Firebase project, đăng ký Android package và iOS bundle hiện là `com.bakhi.dropit.dropit` (đổi thành ID phát hành trước khi tạo app chính thức). Bật Cloud Messaging. Không cần chuyển đăng nhập Cognito sang Firebase Auth.
2. Đăng ký Apple App ID có Push Notifications, tạo/cấu hình APNs key trong Firebase Console, signing/provisioning phù hợp. Không commit APNs private key hoặc Firebase service-account credential.
3. Tạo SNS GCM Platform Application dùng FCM HTTP v1 credentials. Backend setup tại `backend/PUSH_SETUP.md`; Flutter chỉ gửi FCM token, không giữ AWS credential.
4. Build riêng cho từng nền tảng bằng public Firebase options qua dart defines: `PUSH_ENABLED=true`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, iOS thêm `FIREBASE_IOS_BUNDLE_ID` nếu đổi. App ID Firebase iOS và Android khác nhau. Có thể dùng native default config nếu được cấu hình hợp lệ; đường defines không cần Google Services Gradle plugin. API key Firebase client không phải quyền AWS; vẫn cấu hình giới hạn API thích hợp.
5. iOS entitlements: Debug development, Release/Profile production qua `APS_ENVIRONMENT`. Xcode ký archive theo provisioning thật. Android tạo channel `dropit_events` importance high và khai báo POST_NOTIFICATIONS. Người dùng/OS vẫn quyết định banner, âm thanh và quyền.
6. Thiếu config hoặc `PUSH_ENABLED=false`: SDK không khởi tạo, app/inbox hoạt động; bản mobile hiện trạng thái chưa cấu hình. Không giả push thành công.

Ví dụ cấu trúc lệnh (thay placeholder bằng thông số Firebase client công khai, không dùng service-account JSON):

```powershell
D:/flutter/bin/flutter.bat build apk --release --dart-define=PUSH_ENABLED=true --dart-define=FIREBASE_API_KEY=PUBLIC_API_KEY --dart-define=FIREBASE_APP_ID=ANDROID_FIREBASE_APP_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=SENDER_ID --dart-define=FIREBASE_PROJECT_ID=PROJECT_ID
```

Android release signing hiện có cấu hình debug từ scaffold cũ, phải thay signing production trước phát hành. Không coi APK debug là bản phát hành. iOS cần macOS/Xcode, không thể kiểm native build trên Windows.

## Kiểm bắt buộc trên thiết bị thật

- Android 13+ lần đầu cho phép/từ chối, Android cũ channel; iOS permission/Focus/silent. Không suy banner từ test widget.
- Foreground/background/terminated và bấm thông báo trước/sau login; inbox thực, quyền role đúng.
- Token rotation, đăng xuất offline, đổi account, endpoint disabled, retry và duplicate.
- Chạy sự kiện thật (lịch/phiên/giải trình/badge đang có luồng notifications) rồi kiểm inbox + push phù hợp policy. Chỉ các sự kiện backend đã gọi notification service được gửi; không tự coi mọi thay đổi dữ liệu đều có push.
- SNS acceptance không bằng thiết bị nhận; force-stop Android, quyền, mạng, pin và OS có thể ngăn/chậm delivery.

**CHƯA XÁC MINH HÌNH ẢNH / PUSH THIẾT BỊ THẬT.** SNS/FCM/APNs chưa provision. Có thể phát sinh phí SNS và chi phí tài khoản Apple Developer; cập nhật dự toán trước bật production.

Giới hạn liveness còn lại: logout unlink trễ rồi đăng nhập lại cùng tài khoản trên cùng installation có thể xóa binding mới do endpoint xóa theo user/device. Không lộ nội dung, nhưng có thể mất push cho tới resume/đăng ký lại. Cần conditional registration generation trước phát hành rộng.
