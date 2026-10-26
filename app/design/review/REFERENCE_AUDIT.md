# Kiểm kê nguồn thiết kế

Ngày: 22/10/2026. Phạm vi: nguồn cục bộ, ưu tiên màn thành viên N-10 và N-09. **Chưa xác minh trực quan bản app đang chạy.** Đọc mã không đủ kết luận giao diện đẹp hoặc khớp mockup.

## 1. Nguồn và phạm vi sử dụng

| Nguồn | Vai trò | Giới hạn |
| --- | --- | --- |
| `app/design/design-system.html` | Thư viện màu, bề mặt, card, nút, lựa chọn, icon, chuyển động; ví dụ ghép màn Nhóm | Không phải đặc tả đầy đủ mọi màn thành viên; có chế độ so sánh nút đen/cam |
| `app/design/STITCH_DESIGN_SYSTEM.md` | Token đã chuẩn hóa, quy tắc triển khai, thứ tự ưu tiên | Theme chủ nhóm hiện chỉ áp dụng khi `ownerOnlyProvider == true`; không suy ra thành viên đã nhận đủ token |
| `mockup/n_10_l_ch_s_phi_n/code.html` | N-10: lịch sử phiên, nhóm theo ngày, hai thống kê, bộ chọn tuần/tháng | Dữ liệu minh họa; không có ảnh chụp kèm thư mục này |
| `mockup/n_09_k_t_qu_r_i_phi_n_s_m/code.html` | N-09: kết quả tự rời sớm, hậu quả, giải trình, về trang chủ | Chỉ một tình huống; nội dung nghiệp vụ phải đối chiếu backend hiện hành |
| `app/lib/features/history/history_screen.dart` | Hiện thực `/history`, mở `/history/:sessionId` | Bằng chứng mã nguồn, chưa phải bằng chứng render |
| `app/lib/features/session/result_screen.dart` | Kết quả trực tiếp và chi tiết từ lịch sử | Có nhiều trạng thái vượt phạm vi N-09 |

Stitch được ghi nhận trong tài liệu: dự án `2723223813529979616`; nguồn Nhóm `ef8748bdc11b4c0391735eb01a463747`, Shop `f4e4f5f3b5ba4bde91664e19e7c3b2f7`, Hồ sơ `973c5f1448634ef48a45a4ce7525a858`. Lần kiểm kê này không truy cập nguồn từ xa; không khẳng định các bản xuất cục bộ là phiên bản Stitch mới nhất.

## 2. Quy tắc xử lý khác biệt

1. Tuân thứ tự nguồn tại `DECISIONS.md`: yêu cầu/ngoại lệ được duyệt → nghiệp vụ/quyền riêng tư/quyền truy cập/dữ liệu thật/API → quyết định riêng của màn có bằng chứng và người duyệt → HTML cùng Stitch đúng vai trò/trạng thái → nguồn lịch sử.
2. Dùng thư viện HTML và token tham chiếu cho ngôn ngữ thị giác chung; dùng mockup từng màn cho bố cục và thứ bậc. “Chuẩn hóa” trong tài liệu không có nghĩa người dùng đã duyệt mọi token hoặc mọi màn.
3. Khi các nguồn mâu thuẫn, ghi quyết định trước khi sửa: nguồn, khác biệt, lý do giữ/đổi, ảnh hưởng màn khác, người kiểm lại. Không tự đánh dấu mọi khác biệt với Stitch là lỗi.
4. Mã hiện tại cũng không tự động là chuẩn. Kiểm tra hành vi và hợp đồng dữ liệu trước khi giữ một khác biệt vì “app đang như vậy”.

Các yêu cầu người dùng phải giữ: nền xám được làm kỹ; card không tự thêm outline; triển khai từng view. Không khôi phục các nội dung đã yêu cầu bỏ: phụ đề Shop “Đổi Coins lấy vật phẩm trang trí”, câu giải thích giới hạn nhóm, email ở hồ sơ, “Mục đích sử dụng” trong báo cáo. Giữ hướng asset khung đào 2D đã được duyệt. Các yêu cầu này không có nghĩa mọi màn cần thêm cam hoặc trang trí.

## 3. Mâu thuẫn cần phân xử

| Bằng chứng nguồn | Quyết định đề xuất | Cần kiểm lại |
| --- | --- | --- |
| N-09/N-10 dùng `bg-surface` = `#F4F5F7`, nhưng card `bg-surface-bright` = `#FCF9F8`; thư viện quy định card `#FFFFFF` | Ưu tiên nền xám/card trắng theo thư viện và phản hồi người dùng | Ảnh render cùng viewport, card nổi nhờ bề mặt/bóng, không outline |
| Mockup dùng muted `#8E8E93`; thư viện `#6C6C70` | Giữ màu thư viện để chữ dễ đọc | Độ tương phản thực tế trên từng nền |
| Mockup có secondary-soft `#FFEBE5`, primary-container `#2C2C2E`; thư viện soft `#FFF1EC`, nav `#1C1C1E` | Dùng token theo vai trò; không thay màu chỉ vì cùng tên gần giống | Kiểm tra thành viên và chủ nhóm riêng |
| N-10 bộ chọn dùng đen; thư viện có bộ lọc cam mềm kèm dấu chọn và chế độ nút đen/cam | Phân biệt bộ chọn khoảng thời gian với bộ lọc; ghi rõ lựa chọn trước triển khai | Không xem màu đen tự thân là lỗi; selected phải rõ ngoài màu |
| N-09 nút gửi cao 40px, nguồn back 40px; thư viện yêu cầu vùng chạm ≥44px | Có thể giữ kích thước hình ảnh, tăng vùng chạm | Keyboard, focus, thao tác chạm |
| N-09 luôn có ô giải trình; app dùng `canExplain`/`canAppeal` | Theo quyền và trạng thái hiện hành | Trường hợp được/không được giải trình; sau khi đã gửi |
| N-09 nói cả nhóm mất thưởng, mọi người đứt chuỗi; app phân biệt `EXITED` và `LOST` | Không sao chép hậu quả sang mọi trạng thái | Backend, dữ liệu kết quả thực, nội dung chuỗi/Coins |

