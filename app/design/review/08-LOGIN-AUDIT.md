# Đợt 08 — audit đăng nhập thật

Ngày 24/10/2026. Auditor `/root/design_reference`. Phạm vi UI: `LoginScreen` tại `/login`, chưa đăng nhập; đọc auth/env/kiến trúc để xác định hợp đồng. Không sửa code, onboarding, backend hoặc cấu hình. Ưu tiên mới của người dùng: bỏ mock login, thêm production login trước các view còn lại.

**CHƯA XÁC MINH HÌNH ẢNH.** Chỉ audit mã/HTML; không có ảnh app đúng build, viewport, trạng thái. Không dùng browser workaround. Không đọc file secret hoặc in/lưu giá trị môi trường; env chỉ nhận diện tên khai báo và hash.

## Nguồn và nhận diện

| Nguồn | SHA256 | Vai trò |
| --- | --- | --- |
| `mockup/sign_in_login/code.html` | `624119C4D4797A4C5B0EB53F13523EA1E1802B0955D5888E5551188480F6C36F` | Mockup chính, trạng thái email/password |
| `app/lib/features/auth/auth_screens.dart` | `268CC964CEFCE7DDDB755614E81A9C2819E9A6192A287BF0B5A5EA233E235586` | Baseline UI dev trước đợt08 |
| `app/lib/core/auth.dart` | `E63F19692FEC0C081BEF5948E15D8A290E37E1311D8167DEB958F9D56024BD98` | Baseline session/dev auth |
| `app/lib/app/env.dart` | `9D290123A18AE1C55AE1134A36643CCCF988078A6AFFDB3905EA6765FE48A739` | Nhận diện source cấu hình; không ghi giá trị |
| `design/01-kien-truc.md` | `5D6BB1295F8768D5CBF277536EDDA7B0DA65AA237A439C1F62B30A5E8765F8A1` | §1.2, token, NFR-10, DQ-04 |

Đã đọc README, DECISIONS, BACKLOG và prompts reference-reviewer/app-auditor. Hash nguồn không phải hash build đang phục vụ.

## Ý định thị giác cần giữ

Canvas `#F4F5F7`, nội dung một cột tối đa430px, gutter16; header DropIt!, headline28/36, body14/20, khoảng cách16. Input pill cao52, icon mail/lock, bề mặt sáng; CTA đen cao56 chữ trắng, icon tiến. Không thêm card outline quanh toàn form. Input vẫn cần focus/error rõ; quy tắc bỏ viền card không phải bỏ focus.

Mockup có email, mật khẩu, icon hiện mật khẩu, lỗi inline, nhớ đăng nhập, quên mật khẩu, đăng ký. Đây là ngôn ngữ form, không chứng minh các dịch vụ đã tồn tại. HTML bỏ label hiện hữu, icon visibility là span, link không đích, nút chưa có submit; không sao chép các thiếu sót hành vi/accessibility. Không tắt zoom như meta viewport nguồn.

## Hợp đồng thật và điểm phân xử

Kiến trúc ghi app gọi Cognito trực tiếp lấy token; backend chỉ xác minh JWT, không giữ mật khẩu. Access token phải có issuer/client/token_use/expiry hợp lệ; refresh token native vào Keychain/Keystore, refresh access token và socket. DQ-04 lựa chọn SDK còn mở trong tài liệu. Audit này không tự coi Cognito đã cấu hình hoặc production đã sẵn sàng.

| Phương án | UI đề xuất | Điều kiện trước triển khai |
| --- | --- | --- |
| Cognito trực tiếp email/password | Giữ form mockup; nhãn Email/Mật khẩu, toggle thật, submit bàn phím, lỗi xác thực chung, pending rõ | Root chốt client/SDK và challenge hỗ trợ. Nếu có confirm/reset/MFA/new-password, UI phải xử lý hoặc điều hướng hợp lệ; không rơi về dev-token. Không gửi password sang API nghiệp vụ. |
| Cognito Hosted UI | CTA “Tiếp tục đăng nhập”, giải thích ngắn chuyển tới trang xác thực; callback/loading/cancel/error thực | Root chốt Authorization Code + PKCE, redirect cho web/native, state và session lifecycle. Form password local không xuất hiện nếu không dùng. Đây là thích nghi kiến trúc hợp lệ, không lỗi vì khác mockup. |

