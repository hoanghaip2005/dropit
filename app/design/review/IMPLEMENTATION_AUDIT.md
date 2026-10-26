# Kiểm toán triển khai: lịch sử và kết quả phiên

Ngày: 2026-10-22. Phạm vi: đọc mã Flutter, mockup HTML cục bộ, router, theme và máy chủ preview. Chưa đối chiếu ảnh app đang chạy; tài liệu này **không phải xác nhận giao diện đạt**. Không sửa app trong đợt kiểm toán.

## Phát hiện cần phân xử trước khi sửa

| Mức | Bằng chứng | Vấn đề / quyết định cần ghi |
| --- | --- | --- |
| P1 | `app/lib/features/history/history_screen.dart:53–64` | Tuần/tháng chỉ lọc số liệu tổng; danh sách vẫn dùng toàn bộ `page.items`. Chốt selector lọc toàn màn hay chỉ thống kê; không tự đổi nghiệp vụ theo hình. |
| P1 | `app/lib/features/history/history_screen.dart:94` | Có cursor nhưng chỉ báo 50 phiên gần nhất. Thống kê có thể thiếu khi kỳ có hơn một trang. Chốt thống kê toàn kỳ hay dữ liệu đã tải; cần API/tải trang phù hợp trước khi gọi là tổng kỳ. |
| P1 | `app/lib/main.dart:27`, `app/lib/core/providers.dart:61` | Theme chủ nhóm phụ thuộc tài khoản có tất cả nhóm là owner; đang tải hoặc tài khoản có vai trò hỗn hợp dùng theme thành viên. Cần chốt style theo màn hay theo tài khoản, kiểm tra cả ba trạng thái. |
| P1 | `app/scripts/serve_web.py:9–16,56–71` | Prefix dựa tên/kích thước/mtime; URL preview cũ vẫn phục vụ build hiện tại. Không kết luận cache từ URL. Ghi `X-Preview-Version` của HTML, SHA256 `main.dart.js`, vai trò, viewport và thời điểm ảnh. |
| P2 | `app/lib/features/history/history_screen.dart:64` | Nhóm theo `ddmm`, thiếu năm; cần kiểm tra dữ liệu nhiều năm và thứ tự backend trước khi thay. |

## Sai khác bố cục và quyết định thiết kế

| Vùng | Mockup | Triển khai | Hướng xử lý |
| --- | --- | --- | --- |
| Dòng lịch sử | `mockup/n_10_l_ch_s_phi_n/code.html:18,20`: tên, giờ, nhãn trạng thái riêng, Coins bên phải | `history_screen.dart:109–133`: thêm icon tròn 40px; giờ và trạng thái chung subtitle | Theo bố cục tham chiếu: bỏ icon nếu không có lý do sản phẩm; tách nhãn trạng thái để kiểm soát màu, khoảng cách và xuống dòng. Cần ảnh so sánh trước khi duyệt. |
| Màu lịch sử | Nhãn trạng thái có màu ngữ nghĩa riêng | Dùng `ResultCopy` của kết quả, subtitle chưa có màu riêng | Điều chỉnh theo ngữ nghĩa lịch sử; không dùng màu thành công cho mọi biến thể hoàn thành nếu làm mất phân biệt mất thưởng. |
| Giờ kết thúc | Mockup hiện cửa sổ phiên | `history_screen.dart:110`: giờ bắt đầu cộng thời lượng | Giữ nếu biểu diễn lịch dự kiến; nếu muốn giờ rời thực tế phải có dữ liệu thật và nhãn rõ. |
| Navigation lịch sử | Mockup có thanh dưới tại dòng 21 | `app/lib/app/router.dart:46,60`: `/history` ngoài shell, có nút quay lại | Cần phân xử: màn chi tiết từ hồ sơ có thể hợp lý khi không có nav. Không thêm nav chỉ để giống hình. |
| Rời sớm | `mockup/n_09_k_t_qu_r_i_phi_n_s_m/code.html:15–17`: giờ rời, phút x/y, các tác động riêng | `result_screen.dart:106–149`: layout chung, lý do và biên nhận | Tạo spec biến thể EXITED; dùng thông tin thực có, không bịa giờ rời hoặc số người nhận thông báo. |
| Giải trình | Mockup dòng 18 có textarea ngay trên kết quả | `result_screen.dart:165–170`: nút tới màn riêng, có `canExplain` | Có thể giữ flow riêng nếu phù hợp hạn gửi/quyền riêng tư. Xác minh nghiệp vụ hiện hành; ghi deviation rồi mới triển khai. |
| Khiếu nại / miễn trừ | Không đầy đủ trong mockup rời sớm | `result_screen.dart:150–174`: miễn trừ, `canAppeal` | Giữ quyền và trạng thái thật. Mockup cũ không được loại bỏ chức năng hiện hành. |
| Mất kết nối | Mockup rời sớm không thay thế trạng thái này | `result_screen.dart:44–55`: EXITED khác LOST | Giữ phân biệt: LOST không tự gây mất thưởng tập thể. Không hợp nhất vì bố cục giống nhau. |
| Chuỗi | Mockup nói chuỗi mọi người bị ngắt | Biên nhận dùng `res.streakBroken`, `res.streakAfter` | Theo dữ liệu/quy tắc server; không chép câu mockup chưa xác nhận. |
| Điểm quay về | Mockup có về trang chủ | `result_screen.dart:182–197`: từ lịch sử quay lại, kết quả mới về home | Giữ ngữ cảnh điều hướng; kiểm tra cả hai đường vào. |

