# Đợt 01 — kiểm tra độc lập

Ngày: 22/10/2026. Verifier: `/root/design_reference`; implementer: `/root/implementation_audit`. Phạm vi: mã và kiểm thử `/history`, nguồn N-10, thư viện HTML, quyết định H01–H06. **CHƯA XÁC MINH HÌNH ẢNH; đợt 01 còn mở.**

## Bằng chứng đã kiểm

- Đọc độc lập `history_screen.dart`, `history_design_test.dart`, helper ngày, card, header, theme và nguồn N-10.
- Mã tại lần recheck cuối SHA256: `9FDCDAE7EE1F123C131AFA591DB2682C5C167382796D8C7CBF943959B04E60CA`.
- Test tại lần recheck SHA256: `0BA262B2F4B7E3687973C5E7E9947AD4B6ABA23C8B641E39066FAB05259C4287`.
- Implementer báo 6 test đạt và analyze hai file không có issue. Verifier đã đọc nội dung test; không tự chạy lại Flutter khi root đang build, tránh tranh chấp tool lock. Kết quả chạy này là bằng chứng do implementer cung cấp.
- Không có ảnh trước/tham chiếu/sau cùng build, vai trò, viewport và trạng thái. Truy cập UI đã bị chặn trong phiên; không đổi công cụ để né. Không dùng ảnh cũ hoặc widget test thay nghiệm thu browser runtime.

## Kết quả source

| Mục | Kết luận có giới hạn |
| --- | --- |
| Kỳ tuần/tháng | Đã xác nhận từ mã: danh sách, thống kê, empty cùng dùng `inRange`; tuần bắt đầu thứ Hai theo ngày VN, tháng từ ngày 1 đến hiện tại. |
| Ngày null/tương lai | Đã xác nhận bị loại khỏi kỳ; không tự gán ngày. Unit test bao phủ null, tương lai, đúng ranh giới UTC→VN, năm cũ, thứ tự giảm dần. |
| Phân trang | Caption nói rõ chỉ tính phiên đã tải khi còn cursor. Không còn hardcode 50. Chưa có tải tiếp/tổng đầy đủ; đây là thích nghi H02, không phải hoàn tất pagination. |
| Nhóm ngày | Key `DateTime` chứa năm; dùng `dayLabel` cho nhãn. Finding lặp năm của vòng đầu đã được implementer sửa và verifier đọc lại xác nhận. |
| Nội dung/Coins | Giữ nhãn riêng COMPLETED có/mất thưởng, EXITED, LOST, ABSENT, VOID, WITHDRAWN; VOID hiện dấu gạch, giờ là lịch dự kiến theo H06. Chưa kiểm runtime đầy đủ trạng thái. |
| Bề mặt/bố cục | Mã dùng canvas xám, card trắng không border, bỏ icon đầu dòng, trạng thái tách riêng. Selector nền trắng sau recheck; selected đen theo H05. Chưa xác nhận hình ảnh thực. |
| Accessibility | Mã có `Semantics(selected, button)`, touch tối thiểu44, chữ selected đậm hơn; test đếm một selected trước đổi kỳ. Chưa kiểm cây semantics cuối, keyboard/focus hoặc screen reader thực. |
| Responsive | Widget test320/390/768, cao1024, text scale1.5; không báo exception theo kết quả implementer. Chưa đại diện320×740/390×844; tên mẫu ngắn, chưa kiểm tên dài/navigation. |
| Loading/error/empty | Test có chuyển loading → error → retry → empty trong kỳ; mã dùng lại shared AsyncBody. Chưa xác nhận style/interaction browser. |

## Findings và vòng kiểm

| ID | Mức | Phát hiện | Recheck |
| --- | --- | --- | --- |
| V01 | P2 | Nhãn ngày ghép thêm năm dù `dayLabel` đã có năm ở ngày thường. | Đã sửa trong mã được hash ở trên. |
| V02 | P2 | Stats dùng28/14 và selector nền line khác tham chiếu, chưa có lý do thích nghi. | Đã đóng ở mức mã: kích thước22/12, nền trắng; recheck cuối dùng `headlineMedium`22/28 weight600 đúng nguồn. Chưa xác nhận render. |
| V03 | P2 | Hồ sơ01 tại vòng đầu còn hash cũ,5tests, mô tả nhãn kèm năm. | Đã đóng: hồ sơ cập nhật hash cuối,6tests, mô tả `dayLabel`; tách rõ test trước và việc root đang chạy lại sau patch typography cuối. |
| V04 | Cổng nghiệm thu | Thiếu ảnh/runtime đúng build; chưa kiểm tên dài, đủ trạng thái, focus, route/back, baseline viewport. | Còn mở; không được PASS thị giác hoặc chuyển đợt01 thành hoàn tất. |

