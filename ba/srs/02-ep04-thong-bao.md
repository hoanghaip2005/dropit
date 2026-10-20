# EP-04 Thông báo thoát

Nguồn: GĐ1 §4.3, §6, §10 #3, §11; D-05, D-10, D-11, D-13, D-14, D-19, D-20, D-22  ·  MoSCoW: Must (khiếu nại, thông báo hủy: Should — D-13; chọn chế độ báo, bản gộp: Won't — D-20)  ·  Phụ trách: BA (T-BA-10)

Sửa 2026-10-07 theo D-19…D-23 và `ba/review/lan-2.md` (nguồn cũ đã xóa): D-20 (đổi tên epic; US-04.01 báo ngay cho cả nhóm + người trong phiên; US-04.03, US-04.04 → Won't, bỏ BR-83/84); D-22 (nêu tên người thoát; đính chính khi miễn trừ, Q-138); D-19 (LOST không báo, không mất thưởng); T-BA-55 (AC-04.05.3 khớp BR-85); T-BA-58 (gắn nhãn AC phụ thuộc story Should); T-BA-67 (AC-04.05.5 biên đúng mốc hạn).

Sửa 2026-10-19 theo D-25 và `ba/review/lan-3.md`: AC-04.01.9 viết lại (chủ nhóm quản lý nhiều nhóm chỉ nhận thông báo, không tham gia phiên — thay ca "CN tham gia rồi EXITED", đóng phần T-BA-58 của AC này); AC-04.01.11 sĩ số theo Q-141.

Sửa 2026-10-06 theo `ba/review/lan-1.md` (nguồn cũ đã xóa): T-BA-34 (AC-04.04.1 dùng 60 giây, BR-84), T-BA-29 (AC-04.09.x, AC-04.02.8 thêm ngoại lệ BR-68), T-BA-37 (tên trạng thái khiếu nại chuẩn), T-BA-42 (AC-04.02.5 bỏ "có thể"), T-BA-26 (thuật ngữ D-11), D-13 (US-04.09 → Should), D-14 (US-04.02 hủy, gộp vào US-03.09).
Thuật ngữ (D-11, `03-quy-tac.md`): **hoàn thành** = trạng thái cuối COMPLETED (kể cả phiên `forfeited`); **hoàn thành có thưởng** = COMPLETED và phiên không `forfeited`. Trạng thái khiếu nại chỉ dùng: CHỜ XỬ LÝ, ĐANG XỬ LÝ, CHUYỂN QUẢN TRỊ, MIỄN TRỪ, BÁC.

Phạm vi: thông báo `MEMBER_EXITED` (có tên) ngay cho cả nhóm và mọi người trong phiên; giải trình của thành viên; chủ nhóm xem giải trình; khiếu nại, miễn trừ (`EXEMPTION_GRANTED`); thông báo hủy. Không có chế độ gộp cuối phiên ở MVP (D-20).
Quy tắc tham chiếu: `ba/srs/03-quy-tac.md` (BR-14, BR-21, BR-27, BR-28, BR-32, BR-35…BR-39, BR-54, BR-81, BR-82, BR-85…BR-88, BR-114, BR-118, §4 bảng sự kiện). Riêng tư: `ba/srs/04-nfr-rieng-tu.md` (NFR-P03, P06, P07, P10, P14, P18 (D-22); NFR-01, NFR-02; ma trận §3).
Q- chưa chốt dùng theo đề xuất, gắn **(giả định, Q-xx)**: Q-16, Q-37, Q-87, Q-136, Q-137, Q-138, Q-141. Q-19, Q-139 đã chốt (D-25: chủ nhóm không tham gia phiên). Q-03, Q-32, Q-33, Q-50, Q-51 đã chốt (D-19, D-20, D-22).
Vai trò: **Chủ nhóm**, **Thành viên** (theo từng nhóm, D-10). Không có "Trưởng phòng", không cược, không nổ phòng.

---

## US-04.01 Báo ngay cho cả nhóm và người trong phiên khi có người thoát

**Là một** Chủ nhóm hoặc Thành viên, **tôi muốn** được báo ngay, có tên, khi một người thoát thật khỏi phiên của nhóm mình **để** cả nhóm biết kịp thời và giữ áp lực đồng đội trong lúc phiên vẫn tiếp tục.

- Ưu tiên: Must · Ước lượng: M (giữ nguyên — thay `notify_mode` bằng danh sách người nhận cố định; kênh trong phiên theo BR-82 đã thuộc US-03.09) · Nguồn: GĐ1 §4.3, §11; D-05; D-20; D-22 · Liên quan: BR-14, BR-27, BR-28, BR-34, BR-35, BR-38, BR-39, BR-81, BR-82, BR-114, BR-118, NFR-P18, NFR-01, NFR-02

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.01.1 | Bình thường | Nhóm có chủ nhóm O và thành viên A, B, D; phiên ACTIVE có A, B tham gia (D không tham gia, O không tham gia); A đang GRACE | Hết 3 giây khoan hồng, server ghi A EXITED (BR-14) | Server phát `MEMBER_EXITED` cho O, B, D (BR-27 (a)(b)), trừ A. O và D (không có trạng thái chưa kết thúc trong phiên) nhận push + mục hộp thông báo theo câu chuẩn (03 dòng 15–16): vì A là người EXITED **đầu tiên** nên mỗi người nhận **một** thông báo gộp `MEMBER_EXITED` + `SESSION_FORFEITED` “Phiên đã mất thưởng tập thể do A rời phiên — vẫn tiếp tục đến hết giờ” kèm giờ hh:mm:ss (BR-38, AC-03.09.1; T-BA-139), ≤ 5 giây (p95) tính từ lúc server ghi EXITED (BR-28, NFR-01). Nội dung có **tên** A và giờ server; không có tên app, lý do, Coins (BR-27, BR-34) |
| AC-04.01.2 | Bình thường | Như AC-04.01.1; B đang FOCUSING, app ở tiền cảnh, màn hình mở | A EXITED | B thấy banner trong app có tên A, không chặn thao tác, không âm thanh, không push hệ thống (BR-82) ≤ 2 giây (p95) (NFR-02). A là người EXITED đầu tiên → cùng banner nêu "Phiên đã mất thưởng tập thể do A rời phiên — vẫn tiếp tục đến hết giờ" (`SESSION_FORFEITED`, BR-38): **một** thông báo cho mỗi người nhận, không phải hai |
| AC-04.01.3 | Bình thường | Phiên đã `forfeited = true` do A | Thành viên B EXITED tiếp theo | Mọi người nhận ở BR-27 (trừ B) nhận `MEMBER_EXITED` có tên B; **không** gửi lại `SESSION_FORFEITED`; `forfeit_trigger_user_id` vẫn là A (BR-39) |
| AC-04.01.4 | Biên | A rời app, quay lại sau 2,9 giây (theo giờ server) | Server nhận `return` trước hạn | Không gửi `MEMBER_EXITED` cho ai, không ghi thoát (BR-12, BR-28 — không báo khi mới vào GRACE) |
| AC-04.01.5 | Biên | A rời app, không quay lại | Đúng 3 giây hết hạn, server xác nhận EXITED | Thông báo chỉ phát sau khi server xác nhận EXITED, không phát lúc bắt đầu GRACE; người nhận đầu tiên nhận ở giây 5 tính từ lúc xác nhận: đạt; sau giây 5 (p95): không đạt (BR-28) |
| AC-04.01.6 | Lỗi | O tắt quyền thông báo của app / mất mạng / gửi SNS lỗi | A EXITED | Sự kiện vẫn được ghi; thử lại theo BR-81, sau đó chỉ còn mục trong hộp thông báo của O, hiện khi mở app; lỗi gửi ghi log CloudWatch (BR-81) |
| AC-04.01.7 | Lỗi | B đang khóa màn hình (úp máy), GRACE hoặc PAUSED | A EXITED | **Không** gửi push hệ thống, không bật thông báo cục bộ trên màn khóa cho B; thông báo xếp hàng, hiện dạng banner khi B quay lại app/mở khóa; vẫn có trong hộp thông báo (BR-82, BR-81) |
| AC-04.01.8 | Lỗi | Thành viên A chuyển LOST (BR-19) / PAUSED / WITHDRAWN / ABSENT | Sự kiện xảy ra | Không phát `MEMBER_EXITED`, không đặt `forfeited` (BR-36, D-19); không ai nhận thông báo nêu tên A là đã rời app (NFR-P18) **(giả định, Q-136)** |
| AC-04.01.9 | Bình thường | O là chủ nhóm của nhóm A và nhóm B (D-25: chủ nhóm quản lý nhiều nhóm, không tham gia phiên); phiên nhóm A ACTIVE | Thành viên A1 của nhóm A EXITED | O nhận đúng **một** `MEMBER_EXITED` có tên A1, ghi rõ tên nhóm A và tên lịch; thành viên nhóm B không nhận gì; O không bao giờ là `forfeit_trigger_user_id` (BR-114, BR-27, D-25) |
| AC-04.01.10 | Lỗi | Người dùng X là chủ nhóm của nhóm B (sở hữu, không phải thành viên nhóm A) | Nhóm A có người EXITED | X không nhận thông báo của nhóm A; payload gửi cho người nhận không chứa giải trình, lý do tạm dừng, số lần thoát tích lũy (BR-27, NFR-11, NFR-P18) **(giả định, Q-137)** |
| AC-04.01.11 | Biên | Nhóm CN O + 10 TV (đầy, BR-74, đề xuất Q-141); cả 10 TV tham gia phiên; C đã EXITED trước đó trong cùng phiên | Thành viên E EXITED | 9 TV còn lại (kể cả C, BR-27 (b) "kể cả người đã kết thúc") và O nhận thông báo có tên E — tổng 10 người nhận; E không nhận thông báo về chính mình **(đề xuất, Q-141)** |

**Ghi chú / giả định:** Đo độ trễ theo NFR-01 (≥ 3 máy thật, như NFR-01 ghi). EXITED do bấm "Rời phiên" (BR-118, D-29) dùng cùng luồng `MEMBER_EXITED`. Push hiện trên màn khóa của người **không** trong phiên có tên người thoát — chấp nhận theo D-22. Không còn `notify_mode`, không có bản gộp (D-20; BR-83, BR-84 Hủy). Chi tiết tạm dừng/LOST/ABSENT xem ở chi tiết phiên và báo cáo tháng. Gửi qua SNS Mobile Push (APNs/FCM) + socket phiên. Banner `SESSION_FORFEITED` cho người trong phiên đặc tả ở US-03.09; story này chỉ kiểm việc gộp một thông báo.

---

## US-04.02 Thành viên được báo khi phiên mất thưởng tập thể (Hủy — gộp vào US-03.09)

> **Trạng thái: Hủy (D-14).** Nội dung đã gộp vào US-03.09 (EP-03). Không ước lượng, không xếp sprint, không kiểm thử theo mã AC-04.02.x — dùng mã AC-03.09.y. Bảng AC dưới đây giữ lại chỉ để lưu vết.
>
> **Lưu ý D-22 (2026-10-07):** các câu "không có tên A", "không có định danh người thoát", "không chứa `forfeit_trigger_user_id` hay tên người thoát" (AC-04.02.1, .2, .4, .5) **đã lỗi thời** — theo BR-38 bản mới, thông báo mất thưởng tập thể **nêu tên** người khởi phát. Không dùng bảng này để kiểm thử.

**Ánh xạ AC (D-14)**

| AC cũ | AC mới | Cách chuyển |
| --- | --- | --- |
| AC-04.02.1 | AC-03.09.6 | Chuyển nguyên |
| AC-04.02.2 | AC-03.09.7 | Chuyển nguyên |
| AC-04.02.3 | AC-03.09.8 | Chuyển nguyên |
| AC-04.02.4 | AC-03.09.2 | Gộp: AC-03.09.2 bổ sung "payload push" và `forfeit_trigger_user_id` |
| AC-04.02.5 | AC-03.09.9 | Chuyển nguyên (BR-82) |
| AC-04.02.6 | AC-03.09.10 | Chuyển nguyên |
| AC-04.02.7 | AC-03.09.5 | Gộp: AC-03.09.5 bổ sung ca hai EXITED gần như cùng lúc (BR-35) |
| AC-04.02.8 | AC-03.09.11 | Chuyển nguyên (BR-22, ngoại lệ BR-68) |

**Là một** Thành viên, **tôi muốn** được báo ngay khi phiên đã mất thưởng tập thể **để** hiểu vì sao kết quả phiên không có Coins, mà vẫn tập trung đến hết giờ.

- Ưu tiên: — (Hủy, D-14; trước đó Must) · Ước lượng: — · Nguồn: D-05; D-14; GĐ1 §6 · Liên quan: BR-35, BR-37, BR-38, BR-41, BR-47, BR-82, BR-68, NFR-P18, NFR-02, NFR-P06

**Tiêu chí chấp nhận (lưu vết — đã chuyển, xem bảng ánh xạ)**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.02.1 | Bình thường | Phiên ACTIVE, `forfeited = false`, B và C đang FOCUSING | A EXITED, server đặt `forfeited = true` (BR-35) | B và C thấy banner trong app "Phiên đã mất thưởng tập thể do có thành viên rời app — vẫn tiếp tục đến hết giờ" ≤ 2 giây (p95) (NFR-02); banner **không** có tên A (BR-38, NFR-P18) **(giả định, Q-50)** |
| AC-04.02.2 | Bình thường | Phiên đã `forfeited` | Đến `ends_at`, B COMPLETED | Màn kết quả của B ghi "Hoàn thành – 0 Coins – lý do: mất thưởng tập thể" và chuỗi bị ngắt (BR-41, BR-47); không có định danh người thoát |
| AC-04.02.3 | Bình thường | A là người thoát | A mở màn kết quả | A thấy chính mình là người khởi phát (NFR-P18, NFR-P03) |
| AC-04.02.4 | Lỗi | Thành viên C gọi API kết quả phiên / xem payload push | Phiên `forfeited` | Phản hồi API, payload push và màn kết quả không chứa `forfeit_trigger_user_id` hay tên người thoát (NFR-P18) |
| AC-04.02.5 | Lỗi | B đang PAUSED hoặc đã khóa màn hình (app không ở tiền cảnh) | Phiên chuyển `forfeited` | Trong lúc B chưa ở trạng thái kết thúc: **không** gửi push hệ thống nào cho B (BR-82). Khi B quay lại app / mở khóa màn hình / hết PAUSED: banner "Phiên đã mất thưởng tập thể…" hiện ≤ 2 giây (p95) sau khi app nối lại, không tên người thoát (BR-82, BR-38) |
| AC-04.02.6 | Biên | Phiên có 1 người tham gia | Người đó EXITED | Không có thành viên khác để báo; chỉ người đó thấy kết quả (bảng §3 dòng 27) |
| AC-04.02.7 | Biên | Hai người EXITED gần như cùng lúc | Server nhận cả hai | Thành viên chỉ nhận **một** thông báo mất thưởng (BR-35 cờ một chiều, §3 dòng 19) |
| AC-04.02.8 | Lỗi | Phiên `forfeited` rồi CANCELLED do sự cố (BR-22) | Phiên hủy | Người VOID nhận thông báo hủy chung "Phiên bị hủy do sự cố — kết quả của bạn không bị tính"; thông báo mất thưởng trước đó được thay thế; `forfeited` gỡ (BR-22). **Ngoại lệ BR-68:** người đã EXITED trước sự cố nhận thông báo riêng (giữ EXITED, chuỗi đã ngắt, có thể khiếu nại) (US-04.09) |

**Ghi chú / giả định:** Không push trong phiên để tránh dụ rời app (BR-82). Người vào muộn sau `forfeited_at` được cảnh báo theo BR-37 (EP-03, không lặp lại ở đây).

---

## US-04.03 Chủ nhóm chọn chế độ báo (ngay / gộp) — Won't (sau MVP)

> **Trạng thái: Won't ở MVP (D-20).** MVP chỉ báo ngay cho cả nhóm và người trong phiên (US-04.01). Không ước lượng, không xếp sprint. BR-83 đã Hủy; AC dưới đây giữ để tham khảo khi làm sau MVP và cần BR mới lúc đó.

**Là một** Chủ nhóm, **tôi muốn** chọn nhận báo ngay hoặc gộp cuối phiên cho từng nhóm **để** không bị làm phiền khi không cần theo dõi tức thời.

- Ưu tiên: Won't (sau MVP, D-20) · Ước lượng: — · Nguồn: GĐ1 §4.3; D-20 · Liên quan: BR-27

**Tiêu chí chấp nhận (tham khảo sau MVP)**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.03.1 | Bình thường | Nhóm mới tạo | Chủ nhóm mở cài đặt nhóm | Giá trị mặc định là "Ngay" (`immediate`) (BR-27) **(giả định, Q-03)** |
| AC-04.03.2 | Bình thường | Chủ nhóm chọn "Gộp cuối phiên" và lưu | Phiên tiếp theo có thành viên EXITED | Không push từng sự kiện; nhận bản gộp (US-04.04) |
| AC-04.03.3 | Lỗi | Người dùng là thành viên (không phải chủ nhóm) | Gọi API đổi `notify_mode` | 403; giá trị không đổi (NFR-11) |
| AC-04.03.4 | Biên | Phiên đang ACTIVE | Chủ nhóm đổi chế độ | Phiên đang chạy giữ chế độ cũ; áp dụng từ phiên kế **(giả định)** — cần BR mới khi đưa lại vào phạm vi (BR-83 đã Hủy) |
| AC-04.03.5 | Bình thường | Chế độ thay đổi | Thành viên mở thông tin nhóm | Thành viên thấy chế độ báo hiện hành của nhóm (minh bạch, NFR-P03) **(giả định)** |

**Ghi chú / giả định:** Sau MVP cần cân nhắc lại với D-20 (báo ngay cho cả nhóm là chủ ý tạo áp lực đồng đội).

---

## US-04.04 Bản gộp cuối phiên cho chủ nhóm — Won't (sau MVP)

> **Trạng thái: Won't ở MVP (D-20).** Không ước lượng, không xếp sprint. BR-84 đã Hủy; mọi tham chiếu "BR-84" trong bảng dưới chỉ là lưu vết và **không còn hiệu lực**. Thông tin tạm dừng/LOST/ABSENT xem ở chi tiết phiên (EP-03) và báo cáo tháng (EP-08).

**Là một** Chủ nhóm, **tôi muốn** nhận một bản tóm tắt khi phiên kết thúc **để** nắm toàn bộ kết quả phiên trong một lần.

- Ưu tiên: Won't (sau MVP, D-20) · Ước lượng: — · Nguồn: GĐ1 §4.3; D-20 · Liên quan: BR-23, BR-35, BR-37, §4 bảng sự kiện

**Tiêu chí chấp nhận (tham khảo sau MVP — không kiểm thử ở MVP)**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.04.1 | Bình thường | `notify_mode = batch`; phiên 25 phút có 6 người tham gia | Phiên đến `ends_at` | Chủ nhóm nhận đúng 1 push "Phiên <tên> đã kết thúc" + 1 mục hộp thông báo **trong 60 giây sau `ends_at`** (`batch_send_within_s`, BR-84); mở ra thấy nội dung theo BR-84: số COMPLETED, danh sách EXITED (tên, giờ server), tạm dừng (tên, lý do, thời lượng), số LOST, ABSENT, trạng thái `forfeited`; người khởi phát hiện tên trong danh sách EXITED như mọi EXITED khác |
| AC-04.04.8 | Biên | Như AC-04.04.1 | Đo thời điểm push so với `ends_at` (giờ server) | Push đến ở giây 59 sau `ends_at`: đạt; sau giây 60: không đạt. Ngưỡng ≤ 5 giây (BR-28) **không** áp cho bản gộp (BR-84) |
| AC-04.04.2 | Bình thường | Có thành viên tạm dừng có lý do | Bản gộp được tạo | Lý do tạm dừng chỉ xuất hiện trong bản gộp, không push riêng (§4) **(giả định, Q-32)** |
| AC-04.04.3 | Bình thường | `notify_mode = immediate` | Phiên kết thúc | Vẫn có bản tóm tắt phiên xem được trong app, nhưng không push thêm **(giả định)** |
| AC-04.04.4 | Lỗi | Phiên CANCELLED (chủ nhóm hủy hoặc sự cố) | Phiên hủy | Không tạo bản gộp kết quả; chỉ có thông báo hủy (US-04.09, BR-84) |
| AC-04.04.5 | Biên | Phiên 50 phút, không ai EXITED | Đến `ends_at` | Bản gộp ghi "Không có ai rời app – phiên hoàn thành có thưởng" (D-11); không có Coins từng người (BR-53) |
| AC-04.04.6 | Biên | Nhóm 10 người, 10 người EXITED | Đến `ends_at` | Bản gộp liệt kê đủ 10 dòng; push chỉ 1 lần |
| AC-04.04.7 | Lỗi | Thành viên đọc bản gộp | Thành viên gọi API bản gộp | 403; thành viên chỉ xem kết quả của chính mình (ma trận §3, NFR-P06) |

**Ghi chú / giả định:** Bản gộp không chứa Coins và không chứa chuỗi (BR-53, D-12), không tên app (BR-34). Nếu đưa lại vào phạm vi sau MVP: cần BR mới thay BR-84 (nội dung, thời điểm gửi).

---

## US-04.05 Thành viên giải trình sự kiện thoát

**Là một** Thành viên, **tôi muốn** ghi giải trình cho lần bị ghi thoát **để** chủ nhóm hiểu bối cảnh (vd. cuộc gọi khẩn).

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §10 #3; Q-16 · Liên quan: BR-32, BR-54, NFR-P10, NFR-P13

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.05.1 | Bình thường | A có sự kiện EXITED ở phiên đã kết thúc | A mở sự kiện, nhập giải trình, gửi | Giải trình được lưu kèm sự kiện, có thời điểm gửi; trạng thái EXITED không đổi (BR-32) **(giả định, Q-16)** |
| AC-04.05.2 | Bình thường | Giải trình đã gửi | Phiên `forfeited` | Không hoàn Coins, không khôi phục chuỗi cho ai (BR-54) **(giả định, Q-16, Q-37)**; màn giải trình nêu rõ điều này trước khi gửi |
| AC-04.05.3 | Lỗi | Sự kiện là COMPLETED / LOST / ABSENT / WITHDRAWN, hoặc sự kiện của người khác | Gọi API giải trình | Từ chối: 400 nếu loại sự kiện không phải EXITED, 403 nếu sự kiện của người khác; chỉ EXITED của chính mình được giải trình (BR-85) |
| AC-04.05.4 | Lỗi | Giải trình rỗng hoặc chỉ khoảng trắng | Bấm gửi | Báo lỗi "Vui lòng nhập nội dung"; không lưu |
| AC-04.05.5 | Biên | Đã gửi giải trình lần đầu lúc T; `explanation_edit_h = 24` → hạn sửa H = T + 24 giờ | Sửa ở `t = H − 1 ms` / `t = H` | `H − 1 ms`: trong hạn, sửa được, lưu lịch sử bản cũ; `t = H`: quá hạn, chỉ xem, báo "Đã hết hạn sửa" (BR-85, BR-65 nửa mở) |
| AC-04.05.6 | Biên | Phiên đang ACTIVE (A đã EXITED nhưng phiên chưa đến `ends_at`) | A mở giải trình | Cho phép gửi ngay sau EXITED (BR-85) |
| AC-04.05.8 | Biên | Giải trình dài 500 / 501 ký tự (`explanation_max_chars = 500`) | Bấm gửi | 500: lưu; 501: báo lỗi độ dài, không lưu (BR-85) |
| AC-04.05.7 | Lỗi | A muốn xóa sự kiện thoát | A tìm chức năng xóa | Không có; chỉ có giải trình (NFR-P13) |

**Ghi chú / giả định:** Giải trình là dữ liệu do thành viên nhập, không phải nhật ký riêng tư (NFR-P05 không áp dụng). Giải trình chỉ chủ nhóm và chính người đó thấy; dù tên người thoát được báo cho cả nhóm (D-22), giải trình **không** được gửi cho thành viên khác (NFR-P18). Độ dài, hạn gửi, hạn sửa: BR-85.

---

## US-04.06 Chủ nhóm xem giải trình kèm sự kiện thoát

**Là một** Chủ nhóm, **tôi muốn** thấy giải trình ngay cạnh sự kiện thoát **để** đánh giá công bằng.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §10 #3; Q-16 · Liên quan: NFR-P10, NFR-P07, BR-61, §4 dòng "Giải trình sau phiên"

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.06.1 | Bình thường | A đã gửi giải trình cho EXITED | Chủ nhóm mở màn "Chi tiết phiên" (US-08.10) / báo cáo tháng (US-08.02) | Giải trình hiện ngay cạnh dòng EXITED của A (tên, giờ server) ở mọi nơi chủ nhóm xem sự kiện (NFR-P10, BR-61, AC-08.10.1) |
| AC-04.06.2 | Bình thường | A gửi giải trình | Giải trình được lưu | Chủ nhóm nhận thông báo trong app "A đã gửi giải trình"; không push (BR-85) |
| AC-04.06.3 | Bình thường | Chủ nhóm mở giải trình của A | Mở xem | Ghi nhật ký truy cập (NFR-P07). *(Chỉ kiểm phần "A thấy 'Chủ nhóm đã xem lúc …'" khi US-01.11 trong phạm vi — Should, T-BA-58)* **(giả định, Q-21)** |
| AC-04.06.4 | Lỗi | Thành viên C cùng nhóm (đã nhận thông báo có tên A, D-22) | Gọi API xem giải trình của A | 403 (ma trận §3: thành viên khác ✖; NFR-P18) |
| AC-04.06.5 | Lỗi | Chủ nhóm muốn sửa/xóa giải trình | Gọi API sửa | 403; chủ nhóm chỉ đọc |
| AC-04.06.6 | Biên | A sửa giải trình trong 24 giờ | Chủ nhóm xem | Thấy bản mới nhất kèm nhãn "đã sửa lúc …" **(giả định)** |

**Ghi chú / giả định:** Chủ nhóm có phản hồi lại giải trình hay không — ngoài phạm vi MVP **(giả định)**.

---

## US-04.07 Thành viên khiếu nại sự kiện thoát bị ghi nhầm

**Là một** Thành viên, **tôi muốn** khiếu nại sự kiện thoát mà tôi cho là phát hiện nhầm **để** cả phiên không bị mất thưởng oan.

- Ưu tiên: **Should** **(giả định, Q-37)** · Ước lượng: M · Nguồn: GĐ1 §10 #3; D-05; NFR-P14; R-P02 · Liên quan: BR-32, BR-35, BR-86, máy trạng thái KHIẾU NẠI, NFR-P14

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.07.1 | Bình thường | A (thành viên, không phải chủ nhóm) có EXITED, chưa khiếu nại | A chọn "Khiếu nại – phát hiện nhầm", nhập mô tả, gửi | Khiếu nại ở trạng thái **CHỜ XỬ LÝ**; chủ nhóm nhận thông báo trong app (không push); A thấy trạng thái khiếu nại (máy trạng thái KHIẾU NẠI, BR-86) |
| AC-04.07.2 | Lỗi | Sự kiện đã có khiếu nại | A gửi lần hai | Từ chối "Sự kiện đã được khiếu nại" (BR-86: một khiếu nại/sự kiện) |
| AC-04.07.3 | Lỗi | Sự kiện không phải EXITED của A (của người khác, hoặc COMPLETED/LOST/ABSENT) | Gọi API khiếu nại | Từ chối (403 nếu sự kiện của người khác; 400 nếu loại sự kiện không phải EXITED); không tạo khiếu nại |
| AC-04.07.4 | Biên | `appeal_window_h = 24` | Gửi lúc `ends_at` + 23:59:59 / `ends_at` + 24:00:00 | Trước hạn: tạo, CHỜ XỬ LÝ; đúng/quá hạn: từ chối "Đã hết hạn khiếu nại" (BR-86, BR-65) |
| AC-04.07.5 | Lỗi | Người gọi là chủ nhóm của nhóm (chủ nhóm không tham gia phiên nên không có sự kiện EXITED của mình, D-25) | Chủ nhóm gọi API tạo khiếu nại cho một sự kiện EXITED bất kỳ của nhóm | Từ chối 403; không tạo khiếu nại. Chỉ chính thành viên có EXITED được khiếu nại (AC-04.07.3, BR-86). *(Viết lại 2026-10-19 theo D-25, T-BA-108 — bỏ ca "chủ nhóm tự tham gia và EXITED"; khớp BR-86 (a) đã Hủy)* |
| AC-04.07.6 | Bình thường | A nghi lỗi hệ thống | A chọn "nghi lỗi hệ thống" khi gửi | Khiếu nại vào **CHUYỂN QUẢN TRỊ** (BR-86 (c)) |
| AC-04.07.7 | Biên | Khiếu nại CHỜ XỬ LÝ, `appeal_escalate_h = 72` | Đến `created_at` + 72 giờ chưa có kết quả | Chuyển **CHUYỂN QUẢN TRỊ**; A được báo (BR-86 (b)) |
| AC-04.07.8 | Bình thường | A là người EXITED trước sự cố (BR-68) *(chỉ kiểm khi US-04.09 trong phạm vi)* | A mở thông báo riêng của phiên hủy | Có lối vào khiếu nại cho sự kiện EXITED đó, cùng hạn BR-86 |

**Ghi chú / giả định:** Khác giải trình: giải trình không đổi kết quả (BR-54); khiếu nại có thể dẫn đến MIỄN TRỪ (US-04.08). Nếu Q-37 chốt "không có ở MVP" thì story này ra khỏi MVP. Không có trạng thái "hết hạn" (máy trạng thái KHIẾU NẠI).

---

## US-04.08 Chủ nhóm xử lý khiếu nại (miễn trừ / bác)

**Là một** Chủ nhóm, **tôi muốn** miễn trừ hoặc bác khiếu nại **để** sửa kết quả khi phát hiện nhầm thật.

- Ưu tiên: **Should** **(giả định, Q-37)** · Ước lượng: L · Nguồn: GĐ1 §10 #3; D-05; NFR-P14 · Liên quan: BR-32, BR-35, BR-43, BR-44, BR-86, BR-87, BR-88, máy trạng thái KHIẾU NẠI

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.08.1 | Bình thường | A là người EXITED duy nhất, khiếu nại CHỜ XỬ LÝ | Chủ nhóm mở ca, chọn "Miễn trừ", nhập lý do | Khiếu nại qua ĐANG XỬ LÝ → **MIỄN TRỪ**; EXITED của A gắn cờ `exempted` (không xóa, BR-32); phiên gỡ `forfeited` (BR-87); Coins bù bằng dòng `SESSION_REWARD` mới `reason = APPEAL_RESTORE` và chuỗi khôi phục theo BR-88; server phát `EXEMPTION_GRANTED` cho **đúng những người đã nhận `MEMBER_EXITED` của sự kiện đó** (BR-87), **nêu tên** A, kèm trạng thái `forfeited` mới (BR-87, D-22) |
| AC-04.08.9 | Bình thường | Như AC-04.08.1; `MEMBER_EXITED` của A trước đó đã gửi tới O, B, D | MIỄN TRỪ cho A | Thông báo đính chính "Lần rời app của A trong phiên <tên> đã được miễn trừ" đến **đúng** những người đã nhận `MEMBER_EXITED` của A (O, B, D); người mới vào nhóm sau sự kiện không nhận (BR-87) **(đề xuất, Q-138)** |
| AC-04.08.2 | Bình thường | Khiếu nại ĐANG XỬ LÝ | Chủ nhóm chọn "Bác" kèm lý do | Khiếu nại **BÁC**; kết quả phiên không đổi; A thấy lý do |
| AC-04.08.3 | Lỗi | Phiên có 2 người EXITED (A trước, B sau), chỉ A được miễn trừ | MIỄN TRỪ cho A | Phiên vẫn `forfeited`; `forfeit_trigger_user_id` = B, `forfeited_at` = giờ EXITED của B (BR-87) |
| AC-04.08.4 | Biên | Ngày của phiên, người C đã nhận 95 Coins; phiên 25 phút được gỡ `forfeited` | MIỄN TRỪ | C nhận +5 (trần ngày của phiên, BR-43, BR-88), không phải +10 |
| AC-04.08.5 | Lỗi | Người gọi không phải chủ nhóm của nhóm (hoặc khiếu nại đang CHUYỂN QUẢN TRỊ) | Gọi API miễn trừ/bác | 403; trạng thái khiếu nại không đổi (NFR-11, BR-110) |
| AC-04.08.6 | Lỗi | Khiếu nại đã MIỄN TRỪ hoặc BÁC | Chủ nhóm gửi lại quyết định | Từ chối; quyết định là cuối cùng (BR-86) |
| AC-04.08.7 | Lỗi | Thiếu lý do | Chọn MIỄN TRỪ hoặc BÁC | Không lưu; báo "Vui lòng nhập lý do" (máy trạng thái KHIẾU NẠI: lý do bắt buộc) |
| AC-04.08.8 | Bình thường | Khiếu nại ĐANG XỬ LÝ | Chủ nhóm chọn "nghi lỗi hệ thống" | Khiếu nại → **CHUYỂN QUẢN TRỊ**; chủ nhóm mất quyền xử lý (BR-110) |

**Ghi chú / giả định:** Ngoại lệ BR-35 khi miễn trừ: BR-87. Khôi phục hồi tố Coins/chuỗi/huy hiệu: BR-88. Người được miễn trừ được tính như COMPLETED về Coins/điểm danh/chuỗi (BR-87, Q-124). Quản trị xử lý ca CHUYỂN QUẢN TRỊ: EP-09 US-09.05.

---

## US-04.09 Thông báo phiên bị hủy

**Là một** Chủ nhóm hoặc Thành viên, **tôi muốn** được báo khi phiên bị hủy (do chủ nhóm hoặc sự cố) **để** biết kết quả của mình có bị tính hay không.

- Ưu tiên: **Should** (D-13) · Ước lượng: S · Nguồn: GĐ1 §6; D-13; D-19; §4 dòng "Phiên CANCELLED do sự cố" · Liên quan: BR-22, BR-29, BR-68, BR-81, NFR-15

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-04.09.1 | Bình thường | Phiên SCHEDULED | Chủ nhóm hủy trước giờ (BR-29) | Thành viên được mời nhận thông báo "Phiên <tên> hh:mm đã bị hủy" |
| AC-04.09.2 | Bình thường | Phiên ACTIVE; B, C đang FOCUSING; không ai EXITED trước đó | Server xác nhận sự cố (BR-22) | B, C (→ VOID) và chủ nhóm thấy thông báo hủy chung "Phiên bị hủy do sự cố — kết quả của bạn không bị tính (không ghi thoát, không ngắt chuỗi)" ≤ 15 giây (NFR-15); không nêu cá nhân |
| AC-04.09.3 | Lỗi | Một máy không nhận được push | Mở app | Thấy trạng thái phiên CANCELLED và lý do khi đồng bộ (bản trong hộp thông báo, BR-81) |
| AC-04.09.4 | Biên | Phiên `forfeited` do A EXITED; B, C đang FOCUSING | Hủy do sự cố | B, C nhận thông báo hủy chung kèm "thưởng tập thể không bị tính mất, chuỗi không bị ảnh hưởng" (gỡ `forfeited`, BR-22). **A không** nhận thông báo chung mà nhận thông báo riêng (BR-68): "Phiên đã bị hủy do sự cố. Lần rời app của bạn trước sự cố vẫn được ghi; chuỗi đã ngắt. Bạn có thể khiếu nại." |
| AC-04.09.5 | Lỗi | Như AC-04.09.4 | B gọi API kết quả phiên hủy / xem thông báo hủy | Thông báo hủy không nhắc lại A; `MEMBER_EXITED` có tên A đã gửi trước đó **không** bị thu hồi (D-22, BR-68); API kết quả của B không chứa giải trình/khiếu nại của A (NFR-P18) |
| AC-04.09.6 | Bình thường | Như AC-04.09.4 | Hủy do sự cố | `MEMBER_EXITED` của A đã gửi cho cả nhóm và người trong phiên không bị thu hồi (BR-68); chủ nhóm nhận thông báo hủy |
| AC-04.09.7 | Biên | Người D đã LOST trước sự cố | Hủy do sự cố | D giữ LOST, nhận thông báo hủy chung; chuỗi không bị ngắt (BR-22, BR-48) |

---

## Truy vết

| US | Nguồn | BR / NFR liên quan | MoSCoW |
| --- | --- | --- | --- |
| US-04.01 | GĐ1 §4.3, §11; D-05; D-10; D-19; D-20; D-22; D-25 (sửa 2026-10-19); Q-141 | BR-12, BR-14, BR-19, BR-27, BR-28, BR-34, BR-35, BR-36, BR-38, BR-39, BR-74, BR-81, BR-82, BR-114, BR-118; NFR-01, NFR-02, NFR-11, NFR-P18; sự kiện `MEMBER_EXITED`, `SESSION_FORFEITED` | Must |
| US-04.02 | D-05; D-14; GĐ1 §6 | (Hủy — gộp vào US-03.09) BR-35, BR-37, BR-38, BR-41, BR-47, BR-68, BR-82; NFR-P18 (D-22; thay NFR-P16 Hủy), NFR-02 | — (Hủy, D-14) |
| US-04.03 | GĐ1 §4.3; D-20 | BR-27; NFR-11 (BR-83 Hủy) | Won't (sau MVP, D-20) |
| US-04.04 | GĐ1 §4.3; D-20 | BR-23, BR-34, BR-35, BR-53 (BR-84 Hủy) | Won't (sau MVP, D-20) |
| US-04.05 | GĐ1 §10 #3; Q-16 | BR-32, BR-54, BR-65, BR-85; NFR-P10, NFR-P13, NFR-P18 | Must |
| US-04.06 | GĐ1 §10 #3; Q-16; T-BA-105 (AC-04.06.1 tham chiếu US-08.10) | BR-61, BR-85; NFR-P07, NFR-P10, NFR-P18 | Must |
| US-04.07 | GĐ1 §10 #3; D-05; D-25 (AC-04.07.5, T-BA-108); NFR-P14; Q-37; R-P02 | BR-32, BR-35, BR-65, BR-68, BR-86; máy trạng thái KHIẾU NẠI | Should |
| US-04.08 | GĐ1 §10 #3; D-05; D-22; NFR-P14; Q-37; Q-138 | BR-27, BR-32, BR-35, BR-43, BR-44, BR-86, BR-87, BR-88, BR-110; sự kiện `EXEMPTION_GRANTED`; máy trạng thái KHIẾU NẠI | Should |
| US-04.09 | GĐ1 §6; D-13; D-19; D-22 | BR-22, BR-29, BR-48, BR-68, BR-81; NFR-15, NFR-P18 | Should (D-13) |

Sửa 2026-10-07: AC-04.01.1–.11 (viết lại theo D-20/D-22; .10, .11 mới); US-04.03, US-04.04 → Won't; AC-04.05.3 (T-BA-55), AC-04.05.5 (T-BA-67), AC-04.05.8 (mới); AC-04.06.1, .3 (T-BA-58), .4; AC-04.07.8 (nhãn T-BA-58); AC-04.08.1, AC-04.08.9 (mới, Q-138); AC-04.09.5, .6.
Sửa 2026-10-19 theo `review/mockup-tong-hop.md` §3 (S1, S2): AC-04.07.5 viết lại thành ca Lỗi (chủ nhóm không khiếu nại được, D-25, T-BA-108); AC-04.06.1 tham chiếu màn "Chi tiết phiên" US-08.10 (T-BA-105). Ước lượng không đổi.

**Ước lượng Must EP-04:** không đổi (US-04.01 M, US-04.05 S, US-04.06 S). US-04.03 (S), US-04.04 (M) vốn là Should nên không ảnh hưởng tổng Must (nay 86 điểm theo backlog; D-17 ghi 83 — chờ Q-140); tổng Should giảm S + M.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-125 (BR-25 Hủy → BR-114 ở AC-04.01.9, dòng Liên quan/Truy vết US-04.01, đầu tệp); T-BA-127 (AC-04.07.5 bỏ "chờ ba-rules"; AC-04.08.1 người nhận theo BR-87; AC-04.08.9 gỡ "cần BR mới"; tổng Must 86); T-BA-128 (NFR-P16 → NFR-P18; ghi chú US-04.01 NFR-01 ≥ 3 máy); T-BA-131 (nhãn "nguồn cũ đã xóa"); D-29 (US-04.01 dẫn BR-118). Ước lượng không đổi.

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`. Q-87 gộp với câu EP-03; Q-72 gộp với câu EP-02; Q-91 gộp với câu EP-09 (chuyển khiếu nại lên quản trị).

| Mã | Câu hỏi | Đề xuất | Story |
| --- | --- | --- | --- |
| Q-89 | Push không tới (tắt quyền, lỗi SNS): có hộp thông báo trong app và thử lại không? | Có hộp thông báo trong app; SNS thử lại 1 lần, ghi log | US-04.01 |
| Q-87 | Thành viên đang PAUSED/khóa màn hình được báo `forfeited` bằng kênh nào để không bị dụ rời app? | Chỉ banner trong app khi quay lại/mở khóa; không push hệ thống trong phiên | US-03.09 |
| Q-72 | Đổi `notify_mode` khi phiên đang chạy có hiệu lực ngay không? | (Không còn áp dụng ở MVP — D-20) | US-04.03 |
| Q-136 | Có hiện tên người LOST/ABSENT cho cả nhóm? | Không | US-04.01 |
| Q-137 | Thành viên khác có thấy số lần thoát tích lũy của người khác? | Không | US-04.01 |
| Q-138 | Miễn trừ: gửi đính chính cho đúng người đã nhận tin thoát? | Có | US-04.08 |
| Q-139 | Chủ nhóm thoát có bị nêu tên như thành viên? | Đã chốt → D-25 (chủ nhóm không tham gia phiên; không còn áp dụng) | — |
| Q-90 | Giải trình: độ dài tối đa, hạn gửi lần đầu, có gửi trong lúc phiên chạy không? | 500 ký tự; gửi trong 7 ngày; sửa trong 24h; cho gửi ngay sau EXITED | US-04.05 |
| Q-91 | Hạn khiếu nại và ai xử lý khi người khiếu nại là chủ nhóm? | 24h sau `ends_at`; phần "khiếu nại của chủ nhóm" không còn áp dụng (D-25 — chủ nhóm không tham gia phiên, AC-04.07.5) | US-04.07, US-04.08 |
| Q-92 | Miễn trừ một người khi còn EXITED khác: phiên vẫn `forfeited`? người khởi phát đổi thế nào? | Vẫn `forfeited`; khởi phát chuyển sang EXITED kế tiếp chưa miễn trừ | US-04.08 |

BR đã cấp (`03-quy-tac.md` §Thông báo & khiếu nại): (1) hộp thông báo + thử lại push → BR-81; (2) kênh báo `forfeited` cho người không ở tiền cảnh → BR-82; (3) BR-83, (4) BR-84 — Hủy (D-20); (5) quy tắc giải trình → BR-85; (6) quy tắc khiếu nại → BR-86; (7) ngoại lệ BR-35 khi miễn trừ → BR-87 (gỡ `forfeited`, đổi người khởi phát) và BR-88 (khôi phục Coins/chuỗi hồi tố).