## 4. N-10 — lịch sử phiên

**Sự thật từ mã:** Có tiêu đề, bộ chọn tuần/tháng, hai thống kê, card nhóm theo ngày và mở chi tiết. Danh sách hiện có icon trạng thái; mockup không có icon đầu dòng. Đây là khác biệt cần đánh giá mật độ thông tin, chưa đủ kết luận là lỗi.

**Nghi vấn hành vi cần tái hiện:** thống kê lọc `inRange`, nhưng vòng nhóm danh sách dùng `page.items`. Có khả năng đổi tuần/tháng chỉ đổi thống kê. Quyết định rõ phạm vi bộ chọn; nếu áp dụng cả màn thì danh sách và thống kê phải dùng cùng khoảng thời gian. Giới hạn 50 phiên cần kiểm tra với dữ liệu nhiều hơn 50, tránh thống kê khiến người xem hiểu là tổng đầy đủ.

Tiêu chí nghiệm thu:

- Nền `#F4F5F7`, card trắng không viền mặc định, radius16; gutter16 ở mobile; Inter đúng thứ bậc. Nhóm ngày, hai thống kê, bộ chọn giữ cấu trúc N-10.
- Thống kê và danh sách giải thích cùng khoảng thời gian, tính ngày theo múi giờ Việt Nam. Không trộn ngày ở ranh giới UTC.
- Nhìn phân biệt hoàn thành có thưởng, hoàn thành mất thưởng, tự rời, mất kết nối, vắng, hủy; không chỉ dựa màu. Coins lấy dữ liệu thật, hủy không hiện như có thưởng.
- Dòng dài tiếng Việt không đè Coins hoặc mất trạng thái; viewport nhỏ vẫn đọc được. Nhấn dòng mở đúng phiên; quay lại giữ ngữ cảnh.
- Kiểm tra loading, rỗng, lỗi, nhiều ngày, tên nhóm dài, nhiều dữ liệu. Chưa có ảnh các trạng thái thì chưa đánh dấu đạt.

## 5. N-09 — kết quả rời sớm

**Sự thật từ mã:** `ResultScreen` đã có nhánh `EXITED` (“Bạn đã rời phiên”), `LOST`, `ABSENT`, `VOID`, `WITHDRAWN` và hoàn thành. Màn hiện dùng hero, bảng kết quả, người tham gia, CTA theo quyền; khác bố cục N-09 gồm tiêu đề, thời điểm rời/phút đã tham gia, card hậu quả, ô giải trình. Có giao diện rời sớm trong mã, chưa xác minh truy cập/hiển thị thực tế.

Tiêu chí nghiệm thu:

- Giữ trọng tâm “Bạn đã rời phiên”; hiện rõ phiên nào, rời khi nào/thời gian thực tham gia nếu API cung cấp. Không tự dùng giờ kết thúc dự kiến thay giờ rời.
- Hậu quả Coins, chuỗi, thông báo nhóm đúng dữ liệu/backend; tách `EXITED` khỏi `LOST`. Không thêm khẳng định chưa kiểm chứng về người khác.
- Khối hậu quả và hành động gọn, theo bề mặt thư viện. Không bê mọi section chi tiết chung vào hero làm loãng kết quả.
- Giải trình xuất hiện đúng quyền, có validation, gửi thành công/lỗi/đã gửi; chỉ hiển thị khi nghiệp vụ cho phép. Khiếu nại kiểm riêng.
- Luồng vừa rời có CTA về trang chủ; mở từ lịch sử có back về lịch sử. Không mất khả năng đọc kết quả cũ.
- Kiểm tra phiên chưa kết thúc/409, tải chậm, lỗi, thành viên được miễn, tên dài. Ảnh đúng trạng thái là điều kiện nghiệm thu.

## 6. Bằng chứng bắt buộc trước kết luận

Mỗi màn cần ghi build/preview URL, thời điểm, vai trò tài khoản, viewport, dữ liệu/trạng thái, đường dẫn ảnh app và ảnh nguồn render cùng kích thước. Ảnh cũ ở `app/docs/screenshots/` chỉ là lịch sử nếu chưa chứng minh trùng build và trạng thái.

Tách ba loại kết quả: **đã thấy trên ảnh**, **đã xác nhận từ mã/hành vi**, **giả thuyết cần kiểm tra**. Agent kiểm lại phải đối chiếu ảnh sau sửa với quyết định đã ghi; không chỉ chạy analyzer rồi duyệt thị giác.

Thứ tự đề xuất: N-10 lịch sử phiên → N-09 rời sớm/chi tiết kết quả → các màn thành viên còn lại. Mỗi lượt đóng một màn cùng các trạng thái cần thiết, rồi mới mở rộng.