Nguồn và test không cho thấy lỗi mới trong logic lọc VN/null/cursor đã xem. Kết luận này chỉ áp dụng phạm vi đã đọc, không khẳng định toàn màn đạt thiết kế. Khi patch đổi hash sau lần kiểm này, ghi recheck bổ sung; không dùng hash trên như nhận diện build web.

Recheck cuối: verifier đọc lại mã và hồ sơ sau sửa `headlineMedium`, xác nhận V01–V03 đã xử lý. Root đang chạy lại targeted tests/build cho hash cuối; chưa nhận kết quả tại thời điểm ghi. V04 vẫn mở; trạng thái toàn đợt vẫn **CHƯA XÁC MINH HÌNH ẢNH**.

## Vòng bổ sung — checklist người dùng về nội dung thiếu

Yêu cầu mới: badge cá nhân/Squad; thời gian thực hoàn thành/rời sớm thay vì chỉ25phút; chọn ngày; tab Ngày/Tuần/Tháng; banner phần thưởng hôm nay. Hash ở vòng trước không đại diện patch bổ sung này.

| ID | Kiểm tra source mới | Kết quả / hành động |
| --- | --- | --- |
| V05 | Badge chế độ | UI phân nhánh `sessionMode` SOLO/SQUAD, không đoán theo participant. Vòng đầu bỏ badge khi unknown; đã gửi implementer hiện nhãn chưa rõ, tránh mất thông tin hoặc bịa SOLO. Chờ recheck. |
| V06 | Thời gian thực | Mã badge dùng `focusSeconds`, hiển thị phút/giây; COMPLETED dùng `endedAt`, EXITED dùng `exitedAt`; null không bịa giờ. Lịch25phút có nhãn “Kế hoạch” riêng. Đã xác nhận nguồn, chưa xác minh render. |
| V07 | Chọn ngày và kỳ | Có datepicker và3tab; helper lọc `[from,to)` theo ngày VN; API gửi bound thật. Provider tải hết trang trong kỳ và từ chối cursor lặp; test provider có2trang cùng bound. Widget test ban đầu chỉ mở/hủy picker, chưa chọn ngày cũ thật; đã gửi implementer bổ sung test ngày cũ+range+thống kê. |
| V08 | Banner hôm nay độc lập | Endpoint/provider riêng đúng hướng, loading/error không bịa0. Nhưng vòng đầu banner nằm trong builder của AsyncBody lịch sử: mất banner khi history loading/error, có thể autoDispose/refetch khi đổi kỳ. Đã yêu cầu tách khỏi AsyncBody history; chờ recheck. |
| V09 | Controls khi một kỳ lỗi | Selector/picker vòng đầu cùng nằm trong history data builder nên không đổi được kỳ khi kỳ đang lỗi. Đã yêu cầu giữ controls ngoài AsyncBody; chờ recheck. |

Backend contract được bổ sung trong vòng này bởi `/root/design_reference`; **phần backend này không phải kiểm chứng độc lập patch của chính verifier**. Root chịu kiểm contract/live HTTP. Bằng chứng tự kiểm backend: typecheck sạch;41test đạt gồm39unit+2integration mới. Sau bổ sung assert phân trang trong range,2integration đạt lại. Fixtures ban đầu vi phạm check/admin shape và cập nhật trạng thái bất biến; đã sửa fixtures, không nới schema hoặc trigger.

Contract: `myResult` trả mode SQUAD cho group session kể cả chỉ1người; `joined_at/exited_at/ended_at` nullable ISO từ membership. `/v1/me/rewards/today` xác thực currentUser, tổng SESSION_REWARD theo user+reward_date VN, cap cấu hình; integration kiểm user khác, created_at khác reward_date, ADMIN_ADJUST không tính,0khi chưa có thưởng. `/v1/me/sessions` hỗ trợ from/to ISO optional, gte/lt, invalid/equal400, cursor/limit giữ hành vi cũ. Integration kiểm cận, phạm vi tài khoản và2trang.

V05/V07/V08/V09 đang chờ implementer và recheck. V04 thị giác vẫn mở. Không chạy browser bằng công cụ khác để né chặn; không dùng unit/widget/integration hoặc live HTTP thay ảnh runtime.

### Recheck checklist bổ sung

Đã đọc patch UI SHA256 `D888EE02FEBBBF49F4BD59CA89639DBF9BD62D777A0D44B504001D1B8A6D5CEE`, test SHA256 `EF29B9AB88B88B115BDE9F1102059638EF0FB3E1D30CAA1976834AEAE3040671`.

