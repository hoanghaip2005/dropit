# Đợt 02 — chi tiết phiên và giải trình

Trạng thái: AUDIT NGUỒN / ĐÃ PHÂN XỬ PHẠM VI / CHƯA XÁC MINH HÌNH ẢNH. Ngày 22/10/2026. Không phải visual pass. Không chặn triển khai cấu trúc đã xác định vì thiếu ảnh; nghiệm thu hình ảnh vẫn cần runtime.

## Nguồn và ngoại lệ

- `mockup/n_09_k_t_qu_r_i_phi_n_s_m/code.html`: hero rời sớm, thời điểm rời, tác động, giải trình; nguồn cũ nói cả nhóm thấy giải trình, trái privacy hiện hành: **không sao chép**.
- `mockup/success_reward/code.html`, `mockup/session_success_reward/code.html`: hero thành công, biên nhận thưởng, chuỗi, Coins hôm nay, CTA. Giá trị 25/50 phút, Coins, người nhận thông báo là demo.
- Local không có màn giải trình thành viên riêng đầy đủ. `mockup/alert_details/code.html`, `mockup/t_07_xem_l_i_v_x_c_nh_n_phi_n/code.html`, `mockup/t_11_chi_ti_t_b_o_c_o_th_nh_vi_n/code.html` chỉ bổ sung ngữ cảnh; không dùng layout owner hoặc dữ liệu của người khác cho member.
- D02, D06–D12 tại DECISIONS; yêu cầu mới badge mode/thời gian thực từ đợt 01 tiếp tục áp dụng. Một theme scoped, card trắng không outline; giữ back cho route ngoài shell. Không đổi toàn app.

## A — Chi tiết/kết quả phiên

1. Hero ưu tiên kết quả chính, tên nhóm, badge mode explicit `SQUAD`/`PERSONAL` nếu contract hỗ trợ; null không suy thành cá nhân. Mã hiện chỉ group-backed SQUAD. Ngày có năm, giờ VN, tên dài không đè badge.
2. Tách lịch dự kiến (`started_at`, `duration_min`) khỏi thực tế: `focus_seconds` là thời gian tập trung; `exited_at` là giờ rời; `ended_at` là giờ kết thúc của người dùng. Không tính giờ rời bằng started+focus; null ghi chưa có dữ liệu/ẩn giá trị phù hợp, không giả giờ lịch thành giờ thực. Có giây cho phiên ngắn, không floor thành 0 phút gây hiểu nhầm.
3. Giữ COMPLETED có/mất thưởng, EXITED, LOST, ABSENT, VOID, WITHDRAWN, miễn trừ. `forfeited` quyết định khẳng định mất thưởng tập thể; EXITED đã miễn trừ không tự khẳng định cả nhóm mất thưởng. LOST không tự gây ảnh hưởng nhóm. Không khẳng định push/đã nhận thông báo/số người nhận khi API không chứng minh delivery.
4. Hero thưởng theo `coins_awarded` thật; COMPLETED nhận 0 không gọi “có thưởng” vô điều kiện. Trần dùng dữ liệu cấu hình hoặc câu “đã đạt trần ngày”, bỏ hardcode100. Không bịa tiền thưởng lý thuyết/breakdown khi chưa có dữ liệu. VOID không diễn đạt như đã nhận thưởng.
5. Biên nhận gọn: tập trung thực, Coins nhận của phiên, chuỗi, trạng thái mất thưởng/trần khi có. `streak_after` hiện backend lấy chuỗi **hiện tại**, không snapshot sau phiên lịch sử: nhãn “Chuỗi hiện tại”, không “chuỗi sau phiên này”; `streak_broken` mô tả sự kiện phiên nhưng không ép giá trị hiện tại thành0. Không nói cả nhóm đứt chuỗi từ payload của chính mình.
6. Coins hôm nay nếu hiện lấy `historyRewardTodayProvider` aggregate ngày thưởng, cap thật; phân biệt hôm nay với ngày phiên cũ. Loading/error không giả0; retry riêng, không làm hỏng toàn bộ chi tiết. Không bắt buộc thêm banner lớn khi biên nhận gọn đã đủ thứ bậc.
7. Participants tên+trạng thái A–Z, không ranking, Coins, chuỗi hay giải trình của người khác. Không avatar giả; wrap tên/trạng thái ở320px. Không cần dòng giải thích “sắp A–Z” chiếm chỗ nếu thứ tự tự rõ. Empty không hiện card trống.
8. Hành động: giải trình là flow riêng hợp lệ, không cần textarea inline N09. Với EXITED, vẫn có đường “Xem giải trình” sau hạn gửi để đọc bản đã gửi và hạn sửa riêng; không chỉ dựa `can_explain` để giấu mọi truy cập. Khiếu nại theo `can_appeal`, khác giải trình; miễn trừ không đổi bản chất sự kiện. Coins history giữ đường truy cập phụ.
9. Từ lịch sử: back giữ ngữ cảnh. Kết quả mới: CTA về home. Loading skeleton, lỗi+retry, 409 đang chốt, forbidden/notfound có trạng thái rõ; không gọi mọi409 là kết quả đã có. Refresh đồng bộ kết quả, giải trình liên quan và thưởng khi cần.

