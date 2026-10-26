# Đợt04 — phòng chờ và phiên hoạt động

Ngày23/10/2026. SOURCE AUDIT / PHÂN XỬ TRIỂN KHAI; CHƯA XÁC MINH HÌNH ẢNH. Sở hữu triển khai: `session_screen.dart` và test phạm vi này. Không sửa controller, lifecycle, engine hoặc backend. Không một mình trong repo; giữ patch người khác. Khác biệt dưới đây là thích nghi có lý do, không sao chép Stitch100%.

## Nguồn và lựa chọn

- `mockup/session_lobby_1/code.html`, `session_lobby_2/code.html`: layout lobby sáng, timer, metadata, chip người, quy tắc, CTA. Số25/50, thưởng10/25,4/7 người và tên là demo. Mockup nút “Sẵn sàng” không ứng với controller hiện tại tự vào/tự bắt đầu: không thêm nút giả.
- `mockup/lockdown_mode/code.html`, `lockdown_mode_active_focus_1/code.html`: hierarchy active tối. Giữ nền đen tĩnh có chủ đích; không áp canvas sáng vào active. Không thêm hạt sáng, pulse, shimmer, tiến trình động hoặc nội dung gây phân tâm.
- `mockup/n_07_c_nh_b_o_khoan_h_ng_3_gi_y/code.html`: grace overlay, thời gian, warning; dùng deadline server, không tạo grace mới. Chủ đề tối tĩnh giữ ưu tiên hơn biến thể màu của mockup.
- D02 và các quyết định privacy/domain tại DECISIONS. Scope presentation; bản web không chứng minh detection Android native. Không visual pass bằng đọc source/test.

## S01 — trạng thái ngoài phiên

- Connecting có thông báo tiến độ rõ; error có tiêu đề/copy sản phẩm và CTA theo quyền; consent required dẫn nhóm. Không đưa raw socket event, `session:resume`, exception hoặc hướng dẫn kỹ thuật vào text.
- Error code đã biết map copy tiếng Việt tại UI; code lạ dùng thông báo chung và home, không render `errorMessage` chưa lọc. Không thêm nút retry/resume giả khi controller không có hành động public tương ứng.
- Cancelled phân biệt server outage, removed, owner cancel; giữ đường về home và ngữ nghĩa không tính khi outage. Ended/exited đang chuyển kết quả có pending state, không đổi navigation listener.

## S02 — lobby sáng

- Canvas xám, card trắng không outline, gutter16/radius16, inset trung tính, header/back đồng bộ các màn đã sửa. Metadata tên nhóm thật (không giả tên phiên riêng), mode chỉ khi có contract, start giờVN, thời lượng chỉ khi info có.
- Timer phải có nhãn “Bắt đầu sau” vì hiện code đếm tới start; không dùng25:00 của mockup làm thời lượng giả. Null giờ hiện “Đang cập nhật giờ bắt đầu”, null duration hiện đang cập nhật, không fallback25.
- Không tính reward từ duration `>=50?25:10`: API hiện không trả mức thưởng hứa hẹn. Thay chip bằng “Thưởng theo kết quả phiên và trần ngày”; không hứa mọi người chắc chắn nhận cùng số.
- Participants dùng count và lobbyMembers thật; count null là đang cập nhật,0 là0. Không tạo denominator7/10, không biến người chưa có dữ liệu thành vắng, không avatar giả. Tên dài Wrap, giới hạn chiều rộng khi320px, empty có mô tả gọn.
- Quy tắc ngắn: rời trong active/khoan hồng có thể ảnh hưởng thưởng; lobby chưa ghi kết quả active. Không khẳng định mọi người đứt chuỗi từ dữ liệu chưa có. Footer tự bắt đầu đúng giờ, ở lại màn; nút “Rời phòng chờ” dùng confirm hiện hữu. Không “Sẵn sàng” giả.
- Loading/error sessionInfo không giả metadata; session controller waiting vẫn có thể hiển thị tên/giờ fallback hợp lệ từ view. Banner reconnect không biến thành trạng thái đã tham gia chắc chắn.

## S03 — countdown và active tối

