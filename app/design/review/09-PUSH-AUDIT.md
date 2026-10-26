# Đợt 09 — quyền nhận thông báo đẩy

Ngày 25/10/2026. Auditor `/root/implementation_audit`. Phạm vi đọc nguồn/UI và đề xuất điểm xin quyền; không sửa app, router, backend hoặc cấu hình. Đã đọc README, DECISIONS, BACKLOG và hai prompt reference-reviewer/app-auditor.

**AUDIT MÃ NGUỒN / CHƯA XÁC MINH HÌNH ẢNH.** Chưa có ảnh app đúng build, thử quyền OS, thiết bị Android/iOS hoặc kiểm tra nhận push thật. Không dùng browser workaround, không đọc hoặc ghi token/khóa cấu hình.

## Nguồn và baseline

| Nguồn | SHA256 tại lúc đọc | Bằng chứng |
|---|---|---|
| `app/lib/features/profile/profile_screens.dart` | `17AEB47FC038FA45B0F6449AF8D179E39E20BDF40840C763C173A7DA4CA1DE30` | Bell ở hồ sơ; `NotificationsScreen`; `notificationRoute` theo loại và vai trò nhóm |
| `app/lib/app/router.dart` | `3793A1E0695DCAE7E92E0F03FD748E75B5D76B9CDB38713ADB2D4EC6A26DC059` | Có `/notifications`, chưa có `/settings` |
| `app/lib/core/api.dart` | `9B1A2DF445DFA0311ACCE6567812D8E9F1A12829AD8D998076D120EBDA0F1388` | Inbox API, đánh dấu đọc; không chứng minh đăng ký thiết bị/nhận push |
| `app/android/app/src/main/AndroidManifest.xml` | `CB2823156E268EB483CE06AA2C56AFD53C5AB9CD5B11BDB94279DEA05C1B7D65` | Baseline chưa khai báo quyền thông báo trong main manifest; manifest merge/runtime chưa kiểm |
| `design/01-kien-truc.md` | `5D6BB1295F8768D5CBF277536EDDA7B0DA65AA237A439C1F62B30A5E8765F8A1` | ADR-06 phân biệt socket/inbox và SNS APNs/FCM; payload riêng tư |

`design/openapi.yaml` mô tả đăng ký `platform: IOS|ANDROID` cùng `push_token`, tạo/cập nhật SNS endpoint. Điều này chưa phải bằng chứng Flutter/native/backend hiện đã hoạt động. Không thấy màn settings hoặc mockup xin quyền chuyên biệt qua danh sách file hiện tại. Không tự lấy mockup hồ sơ làm bản duyệt cho một màn settings mới.

## Findings và phạm vi đề xuất

| ID | Mức | Quan sát nguồn | Đề xuất cho arbiter/root |
|---|---|---|---|
| PUSH01 | P2 | Không có `SettingsScreen`/route settings; entry hiện có là bell home/hồ sơ tới `/notifications`. | Lô tối thiểu thêm một component xin quyền ở đầu `NotificationsScreen`, không tạo màn settings giả hoặc đổi navigation toàn app. |
| PUSH02 | P1 | Inbox dùng `AsyncBody` với empty/error thay toàn nội dung. | Card quyền nằm ngoài `AsyncBody`; người chưa có thông báo hoặc inbox lỗi vẫn xem/đổi trạng thái đăng ký được. Lỗi inbox không được giả thành chưa cấp quyền. |
| PUSH03 | P1 | Inbox có dữ liệu/đánh dấu đọc không chứng minh quyền OS hoặc đăng ký token đã thành công. | Tách trạng thái quyền OS và đăng ký máy chủ. Chỉ ghi “Đã bật trên thiết bị này” khi quyền phù hợp và đăng ký hoàn tất; đã cấp quyền nhưng đăng ký lỗi phải có retry an toàn. |
| PUSH04 | P1 | Quyền notification là lựa chọn thiết bị, không phải consent thành viên hoặc điều kiện phiên. | Không tự mở native prompt khi khởi động/login/vào phiên. CTA người dùng chủ động “Bật thông báo”; từ chối không chặn đăng nhập, inbox, tham gia nhóm hoặc phiên. |
| PUSH05 | P2 | Nền tảng từ chối/không hỗ trợ/chưa cấu hình khác nhau. | denied: giải thích ngắn, không lặp prompt; chỉ có “Mở cài đặt” nếu triển khai mở cài đặt thật. unsupported/unconfigured: nói chưa hỗ trợ/chưa sẵn sàng, không render toggle bật giả. Web không được mô phỏng Android đã nhận push. |
| PUSH06 | P1 | `notificationRoute` hiện lấy session/group và vai trò nhóm từ inbox. | Mở push cần dùng cùng quy tắc domain, allowlist loại/ID; không tin URL tùy ý từ payload. Chưa đăng nhập thì giữ ý định và xác minh phiên/quyền trước mở; không lộ màn bảo vệ hoặc giả đánh dấu đã đọc chỉ vì nhận push. |
| PUSH07 | P1 | ADR-06 tránh gửi SNS cho người đang ở trạng thái phiên chưa kết thúc; thông báo thoát giới hạn tên/thời điểm. | Không thêm nội dung nhật ký, Coins/streak hoặc giải trình vào lock-screen notification. Không xin quyền bằng cách hứa đọc app khác/hành vi ngoài contract. Transport và audience do root/backend xác minh. |

