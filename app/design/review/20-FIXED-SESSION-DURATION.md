# Thời lượng lịch cố định 25/50 phút

## Phạm vi và nguồn

- View: chủ nhóm, tạo lịch V-44 và sửa lịch V-45; shared component `SessionDurationInput`.
- Source of truth: BR-02 tại `ba/srs/03-quy-tac.md`; V-44 mockup `mockup/schedule_focus/code.html`; V-45 tại `ba/views/V45-sua-huy-lich.md`.
- Reference audit: agent `duration-reference`; app source audit: agent `duration-app-audit`; arbiter: agent `duration-arbiter`.
- Quyết định: D19 — chỉ cho chọn 25 hoặc 50 phút, không có nhập tự do. Lịch cũ có thời lượng khác không tự đổi; màn sửa yêu cầu người dùng chọn thời lượng hợp lệ.
- Screenshot/build runtime sau thay đổi: chưa có. **CHƯA XÁC MINH HÌNH ẢNH**.

## Findings và phân xử

| ID | Ưu tiên | Quan sát | Phân xử |
|---|---|---|---|
| SD-01 | P1 | BR-02/OpenAPI quy định `{25, 50}`, nhưng UI, API và schema cho phép 1–240; CI không chặn được 30 phút. | SỬA: cùng một tập 25/50 ở UI, API và DB; giữ 25/50 là hai lựa chọn duy nhất. |
| SD-02 | P2 | Control sửa lịch có thể gặp dữ liệu cũ ngoài 25/50. | THÍCH NGHI: không tự đổi; không chọn sẵn giá trị không hợp lệ, yêu cầu chủ nhóm chọn 25/50 trước khi lưu. |

## Triển khai và kiểm thử

- UI: bỏ trường nhập phút tùy ý; chỉ còn hai lựa chọn 25/50; cập nhật lỗi validation.
- Backend: validate chỉ chấp nhận 25/50; kiểm thử API và unit bao phủ giá trị ngoài tập.
- Schema: thêm CHECK cho schedules/sessions; migration không tự sửa dữ liệu cũ.
- Flutter: `flutter test test/group_management_test.dart test/local_gaps_test.dart` — 21 tests đạt; `flutter analyze` hai file nhóm — không có vấn đề; `flutter build web --debug` — đạt. Flutter báo cảnh báo WASM từ dependency `socket_io_common`, JavaScript build thành công.
- Backend: typecheck đạt; unit/integration mục tiêu — 24 tests đạt; kiểm thử PATCH 30 phút bổ sung — 1 test đạt. Verifier độc lập yêu cầu ca PATCH 30 phút; đã thêm vào `local-gaps.test.ts`.
- Schema: `design/tests/schema_test.sql` — 57 PASS / 0 FAIL trên PostgreSQL 16 tạm; migration 009 áp dụng thành công trên database tạm. Dữ liệu duration cũ không bị tự chuyển; migration báo lỗi nếu dữ liệu hiện có vi phạm quy tắc mới.
- Diff whitespace: `git diff --check` đạt.
- Diff: `app/lib/features/groups/group_screens.dart`, `app/lib/features/groups/membership_screens.dart`, tests UI/backend, `design/schema.sql`, `design/tests/schema_test.sql`, migration 009.

## Vòng kiểm tra độc lập

| Vòng | Verifier | Build | Kết luận |
|---|---|---|---|
| Source arbitration | `duration-arbiter` (không phải implementer) | Không áp dụng | SỬA theo BR-02; CHƯA XÁC MINH HÌNH ẢNH |
| Kiểm tra cuối | `duration-final-check` (không phải implementer) | Web debug build | Không phát hiện đường tạo/sửa ngoài 25/50; đề xuất test PATCH 30 phút đã được bổ sung. CHƯA XÁC MINH HÌNH ẢNH |
