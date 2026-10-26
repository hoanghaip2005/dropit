# Đợt 09 — kiểm tra độc lập push

Ngày 25/10/2026. Verifier `design_arbitration`, khác implementer. Chỉ đọc source; không Flutter/browser, không cloud credentials. **CHƯA XÁC MINH HÌNH ẢNH**; chưa SNS/FCM/APNs end-to-end.

## Vòng 1 — findings chuyển root

| ID | Mức | Bằng chứng và ảnh hưởng | Tiêu chí đóng | Trạng thái |
|---|---|---|---|---|
| V09-01 | P2 | `PushController.sync` nhận permission rồi chỉ lưu sau token/DELETE/PUT thành công. Lỗi backend giữ status cũ/null; denied có thể biến thành CTA Bật và request native lần nữa. | Lưu permission quan sát được độc lập registration; denied không request lại qua lỗi/rebuild; Android phân biệt chưa hỏi bằng trạng thái/asked flag phù hợp. | ĐÓNG SOURCE vòng 2: permission lưu trước network; asked flag memory/preferences và canRequest giữ qua catch; không request lại denied đã hỏi. |
| V09-02 | P2 | tokenChanges gọi sync trong khi busy bị bỏ. Rotation sau token() nhưng trước PUT cũ hoàn tất có thể để backend giữ token cũ tới lần resume. | Dirty/queued resync sau busy, lấy token mới; test rotation giữa pending PUT. | ĐÓNG SOURCE vòng 2: busy đặt dirty, finally chạy sync mới. |
| V09-03 | P2 | Entitlement `aps-environment=development` dùng chung cả Debug/Release/Profile. | Signing/archive config đúng môi trường APNs; không hardcode development cho release; ghi hạn chế chưa archive trên macOS. | ĐÓNG SOURCE vòng 2: entitlement dùng APS_ENVIRONMENT; Debug development, Profile/Release production. Chưa archive/sign thực. |
| V09-04 | P1 | Hook logout timeout 5s không hủy future. stop có thể chờ sync lâu; hook tiếp tục sau logout/login mới, disconnectPush cũ gọi Firebase deleteToken() xóa token hiện tại của phiên mới. | Cancellation/generation kiểm trước destructive cleanup hoặc bỏ client deleteToken và giải quyết authenticated unlink; test pending cleanup không phá token/binding phiên mới. | ĐÓNG SOURCE vòng 3: bỏ native deleteToken, chỉ authenticated unlink; stop chỉ reset khi captured version còn đúng. Offline unlink residual chỉ thông báo chung được ghi rõ setup doc. |
| V09-05 | P1 | Backend queue online branch chạy trước active defer: người đang có trạng thái phiên chưa kết thúc có thể nhận event đã xếp hàng ngay khi socket online. | Active WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED defer trước online emit; test online + active không emit/publish, vẫn pending. | ĐÓNG SOURCE vòng 4: activeRecipient kiểm trước emit cả direct và queue; active defer pending, không publish. Owner báo có regression online+active đạt. |
| V09-06 | P2 | Cron tick await flushPush trước loadDue; batch SNS chậm giữ running, có thể trễ mở phiên và các job domain. | Push worker single-flight độc lập, lỗi/chậm SNS không chặn session/domain cron; shutdown timer cleanup đúng. | ĐÓNG SOURCE vòng 4: timer push single-flight độc lập; tick domain không await SNS; close dừng timer và await pushWork. |

## Đã đọc

Flutter PushClient/controller/bridge/card/main; auth logout hook; API registration; NotificationsScreen embed; manifest/channel Android; iOS plist/entitlement/project. Root cung cấp push 8 + permission 4 đạt, auth/login 25 đạt; đây không đóng findings source phát hiện sau test.

- Client không tin route từ payload, mở inbox có router auth; foreground không dùng nội dung push lên snackbar nhạy cảm, presentation options tắt alert/badge/sound.
- Push thiếu config/unsupported không chặn startup. Card nằm ngoài AsyncBody, inbox rỗng/lỗi vẫn truy cập được quyền.
- Logout có timeout, không khóa app vô hạn; cần xử lý V09-04 vì timeout không cancel future.
- Backend cuối: registration/unregister serialized bằng transaction advisory lock; ownership user+device/token, disabled endpoint xóa có điều kiện; payload generic allowlist. No endpoint trả SKIPPED/NONE thay SENT; production không config retry bounded tới FAILED. Inbox/outbox giữ trước I/O; domain không await SNS. Chưa kiểm cloud thật.

## Vòng 3 — giới hạn và thực thi được báo cáo

- Flutter source V09-01–04 đã kiểm lại/đóng. Root báo 185 tests đạt, 1 skip trước các sửa nhỏ cuối; 12 push tests đạt trước stop version guard cuối. Không quy kết các kết quả cũ thành test patch cuối.
- Root báo web đang build; Android chưa compile native thành công do Gradle loopback IOException sau sửa wrapper. iOS chưa archive/sign trên macOS. Không tuyên bố APK/iOS hoạt động.
- Setup doc đã đọc: public Firebase options/native config, iOS APNs qua Firebase và SNS GCM v1, production signing còn mở, permission không chặn app, generic lockscreen, offline unlink residual, SNS acceptance không phải delivery thiết bị. Cấu hình cloud/device E2E chưa có.

## Vòng 4 — bàn giao source cuối

- Root cung cấp 13 push + 10 auth tests đạt, analyze sạch sau patch cuối; 185 Flutter tests đạt/1 skip là lần rộng trước các sửa nhỏ cuối. Event dedupe mới dùng event_id, fallback messageId đã đọc ở source sau đó; chưa gán kết quả lần trước cho sửa dedupe mới.
- Backend owner cung cấp 85 unit/integration liên quan đạt, trong đó 13 push-specific, typecheck sạch. Verifier không chạy lại tests.
- Giới hạn liveness cần theo dõi: DELETE logout cũ đang in-flight và PUT mới khi đăng nhập lại cùng user/device có thể cạnh tranh; user predicate chỉ bảo vệ khác account. Resume/retry đăng ký lại; root đã được thông báo, không suy ra exactly-once ownership từ tests. Không ảnh hưởng confidentiality vì payload lockscreen chung và inbox vẫn auth. Nếu cần đảm bảo chặt, thêm binding generation/conditional delete ở đợt riêng.
- Build web cuối do root ghi sau rebuild; Android loopback/native signing, iOS archive, SNS/FCM/APNs delivery và **CHƯA XÁC MINH HÌNH ẢNH** vẫn là cổng mở.

Hash SHA256 đọc trực tiếp ở vòng 4:

| File | SHA256 |
|---|---|
| `app/lib/core/push.dart` | `8A5F66CE5C00F3434FD15DE38D47C8E40BCC6C76D08DA979D610AFE4220DCC0A` |
| `app/lib/main.dart` | `F306873AC221EE0D622034A2C2D2E97A09983800BEFA27C4CE7758A7B349F692` |
| `backend/src/modules/notifications/service.ts` | `4E1BE46DE2699D909167393594CA02A2AE2EAA4B81731687383EE251194414F5` |
| `backend/src/modules/notifications/sns.ts` | `A9A5841D5CFC26CD1A53815FAAFD5084B71B4F3AE7315F867E0EE8F810ECB7E6` |
| `backend/src/modules/jobs/cron.ts` | `ADD6D8C6D1D77AA41347FF5A11F115B02FA7D123084D5F9F3B4229FA698E4D85` |
| `backend/src/app.ts` | `4C30D45B3B2E52056AC2D9A4DDD9903EEE501813D536B1D429F35934BC5FAE84` |