- V05 đóng mức source: unknown hiển thị “Chưa rõ chế độ”; không suy chế độ từ số người.
- V07 đóng mức source: picker chọn ngày cũ thực qua input; test xác nhận bound UTC tương ứng đầu ngày VN, kết quả rỗng đúng kỳ và banner hôm nay giữ40Coins. Provider test kiểm tải2trang cùng bound, cursor lặp báo lỗi. Runtime chưa kiểm.
- V08/V09 đóng mức source: selector, picker, banner nằm trong `controls` được giữ ở cả history loading/error/data, độc lập AsyncValue phần thưởng. Đã yêu cầu thêm assert banner/picker trong history loading/error để chống tái phát; đang chờ implementer chạy test cuối.
- V06 giữ kết luận source: focusSeconds thực, giờ ended/exited đúng trường dữ liệu; null không thế bằng giờ kết thúc kế hoạch.

Không có finding source mới ngăn triển khai trong checklist đã xem. Kiểm thử Flutter cuối do implementer/root chạy tuần tự; verifier không chạy tranh lock. **V04 vẫn mở, chưa PASS thị giác, chưa đóng toàn đợt.**

### Findings bổ sung từ arbiter — vòng cuối đang mở

| ID | Mức | Vấn đề | Trạng thái |
| --- | --- | --- | --- |
| V10 | P2 | Luồng giải trình/khiếu nại chỉ invalidate provider lịch sử cũ, bỏ provider theo kỳ và tổng thưởng mới. | Root đã sửa cả hai nơi trong `appeal_screens.dart`; verifier đọc xác nhận invalidate `historyPeriodProvider` và `historyRewardTodayProvider`. Chờ checks cuối. |
| V11 | P2 | Trang giữ mở qua nửa đêm VN hoặc resume có thể còn nhãn/kỳ/tổng thưởng hôm trước. | Implementer đang thêm observer/timer đổi ngày/resume; chưa recheck patch cuối, chưa đóng finding. |

Vòng bổ sung chưa đóng tới khi V11 và checks cuối được xem lại. V04 tiếp tục độc lập với kiểm thử chức năng.

### Recheck observer/timer và cache

Mã history cuối đã đọc SHA256 `B178E8070566D776E1A36D284DC8FB8402B43F07BA250A497791CE1DECF24DA2`; test `9D0A1DE67B993BFD587795861BD715D2021C096CE4AF6AA59DB47EACB8653A96`. Appeals SHA256 `C8AA3895BE3B66A53EEE7B000CFBCFB8B97E54069B06180CC62D11A053BD212A`.

- V10 đóng mức source: cả gửi giải trình và tạo khiếu nại invalidate provider cũ, period family, reward summary; không sửa contract trạng thái.
- V11 đóng mức source: helper tính nửa đêm VN tại17:00UTC; Timer được cancel trước reschedule, dispose cancel timer/remove observer. Khi timer chạy hoặc resume thấy ngày đổi, invalidate tổng thưởng và kỳ hiện tại rồi rebuild; ngày người dùng chọn rõ không bị reset. Test helper bao phủ ranh giới năm. Chưa có giả lập clock/lifecycle runtime để chứng minh callback thực.
- V08/V09 test regression đã đọc: trong history loading và error vẫn assert banner30Coins và picker tồn tại; reward loading/error có test riêng. Datepicker chọn ngày cũ không đổi tổng thưởng hôm nay.

Các findings source đã xử lý trong patch được hash tại đây. Final analyze/tests/build do implementer/root đang thực hiện; ghi kết quả cuối khi có. Đây vẫn **CHƯA XÁC MINH HÌNH ẢNH**, không đóng V04.

### Kết quả checks cuối được cung cấp

Root/implementer báo12/12test đạt (`history_design_test.dart` + `history_period_provider_test.dart`), analyze8file sạch gồm history, appeals, API/models/providers và tests; hash history cuối vẫn `B178E8070566D776E1A36D284DC8FB8402B43F07BA250A497791CE1DECF24DA2`. Verifier đã đọc source/test độc lập; kết quả thực thi này do root/implementer cung cấp, không nhận là đã tự chạy lại. Root đang build web; chưa có bộ ảnh/browser runtime phù hợp để verifier đánh giá.

**Kết luận vòng source:** V05–V11 đã xử lý trong phạm vi mã/test đã đọc. **Kết luận thị giác:** V04 còn mở; chưa xác minh hình ảnh, chưa nghiệm thu toàn đợt. Backend41test/typecheck nêu trên là tự kiểm backend; arbiter/root kiểm contract độc lập, không lẫn với nghiệm thu UI.