Ưu tiên form trực tiếp nếu contract thật đã được root chọn và hỗ trợ đủ; Hosted UI phù hợp khi muốn giao bước xác thực/challenge cho Cognito. Arbiter cần chốt theo triển khai thực, không ép email/password chỉ để khớp ảnh. Đăng ký/quên mật khẩu chỉ hiển thị khi có đích thật. “Ghi nhớ” không được là checkbox không tác dụng; quyết định session phải phù hợp từng nền tảng.

## Findings baseline

| ID | Mức | Bằng chứng | Hướng xử lý |
| --- | --- | --- | --- |
| LG01 | P1 | Login chỉ gọi `DevAuthApi.token`, chọn seed hoặc tự nhập email/id, không mật khẩu | Thay bằng auth contract thật; production không fallback dev token hoặc giả đăng nhập. Không chỉ giấu danh sách rồi vẫn gọi dev endpoint. |
| LG02 | P1 | `AuthState.loggedIn` chỉ kiểm token khác null; controller đọc `dev_token` từ SharedPreferences | Root xử lý migration/session verification/expiry/refresh/storage. UI phân biệt đang khôi phục và đã xác thực; không flash home từ token dev còn lưu. |
| LG03 | P1 | `_login` dùng ref sau await, catch setState không mounted guard; không có guard đầu method | Chống submit lặp, dependency/lifecycle an toàn, lỗi khi rời màn không setState sau dispose. Dispose controller đang thiếu trong LoginScreen. |
| LG04 | P2 | UI có banner phát triển, máy chủ, danh sách tài khoản seed; lỗi nhắc backend và địa chỉ máy chủ | Bỏ khỏi flow thật. Copy lỗi mạng hướng người dùng thử lại; lỗi xác thực không xuất raw exception, token hoặc chi tiết cấu hình. Không liệt kê tài khoản thật. |
| LG05 | P2 | Scaffold mặc định; form custom chỉ một input, chưa trạng thái field/password | Scoped canvas/control theo nguồn; không đổi theme toàn app. Label rõ ngoài placeholder, autofill phù hợp, Enter submit, focus, toggle có semantics. |
| LG06 | P2 | Mockup link/visibility không tương tác, error hidden, checkbox không hợp đồng | Không tạo control giả. Sai email field validation riêng; sai credential chung. Pending giữ nội dung hợp lý, không đưa password vào log/lỗi. |

## Ma trận kiểm giao cho implementer/verifier

- Chưa cấu hình: trạng thái rõ, không mở mock fallback; không hiển thị giá trị cấu hình.
- Form/Hosted UI theo quyết định: empty/invalid/submit/pending/nhấn lặp; success; sai thông tin; offline/timeout/server; cancel/callback nếu hosted.
- Session: không token, token dev cũ, hết hạn, refresh thất bại, logout; root sở hữu backend/auth, UI phản ánh trạng thái thật.
- Challenge/reset/register chỉ khi contract hỗ trợ; không hứa tính năng chưa có.
- 390×844, 320×740, 768×1024, chữ lớn, bàn phím, autofill, keyboard focus; form và footer cuộn được.
- Verifier khác implementer kiểm diff/test/build và ảnh đúng URL/hash/state. Chưa có ảnh giữ CHƯA XÁC MINH HÌNH ẢNH; chưa có thử Cognito thật không gọi production login đã xác minh.

Đây là đề xuất nguồn cho arbiter; quyết định đăng nhập và cấu hình do root chốt. Không sửa dữ liệu thật để dựng ảnh, không lưu credential trong audit.