## Component tối thiểu

Vị trí: sau header “Thông báo”, trước vùng inbox co giãn. Canvas/card scoped theo D02: nền trung tính, surface trắng không outline mặc định; icon chuông; nhãn “Thông báo trên thiết bị”; mô tả ngắn “Nhận nhắc phiên và cập nhật khi bạn không mở ứng dụng.” Chỉ dùng lời hứa này khi backend đúng loại sự kiện được hỗ trợ; nếu chưa có nhắc phiên thì rút còn “Nhận cập nhật khi bạn không mở ứng dụng.”

CTA ít nhất48px, label wrap; busy không gửi nhiều permission/register request; live-region cho kết quả. Không dùng switch vì native permission không phải một bool người dùng có thể đảo tức thì. Trạng thái đề xuất: đang kiểm tra; chưa bật + Bật thông báo; đang đăng ký; đã bật; đã cấp quyền/chưa đăng ký + Thử lại; từ chối + hướng dẫn cài đặt thật; không hỗ trợ/chưa sẵn sàng. Không hiện token, provider name hoặc URL kỹ thuật.

Thay đổi đề xuất chỉ `NotificationsScreen` và component riêng liên quan, cùng import/provider cần thiết. Không redesign profile/owner/member; không đổi inbox rows/mark-read/route ngoài sửa cần thiết để nhận payload thật đã được phân xử. Root sở hữu Flutter core và tích hợp nền tảng; implementer UI chỉ nhận file sau khi có phân xử rõ.

## Ma trận nghiệm thu

- Không tự prompt ở startup/login; CTA chủ động xin một lần; denied không cản các chức năng chính.
- Quyền OS granted nhưng token/register thất bại không báo đã bật; retry không lặp đồng thời; permission null/loading không giả denied.
- Inbox loading/error/empty/populated đều giữ card quyền; card lỗi không xóa inbox.
- Sign-out/account switch/expiry không đăng ký nhầm thiết bị cho tài khoản cũ; response chậm/dispose không ghi sai UI hoặc truy cập ref đã hủy. Root kiểm cleanup token/server endpoint.
- Push foreground/background/cold start: dữ liệu hợp lệ mới điều hướng, đúng vai trò nhóm; payload lỗi/thiếu ID/URL tùy ý không mở route ngoài allowlist. Khi auth chưa sẵn sàng, không vượt guard.
- 320×740,390×844,768×1024 và text1.5: card/CTA không overflow; focus/semantics đọc được. Widget layout test không thay thử prompt OS.
- Android13+ permission, Android cũ, iOS denied/provisional/granted; nền tảng không hỗ trợ/config thiếu được ghi riêng. Cần thiết bị/build/config thật để chứng minh nhận push sau tắt/mở app và quyền từ system settings.
- Verifier độc lập kiểm source/test/build; ảnh runtime và native delivery còn thiếu phải ghi **CHƯA XÁC MINH HÌNH ẢNH / CHƯA KIỂM TRA PUSH TRÊN THIẾT BỊ THẬT**, không kết luận production-ready.

Đây là đề xuất audit, chưa phải quyết định hoặc nghiệm thu. Không thay dữ liệu thật để tạo ảnh.
