# V-05 Đồng ý minh bạch — bổ sung trạng thái lỗi

Story: US-01.05 (Must) · Quy tắc: BR-06, BR-33, BR-74, BR-75, BR-76 · Quyết định: D-05, D-10, D-14, D-20, D-21, D-22, D-25 · NFR: NFR-P04, NFR-P09, NFR-P18 · Token: DESIGN.md
Bổ sung cho `mockup/c_04_ng_quy_t_c_minh_b_ch_v_quy_n_ri_ng_t` (nội dung 8 mục đã viết lại ở đợt 1). Tệp này chỉ thêm trạng thái lỗi/biên; nội dung 8 mục theo 04 §2.

## Mục đích
Người được mời đọc đủ luật trước khi vào nhóm; mọi lỗi khi bấm "Đồng ý và vào nhóm" phải có câu rõ, không lưu bản ghi đồng ý.

## Vai trò
Người dùng đã nhập mã hợp lệ ở V-04, chưa là thành viên nhóm nào chưa giải tán.

## Lối vào / lối ra
- Vào: V-04 (mã hợp lệ); V-06 khi chưa đồng ý phiên bản điều khoản mới (AC-03.01.2).
- Ra: "Đồng ý và vào nhóm" thành công → V-03. "Không đồng ý" / đóng → V-19, không lưu (AC-01.05.3).

## Thành phần
| Phần tử | Dữ liệu | Nguồn |
| --- | --- | --- |
| 8 mục 04 §2 | Như mockup; mục 2b và mục 4 (D-05, D-22) nổi bật | AC-01.05.1, .9 |
| Khối mục đích báo cáo (V-35) | Nguyên văn mục đích của nhóm | US-08.08 |
| Công tắc / nút | Không đánh dấu sẵn; nút bật sau khi cuộn đến cuối | AC-01.05.5 |
| Vùng báo lỗi | Thẻ nền `#FFF1EC`, chữ `#111111`, ngay trên nút | DESIGN.md |

## Trạng thái

| Trạng thái | Hiển thị |
| --- | --- |
| Bình thường | 8 mục + nút khóa đến khi cuộn hết |
| Đang gửi | Nút "Đang vào nhóm…" khóa, chống bấm hai lần |
| Thành công | → V-03, toast "Bạn đã vào nhóm ‹Tên nhóm›" |
| Lỗi — nhóm đầy | "Nhóm đã đủ 10 thành viên." Không lưu (AC-01.05.6, .7) |
| Biên — còn 1 chỗ, hai người bấm cùng lúc | Người đến server trước vào được; người sau thấy như "nhóm đầy" (AC-01.05.7, BR-33) |
| Lỗi — đang ở nhóm khác | "Bạn đang ở nhóm ‹A›. Rời nhóm ‹A› trước khi tham gia nhóm khác." + liên kết → V-21 (AC-01.05.10) |
| Lỗi — nhóm cũ đang CHỜ GIẢI TÁN | Như dòng trên (AC-01.05.11) |
| Lỗi — là chủ nhóm của nhóm này | Không mở màn này; V-04 báo "Bạn là chủ nhóm" (AC-01.05.8) |
| Lỗi — mã hết hiệu lực / nhóm giải tán trong lúc đọc | "Mã mời không còn hiệu lực." → V-04 (BR-76, giả định) |
| Lỗi — điều khoản vừa đổi phiên bản | "Nội dung vừa được cập nhật. Vui lòng đọc lại." Tải lại, nút khóa lại (BR-06, giả định) |
| Đang tải | Khung xương |
| Lỗi tải | "Chưa tải được nội dung." + "Thử lại"; nút khóa |
| Mất mạng | Nút khóa; "Cần kết nối mạng để vào nhóm." Không lưu đồng ý trên máy |

## Câu chữ chính
- "Nếu bất kỳ ai trong phiên rời app, cả phiên mất Coins và chuỗi, và mọi người trong nhóm biết tên người thoát."
- "Nhóm đã đủ 10 thành viên."
- "Bạn đang ở nhóm ‹A›. Rời nhóm ‹A› trước khi tham gia nhóm khác."

## Điều cấm
- Không đánh dấu sẵn (AC-01.05.5).
- Không lưu bản ghi đồng ý khi lỗi (AC-01.05.6, .10).
- Không "mã hóa đầu cuối", "chỉ ghi tổng phút", cảm biến (T-BA-95).
- Không cho vào phòng chờ khi chưa đồng ý (AC-01.05.4).

## AC liên quan
AC-01.05.1 … .11; AC-02.03.5, .7; AC-03.01.2.