## B — Gửi/xem/sửa giải trình

1. Context card cùng ngôn ngữ chi tiết: tên, badge mode thật, giờ rời và tập trung thực; lịch dự kiến có nhãn riêng. Header/CTA thay theo chưa gửi, đã gửi sửa được, hết hạn chỉ đọc. Không nhập tay trước khi tải trạng thái để tránh dữ liệu mới ghi đè draft.
2. Gate hai nguồn async: result và GET giải trình. Loading chưa cho submit; lỗi không coi như chưa gửi. GET404 chính chủ theo API hiện là chưa gửi, nhưng session404 phải hiện không tìm thấy. EXITED chính chủ mới gửi; LOST/ABSENT/owner không thành form khả dụng. Chỉ đọc bản cũ vẫn hoạt động sau hạn.
3. Hạn gửi lần đầu theo `sessions.ends_at + explanationSubmitDays`; hạn sửa theo `submitted_at + explanationEditH`, độc lập hạn gửi. Cấu hình hiện7ngày/24giờ nhưng UI không bịa deadline từ started+duration; ưu tiên metadata server chính xác. Nếu chưa có metadata, dùng mô tả chính sách hiện hành và backend là trọng tài, không hiện timestamp suy đoán. Hết hạn cập nhật cả field readOnly lẫn CTA, không chỉ disable nút.
4. Nội dung trim không rỗng, tối đa500 Unicode code points theo backend `[...text].length`; counter/validation phải cùng cách đếm (emoji không lệch UTF16). Submit disabled khi rỗng/quá giới hạn/loading/busy/locked; ngăn gửi đôi. Lưu thay đổi không tạo revision nếu nội dung không đổi.
5. Privacy ngắn nhưng đủ: chỉ bạn/chủ nhóm thấy, thành viên khác không thấy; giải trình không tự đổi kết quả/Coins/chuỗi, không xóa sự kiện. Không hứa miễn trừ khi gửi. Chủ nhóm nhận thông báo trong app, không hứa push.
6. Hiện submitted_at, edited_at, edit_deadline theo VN, có năm; added_after_report khi true. Lịch sử bản cũ chỉ của chính mình, newest-first theo server, đọc được nội dung và mốc thay thế; có thể collapse để giảm dài nhưng không bỏ. Không thêm xóa vì API không có.
7. Success giữ nội dung đã gửi, hiện trạng thái gọn, invalidate/refetch GET giải trình để lấy can_edit/deadline/history đầy đủ (PUT hiện không trả đủ metadata), invalidate result/history family. Không reset draft chỉ vì provider refetch. Lỗi giữ draft và focus hợp lý.
8. VERSION_CONFLICT: thông báo rõ tải bản mới, giữ draft để đối chiếu, không âm thầm retry ghi đè. Nên dùng If-Match từ `version`/updatedAt server khi sửa; API hiện hỗ trợ header optional, model chưa giữ version. Không đổi backend policy trong patch UI.
9. EXPLANATION_WINDOW_CLOSED: re-fetch trạng thái và chuyển read-only nếu có bản; NOT_EXITED/FORBIDDEN không tiếp tục cho gửi; lỗi mạng retry được. Dirty draft khi đóng cần lựa chọn giữ/sửa hoặc bỏ thay đổi, không mất âm thầm. Bàn phím không che CTA/counter, text scale lớn không overflow.

## Tiêu chí kiểm độc lập

- Detail: mọi trạng thái A3, thưởng0/>0/trần, miễn trừ, timestamps null, tên dài, participants rỗng/nhiều, trực tiếp/từ history, loading/error/409.
- Explanation: mới, đã gửi chưa sửa, đã sửa có history, hết hạn gửi, hết hạn sửa, read-only, khác user/notEXITED, request conflict, offline, retry,500/501 code points/emoji/whitespace, draft khi back, thời hạn vừa trôi qua.
- Hai worker sở hữu file riêng; thay shared/API/model phải báo root để tránh ghi đè. Kiểm hành vi và visual riêng. Ảnh runtime đúng build/viewport/role/state mới cho phép kết luận thị giác.
