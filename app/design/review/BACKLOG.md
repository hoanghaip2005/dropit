# Các đợt triển khai

- 10 — [Đăng ký](10-REGISTRATION.md): đã triển khai web và bật Cognito self-registration; 38 tests đạt. Kiểm hình ảnh từng trạng thái, email end-to-end còn giới hạn ghi trong hồ sơ.

## Bước 0 — dựng cơ chế đánh giá (đã lập)

- Thiết lập vai trò, prompt, hồ sơ view, decision log và audit ban đầu.
- Đã có audit nguồn, phân xử và kiểm chéo tài liệu. Những patch trước chưa được coi là đạt visual.
- Người dùng đã yêu cầu tiếp tục triển khai theo từng cụm màn; cổng ảnh runtime vẫn mở cho các đợt chưa có bằng chứng.

| Đợt | View/phạm vi | Nguồn | Trạng thái |
|---|---|---|---|
| 01 | [Thành viên: Lịch sử phiên](01-MEMBER-HISTORY.md) | Yêu cầu bổ sung người dùng + `mockup/n_10_l_ch_s_phi_n/code.html` | Bổ sung badge/time thật, Ngày + picker, thưởng hôm nay, query kỳ đủ trang; 12 Flutter tests, backend 41 tests; [verifier](01-VERIFICATION.md) đóng findings nguồn, chưa xác minh hình ảnh |
| 02 | [Chi tiết phiên và gửi/sửa giải trình](02-EARLY-EXIT.md) | N-09 + kết quả thành công + [phân xử](02-DETAIL-EXPLANATION-DECISIONS.md) | Đã triển khai theo yêu cầu chuyển màn của người dùng; 63 Flutter tests, 9 backend integration đạt; [kiểm chéo](02-VERIFICATION.md), chưa xác minh hình ảnh |
| 03 | Thành viên: hoàn thành, mất kết nối, hủy | `session_success_reward`, `success_reward` + trạng thái thật | Biến thể kết quả đã sửa/kiểm mã chung [đợt 02](02-VERIFICATION.md); chưa nghiệm thu hình ảnh |
| 04 | [Phòng chờ và màn tập trung](04-SESSION.md) | `session_lobby_1`, `session_lobby_2`, `lockdown_mode`, `n_07` | Đã sửa và kiểm chéo 5 findings source; 56 tests đạt, analyze sạch; không đổi controller/lifecycle/backend; chưa xác minh hình ảnh |
| 05A | [Thành viên: Shop](05A-SHOP.md) | `the_shop`, `rewards_shop`, HTML + artwork đã chấp nhận | Đã redesign danh sách, filter, card và CTA; 12 tests Shop + 23 tests liên quan đạt, analyze sạch; kiểm chéo source, chưa xác minh hình ảnh |
| 05B | [Chi tiết vật phẩm và xác nhận mua](05B-ITEM.md) | `s_02`, HTML + artwork đã chấp nhận | Đã sửa; 25 tests mới + 35 regression đạt, analyze sạch, kiểm chéo source; chưa xác minh hình ảnh; danh sách/kho giữ nguyên |
| 05C | Thành viên: Đồ của tôi | Mockup kho + dữ liệu thật | Chờ đợt riêng; bảo toàn artwork và trạng thái trang bị |
| 05D | Thành viên: hồ sơ và thành tích | HTML + mockup tương ứng | Chờ đợt riêng; không coi đổi Shop là hoàn thiện flow thành viên |
| 06 | Chủ nhóm: nhóm và chi tiết nhóm | T-02 + HTML + quyết định mới | Đã có patch, chưa kiểm hình ảnh độc lập |
| 07 | Chủ nhóm: lịch, báo cáo, hồ sơ | Mockup tương ứng + các override đã ghi | Đã có patch, chưa kiểm hình ảnh độc lập |
| 08 | [Đăng nhập Cognito](08-LOGIN.md) | `sign_in_login` + hợp đồng auth thật | Bỏ mock, form thật/config failclosed; Flutter173 đạt/1 skip, backend58 đạt; verifier source đóng V08-01; chờ cấu hình AWS và hình ảnh |

Mỗi đợt chốt đúng route/state, lập hồ sơ, sửa, kiểm độc lập rồi mới coi là hoàn thành. Có thể đổi thứ tự khi người dùng ưu tiên view khác. Không tự coi việc hoàn thành bước 0 là hoàn thành tất cả đợt UI.

## Đợt 09 — Push mobile

[Push iOS/Android](09-PUSH.md): triển khai card quyền tự nguyện + FCM/SNS backend; kiểm source độc lập, chưa cấu hình cloud, chưa xác minh hình ảnh/native delivery. Không coi web preview là bằng chứng push iOS/Android.