- Countdown giữ số theo startedAt/serverNow và giới hạn hiện hữu; label chưa ghi trước start. Null đồng bộ giờ; disconnect có nhãn reconnect. Không thêm nút/đổi điều kiện pop hoặc policy count5s.
- Active timer theo endsAt/serverNow, tabular, null `--:--`; nhãn rõ thời gian còn lại/kết thúc lúc. RecordingPill chỉ khi view.recording; không ghi “đang ghi” ở lost/countdown. Đây ghi trạng thái phiên, không ngụ ý ghi âm/video.
- Static ring/typography có thể dùng nếu không cung chạy/animation. Dark controls trung tính, danger ở leave; không biến dark chủ đích thành lỗi “default black”.
- Nội dung quan trọng phải cuộn được khi320×740/chữ1.5; tránh Column+Spacer cứng+margin72 gây overflow. Countdown số không bị cắt; footer/CTA trong SafeArea, không che banner.
- `forfeited` chỉ hiện khi payload true; không tự set hoặc đoán khi disconnect. Retain nút rút đồng ý/rời nhóm và route; không thay privacy flow để khớp mockup.

## S04 — grace, disconnect, lost và banner

- Grace dùng graceDeadline/serverNow thật; null hiện dấu chờ. Câu “Ở lại trong app để tiếp tục” phù hợp state; không thêm action reset/continue nếu controller tự xử lý. Emergency leave vẫn confirm hiện hữu. Không claim tất cả mất chuỗi; copy consequence theo policy, không delivery xác nhận.
- Disconnect overlay phải chặn tương tác với CTA active phía dưới bằng lớp bắt pointer đầy màn; không nút “rời” đang hoạt động khi canLeave=false. Giữ reconnect tự động, không fake nút reconnect. Diễn đạt “Mất mạng tự nó không làm cả phiên mất thưởng”; không phủ nhận forfeited có sẵn do người khác.
- Lost không còn recording; hero “Phần tham gia đã kết thúc do mất kết nối”, không tiếp tục hiển thị remaining như thời gian của chính người dùng đang chạy. Có thể ẩn timer hoặc nhãn rõ phiên nhóm. Không khẳng định finalized reward khi chưa result; nhấn trạng thái mất kết nối, kết quả chốt sau. CTA home giữ hiện hữu.
- ExitBanner chỉ tên, giờ sự kiện, forfeited flag từ payload, thêm-count thật; không Coins/streak/explanation người khác. Dismiss đúng eventId nếu có UI đóng; giữ timerẩn6s/controller xử lý hiện hữu. Không tự animation và không lộ eventId text.

## S05 — confirm leave và giới hạn nền tảng

- Lobby confirm diễn đạt rời phòng chờ/ghi vắng theo behavior hiện hữu, không dùng consequence EXITED active. Active/grace confirm hủy hoặc xác nhận rời, destructive rõ; đang leaving disable trigger để không gửi đôi. Không đổi leave() hoặc thời điểm áp nghiệp vụ.
- Countdown/disconnected/lost không thêm leave action khi controller không cho; system-back policy giữ nguyên. Dialog cũng phải wrap/scroll ở320/chữ lớn; không để nút lỗi overflow.
- Web không phân biệt chắc chắn khóa màn hình với background/tab khác. Dùng copy kIsWeb rõ “Bản web có thể xem chuyển tab/ẩn trang là rời; không đảm bảo phân biệt khóa màn hình.” Android native chỉ mô tả signal đã hỗ trợ, không hứa theo dõi toàn bộ thao tác OS/đổi mạng. Không câu “được tắt màn hình” vô điều kiện trên web. Không đổi detection để đáp ứng copy.

## Checklist kiểm độc lập

1. Connecting/error known+unknown/consent/cancelled; không raw tech copy.
2. Lobby countnull/0/many, empty/tên dài, startnull/durationnull, reconnect, leavebusy, headerback và systemback.
3. Countdown startnull/1–5, reconnect, không nút/recording; active null/normal/forfeit/longbanner.
4. Grace deadline/null/emergencyconfirm; disconnected pointerblock; lost không recording/timer hiểu nhầm; banner count/dismiss.
5. Confirm hai ngữ cảnh, hủy không leave/xác nhận chỉ1request; rút đồng ý vẫn truy cập đúng.
6.320/390/768, text1.5, scroll/SafeArea; dark tĩnh, focus/semantics, không outline card vô ý. Widget tests cho hành vi/layout; ảnh runtime đúng build/role/state mới nghiệm thu thị giác.
