# 14 — Rủi ro I-01 đến I-10

Ngày: 03/11/2026. Nhánh: `feature/registration-flow`.
Nguồn yêu cầu: ảnh người dùng `Screenshot 2026-11-03 133816.png`, bảng “Các điểm bất hợp lý và rủi ro”. Thứ tự xử lý High (I-01…04), Medium (I-05…08), Low (I-09…10).

Nguồn hiện trạng: mã nguồn app/backend và các test được liệt kê dưới đây. Bảng ảnh là danh sách vấn đề cần xác minh, không phải bằng chứng rằng tính năng chưa tồn tại. Không đổi quyền tham gia phiên hoặc thời gian khoan hồng mặc định chỉ để đóng finding.

## Phạm vi và quyết định từng mục

| ID | View / component / hành vi | Phân xử và thay đổi | Kiểm chứng |
|---|---|---|---|
| I-01 High | GroupDetail owner hero; Schedule hint | SỬA: giải thích owner quản lý lịch/báo cáo, không tham gia phiên của chính nhóm; có thể là member nhóm khác. Giữ member view và quyền backend. | owner_groups_design, owner_schedule_hub, invite_duration_policy: 10 tests đạt; owner layout 320/390/768. |
| I-02 High | SessionScreen leave dialog | GIỮ confirm/cancel, cảnh báo mất thưởng và grace timer đã có; SỬA copy: xác nhận rời chủ động có hiệu lực ngay, không có khoan hồng. Lobby vẫn cho quay lại. | session_screen_design + session_controller: 34 tests đạt trước bổ sung I-05; engine + session-policy: 26 đạt. |
| I-03 High | ConsentScreen stale version | SỬA: reset toggles/read-to-end/scroll khi stale hoặc đổi version; tải bản mới, hướng dẫn chọn lại và nút tải lại. Không dùng đồng ý bản cũ cho điều khoản mới. | consent_refresh + registration_home_flow: 6 đạt, gồm retry tải và không submit lại ngoài ý muốn. |
| I-04 High | SessionManager lifecycle | Dispose đã có. SỬA: kiểm status khi load, loại snapshot đang tải bị invalidated, chặn load trong cancelInDb và toàn bộ transaction đổi lịch/giải tán/xóa tài khoản. Release guard cả commit/rollback. Không đổi DB thật ngoài dữ liệu fixture local. | Lần đầu integration tái hiện runtime còn sau cancel. Sau sửa: session-loading + local-gaps + group-management + account-deletion: 30 đạt, gồm WebSocket join/resume bị từ chối sau cancel. |
| I-05 Medium | Lobby rules + session state envelope | THÍCH NGHI: gửi grace_ms/grace_max thực từ server và hiển thị trước phiên; timer vẫn dựa deadline server; nói rõ không overlay lên app khác. GIỮ mặc định GRACE_MS=3000, cấu hình backend đã có. | Test lobby 8s/2 lượt đạt; session/controller suite đạt. Chưa xác minh lifecycle từng OS/device. |
| I-06 Medium | Journal privacy label; Explanation notice | SỬA copy đối chiếu: journal chỉ mình xem, không gửi kèm; explanation gửi owner. GIỮ API quyền riêng tư có sẵn. | journal-reports: 7 đạt; explanation_design: 10 đạt. |
| I-07 Medium | Final appeal decision + OwnerAppealScreen | SỬA: decision_effect lưu trước/sau exempted/forfeited trong cùng transaction, khóa session; existing handler/reason/timestamp giữ nguyên. UI đối chiếu tại thời điểm quyết định. Không trả Coins/chuỗi người khác; ledger hiện có vẫn ghi giao dịch bù. | appeals integration: 7 đạt, kiểm GET persisted snapshot và sensitive keys; appeal_effect widget đạt; TypeScript typecheck đạt. |
| I-08 Medium | MyData owned-report section | Backend đã cho đọc báo cáo nhóm giải tán. SỬA discovery: owned_reports chỉ owner hiện tại của bản ghi, kỳ GENERATED còn hạn; section riêng theo nhóm, mở chọn kỳ. Không thêm nhóm giải tán vào active memberships. Header unknown membership dùng “Báo cáo tháng”. | local-gaps kiểm owner archive/member own row/stranger denied; archived_reports widget mở report từ group rỗng đạt. |
| I-09 Low | PushPermissionCard fallback | FCM/SNS đã có. THÍCH NGHI phương án “ghi rõ in-app” trong ảnh: web/desktop nói inbox-only; mobile chưa cấu hình hướng dẫn mở inbox. GIỮ permission tự nguyện. | push_permission + push + explanation_design: 24 đạt; backend push unit/jobs/integration: 13 đạt. Chưa gửi thử native production. |
| I-10 Low | Explanation revision history | Lịch sử append-only đã có. GIỮ, bổ sung copy cách đối chiếu và quyền: người viết xem bản cũ, owner xem bản mới nhất/time edited. Không mở rộng quyền theo một finding thiếu ngữ cảnh. | local-gaps kiểm nhiều lần sửa, thứ tự revision, chặn xóa và owner không nhận history; explanation_design kiểm hiển thị lịch sử đạt. |

## Kiểm tra độc lập

Agent `flow_review` thực hiện source reviewer/app source auditor/arbiter theo prompts trong `agents/`, sau đó verifier độc lập với root implementer. Findings I-04 load-after-invalidate đã được sửa với guard toàn mutation. I-08 nhãn tháng mở kỳ mới nhất được sửa thành liên kết cấp nhóm. Không còn finding chặn từ source review.

`flutter analyze`: không có vấn đề. `git diff --check`: sạch. `flutter build web --release` bản cuối thành công (33.8s), artifact `app/build/web`; không deploy. Còn cảnh báo Wasm dry-run từ socket_io_common và font Cupertino của cấu hình hiện có, không chặn build JavaScript.

## Migration và giới hạn

- Thêm `backend/db/migrations/006-appeal-decision-effect.sql` (idempotent). Cơ chế migration hiện có tự phát hiện; integration chạy trên Postgres local đã áp dụng. Chưa áp dụng production trong phiên này.
- Quyết định cũ không có decision_effect vẫn hiển thị lý do/thời điểm, không bịa snapshot.
- **CHƯA XÁC MINH HÌNH ẢNH** cho mọi view thay đổi: chưa có ảnh browser/native đúng build/state. Widget layout tests không thay nghiệm thu hình ảnh. Không tuyên bố khớp mockup.
- Push có mã tích hợp và fallback rõ ràng, chưa chứng minh delivery FCM/APNs trên điện thoại thật. Thời gian grace giữ nguyên; chưa kết luận đủ dài cho mọi thiết bị.
- Không sửa workbook Excel của người dùng. Theo yêu cầu bổ sung, đã commit và push riêng từng mục I-01 đến I-10 lên `feature/registration-flow`; chưa deploy.
