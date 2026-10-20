# V-25 Dữ liệu của tôi

Story: US-01.08 (Must); US-01.09 xuất (Should), US-01.11 nhật ký truy cập (Should) · Quy tắc: BR-38, BR-53, BR-59, BR-73, BR-103, BR-119 · Quyết định: D-12, D-21, D-22 · NFR: NFR-P03, NFR-P06, NFR-P11, NFR-P13, NFR-P18, NFR-11; ma trận 04 §3 cột "Thành viên (của mình)" · Token: DESIGN.md

## Mục đích
Cho người dùng xem **mọi** dữ liệu hệ thống lưu về mình, cùng trường và cùng độ chi tiết chủ nhóm thấy (NFR-P03). Màn chỉ đọc.

## Vai trò
Người dùng (chính mình). Không ai khác mở được (AC-01.08.3).

## Lối vào / lối ra
- Vào: V-22 "Dữ liệu của tôi".
- Ra: chạm từng mục → màn chi tiết tương ứng (cột "Chạm →").

## Thành phần

| Phần tử | Dữ liệu | Nguồn |
| --- | --- | --- |
| Đầu màn | "Dữ liệu của tôi" · câu "Đây là mọi thứ DropIt! lưu về bạn. Chủ nhóm chỉ thấy phần ghi '(chủ nhóm thấy)' và chỉ trong nhóm của họ." | NFR-P03 |
| Bộ lọc nhóm | "Tất cả" · nhóm hiện tại · các nhóm cũ (đã rời / đã giải tán) | AC-01.08.1, BR-59, D-21 |
| Nhãn "Chủ nhóm thấy" | Chip trắng viền trên mỗi mục chủ nhóm thấy; chip "Chỉ bạn" cho mục còn lại | 04 §3 |

### Các mục (theo ma trận 04 §3, cột 1)

| Mục | Nội dung | Nhãn | Chạm → |
| --- | --- | --- | --- |
| Sự kiện rời app | Mỗi sự kiện: phiên, giờ rời (giờ server), giờ quay lại app nếu server có ghi (04 §2 mục 2, ma trận dòng "Thời điểm quay lại app"), giải trình (nếu có), kết quả khiếu nại (Should) | Chủ nhóm thấy | V-15 |
| Kết quả phiên | Mỗi phiên: trạng thái của bạn (Hoàn thành / Hoàn thành có thưởng / Rời app / Mất kết nối / Vắng / Không tính), phiên có mất thưởng tập thể không, tên người khởi phát | Chủ nhóm thấy | V-12/V-13/V-14 |
| Vắng, vào muộn, mất kết nối | Đếm và danh sách theo phiên | Chủ nhóm thấy | V-14 |
| Số lần gây mất thưởng / số lần rời app trong tháng | Theo nhóm, theo tháng | Chủ nhóm thấy | V-34 |
| Tạm dừng *(khi US-03.06 trong phạm vi)* | Lý do, thời lượng | Chủ nhóm thấy | — |
| Giải trình | Nội dung, lúc gửi, lúc sửa | Chủ nhóm thấy | V-15 |
| Điểm danh trong nhóm | Số ngày, số phiên, số phút — theo nhóm | Chủ nhóm thấy (chỉ nhóm của họ) | V-34 |
| Báo cáo tháng (phần của tôi) | Danh sách kỳ có dòng của bạn | Chủ nhóm thấy | V-34 |
| Chuỗi ngày | Hiện tại, dài nhất | Chỉ bạn (trừ khi tự bật trên hồ sơ, D-12) | V-26 |
| Huy hiệu | Danh sách đã đạt, ngày đạt | Chỉ bạn (trừ khi tự bật) | V-26 / V-28 |
| Coins | Số dư, lịch sử | Chỉ bạn | V-29 |
| Đồ Shop | Đã mua; đang trang bị | Đang trang bị: mọi người cùng nhóm thấy | V-22 |
| Hồ sơ | Tên, ảnh, email | Tên/ảnh: người cùng nhóm thấy; email: chỉ bạn và quản trị | V-23 |
| Nhật ký | Số mục (không hiện nội dung ở đây) | Chỉ bạn | V-33 |
| Bản ghi đồng ý | Nhóm, phiên bản nội dung, thời điểm đồng ý / rút đồng ý | Chỉ bạn | (chi tiết dạng danh sách) |
| Ai đã xem dữ liệu của tôi *(US-01.11, Should)* | Ẩn khi chưa trong phạm vi | — | — |
| Xuất dữ liệu *(US-01.09, Should)* | Ẩn khi chưa trong phạm vi | — | — |

API: `GET /me/data?group_id=` — luôn lấy `user_id` từ token, không nhận `user_id` từ tham số (AC-01.08.3).

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | Danh sách mục; mỗi mục có số tóm tắt |
| Chưa vào nhóm nào | Mục cá nhân (hồ sơ, Coins, nhật ký, chuỗi) có dữ liệu; mục nhóm hiện "Chưa có dữ liệu" (AC-01.08.5) |
| Mục rỗng | "Chưa có dữ liệu" ở mục đó |
| Đang tải | Khung xương từng mục |
| Lỗi | Lỗi theo mục: "Chưa tải được mục này." + "Thử lại"; mục khác vẫn hiện |
| Mất mạng | Bản đã lưu + "Chưa cập nhật" |

## Câu chữ chính
- "Đây là mọi thứ DropIt! lưu về bạn."
- "Chủ nhóm thấy" / "Chỉ bạn"
- "Không xóa được sự kiện rời app khi còn trong nhóm. Nếu ghi nhầm, hãy gửi giải trình." (NFR-P13)
- Ở kết quả phiên `forfeited` do người khác: "Phiên đã mất thưởng tập thể do ‹Tên› rời phiên." (AC-01.08.4)

## Điều cấm
- Không hiện dữ liệu của người khác ngoài tên người khởi phát ở phiên `forfeited`: không lý do tạm dừng, giải trình, Coins hay số lần thoát tích lũy của họ (AC-01.08.4, NFR-P06).
- Không nút sửa/xóa sự kiện phiên (màn chỉ đọc).
- Không gộp chỉ số cấp người dùng (chuỗi, tổng giờ huy hiệu) vào mục "chủ nhóm thấy" (D-12, BR-59).
- Không hiện nội dung nhật ký trong màn tổng hợp (mở V-33 mới đọc).
- Trường chủ nhóm thấy mà thiếu ở màn này = lỗi chặn phát hành (NFR-P03, AC-01.08.2).

## AC liên quan
AC-01.08.1, .2, .3, .4, .5; AC-02.06.5.
