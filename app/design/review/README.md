# Quy trình kiểm tra và triển khai giao diện DropIt!

Đây là bộ vai trò agent, hồ sơ quyết định và kế hoạch theo view. Có thể dùng lại trong các phiên sau; không phải dịch vụ tự chạy nền. Quy tắc được dẫn từ `AGENTS.md` ở gốc repo.

Hồ sơ đợt đầu: [01 — lịch sử thành viên](01-MEMBER-HISTORY.md), [02 — kết quả rời sớm](02-EARLY-EXIT.md). Kết quả kiểm tài liệu: [WORKFLOW_RECHECK.md](WORKFLOW_RECHECK.md).

Quy ước đường dẫn: chuỗi code bắt đầu `app/` hoặc `mockup/` tính từ gốc repo `D:\DropIt!`; tên file trần trong bộ review tính từ `app/design/review/`. Liên kết Markdown trong bộ này dùng đường dẫn tương đối tới tài liệu đích.

## Vì sao thay quy trình

Các đợt trước sửa token/bố cục rồi dùng analyze/test làm căn cứ kết luận. Chưa có bộ ảnh runtime mới, cùng kích thước, cùng trạng thái để đối chiếu độc lập. Vì vậy trạng thái các view đã sửa là **đã triển khai, chưa xác minh hình ảnh**, không phải “đạt mockup”.

## Vai trò

| Agent | Đầu vào | Đầu ra | Không được làm |
|---|---|---|---|
| Reference reviewer | Mockup, HTML, yêu cầu đã chấp nhận | Map nguồn + tiêu chí từng view | Chọn ngẫu nhiên một phiên bản Stitch |
| App auditor | App đúng build, route, vai trò, viewport, trạng thái | Danh sách khác biệt có bằng chứng | Suy ra hình ảnh từ code hoặc test |
| Design arbiter | Hai audit + domain + yêu cầu người dùng | Giữ / sửa / thích nghi / chờ bằng chứng | Ép app chép 100% mockup cũ |
| Implementer | Hồ sơ view có quyết định và phạm vi | Patch nhỏ + ảnh sau + kết quả kiểm tra | Đổi các view/component khác không ghi tác động |
| Independent verifier | Nguồn đã chọn + quyết định + build mới | Pass / cần sửa / chưa thể xác minh | Tự xác nhận patch mình vừa làm |

Các prompt nằm trong `agents/`. Auditor và arbiter có thể chạy song song khi đầu vào độc lập. Implementer chỉ chạy sau khi quyết định rõ. Verifier chạy sau build; nếu cần sửa, trả findings về implementer rồi kiểm lại đúng findings và phạm vi ảnh hưởng.

## Thứ tự chọn nguồn

Thứ tự chuẩn nằm tại `DECISIONS.md`; các prompt và audit phải dùng cùng thứ tự:

1. Yêu cầu hiện tại của người dùng và ngoại lệ đã được duyệt rõ ràng.
2. Quy tắc nghiệp vụ, quyền riêng tư, quyền truy cập, dữ liệu thật và khả năng API hiện tại.
3. Quyết định riêng của màn đã có bằng chứng và người duyệt.
4. Thư viện HTML cùng màn Stitch phù hợp đúng vai trò, trạng thái; ghi phiên bản, đường dẫn và hash. HTML hiện là tham chiếu, không tự coi toàn bộ là đã duyệt.
5. Biến thể Stitch cũ và tài liệu lịch sử.

Accessibility hoặc giới hạn nền tảng có thể cần thích nghi. Ghi quyết định thay vì âm thầm thêm style mới. Khác biệt nội dung không được đánh giá bằng pixel diff thuần túy.

## Các bước của một đợt

1. **Chốt phạm vi:** một view, vai trò, route, source, state matrix, file sở hữu. Tạo hồ sơ từ `VIEW_TEMPLATE.md`.
2. **Thu bằng chứng trước:** build identity + ảnh app + ảnh mockup cùng viewport. Ghi thời điểm, dữ liệu seed và trạng thái. Không đổi viewport giữa ảnh trước/sau.
3. **Đối chiếu:** phân loại nền, surface, type, spacing, icon, navigation, nội dung, hành vi, accessibility; mỗi finding có source và mức ưu tiên.
4. **Phân xử:** ghi giữ/sửa/thích nghi/chờ bằng chứng, lý do và tiêu chí chấp nhận. Chỉ hỏi người dùng khi lựa chọn sản phẩm còn mơ hồ và ảnh hưởng lớn.
5. **Sửa:** implementer sửa đúng scope. Shared component phải ghi view/vai trò bị ảnh hưởng; không thay token toàn app để sửa một màn.
6. **Kiểm tra:** analyze, kiểm thử hành vi liên quan, render kích thước hẹp; build web; kiểm đúng URL/hash. Kiểm thử thiết bị Android ghi riêng với web.
7. **Đánh giá độc lập:** verifier xem ảnh sau và tương tác thật, không dùng mô tả implementer làm bằng chứng. Findings còn mở → quay lại bước 5. Không ép “pass” bằng cách bỏ tiêu chí.
8. **Bàn giao:** link build mới + ảnh so sánh + thay đổi chính + ngoại lệ còn mở. Chờ phản hồi view hiện tại trước khi mở rộng hàng loạt.

## Cổng chất lượng

- Canvas, inset và card được kiểm riêng; card không viền trừ quyết định cụ thể. Không nhầm viền focus với outline thường trực.
- Baseline 390×844; kiểm hẹp 320×740, rộng 768×1024, chữ phóng lớn. View dữ liệu dài cần ảnh toàn trang hoặc nhiều ảnh cuộn có mốc.
- Trạng thái bắt buộc tùy view: loading/error/empty/populated; tên dài, số null, bị khóa/disabled, selected/focus. Result phải phân biệt EXITED, LOST, ABSENT, VOID, WITHDRAWN và COMPLETED có/mất thưởng theo hợp đồng dữ liệu hiện tại; không tự tạo enum CANCELLED từ nhãn “hủy”.
- Ảnh có nguồn, build, role, viewport và state. Ảnh cũ ở `app/docs/screenshots` chỉ là tham khảo nếu chưa khớp build.
- Khi công cụ truy cập UI bị chặn, ghi giới hạn và dừng kết luận visual. Không đổi công cụ để né chính sách. Ảnh widget render có thể hỗ trợ layout nhưng không chứng minh browser runtime/native lifecycle.
- `PASS` cần verifier xác nhận bằng chứng, không chỉ implementer. Đánh giá của người dùng được ghi riêng, không bịa là đã duyệt.

## Trạng thái hồ sơ

`CHƯA AUDIT` → `AUDIT NGUỒN` → `CHỜ ẢNH APP` → `ĐÃ PHÂN XỬ` → `ĐANG SỬA` → `CHỜ VERIFIER` → `CẦN SỬA` hoặc `ĐẠT KIỂM TRA ĐỘC LẬP` → `CHỜ PHẢN HỒI NGƯỜI DÙNG`.

Không có screenshot hiện tại thì chỉ ghi “audit mã nguồn”, không “audit hình ảnh”. Không có tự động tiếp tục hoặc lịch chạy nền được thiết lập bởi tài liệu này.
