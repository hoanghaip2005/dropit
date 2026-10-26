# Đợt 08 — kiểm tra độc lập đăng nhập

Ngày 24/10/2026. Verifier `design_arbitration`, khác implementer UI/auth/backend. Chỉ đọc source; không chạy Flutter, không đọc env bí mật, không dùng browser. **CHƯA XÁC MINH HÌNH ẢNH**.

## Phạm vi

Đối chiếu `08-LOGIN-DECISIONS.md`, audit reference, LoginScreen, `core/auth.dart`, `app/env.dart`, router/API interceptor/socket; backend verifier/config/app factory/dev route và provisioning user; `infra/cognito.yaml` và `app/docs/COGNITO-SETUP.md`. Đã kiểm lại source cuối theo bàn giao chủ file; dấu vết hash bên dưới.

## Findings

| ID | Mức | Bằng chứng và ảnh hưởng | Tiêu chí đóng | Trạng thái |
|---|---|---|---|---|
| V08-01 | P2 | `core/api.dart` xử lý mọi response 401 bằng `expire()` vô điều kiện. Request gửi token A có thể trả muộn sau refresh hoặc đăng nhập token B, làm đăng xuất phiên B hợp lệ. | Chỉ expire khi Authorization của request lỗi còn tương ứng phiên/token hiện tại; kiểm regression 401 cũ không xóa phiên mới, 401 hiện tại vẫn expire. | ĐÓNG SOURCE vòng 2: interceptor so Authorization với token hiện tại. Đã đọc regression đồng bộ adapter bắt đầu request A trước khi nhận B; 401 A giữ B, 401 B expire. Root cung cấp test đạt. |

## Đã xác nhận ở source vòng đầu

- UI bỏ seed account/dev token/banner backend; email/password có validation, autofill, che/hiện với tooltip, busy serialization, mounted guard, lỗi live region và trạng thái thiếu cấu hình. Không có link reset/signup/remember giả.
- Cognito request gửi mật khẩu trực tiếp HTTPS tới AWS; không qua backend app. Không đưa raw error, mật khẩu hoặc token vào copy UI. Challenge chưa hỗ trợ phải dừng trước `acceptSession`, hiện hướng dẫn liên hệ quản trị viên.
- Access/refresh token chỉ giữ trong memory; SharedPreferences chỉ lưu onboard/device, dọn khóa dev cũ. Reload cần đăng nhập lại. Timer refresh có generation guard chống callback refresh phục hồi phiên đã logout.
- Backend dùng RS256 + issuer + exp + sub + token_use access + client_id; ID token/HS256/sai client/issuer/signature bị từ chối. Dev token route chỉ mở khi local/test, devAuth bật và verifier HS256. Factory thông thường thiếu Cognito phải fail closed; development có một phần Cognito config không âm thầm fallback dev. Production cấm devAuth/HS256.
- `opts.verifier` là dependency injection tin cậy trong tiến trình theo quyết định root, không phải dữ liệu request. Cho phép non-HS verifier injection mà không bắt config Cognito là ngoại lệ chủ ý; không ghi thành lỗ hổng do người dùng điều khiển. Không dùng exception này cho đường startup/config production thông thường.
- Socket factory đọc token hiện tại tại handshake/reconnect thay vì giữ token khởi tạo. Source guard API đã đóng V08-01; chưa kiểm AWS/socket integration thực.
- Template khớp public client không secret, USER_PASSWORD_AUTH/REFRESH_TOKEN_AUTH, access 60 phút, refresh 1 ngày; user pool giữ lại khi xóa/thay stack, chỉ admin tạo user. Tài liệu ghi chưa deploy, cần permanent password do thiếu new-password challenge, MFA chưa hỗ trợ, local logout chưa revoke, thiếu metadata email/name và các cổng phát hành khác. Không tuyên bố toàn hệ thống production ready.

## Giới hạn phải công bố

- Chưa có public config Cognito và chưa kiểm integration AWS thực; không kết luận production ready.
- Không MFA/new-password/signup/reset flow. Challenge hoặc yêu cầu reset phải từ chối an toàn, không điều hướng như đã đăng nhập. App client phải tương thích public client không secret, USER_PASSWORD_AUTH và refresh flow hiện có; không tự bỏ challenge trong pool để làm test qua.
- Memory-only là quyết định phạm vi: không nhớ đăng nhập sau reload/đóng app, không hứa secure persistence. Chưa xác minh revoke phiên server/global logout.
- Cognito access token thường không chứa email/name; provisioning hiện chấp nhận email null và tên mặc định. Chưa có trusted profile enrichment; không dùng ID token thay access token để lấp metadata. Cần phản ánh giới hạn hồ sơ/báo cáo nếu những màn đó cần email.
- Test source không chứng minh kích thước/focus/keyboard/render đạt. Chưa có ảnh app đúng build/state; **CHƯA XÁC MINH HÌNH ẢNH**.

## Kết quả thực thi

- UI implementer/root cung cấp **15/15 tests login + 16 local_gaps đạt**, analyze 5 file sạch. Verifier đã đọc test: validation; email trim/password nguyên trạng; serialize submit qua acceptSession; Enter; lỗi mạng/rate limit/challenge không nhận session; raw exception không lộ; dispose; kích thước hẹp/text scale/keyboard inset.
- Root cung cấp **10 production auth + 15 session tests đạt**; gồm regression 401 cũ đã đồng bộ request-start. Backend owner cung cấp **19 auth tests đạt**, typecheck sạch.
- Verifier không tự chạy test; kết quả thực thi trên do root/implementer cung cấp. Không còn blocker source mới trong phạm vi đã đọc; cổng integration AWS và hình ảnh vẫn mở. Build cuối do root ghi riêng, không suy ra từ source hash.

## Hash SHA256 bản source kiểm cuối

Đọc trực tiếp từ file, không đọc env bí mật:

| File | SHA256 |
|---|---|
| `app/lib/features/auth/auth_screens.dart` | `45CF9F7B716D0917E13A5E889839285E098B4D556ADF2505672F9D3FEB68F724` |
| `app/lib/core/auth.dart` | `6187C004C95E3E49281F45703C8E26B6D625B1B912E66CDCB8603D0FF9BB57DC` |
| `app/lib/core/api.dart` | `9B1A2DF445DFA0311ACCE6567812D8E9F1A12829AD8D998076D120EBDA0F1388` |
| `app/lib/core/socket.dart` | `4E1BB94E9247CA151E7071B8CC05716A6EB64A2A3989A4A1E1D628905510283E` |
| `app/lib/app/env.dart` | `BE8B58B24F7A0C94C31F053B18FE82D811E748B2466EF2CE99D6A37C5F232C7E` |
| `backend/src/shared/auth.ts` | `77BD745E5B5014A4EB077D31D303F45D63C406B506968C97E1C99BEB244118E2` |
| `backend/src/config.ts` | `E8FB2EBDBC6C42271B6C54F9B50DDEDF5493F757BABAF0CD2334CD839F922AF5` |
| `backend/src/app.ts` | `73CE350D84FC72EDD56879109316569DCFE9F143AE5755CA9CDDDF360648F228` |
| `backend/src/modules/auth/routes.ts` | `D693144FAF652C9FF690D055B047441363C47CF54D94D568E113C39C4EF423B0` |
| `infra/cognito.yaml` | `0833A686C9B7A2F4DAF24B864E71F6E9F49610E529C0DE50B2634A563FFE40C6` |
| `app/docs/COGNITO-SETUP.md` | `39C882B61204D40AAB76DB4F7E1F527617E923C9C7332C8AAF7B49045BFEA73A` |