Đường dẫn rút gọn trong bảng: `history_screen.dart` thuộc `app/lib/features/history/`; `result_screen.dart` thuộc `app/lib/features/session/`.

## Các phần triển khai nhỏ

1. **Chốt bằng chứng:** mở đúng build, ghi vai trò và dữ liệu fixture. Chụp trước ở 320, 390, 768px. Lưu ảnh tham chiếu và app cùng kích thước; đánh dấu sai khác. Chưa có ảnh thì trạng thái là `chưa kiểm chứng`.
2. **Chỉ lịch sử:** reviewer phân xử selector, thống kê phân trang, navigation, giờ dự kiến/thực tế; ghi quyết định. Implementer sửa bố cục dòng và nhãn đã duyệt, không kéo theo theme toàn app. Reviewer độc lập so ảnh sau, kiểm tra nhãn dài, trống, lỗi, loading và đủ trạng thái.
3. **Chỉ kết quả rời sớm:** lập ma trận COMPLETED có/không thưởng, EXITED, LOST, ABSENT, VOID, WITHDRAWN, miễn trừ, được/không được giải trình và khiếu nại. Chốt nội dung dựa API, sau đó sửa hero/tác động và thứ bậc CTA. Kiểm tra cả vào từ lịch sử và kết thúc phiên.
4. **Theme và navigation:** làm lô riêng sau khi hai màn được duyệt; kiểm tra tài khoản owner, member, hỗn hợp và lúc provider tải. Không sửa token toàn cục trong lô chỉnh một màn.

## Điều kiện đóng từng phần

- Có ảnh trước / tham chiếu / sau, build identity, viewport, fixture, route và vai trò.
- Mọi sai khác có một quyết định: theo tham chiếu, thích nghi có lý do, giữ nghiệp vụ, hoặc cần xác minh. Không để `cần xác minh` thành `đạt`.
- Người kiểm tra lại độc lập đối chiếu đúng phạm vi; phần chưa xem không được ghi đạt.
- Test hành vi xác nhận selector, phân trang hoặc quyền nếu đã thay; analyze/test xanh không thay thế duyệt hình.
- Sai khác chưa sửa ghi rõ file, mức độ, chủ trách nhiệm và lô tiếp theo. Không đóng bằng nhận xét chung “đã giống mockup”.
