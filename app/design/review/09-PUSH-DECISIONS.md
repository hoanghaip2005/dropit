# Đợt 09 — quyền thông báo và đăng ký thiết bị

Ngày 25/10/2026. Arbiter `design_arbitration`, không triển khai. Phạm vi UI một component quyền push tại `/notifications`; không redesign toàn bộ inbox hoặc toàn app. **CHƯA XÁC MINH HÌNH ẢNH**.

## Nguồn và phạm vi

- Đã đọc quy trình review, decision log, backlog; baseline `NotificationsScreen` trong `app/lib/features/profile/profile_screens.dart`, backend notification routes/service.
- Nguồn domain: `design/03-api-socket.md` §4, `design/01-kien-truc.md` ADR-06, `design/openapi.yaml` `/me/devices`. Inbox ghi trước, socket/push chia kênh, payload có event_id để khử trùng; không tự sửa chính sách người nhận trong UI.
- Root sở hữu core Flutter/Firebase/permission card, backend agent sở hữu SNS/device API, UI worker chỉ nhúng component vào NotificationsScreen. Không hoàn tác file người khác. Cấu hình cloud chưa có, không đọc/lưu credentials trong hồ sơ.
- Contract root/backend chốt: `PUT /v1/me/devices/:deviceId/push` body `{token, platform: ANDROID|IOS}`, `DELETE` cùng URL, 204. Token FCM cho cả hai nền tảng; user từ auth. Token unique chuyển binding sang người hiện tại; DELETE lọc user+device để logout cũ không xóa binding mới. Đây là thích nghi endpoint so với `/me/devices` cũ; phải đồng bộ API docs. Client serialize rotation/registration, cleanup trước clear auth nhưng lỗi cleanup không khóa logout vô hạn.

## Phân xử

| ID | Quyết định | Tiêu chí và lý do |
|---|---|---|
| PUSH01 | THÍCH NGHI: card opt-in đặt ngoài AsyncBody tại `/notifications`. | Inbox rỗng/lỗi vẫn thấy quyền; quyền push không chặn đọc inbox, login, nhóm hoặc phiên. Không auto prompt OS sau login. Startup chỉ kiểm trạng thái hiện có. |
| PUSH02 | SỬA: chưa hỏi quyền có CTA “Bật thông báo”. | Copy ngắn nêu nhận nhắc phiên/thông báo khi rời app; không hứa luôn đến đúng giờ. Chỉ CTA người dùng chủ động mới mở native prompt; busy chống gửi đôi, không lặp prompt khi rebuild hoặc quay lại màn. |
| PUSH03 | THÍCH NGHI: từ chối vẫn dùng app bình thường. | Không nài cấp quyền hoặc tự mở prompt lần nữa. Giải thích có thể bật ở Cài đặt hệ thống; CTA “Kiểm tra lại” chỉ đọc trạng thái. Không tạo link mở settings giả; có thể hướng dẫn thủ công thay thêm dependency nếu chưa có action thật. |
| PUSH04 | SỬA: phân biệt quyền OS với đăng ký backend. | “Đã bật” không đồng nghĩa đăng ký token đã thành công. Quyền cho phép nhưng token/registration lỗi hiện trạng thái chưa kết nối và retry; không sửa quyền thành denied. Loading/lỗi không giả enabled, không hiện token/ARN/raw exception. |
| PUSH05 | THÍCH NGHI: web/thiếu Firebase config/unsupported có trạng thái trung thực. | Android+iOS là scope push; web không gọi native Firebase/token hoặc hiển thị CTA không hoạt động. Không fallback mock gửi thành công. Thiếu cloud config không chặn app; ghi giới hạn thật trong docs. |
| PUSH06 | GIỮ: canvas trung tính, surface trắng không outline, CTA chính đen, brand dùng có chủ đích. | Component gọn, label/icon/semantics rõ; không dùng màu làm bằng chứng quyền duy nhất. 320 px/text1.5 có wrap/scroll, target tối thiểu 48 px. Không đổi theme inbox. |
| PUSH07 | THÍCH NGHI: FCM token cho cả Android và iOS qua SNS FCM platform. | iOS APNs cấu hình trong Firebase. Ghi rõ đây là quyết định adapter khác sơ đồ APNs trực tiếp; backend vẫn SNS, không gửi token APNs vào endpoint FCM. Không thêm web push/service worker ngoài phạm vi. |
| PUSH08 | SỬA: token lifecycle ràng buộc phiên/người dùng. | Đăng ký chỉ khi authenticated và quyền hợp lệ; token rotation cập nhật endpoint; pending callback sau logout/account switch không gắn sai người. Logout cần cleanup ownership an toàn; backend không tin user_id/ARN do client gửi. Fail/retry không khóa logout hoặc làm thất bại thao tác domain đã commit. |
| PUSH09 | GIỮ: chính sách privacy và kênh domain hiện hữu. | Không tạo local foreground notification làm lộ lên lockscreen khi trạng thái phiên chưa kết thúc; không gửi Coins/chuỗi cho owner. Push chỉ là tín hiệu; mở inbox/route phải xác thực và kiểm quyền dữ liệu thật, không tin payload như quyền truy cập. Khử trùng event_id, không hứa exactly-once. |
| PUSH10 | THÍCH NGHI: payload lockscreen chung, data allowlist định danh/type. | SNS không đưa body inbox nhạy cảm lên lockscreen; inbox xác thực giữ nội dung domain. Durable queue/retry bounded theo backend, không giả SENT khi không có endpoint/dịch vụ chưa cấu hình. |

## Cổng kiểm độc lập

- Permission: unknown/notDetermined → explicit request; granted/provisional; denied; config missing; unsupported/web; registration offline/retry; dispose; busy; logout/rotation/account switch.
- Backend: ownership endpoint, authentication, validation token/platform, SNS payload/version, retry bounded, endpoint disabled/invalid, không log token/ARN; push failure không rollback nghiệp vụ/inbox đã commit.
- Mỗi owner chạy tests phù hợp, báo source hash/build. Verifier khác implementer đọc lại findings và phạm vi ảnh hưởng. Chưa có cloud credentials/device build thì ghi chưa kiểm SNS/FCM/APNs end-to-end; không tuyên bố push production hoạt động chỉ từ mock tests.
- **CHƯA XÁC MINH HÌNH ẢNH** đến khi có ảnh đúng build/viewport/state. Test render không thay đối chiếu hình ảnh độc lập.
