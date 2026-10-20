# SRS 03 — Quy tắc nghiệp vụ

Việc: T-BA-06 (§Phiên), T-BA-12 (§Thưởng), T-BA-15 (§Báo cáo). Mẫu: `ba/mau/quy-tac-nghiep-vu.md`. Nguồn: GĐ1 §4, §6; `ba/srs/04-nfr-rieng-tu.md`; `05-tham-chieu-ky-thuat.md` (chỉ mượn kỹ thuật).
Cập nhật 2026-10-06 theo D-05…D-10. Bổ sung 2026-10-06: BR-63…BR-112 (gom "cần BR mới" từ 9 tệp story EP-01…EP-09; mã tạm BR-N1…N6 của EP-02 → BR-74, BR-71, BR-76, BR-77, BR-78, BR-79); sửa BR-30 (ABSENT vs VOID), BR-35 (ngoại lệ miễn trừ), BR-32, BR-54, BR-56, BR-57.
Ràng buộc: không cược (D-01). Không có trạng thái FAILED cả phòng — phiên luôn chạy đến hết giờ; nhưng **một người thoát thật thì cả phiên mất thưởng tập thể** (D-05).
Vai trò theo từng nhóm: **chủ nhóm** (người tạo nhóm) và **thành viên**; không có vai trò hệ thống "Trưởng phòng" (D-10).
Q- chưa chốt: viết theo phương án đề xuất, gắn **(giả định, Q-xx)**. Đã chốt: ghi mã **D-xx**.
Sửa 2026-10-06 theo review lần 1 (`ba/review/lan-1.md`, nguồn cũ đã xóa) và D-11…D-15: T-BA-26 (thuật ngữ hoàn thành, D-11), T-BA-27 (BR-112 khớp D-02/BR-02), T-BA-28 (chủ nhóm không thấy chuỗi, D-12), T-BA-29 (BR-22 ↔ BR-68), T-BA-34 (BR-84), T-BA-35 (định nghĩa mất kết nối), T-BA-36 (mốc đếm ngược), T-BA-37 (máy trạng thái khiếu nại, nhóm, món Shop), T-BA-38 (rút đồng ý sau `forfeited_at`, Q-131), T-BA-40 (BR-100), T-BA-48 (BR-48), T-BA-52 (nhãn số liệu, Q-132). Thêm BR-113 (lịch lặp, US-02.10b, Q-78) và tham số `recurrence_max_weeks`.
Sửa 2026-10-07 theo D-19…D-24 và review lần 2 (`ba/review/lan-2.md`, nguồn cũ đã xóa): D-19 (LOST không kích hoạt D-05; sự cố → hủy) ở BR-21, BR-22, BR-36; D-20 (báo thoát ngay cho cả nhóm và cả phiên, bỏ gộp) ở BR-14, BR-25, BR-27, BR-28, BR-82, BR-83, BR-84, §4; D-21 (1 người tối đa 1 nhóm là thành viên) ở BR-09, BR-10, BR-43, BR-46, BR-75, BR-78, BR-114; D-22 (nêu tên người thoát) ở BR-38, BR-87; D-23 ở BR-37, BR-48; D-24 ở BR-57, BR-105. T-BA-55 (BR-85 chỉ EXITED), T-BA-64 (BR-112 đủ miền), T-BA-66 (máy trạng thái nhóm).
Sửa 2026-10-19 theo D-25 (chủ nhóm không tham gia phiên): BR-25, BR-69 Hủy; BR-114 viết lại; sửa BR-09, BR-35, BR-46, BR-60, BR-74, BR-75, BR-78, BR-86, §2.2, §3, §4, §Báo cáo, máy trạng thái nhóm và khiếu nại. Q-141 (đề xuất): sĩ số 4–10 không gồm chủ nhóm.
Sửa 2026-10-19 theo `ba/review/mockup-tong-hop.md` §3 (S1–S11): sửa BR-08 (hạn vào = `started_at` khi chưa làm US-03.11), BR-60, BR-86 (a); thêm BR-115 (thứ tự hiển thị), BR-116 (chi tiết phiên của chủ nhóm, không thời gian thực), BR-117 (chỉ số nhiều nhóm), BR-118 (rời chủ động = EXITED), BR-119 (lịch sử phiên của tôi), BR-120 (riêng tư EP-10), BR-121 (Shop không ngẫu nhiên). S7, S8 thuộc `01-pham-vi.md`, không có BR. Q-143…Q-145.
Sửa 2026-10-19 theo `ba/review/lan-4.md` và D-29: T-BA-123 (BR-118 viết lại — nút "Rời phiên", ca WAITING → ABSENT, §2.2 thêm 2 dòng, §3 dòng 53–57 — đánh lại từ 45–49 trùng số, T-BA-133), T-BA-126 (BR-115 tie-break + ngoại lệ chủ nhóm đứng đầu; BR-117 tiêu chí kiểm), T-BA-127 (BR-87 nêu rõ ngoại lệ BR-27), T-BA-129 (BR-75 (c) dẫn Q-150), T-BA-131 (ghi chú nguồn đã xóa). Q-149, Q-150.
Sửa 2026-10-19 theo `ba/review/lan-5.md`: T-BA-132 (BR-118 — màn đếm ngược không có nút; §3 #53, K-16 (c)), T-BA-133 (§3 dòng mới đánh lại #53–#57), T-BA-134 (BR-115 ngoại lệ thứ hai — danh sách sự kiện theo giờ server), T-BA-136 (thêm BR-122 theo D-27, BR-123 theo D-28), T-BA-140 (§2.2 WAITING mất kết nối, Q-153).

**Tên sự kiện / thông báo chuẩn (D-20, D-22)** — story dùng đúng các mã này:
- `MEMBER_EXITED` — "‹Tên› đã rời phiên lúc hh:mm:ss." Gửi **ngay** cho mọi thành viên nhóm (kể cả chủ nhóm, kể cả người không tham gia phiên) và mọi người trong phiên, trừ chính người thoát.
- `SESSION_FORFEITED` — "Phiên đã mất thưởng tập thể do ‹Tên› rời phiên — vẫn tiếp tục đến hết giờ." Gửi cùng lúc với `MEMBER_EXITED` đầu tiên (gộp chung một thông báo cho mỗi người nhận).
- `SESSION_CANCELLED_OUTAGE` — thông báo hủy chung do sự cố; `SESSION_CANCELLED_OUTAGE_EXITED` — bản riêng cho người đã EXITED trước sự cố (BR-68).
- `SESSION_RESULT` — màn/push kết quả sau `ends_at` (BR-91).
- `EXEMPTION_GRANTED` — miễn trừ có nêu tên người được miễn trừ (BR-87).
- LOST, PAUSED, WITHDRAWN, ABSENT: **không** có thông báo tức thời cho người khác.

**Thuật ngữ (D-11):**
- **Hoàn thành (phiên, cá nhân)** = trạng thái cuối của người đó là COMPLETED: hết giờ mà **bản thân** không thoát, **kể cả** khi phiên `forfeited`.
- **Hoàn thành có thưởng** = COMPLETED **và** phiên không `forfeited` (tại lúc chốt, sau miễn trừ nếu có).
- **Mất kết nối** (định nghĩa duy nhất, BR-19/BR-66): xem BR-19.

---

## §Phiên

### 1. Quy tắc

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-01 | Phiên nhóm chỉ được tạo từ lịch do **chủ nhóm** của nhóm đặt (D-06). MVP không có phiên tự do **(giả định, Q-02 phần “phiên tự do”)**. | — | GĐ1 §4.1; D-06 | EP-02, EP-03 |
| BR-02 | Thời lượng phiên chỉ là 25 hoặc 50 phút. Giá trị **cố định ở MVP, không cấu hình** (Coins chỉ định nghĩa cho 25/50, BR-40). Mở thêm thời lượng cần quyết định mới và định nghĩa Coins tương ứng. | `duration ∈ {25, 50}` (**không** cấu hình) | GĐ1 §4.1; D-09 | EP-02, EP-03 |
| BR-03 | Mọi mốc thời gian phiên (bắt đầu, kết thúc, hạn khoan hồng, hạn tạm dừng, hạn mất liên lạc, mốc mất thưởng tập thể) do server tính; không dùng đồng hồ client. | — | `05-tham-chieu-ky-thuat.md` §5 | EP-03 |
| BR-04 | **Mốc giờ phiên:** giờ bắt đầu trên lịch **chính là** `started_at`. Phiên vào COUNTDOWN lúc `started_at − countdown_s` (giờ server); hết đếm ngược đúng tại `started_at`, server bắt đầu ghi và hẹn `ends_at = started_at + duration`. Mọi mốc dựa trên "giờ bắt đầu" (hạn vào muộn BR-07, nhắc BR-79, phòng chờ BR-63, chồng phiên BR-78) đều tính từ `started_at` = giờ lịch. *(Sửa T-BA-36: trước đây COUNTDOWN bắt đầu tại giờ lịch, lệch 5 giây.)* | `countdown_s = 5` (có) | GĐ1 §4.2; `05-tham-chieu-ky-thuat.md` §2 | EP-02, EP-03 |
| BR-05 | Chỉ ghi sự kiện từ khi hết đếm ngược đến khi người đó kết thúc phiên; trước/sau đó không gửi sự kiện nào. Suốt thời gian ghi phải hiện chỉ báo “Phiên đang được ghi”. | — | NFR-P02, NFR-P08 | EP-03 |
| BR-06 | Thành viên chưa đồng ý (hoặc chưa đồng ý lại phiên bản điều khoản mới) không được vào phiên. Trước khi đồng ý phải thấy quy tắc D-05 (một người thoát thì cả phiên mất thưởng). | — | NFR-P04; 04-nfr §2; D-05 | EP-01, EP-03 |
| BR-07 | Thành viên vào phòng chờ trước giờ bắt đầu thì tham gia đầy đủ; vào sau `started_at` nhưng trong 5 phút thì được tham gia phần còn lại, đánh dấu “vào muộn” **(giả định, Q-18)**. | `late_join_max_min = 5` (có) | Q-18 | EP-03, EP-08 |
| BR-08 | Quá hạn vào mà chưa vào: ghi ABSENT; vắng không phải thoát, không thông báo ai, không kích hoạt D-05, không ngắt chuỗi vì vắng **(giả định, Q-18, Q-17)**. **Hạn vào** = `started_at + late_join_max_min`. Khi US-03.11 (vào muộn, Should) **chưa** làm, hệ thống chạy với `late_join_max_min = 0`: hạn vào = `started_at`; mọi thành viên còn INVITED đúng lúc `started_at` (giờ server) → ABSENT ngay, không có cờ "vào muộn", 0 Coins, màn kết quả ghi "Vắng" (khớp AC-03.10.7). Khi làm US-03.11 thì dùng mặc định 5 phút (BR-07). *(Sửa 2026-10-19, T-BA-70.)* | dùng `late_join_max_min` (MVP thực tế = 0 khi chưa làm US-03.11) | Q-18; D-13 | EP-03, EP-08 |
| BR-09 | Một người chỉ ở trạng thái “đang trong phiên” ở tối đa 1 phiên tại một thời điểm; vào phiên thứ hai trùng giờ bị từ chối kèm thông báo “Bạn đang ở phiên khác”. Với D-21, D-25 và BR-78, ca này gần như không xảy ra (chủ nhóm không vào phiên; mỗi người là thành viên tối đa 1 nhóm); giữ làm chốt chặn kỹ thuật (vd. lịch bị sửa đồng thời). | — | D-21; D-25; D-10 | EP-02, EP-03 |
| BR-10 | (Hủy — D-21: một người chỉ là thành viên của tối đa 1 nhóm nên không còn trùng lịch giữa nhiều nhóm của cùng thành viên; trong nhóm đã có BR-78. Chủ nhóm không tham gia phiên: D-25, BR-114.) | — | D-21 | — |
| BR-11 | Rời app (chuyển app, đưa xuống nền, mở khóa rồi rời app) khi đang FOCUSING → chuyển GRACE, server đặt hạn 3 giây. | `grace_s = 3` (có) | GĐ1 §4.2; `05-tham-chieu-ky-thuat.md` §1 | EP-03 |
| BR-12 | Quay lại app trước hạn khoan hồng: về FOCUSING, ghi `grace_recovered`, không phạt, không báo, **không kích hoạt D-05**. | — | `05-tham-chieu-ky-thuat.md` §1; D-05 | EP-03 |
| BR-13 | Mỗi người được tối đa 1 lần khoan hồng/phiên; lần rời app sau khi đã dùng hết → EXITED ngay **(giả định, Q-10)**. | `grace_max_per_session = 1` (có) | Q-10 | EP-03 |
| BR-14 | Quá hạn khoan hồng mà chưa quay lại → EXITED: ghi sự kiện thoát (thời điểm server), gửi `MEMBER_EXITED` theo BR-27, và **kích hoạt mất thưởng tập thể** theo BR-35. Phiên **vẫn tiếp tục** cho mọi người đến `ends_at` (D-05). | — | GĐ1 §4.3; D-05 | EP-03, EP-04 |
| BR-15 | Khóa màn hình / tắt màn hình (úp máy) không tính là rời app; mở khóa và rời app mới tính theo BR-11 (D-08; cách phát hiện chờ spike). | — | D-08 | EP-03 |
| BR-16 | Thành viên được tạm dừng có lý do tối đa 1 lần/phiên, tối đa 5 phút, lý do chọn từ danh sách; trong PAUSED rời app không bị tính và không kích hoạt D-05 **(giả định, Q-11, Q-15)**. | `pause_max_count = 1`, `pause_max_min = 5`, `pause_reasons` (có) | GĐ1 §6; Q-11 | EP-03, EP-04 |
| BR-17 | Thời gian tạm dừng không cộng vào phút tập trung; `ends_at` của phiên **không** lùi lại **(giả định, Q-11)**. | — | Q-11 | EP-03, EP-08 |
| BR-18 | Hết hạn tạm dừng: nếu đang ở app → FOCUSING; nếu không ở app → GRACE (đếm 3 giây, không tốn lượt khoan hồng) **(đề xuất, Q-26)**. | — | Q-26 | EP-03 |
| BR-19 | **Định nghĩa duy nhất về mất kết nối** (T-BA-35). (1) Khi app ở tiền cảnh và màn hình mở, client gửi heartbeat mỗi `heartbeat_s` giây. Khi màn hình khóa (đã báo "khóa màn hình", BR-66) client **không bắt buộc** gửi heartbeat; khi app rời tiền cảnh thì đã thuộc GRACE/PAUSED, không áp ngưỡng heartbeat cho GRACE (§3 #1). (2) `last_seen_at` = lần cuối server nhận bất kỳ gói nào (heartbeat hoặc sự kiện) của (người, phiên). (3) **`disconnected_at`** = thời điểm sớm hơn trong hai mốc: lúc server phát hiện socket đóng, hoặc `last_seen_at + heartbeat_timeout_s` (BR-66). Tại `disconnected_at` người đó → DISCONNECTED. (4) **Mốc gốc** của hạn giữ chỗ là `disconnected_at`: kết nối lại khi `t < disconnected_at + disconnect_hold_s` thì trong hạn (BR-65); ngược lại → LOST tại `disconnected_at + disconnect_hold_s`. (5) Vì vậy "mất mạng quá 10 giây" nghĩa là **10 giây kể từ `disconnected_at`**; tính từ heartbeat cuối thì LOST chậm nhất sau `heartbeat_timeout_s + disconnect_hold_s` (= 20 giây với mặc định). Mọi AC về mất kết nối phải ghi mốc là `disconnected_at`. | `heartbeat_s = 5`, `heartbeat_timeout_s = 10`, `disconnect_hold_s = 10` (có) | `05-tham-chieu-ky-thuat.md` §5; Q-14; Q-86; D-08 | EP-03 |
| BR-20 | Kết nối lại trong hạn giữ chỗ (BR-19 mục 4), gửi lại `session_id`: trở về trạng thái trước khi mất (FOCUSING / PAUSED). Thời gian DISCONNECTED **không** cộng vào phút tập trung; hạn tạm dừng (nếu đang PAUSED) vẫn chạy **(giả định, Q-14)**. | — | Q-14 | EP-03 |
| BR-21 | Quá hạn giữ chỗ → LOST: ghi “mất kết nối” tách khỏi “thoát”, không gửi `MEMBER_EXITED`, chỉ người đó không nhận Coins phiên, **không kích hoạt D-05** (không đặt `forfeited`) (D-19); chuỗi theo BR-48 **(đề xuất, Q-27)**. | — | D-19; Q-27 | EP-03, EP-04, EP-08 |
| BR-22 | Nếu ≥ ngưỡng % thành viên đang hoạt động (trên mọi nhóm của server) cùng mất kết nối trong cửa sổ ngắn, hoặc server lỗi → phiên CANCELLED: mọi người **chưa ở trạng thái kết thúc** → VOID (không ghi thoát/mất kết nối, không ngắt chuỗi); không ai nhận Coins; không ai bị phạt; cờ `forfeited` (nếu đã bật) bị gỡ (D-19). **Ngoại lệ BR-68:** người đã EXITED **trước** sự cố giữ EXITED và giữ ngắt chuỗi cá nhân, nhận `SESSION_CANCELLED_OUTAGE_EXITED` (khác `SESSION_CANCELLED_OUTAGE`) (D-19 giữ ngoại lệ; chi tiết **(đề xuất, Q-123)**). Người đã LOST trước sự cố: giữ LOST (không ngắt chuỗi, BR-48). | `outage_ratio = 80%`, `outage_window_s = 10` (có) **(đề xuất, Q-28)** | `05-tham-chieu-ky-thuat.md` §5; Q-14 | EP-03 |
| BR-23 | Hết `ends_at`: thành viên ở FOCUSING/PAUSED/GRACE (chưa quá hạn) → COMPLETED = **hoàn thành** (D-11); phút tập trung = thời gian thực FOCUSING (+GRACE đã hồi phục). COMPLETED vẫn được ghi kể cả khi phiên đã `forfeited` (khi đó là hoàn thành nhưng **không** phải hoàn thành có thưởng). | — | GĐ1 §4.5; D-05; D-11 | EP-03, EP-06 |
| BR-24 | Chỉ **hoàn thành có thưởng** mới nhận Coins theo §Thưởng; hoàn thành trong phiên `forfeited` nhận 0 (D-05, D-11, BR-41). | xem §Thưởng | D-05, D-09, D-11 | EP-06 |
| BR-25 | (Hủy — D-25: chủ nhóm không tham gia phiên của nhóm mình; không có trạng thái, không EXITED, không kích hoạt D-05. Thay bằng BR-114.) | — | D-25 | — |
| BR-26 | Rút đồng ý giữa phiên: hiệu lực ngay, dừng ghi, trạng thái WITHDRAWN — không tính thoát, không gửi `MEMBER_EXITED`, không Coins, **không kích hoạt D-05**; rời nhóm ngay **(giả định, Q-20, Q-60)**. Rút sau `forfeited_at` vẫn bị ngắt chuỗi (BR-37, D-23). | — | Q-20; D-23; 04-nfr §3 | EP-01, EP-03 |
| BR-27 | **Người nhận `MEMBER_EXITED`** (D-20, D-22): khi server xác nhận EXITED, gửi **ngay** cho (a) mọi thành viên hiện tại của nhóm, kể cả chủ nhóm và người không tham gia phiên này, và (b) mọi người có trạng thái trong phiên (kể cả người đã kết thúc trước đó); trừ chính người thoát. Nội dung có **tên** người thoát và giờ server; không có tên app, lý do, Coins (BR-34, BR-53). Kênh: người **không** có trạng thái chưa kết thúc trong phiên nhận push + hộp thông báo; người đang trong phiên nhận theo BR-82. Không có chế độ gộp (bỏ `notify_mode`). | — | GĐ1 §4.3; D-20; D-22 | EP-03, EP-04 |
| BR-28 | `MEMBER_EXITED` phải được server phát ≤ `notify_latency_s` giây sau khi xác nhận EXITED (không phải khi bắt đầu GRACE); áp cho mọi người nhận ở BR-27. | `notify_latency_s = 5` (NFR) | GĐ1 §11; D-20 | EP-04 |
| BR-29 | Chủ nhóm hủy phiên trước `started_at` → CANCELLED, không ghi dữ liệu nào; sau `started_at` chủ nhóm không dừng được phiên **(đề xuất, Q-29)**. | — | Q-29 | EP-02, EP-03 |
| BR-30 | Phiên không có ai vào khi hết hạn vào muộn: **trước tiên** mọi thành viên INVITED được ghi ABSENT (BR-08), **sau đó** phiên → CANCELLED với `cancel_reason = NO_ATTENDEE`. Ngoại lệ của dòng “Phiên CANCELLED → VOID” (§2.2): không ai được ghi VOID trong trường hợp này. ABSENT không ngắt chuỗi (BR-48) **(đề xuất, Q-88)**. *(Sửa 2026-10-06: trước đây mâu thuẫn ABSENT vs VOID.)* | — | suy từ Q-18; Q-88 | EP-03, EP-08 |
| BR-31 | Mỗi sự kiện client gửi có `event_id` duy nhất; server xử lý idempotent (trùng thì bỏ qua) và chỉ chấp nhận chuyển trạng thái hợp lệ theo §2.2. | — | `05-tham-chieu-ky-thuat.md` §2 | EP-03 |
| BR-32 | Trạng thái kết thúc của thành viên (COMPLETED, EXITED, LOST, ABSENT, WITHDRAWN, VOID) là cuối cùng; không chuyển tiếp và không sửa, chỉ được thêm giải trình (BR-85) hoặc cờ “miễn trừ” trên EXITED khi khiếu nại được chấp nhận (BR-87) **(giả định, Q-16, Q-37)**. | — | Q-16; Q-20; Q-37 | EP-03, EP-04, EP-08 |
| BR-33 | Khi hai sự kiện đến gần nhau, server lấy theo **thời điểm server nhận** sớm hơn; sự kiện sau `ends_at` không có hiệu lực. | — | BR-03 | EP-03 |
| BR-34 | Không ghi tên app, nội dung máy hay vị trí; tín hiệu chỉ là “rời app/khóa màn hình/quay lại”. Không dùng UsageStatsManager để biết app khác. | — | GĐ1 §6; D-03 | EP-03 |
| BR-35 | **Mốc mất thưởng tập thể.** Phiên có cờ `forfeited` (mặc định `false`). Sự kiện EXITED **đầu tiên** của bất kỳ thành viên tham gia nào (chủ nhóm không tham gia phiên, D-25) khi phiên ACTIVE và trước `ends_at` → server đặt `forfeited = true`, ghi `forfeited_at` (giờ server) và `forfeit_trigger_user_id` (người khởi phát). Cờ một chiều: không tắt lại, **trừ hai ngoại lệ**: (1) phiên CANCELLED do sự cố (BR-22); (2) khiếu nại được chấp nhận làm mọi EXITED của phiên đều được miễn trừ (BR-87). *(Sửa 2026-10-06: thêm ngoại lệ 2.)* | — | D-05; NFR-P14 | EP-03, EP-05, EP-06, EP-08 |
| BR-36 | Chỉ EXITED kích hoạt BR-35. **Không** kích hoạt: GRACE đã hồi phục, PAUSED, LOST (D-19), WITHDRAWN, ABSENT, vào muộn, VOID. | — | D-05; D-19 | EP-03 |
| BR-37 | **Phạm vi ảnh hưởng** khi `forfeited = true`: mọi người tham gia phiên có trạng thái cuối là COMPLETED, EXITED hoặc LOST đều nhận 0 Coins phiên và bị ngắt chuỗi (BR-47). Người ABSENT, VOID không bị ảnh hưởng. WITHDRAWN **trước** `forfeited_at` không bị ảnh hưởng; WITHDRAWN (rút đồng ý / rời nhóm) **sau** `forfeited_at` vẫn bị ngắt chuỗi (không Coins vì đã WITHDRAWN) để chặn kẽ hở "rời nhóm rồi được mời lại để giữ chuỗi" (D-23). WITHDRAWN do khóa tài khoản (BR-108) không bị ngắt chuỗi. **Mốc biên:** so sánh nghiêm ngặt theo giờ server — WITHDRAWN có thời điểm `< forfeited_at` là "trước"; WITHDRAWN đúng bằng `forfeited_at` coi là "sau" (bị ngắt chuỗi) (khớp BR-65, AC-05.03.15). Người vào muộn **sau** `forfeited_at` cũng bị ảnh hưởng và phải được cảnh báo trước khi vào **(đề xuất, Q-41)**. | — | D-05; Q-41 | EP-03, EP-05, EP-06 |
| BR-38 | Khi phiên chuyển `forfeited = true`: mọi người nhận `MEMBER_EXITED` (BR-27) nhận cùng lúc `SESSION_FORFEITED` **có tên** người khởi phát: “Phiên đã mất thưởng tập thể do ‹Tên› rời phiên — vẫn tiếp tục đến hết giờ” (D-22). Hai nội dung gộp trong **một** thông báo cho mỗi người nhận. Kênh cho người đang trong phiên: BR-82. *(Sửa 2026-10-07: trước đây không nêu tên, Q-50 — thay bằng D-22.)* | — | D-05; D-22 | EP-03, EP-04 |
| BR-39 | Sau khi `forfeited = true`, các EXITED tiếp theo vẫn được ghi đủ và gửi `MEMBER_EXITED` như thường (không gửi lại `SESSION_FORFEITED`); không thay đổi `forfeit_trigger_user_id` (trừ khi miễn trừ, BR-87). | — | D-05 | EP-03, EP-04, EP-08 |
| BR-63 | **Phòng chờ** mở `lobby_open_min` phút trước giờ bắt đầu theo lịch. Trước mốc đó không vào được (báo “Phòng chờ mở lúc hh:mm”). Ở WAITING không ghi sự kiện (BR-05). Phiên bị hủy khi đang WAITING → VOID **(đề xuất, Q-83)**. | `lobby_open_min = 10` (có) | Q-83 | EP-02, EP-03 |
| BR-64 | **Rời app trong COUNTDOWN:** không ghi, không tính. Tại `started_at` server hỏi trạng thái tiền cảnh: đang ở app → FOCUSING; không ở app (hoặc chưa báo) → GRACE tính từ `started_at`, **có** trừ lượt khoan hồng (BR-13) **(đề xuất, Q-84)**. | — | Q-84 | EP-03 |
| BR-65 | **Quy ước biên thời gian** (áp cho mọi hạn: khoan hồng, vào muộn, tạm dừng, giữ chỗ mất kết nối, giải trình, khiếu nại, mã mời): hạn là mốc **nửa mở** — sự kiện được server nhận tại thời điểm `t < hạn` thì **trong hạn**; `t ≥ hạn` là **quá hạn**. Ví dụ: quay lại đúng 3,000s sau khi rời app → EXITED; vào phiên đúng 5:00 sau `started_at` → không được vào (ABSENT). Độ chính xác đo: mili giây theo giờ server. | — | BR-03; BR-33 | EP-03, EP-04, EP-02 |
| BR-66 | **Ngưỡng mất heartbeat:** dùng trong BR-19 mục 3: DISCONNECTED khi `t ≥ last_seen_at + heartbeat_timeout_s` (mặc định 2 × `heartbeat_s` = 10s) **hoặc** socket đóng. Ràng buộc: `heartbeat_timeout_s ≥ 2 × heartbeat_s` (để một nhịp trễ không chạm ngưỡng). Khi client đã báo “khóa màn hình” (D-08), server **không** áp ngưỡng heartbeat và không coi socket đóng là DISCONNECTED cho đến khi client báo mở khóa (khi đó `last_seen_at` = lúc nhận báo mở khóa) hoặc đến `ends_at`; client ở trạng thái khóa có thể giảm/ngừng heartbeat (nguồn cho NFR-08 heartbeat nền) **(đề xuất, Q-86, Q-61 — chờ spike)**. | `heartbeat_timeout_s = 10` (có) | Q-86; Q-61; D-08 | EP-03 |
| BR-67 | **Danh sách lý do tạm dừng mặc định** (`pause_reasons`): “Cuộc gọi”, “Việc gấp của công việc”, “Việc cá nhân khẩn”, “Khác”. Chọn “Khác” không bắt buộc nhập chữ. Lý do không chứa tên app hay nội dung máy (BR-34) **(giả định, Q-11)**. | `pause_reasons` (có) | Q-11; Q-15 | EP-03, EP-04 |
| BR-68 | **EXITED trước sự cố:** khi phiên CANCELLED do sự cố (BR-22), người đã EXITED trước đó vẫn giữ sự kiện EXITED và **giữ ngắt chuỗi cá nhân** (BR-47a, vì đã rời app thật trước sự cố); `MEMBER_EXITED` đã gửi không thu hồi. Người đó nhận `SESSION_CANCELLED_OUTAGE_EXITED`: “Phiên đã bị hủy do sự cố. Lần rời app của bạn trước sự cố vẫn được ghi; chuỗi đã ngắt. Bạn có thể khiếu nại (BR-86).” — khác thông báo hủy chung gửi người VOID. Phiên không vào báo cáo tháng (BR-58) nên không đếm “số lần thoát”. Người khác chưa kết thúc: VOID, không bị ảnh hưởng. Đây là ngoại lệ duy nhất của câu “không ai bị tính” ở BR-22 **(đề xuất, Q-123)**. | — | BR-22; Q-14; Q-123 | EP-03, EP-05, EP-08 |
| BR-69 | (Hủy — D-25: nội dung chuyển thành quy tắc chung ở BR-114; chủ nhóm không bao giờ có trạng thái trong phiên của nhóm mình, không ABSENT, không tính “lượt dự kiến”, không có dòng trong báo cáo.) | — | D-25 | — |
| BR-70 | **Đăng xuất / nhiều thiết bị trong phiên:** khi người dùng có trạng thái chưa kết thúc (WAITING/FOCUSING/GRACE/PAUSED/DISCONNECTED), app chặn đăng xuất (báo “Đang trong phiên”). Mỗi (người, phiên) chỉ một socket; thiết bị thứ hai đăng nhập không vào/chiếm được phiên đang chạy. Nếu phiên đăng nhập bị thu hồi phía server (đổi mật khẩu, quản trị khóa) → xử lý theo BR-19/BR-108, không tính là thoát do chính hành động đó **(đề xuất, Q-66)**. | — | Q-66 | EP-01, EP-03 |

### 2. Máy trạng thái

#### 2.1 Cấp PHIÊN

Không có trạng thái FAILED. `SCHEDULED → COUNTDOWN → ACTIVE → COMPLETED`; `SCHEDULED/COUNTDOWN/ACTIVE → CANCELLED`. Thuộc tính phụ ở cấp phiên: `forfeited`, `forfeited_at`, `forfeit_trigger_user_id` (BR-35) — **không phải** trạng thái; phiên vẫn ACTIVE đến `ends_at`.

| Trạng thái | Sự kiện | Điều kiện | Trạng thái kế | Hành động hệ thống |
| --- | --- | --- | --- | --- |
| SCHEDULED | Đến `started_at − countdown_s` (giờ server; `started_at` = giờ lịch, BR-04) | — | COUNTDOWN | Mở đếm ngược 5s cho người đã vào phòng chờ |
| SCHEDULED | Chủ nhóm hủy | Trước giờ | CANCELLED | Thông báo thành viên; không ghi dữ liệu (BR-29) |
| COUNTDOWN | Đến `started_at` | — | ACTIVE | Bắt đầu ghi, đặt `ends_at`; thành viên đã vào → FOCUSING |
| COUNTDOWN | Sự cố server | — | CANCELLED | Không ghi thoát, không ngắt chuỗi (BR-22) |
| ACTIVE | Hết hạn vào muộn | Không ai vào | CANCELLED | Ghi ABSENT cho mọi người trước, rồi hủy với `cancel_reason = NO_ATTENDEE`; không ai VOID (BR-30) |
| ACTIVE | Mọi EXITED đều được miễn trừ (sau phiên) | `forfeited = true` | (giữ COMPLETED) | Gỡ `forfeited`, khôi phục hồi tố (BR-87, BR-88) |
| ACTIVE | Thành viên EXITED đầu tiên | `forfeited = false` | ACTIVE | Đặt `forfeited = true`, ghi `forfeited_at`, người khởi phát; gửi `MEMBER_EXITED` + `SESSION_FORFEITED` (BR-27, BR-38) |
| ACTIVE | Thành viên EXITED tiếp theo | `forfeited = true` | ACTIVE | Ghi + gửi `MEMBER_EXITED` (BR-39) |
| ACTIVE | Thành viên LOST | bất kỳ | ACTIVE | Không đổi `forfeited` (D-19) |
| ACTIVE | Đến `ends_at` | — | COMPLETED | Chốt trạng thái từng thành viên (§2.2); nếu `forfeited` thì 0 Coins + ngắt chuỗi cho phạm vi BR-37, ngược lại tính Coins; gửi `SESSION_RESULT` (BR-91). Không có bản gộp (D-20) |
| ACTIVE | Sự cố server (BR-22) | — | CANCELLED | Mọi thành viên chưa kết thúc → VOID; gỡ `forfeited`; không phạt; người đã EXITED trước đó giữ EXITED + ngắt chuỗi và nhận thông báo riêng (BR-68) **(giả định, Q-14, Q-123)** |
| ACTIVE | Mọi thành viên đã ở trạng thái kết thúc | — | ACTIVE (đến `ends_at`) | Giữ nguyên để báo cáo nhất quán **(giả định)** |

Ghi chú: phiên COMPLETED dù không ai COMPLETED; kết quả từng người nằm ở cấp thành viên.

#### 2.2 Cấp THÀNH VIÊN TRONG PHIÊN

Chỉ áp cho **thành viên**; chủ nhóm không có trạng thái trong phiên của nhóm mình (D-25, BR-114). Trạng thái: INVITED, WAITING, FOCUSING, GRACE, PAUSED, DISCONNECTED. Kết thúc: COMPLETED, EXITED, LOST, ABSENT, WITHDRAWN, VOID.

| Trạng thái | Sự kiện | Điều kiện | Trạng thái kế | Hành động hệ thống |
| --- | --- | --- | --- | --- |
| INVITED | Vào phòng chờ | Đã đồng ý; không ở phiên khác (BR-06, BR-09) | WAITING | — |
| INVITED | Vào phiên | Sau `started_at`, ≤5 phút | FOCUSING | Đánh dấu vào muộn (BR-07); nếu `forfeited` thì cảnh báo trước (BR-37) |
| INVITED | Hết hạn vào muộn | — | ABSENT | Ghi vắng, không báo (BR-08) |
| WAITING | Phiên → ACTIVE | Đang ở app | FOCUSING | Bật ghi + chỉ báo (BR-05) |
| WAITING | Phiên → ACTIVE | Không ở app (đã rời trong COUNTDOWN) | GRACE | Hẹn 3s từ `started_at`, trừ lượt (BR-64) |
| WAITING | Mất kết nối | Trước `started_at` | WAITING | Giữ WAITING; nối lại trước `started_at` thì vào phiên bình thường; đến `started_at` chưa nối lại → ABSENT **(đề xuất, Q-153)** |
| WAITING | Bấm "Rời phiên" + xác nhận (`session:leave`) | Trước `started_at` | ABSENT | Ghi vắng, không `MEMBER_EXITED`, không kích hoạt D-05 (BR-118 (2)) **(giả định, Q-149)** |
| FOCUSING / GRACE / PAUSED | Bấm "Rời phiên" + xác nhận (`session:leave`) | Phiên ACTIVE | EXITED | Ghi thoát `reason = USER_LEAVE`, hủy hẹn GRACE/PAUSED, `MEMBER_EXITED` (BR-27), BR-35 (BR-118 (1), D-29) |
| FOCUSING | Rời app | Còn lượt khoan hồng | GRACE | Hẹn 3s, trừ lượt |
| FOCUSING | Rời app | Hết lượt khoan hồng | EXITED | Ghi thoát, `MEMBER_EXITED` (BR-27), BR-35 |
| FOCUSING | Khóa/tắt màn hình | — | FOCUSING | Không ghi (BR-15, D-08) |
| FOCUSING | Bấm tạm dừng + lý do | Còn lượt | PAUSED | Hẹn 5 phút, ghi lý do |
| FOCUSING / PAUSED | `t ≥ last_seen_at + heartbeat_timeout_s` hoặc socket đóng | Chưa báo khóa màn hình (BR-66) | DISCONNECTED | Ghi `disconnected_at`; hẹn LOST tại `disconnected_at + disconnect_hold_s`; nhớ trạng thái trước (BR-19) |
| GRACE | Quay lại app | Trước hạn 3s | FOCUSING | Ghi `grace_recovered`; không kích hoạt D-05 |
| GRACE | Hết 3s | — | EXITED | Ghi thoát, `MEMBER_EXITED` (BR-27), BR-35 |
| GRACE | Mất heartbeat | — | GRACE | Không đổi; xem §3 dòng 1 |
| PAUSED | Bấm tiếp tục | — | FOCUSING | Ghi thời lượng tạm dừng |
| PAUSED | Hết 5 phút | Đang ở app | FOCUSING | — |
| PAUSED | Hết 5 phút | Không ở app | GRACE | Hẹn 3s, không trừ lượt (BR-18) |
| PAUSED | Rời app | — | PAUSED | Không ghi (BR-16) |
| DISCONNECTED | Kết nối lại + `session_id` | `t < disconnected_at + disconnect_hold_s` (BR-65) | trạng thái trước | Ghi `reconnected` |
| DISCONNECTED | `t ≥ disconnected_at + disconnect_hold_s` | — | LOST | Ghi “mất kết nối”; không thông báo người khác; không kích hoạt D-05 (BR-21, D-19) |
| Mọi trạng thái chưa kết thúc | Rút đồng ý | — | WITHDRAWN | Dừng ghi, không báo, không kích hoạt D-05 (BR-26) |
| Mọi trạng thái chưa kết thúc | Quản trị khóa tài khoản | — | WITHDRAWN (`reason = ACCOUNT_LOCKED`) | Dừng ghi, không báo như thoát, không kích hoạt D-05; **không** rời nhóm (BR-108) |
| FOCUSING / PAUSED / GRACE (chưa quá hạn) | Đến `ends_at` | — | COMPLETED | Tính phút; Coins = 0 nếu `forfeited` |
| Mọi trạng thái chưa kết thúc | Phiên CANCELLED | Không phải BR-30 | VOID | Không phạt, không Coins (BR-30 thì ghi ABSENT, không VOID) |

### 3. Bảng quyết định — tình huống chồng chéo

| # | Trạng thái lúc xảy ra | Sự kiện | Kết quả | Kích hoạt D-05? |
| --- | --- | --- | --- | --- |
| 1 | GRACE | Mất kết nối | Hạn 3s vẫn chạy trên server. Nối lại trong 3s và báo đang ở app → FOCUSING; không → EXITED (không chuyển DISCONNECTED, tránh lách bằng tắt mạng) **(đề xuất, Q-30)** | Chỉ khi thành EXITED |
| 2 | DISCONNECTED | Nối lại, báo đã rời app lúc mất mạng | Áp BR-11/BR-13 tính từ lúc nối lại (server không tin mốc client) | Chỉ khi thành EXITED |
| 3 | PAUSED | Rời app / thoát app | Không tính (BR-16) | Không |
| 4 | PAUSED | Hết 5 phút khi không ở app | GRACE 3s không trừ lượt → về app: FOCUSING; không: EXITED | Chỉ khi thành EXITED |
| 5 | PAUSED | Đến `ends_at` | COMPLETED; phút tạm dừng không tính | Không |
| 6 | GRACE | Đến `ends_at` | COMPLETED (chưa quá hạn tại `ends_at`) **(giả định)** | Không |
| 7 | DISCONNECTED | Đến `ends_at` | Chưa chốt tại `ends_at`; nối lại khi `t < disconnected_at + disconnect_hold_s` → COMPLETED (phút tính đến `disconnected_at`); không → LOST. Cùng một mốc gốc như BR-19, không có hạn riêng `ends_at + 10s` **(đề xuất, Q-31)** | Không |
| 8 | DISCONNECTED | Sự cố server xác nhận (BR-22) | VOID — không phạt; gỡ `forfeited` | Không (gỡ nếu có) |
| 9 | GRACE | Rời app lần nữa (sự kiện trùng) | Bỏ qua — idempotent (BR-31) | Không |
| 10 | Bất kỳ | Cùng `event_id` gửi lại | Bỏ qua, trả kết quả cũ | Không |
| 11 | GRACE | `return` và `grace_timeout` gần như cùng lúc | Theo thời điểm server nhận (BR-33); `return` trước hạn thì thắng | Chỉ khi timeout thắng |
| 12 | Trạng thái kết thúc | Sự kiện mới | Bỏ qua (BR-32) | Không |
| 13 | FOCUSING | Bấm tạm dừng khi đã hết lượt | Từ chối, giữ FOCUSING | Không |
| 14 | GRACE | Bấm tạm dừng | Không cho (phải về app trước) **(giả định)** | — |
| 15 | Bất kỳ chưa kết thúc | Rút đồng ý | WITHDRAWN, ưu tiên hơn mọi hạn đang chạy | Không (BR-26) |
| 16 | INVITED | Muốn vào khi đang ở phiên khác (chốt chặn kỹ thuật; gần như không xảy ra theo D-21, D-25) | Từ chối (BR-09) | — |
| 17 | FOCUSING | Khóa màn hình rồi mở khóa và rời app | Tính rời app từ lúc rời app (BR-15) | Chỉ khi thành EXITED |
| 18 | (Hủy — D-25) | Chủ nhóm không tham gia phiên nên không có ca chủ nhóm EXITED. Chủ nhóm thử vào phòng chờ phiên nhóm mình → từ chối (BR-114) | — | — |
| 19 | `forfeited = false` | Hai người EXITED gần như cùng lúc | Người server nhận trước là khởi phát (tên trong `SESSION_FORFEITED`); người sau ghi EXITED thường, chỉ gửi `MEMBER_EXITED` (BR-39). Cả hai đều tính “số lần thoát” | Có (một lần) |
| 20 | `forfeited = true` | Thêm người EXITED | Ghi + gửi `MEMBER_EXITED`; không đổi người khởi phát | Đã kích hoạt |
| 21 | `forfeited = true` | Người khác đang FOCUSING đến `ends_at` | COMPLETED, phút được tính, Coins = 0, ngắt chuỗi | Đã kích hoạt |
| 22 | GRACE → quay lại trước 3s | — | FOCUSING, không ghi thoát | **Không** (BR-12) |
| 23 | Chỉ có LOST, không ai EXITED | Đến `ends_at` | Người LOST: 0 Coins; người COMPLETED: Coins bình thường (D-19) | Không (D-19) |
| 24 | LOST xảy ra trước, sau đó người khác EXITED | — | `forfeited = true` do EXITED; người LOST nằm trong phạm vi BR-37 (ngắt chuỗi) **(đề xuất, Q-27)** | Có (do EXITED, không do LOST) |
| 25 | INVITED | Vào muộn sau `forfeited_at` | Cảnh báo “phiên đã mất thưởng”; vào thì chịu BR-37 **(đề xuất, Q-41)** | Đã kích hoạt |
| 26 | `forfeited = true` | Một người rút đồng ý sau đó | WITHDRAWN, rời nhóm, không Coins; **vẫn bị ngắt chuỗi** vì đã ở trong phiên khi `forfeited` (BR-37, D-23) | Đã kích hoạt |
| 26b | `forfeited = false` | Rút đồng ý, sau đó người khác EXITED | WITHDRAWN trước `forfeited_at` → không bị ảnh hưởng (BR-37) | Có (với người khác) |
| 27 | Người duy nhất trong phiên | EXITED | `forfeited = true`; phạm vi chỉ có chính người đó | Có |
| 28 | `forfeited = true` | Phiên CANCELLED do sự cố trước `ends_at` | VOID cho mọi người chưa kết thúc; gỡ `forfeited`; EXITED đã ghi vẫn giữ là sự kiện và **giữ ngắt chuỗi của chính người EXITED** (BR-68), không ngắt chuỗi người khác **(giả định, Q-14, Q-123)** | Gỡ |
| 29 | GRACE | Quay lại đúng 3,000s sau khi rời app | Quá hạn (BR-65) → EXITED | Có |
| 30 | INVITED | Vào phiên đúng 5:00 sau `started_at` | Quá hạn vào muộn (BR-65) → từ chối, ABSENT | Không |
| 31 | WAITING (COUNTDOWN) | Rời app, đến `started_at` vẫn chưa quay lại | GRACE từ `started_at`, trừ lượt (BR-64) | Chỉ khi thành EXITED |
| 32 | Mọi người INVITED | Không ai vào đến hết hạn vào muộn | ABSENT cho tất cả, phiên CANCELLED `NO_ATTENDEE`, không VOID (BR-30) | Không |
| 33 | Bất kỳ chưa kết thúc | Quản trị khóa tài khoản | WITHDRAWN (`ACCOUNT_LOCKED`), không rời nhóm (BR-108) | Không |
| 34 | Bất kỳ chưa kết thúc | Chủ nhóm xóa người đó khỏi nhóm | Không đổi gì trong phiên; xóa có hiệu lực sau `ends_at` (BR-77) | Theo diễn biến phiên |
| 35 | Phiên COUNTDOWN/ACTIVE | Chủ nhóm hoặc quản trị giải tán nhóm | Phiên chạy đến `ends_at` bình thường; giải tán sau đó (BR-80) | Theo diễn biến phiên |
| 36 | Bất kỳ chưa kết thúc | Bấm đăng xuất / máy thứ hai đăng nhập | Chặn đăng xuất; máy hai không chiếm phiên (BR-70) | Không |
| 37 | `forfeited = true`, sau `ends_at` | Khiếu nại của người khởi phát được miễn trừ, không còn EXITED nào khác | Gỡ `forfeited`, khôi phục Coins/chuỗi hồi tố cho phạm vi BR-37 (BR-87, BR-88) | Gỡ |
| 38 | `forfeited = true`, có A (khởi phát) và B cùng EXITED | Chỉ A được miễn trừ | Vẫn `forfeited`; khởi phát chuyển sang B (BR-87) | Giữ |
| 39 | Phiên CANCELLED do sự cố | Khiếu nại EXITED trước sự cố được miễn trừ | Khôi phục chuỗi cá nhân của người đó (BR-88); không Coins (phiên hủy) | — |
| 40 | Khóa màn hình (đã báo), mất heartbeat | Chưa mở khóa | Không DISCONNECTED cho đến khi mở khóa hoặc `ends_at` (BR-66) | Không |
| 41 | DISCONNECTED | Nối lại đúng `disconnected_at + 10,000s` | Quá hạn (BR-65) → LOST | Không |
| 42 | FOCUSING, heartbeat cuối lúc T | Không gói nào tới | DISCONNECTED tại T+10s; LOST tại T+20s (mặc định) (BR-19) | Không |
| 43 | Khóa màn hình (đã báo) | Mở khóa, sau đó không heartbeat | `last_seen_at` = lúc báo mở khóa; DISCONNECTED sau 10s từ đó (BR-66) | Không |
| 44 | DISCONNECTED | Sự cố toàn server được xác nhận trong lúc giữ chỗ | VOID (BR-22), hủy hẹn LOST | Không |
| 53 | WAITING (ở phòng chờ V-06, phiên SCHEDULED hoặc đã COUNTDOWN, trước `started_at`) | Bấm "Rời phiên" + xác nhận | ABSENT; không áp BR-64 (BR-118 (2)) **(giả định, Q-149)** | Không |
| 54 | GRACE / PAUSED | Bấm "Rời phiên" + xác nhận | EXITED ngay, hủy hẹn đang chạy (BR-118 (1), D-29) | Có (nếu `forfeited = false`) |
| 55 | GRACE | `session:leave` và `grace_timeout` gần như cùng lúc | Sự kiện server nhận trước thắng (BR-33); kết quả đều EXITED, chỉ một bản ghi | Có (một lần) |
| 56 | DISCONNECTED | Bấm "Rời phiên" khi không có mạng | Không gửi, không xếp hàng; diễn biến theo BR-19 (LOST nếu không nối lại) | Không |
| 57 | Bất kỳ chưa kết thúc | Bấm "Rời phiên" rồi hủy hộp xác nhận | Không ghi gì; hạn đang chạy vẫn chạy | Không |
| 45 | EXITED trước sự cố | Phiên CANCELLED do sự cố | Giữ EXITED + ngắt chuỗi; thông báo riêng (BR-68) | Gỡ cấp phiên |
| 46 | Người nhận đang FOCUSING | Có `MEMBER_EXITED` của người khác | Banner trong app nếu đang ở tiền cảnh; nếu đang khóa màn hình thì chỉ hiện khi mở khóa/quay lại — không push hệ thống (BR-82) **(đề xuất, Q-87)** | Theo người thoát |
| 47 | Người nhận đang GRACE / PAUSED | Có `MEMBER_EXITED` | Không gửi gì ra ngoài app; hiện khi quay lại app (BR-82) | Theo người thoát |
| 48 | Thành viên nhóm không tham gia phiên (ABSENT) hoặc chủ nhóm (không bao giờ tham gia, D-25) | Có `MEMBER_EXITED` | Nhận push + hộp thông báo ngay (BR-27) | — |
| 49 | Người đã kết thúc trong phiên (EXITED/LOST/COMPLETED trước) | Người khác EXITED sau đó | Vẫn nhận `MEMBER_EXITED` qua push + hộp thông báo (BR-27) | Theo người thoát |
| 50 | WITHDRAWN (đã rời nhóm) | Người khác EXITED sau đó | Không nhận (không còn là thành viên); vẫn bị ngắt chuỗi nếu sau `forfeited_at` (D-23) | — |
| 51 | GRACE | Mất kết nối, hết 3s trên server | EXITED (§3 #1) → gửi `MEMBER_EXITED` dù người đó đang mất mạng | Có |
| 52 | DISCONNECTED | Server sự cố đúng lúc người đó sắp LOST | Sự cố thắng nếu xác nhận trước mốc LOST (BR-33); ngược lại LOST giữ nguyên, phiên vẫn hủy (BR-22) | Không |

### 4. Sự kiện hệ thống → ai được báo

Chỉ có chế độ báo **ngay**; không có `notify_mode`, không có bản gộp cuối phiên (D-20). "Cả nhóm" = mọi thành viên hiện tại kể cả chủ nhóm; "cả phiên" = mọi thành viên có trạng thái trong phiên (chủ nhóm không có trạng thái, D-25; chủ nhóm luôn nhận qua push + hộp thông báo). Kênh cho người đang trong phiên: BR-82. Thành viên luôn thấy đúng dữ liệu chủ nhóm thấy về mình (GĐ1 §6).

| Sự kiện | Ghi vào hồ sơ phiên? | Báo chủ nhóm? | Báo người khác? | Ghi chú |
| --- | --- | --- | --- | --- |
| Vào phòng chờ / vào phiên | Có | Không | Không | |
| Vào muộn | Có | Không (chỉ báo cáo) | Không | Q-18 |
| Vắng (ABSENT) | Có | Không (chỉ báo cáo) | Không | Q-18 |
| Rời app → GRACE | Có (nội bộ) | Không | Không | |
| `grace_recovered` | Có | Không | Không | |
| EXITED | Có | **Có**, ngay, có tên (`MEMBER_EXITED`) | **Có**, ngay, có tên — cả nhóm + cả phiên, trừ chính người thoát (BR-27) | D-05, D-20, D-22 |
| Phiên chuyển `forfeited = true` | Có (cấp phiên) | Có, gộp trong cùng thông báo EXITED đầu tiên (`SESSION_FORFEITED`, có tên khởi phát) | Như chủ nhóm | BR-38; D-22 |
| Tạm dừng có lý do | Có (lý do) | Không push; chỉ thấy ở chi tiết phiên/báo cáo (D-20; Q-32 đã đóng) | Không | Q-11 |
| DISCONNECTED (tạm) | Có (nội bộ) | Không | Không | |
| LOST | Có | Không push; chi tiết phiên/báo cáo tách khỏi “thoát” | Không | D-19 |
| COMPLETED | Có | Không | Không | Kết quả ở `SESSION_RESULT` cho chính người đó |
| WITHDRAWN | Có (chỉ “rời nhóm”) | Không như thoát; chỉ thấy thành viên đã rời nhóm | Không | Q-20 |
| Phiên CANCELLED do sự cố | Có | Có — `SESSION_CANCELLED_OUTAGE`, không nêu cá nhân | Có, cả phiên (người EXITED trước sự cố nhận `SESSION_CANCELLED_OUTAGE_EXITED`, BR-68) | D-19 |
| Giải trình sau phiên | Có | Hiện kèm sự kiện EXITED, thông báo trong app (BR-85) | Không | Q-16 |
| ~~Sự kiện của chủ nhóm (khi tham gia)~~ | (Hủy — D-25: chủ nhóm không tham gia phiên) | — | — | D-25 |

### 5. Tham số cấu hình được

| Tham số | Mặc định | Cấp cấu hình | Nguồn |
| --- | --- | --- | --- |
| `duration` | {25, 50} phút | **Cố định** (không cấu hình ở MVP) | BR-02 |
| `countdown_s` | 5 | Admin | BR-04 (COUNTDOWN bắt đầu `started_at − countdown_s`) |
| `late_join_max_min` | 5 | Admin | BR-07, Q-18 |
| `grace_s` | 3 | Admin | BR-11 |
| `grace_max_per_session` | 1 | Admin | BR-13, Q-10 |
| `pause_max_count` | 1 | Admin | BR-16, Q-11 |
| `pause_max_min` | 5 | Admin | BR-16, Q-11 |
| `pause_reasons` | danh sách chọn sẵn | Admin | BR-16 |
| `heartbeat_s` | 5 | Admin | BR-19 |
| `disconnect_hold_s` | 10 (tính từ `disconnected_at`) | Admin | BR-19, Q-14 |
| `outage_ratio` / `outage_window_s` | 80% / 10s | Admin | BR-22, Q-28 |
| ~~`notify_mode`~~ | — | (Hủy — D-20: chỉ báo ngay) | BR-27 |
| `lobby_open_min` | 10 | Admin | BR-63, Q-83 |
| `heartbeat_timeout_s` | 10 (= 2 × `heartbeat_s`) | Admin | BR-66, Q-86 |

Miền giá trị hợp lệ của mọi tham số: xem §Quản trị BR-112.

---

## §Thưởng (T-BA-12)

Nguyên tắc: Coins, điểm danh, chuỗi, huy hiệu chỉ là **ghi nhận tích cực**; không cược, không mua lợi thế, không nạp tiền thật (D-01, D-03). Ngày tính theo **Asia/Ho_Chi_Minh** (UTC+7), mốc 00:00 **(giả định)**. Một phiên thuộc ngày của `started_at`.

### 1. Quy tắc

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-40 | Coins phiên chỉ được ghi khi phiên COMPLETED (tại `ends_at`), cho thành viên **hoàn thành có thưởng** (COMPLETED và phiên không `forfeited`, D-11). Mức cơ bản: 25 phút = 10 Coins, 50 phút = 25 Coins. | `coins_25 = 10`, `coins_50 = 25` (có) | D-09; GĐ1 §4.5 | EP-06 |
| BR-41 | Phiên `forfeited = true` → **0 Coins cho mọi người** trong phạm vi BR-37; không ghi dòng sổ cái nào (kết quả phiên hiển thị lý do “mất thưởng tập thể”). | — | D-05 | EP-06 |
| BR-42 | Vào muộn: Coins = `floor(mức cơ bản × phút có mặt / duration)`, phút có mặt tính từ lúc vào đến `ends_at`. Thời gian tạm dừng hợp lệ **không** làm giảm Coins **(đề xuất, Q-18, Q-45)**. | — | Q-18; Q-45 | EP-06 |
| BR-43 | Trần 100 Coins/người/ngày (tính trên mọi SESSION_REWARD của người đó trong ngày; theo D-21 thực tế là các phiên của một nhóm). Phiên làm vượt trần chỉ ghi phần còn lại đến trần; khi đã đạt trần, phiên sau ghi 0 và hiện “đã đạt trần ngày”. | `coins_daily_cap = 100` (có) | D-09 | EP-06 |
| BR-44 | **Sổ cái Coins bất biến** (xem `05-tham-chieu-ky-thuat.md` §3): mỗi thay đổi là một dòng chỉ-thêm gồm `entry_id`, `user_id`, `amount` (±), `type ∈ {SESSION_REWARD, SHOP_PURCHASE, ADMIN_ADJUST}`, `ref_id` (phiên/đơn hàng), `reward_date` (ngày tính trần, chỉ cho SESSION_REWARD — ngày của `started_at`), `created_at`, `reason`. Không UPDATE/DELETE; sửa sai bằng dòng bù trừ. Số dư = tổng `amount`. | — | D-09; `05-tham-chieu-ky-thuat.md` §3 | EP-06, EP-09 |
| BR-45 | Chống ghi trùng: khóa duy nhất (`type`, `ref_id`, `user_id`) cho SESSION_REWARD. Số dư không bao giờ âm; mua hàng thiếu Coins bị từ chối. ADMIN_ADJUST bắt buộc có lý do và ghi nhật ký truy cập. | — | D-09; NFR | EP-06, EP-09 |
| BR-46 | **Điểm danh:** một ngày là “đã điểm danh” nếu người dùng có ≥1 phiên **hoàn thành** (COMPLETED, D-11) trong ngày, **kể cả phiên `forfeited`** (người đó đã có mặt và tập trung đủ). Không cần hoàn thành có thưởng. Tối đa 1 điểm danh/ngày (D-11; phần “ngày” theo Q-17 vẫn là đề xuất). Theo D-21, điểm danh cấp người dùng và điểm danh trong nhóm (§Báo cáo §2) trùng nhau với thành viên; chỉ khác với người đổi nhóm trong tháng. Chủ nhóm không điểm danh qua phiên nhóm mình quản lý (D-25); chỉ điểm danh qua phiên của nhóm mà người đó là thành viên (nếu có). | — | GĐ1 §4.4; D-11; D-21; Q-17; Q-39 | EP-05, EP-08 |
| BR-47 | **Ngắt chuỗi** (chuỗi = 0 ngay khi xảy ra) khi người dùng: (a) EXITED ở bất kỳ phiên nào; hoặc (b) nằm trong phạm vi BR-37 của một phiên `forfeited` (D-05, áp dụng tại `ends_at` của phiên đó). | — | D-05; GĐ1 §4.3 | EP-05 |
| BR-48 | **Không ngắt chuỗi:** ABSENT, WITHDRAWN, VOID (sự cố), ngày không có lịch của nhóm người đó, và LOST **(đề xuất, Q-27)** — LOST không cộng chuỗi, không ngắt chuỗi. **Ngoại lệ:** LOST **(đề xuất, Q-27)** và WITHDRAWN sau `forfeited_at` (D-23) trong phiên `forfeited` (do người khác EXITED) thì bị ngắt theo BR-37/BR-47(b). | — | Q-17; Q-27; D-23 | EP-05 |
| BR-49 | **Chuỗi +1:** tối đa 1 lần/ngày, khi người dùng có phiên **hoàn thành có thưởng** (D-11) trong ngày. Ngày có lịch nhưng không phiên nào đạt (chỉ vắng) thì giữ nguyên chuỗi **(đề xuất, Q-17)**. | — | Q-17 | EP-05 |
| BR-50 | Thứ tự trong cùng ngày: xử lý theo thời điểm server. Ngắt sau khi đã +1 → chuỗi = 0. Ngắt rồi sau đó có phiên đạt BR-49 cùng ngày → chuỗi = 1 (bắt đầu lại) **(đề xuất, Q-40)**. | — | Q-40 | EP-05 |
| BR-51 | Chuỗi chỉ cho huy hiệu, **không cộng Coins** **(đề xuất, Q-17)**. Hệ thống lưu `current_streak` và `longest_streak`; `longest_streak` không giảm. | — | Q-17 | EP-05 |
| BR-52 | **Huy hiệu thành tích** (Must) cấp tự động, một lần, không bị thu hồi khi chuỗi ngắt. Mốc mặc định **(đề xuất, Q-132)**: chuỗi 3/7/14/30/60/100 ngày; số phiên **hoàn thành có thưởng** 10/50/100/500; tổng giờ tập trung (BR-89) 10/50/100. Huy hiệu bán trong Shop là Could **(đề xuất, Q-38)**. | `badge_milestones` (có) | GĐ1 §4.4; Q-38 | EP-05, EP-06 |
| BR-53 | **Chủ nhóm thấy gì về thưởng:** (a) **không** thấy Coins **(đề xuất, Q-23)**; (b) **không** thấy chuỗi (`current_streak`, `longest_streak`, lịch sử/lý do ngắt chuỗi) ở bất kỳ màn, API, thông báo, báo cáo, email hay PDF nào — kể cả khi thành viên tự bật hiện chuỗi trên hồ sơ, chủ nhóm xem với tư cách chủ nhóm cũng không có trường chuỗi trong dữ liệu quản lý (D-12); (c) chỉ thấy **điểm danh và kết quả phiên tính trên phiên của nhóm mình** (BR-46 giới hạn trong nhóm, §Báo cáo §2). Chuỗi chỉ hiện cho chính người dùng và trên phần công khai nếu họ tự bật (BR-99). API trả cho chủ nhóm không chứa trường chuỗi (kiểm tra bằng schema phản hồi). | — | D-12; Q-23 | EP-05, EP-06, EP-08 |
| BR-54 | Giải trình sau phiên không hoàn Coins, không khôi phục chuỗi **(đề xuất, Q-16, Q-37)**. Chỉ **khiếu nại được chấp nhận** mới khôi phục (BR-87, BR-88). | — | Q-16 | EP-04, EP-05 |
| BR-89 | **Tổng giờ tập trung cho huy hiệu** = tổng phút tập trung (BR-23) của mọi phiên người đó COMPLETED, **kể cả phiên `forfeited`**; **không** tính phần đã tập trung trước khi EXITED/LOST. Cấp người dùng, gồm cả phiên ở nhóm cũ đã rời (D-21). Khác chỉ số “tổng phút tập trung” trong báo cáo tháng (có tính phần trước EXITED/LOST) — hai chỉ số phải đặt tên khác nhau trên giao diện **(đề xuất, Q-127)**. | — | BR-52; Q-127 | EP-05 |
| BR-90 | **Đổi `badge_milestones`:** mốc mới được xét **hồi tố** trong lần tính kế tiếp (chậm nhất job 00:05 hằng ngày): ai đã vượt mốc mới thì được cấp, `awarded_at` = lúc cấp. Mốc bị bỏ không thu hồi huy hiệu đã cấp (BR-52) **(đề xuất, Q-125)**. | — | BR-52; Q-125 | EP-05, EP-09 |
| BR-91 | **Thông báo thưởng:** không gửi push hệ thống về Coins/chuỗi/huy hiệu trong lúc phiên chạy. Ngắt chuỗi do D-05 được **gộp** vào một push duy nhất tại `ends_at` (“Phiên mất thưởng tập thể — chuỗi bị ngắt”) **(đề xuất, Q-93)**. Nhận huy hiệu chỉ thông báo trong app **(đề xuất, Q-95)**. Chi tiết ở màn kết quả phiên. | — | Q-93; Q-95 | EP-04, EP-05 |
| BR-92 | **Nhật ký thành tích chỉ-thêm** (cùng tinh thần BR-44): mọi thay đổi chuỗi/điểm danh/huy hiệu ghi một dòng `entry_id`, `user_id`, `kind ∈ {CHECKIN, STREAK_INC, STREAK_BREAK, STREAK_RESTORE, BADGE_AWARD}`, `value_before`, `value_after`, `day`, `ref_session_id`, `created_at`, `reason`. Không UPDATE/DELETE; `current_streak`/`longest_streak` phải tái lập được bằng cách phát lại nhật ký. Lưu đến khi xóa tài khoản (BR-72). | — | BR-44; 04 §4 | EP-05 |

### 2. Bảng quyết định — thưởng theo kết quả phiên

| Trạng thái cuối của người | Phiên `forfeited`? | Coins | Điểm danh | Chuỗi |
| --- | --- | --- | --- | --- |
| COMPLETED — hoàn thành có thưởng | Không | Theo BR-40/42/43 | Có | +1 (nếu chưa +1 hôm đó) |
| COMPLETED — hoàn thành, không thưởng | Có | 0 | Có (D-11) | Ngắt |
| EXITED | bất kỳ (luôn Có) | 0 | Không (từ phiên này) | Ngắt |
| LOST | Không | 0 | Không | Giữ nguyên **(Q-27)** |
| LOST | Có (do người khác EXITED) | 0 | Không | Ngắt **(Q-27)** |
| ABSENT / VOID / WITHDRAWN (trước `forfeited_at` hoặc do khóa tài khoản) | bất kỳ | 0 | Không | Giữ nguyên |
| WITHDRAWN (rút đồng ý/rời nhóm) sau `forfeited_at` | Có | 0 | Không | Ngắt (D-23) |
| EXITED **được miễn trừ** (BR-87) | Không (sau tính lại) | Như COMPLETED, ghi hồi tố (BR-88) **(Q-124)** | Có | Khôi phục (BR-88) |
| EXITED được miễn trừ (BR-87) | Vẫn Có (còn EXITED khác) | 0 | Có **(Q-124)** | Ngắt (theo BR-37) |

### 3. Tham số

| Tham số | Mặc định | Cấp | Nguồn |
| --- | --- | --- | --- |
| `coins_25` / `coins_50` | 10 / 25 | Admin | D-09 |
| `coins_daily_cap` | 100 | Admin | D-09 |
| `day_timezone` | Asia/Ho_Chi_Minh | **Cố định** (BR-112) | (giả định) |
| `badge_milestones` | như BR-52 | Admin | Q-38, BR-90 |

---

## §Báo cáo (T-BA-15)

### 1. Quy tắc

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-55 | Kỳ báo cáo = **tháng dương lịch** theo Asia/Ho_Chi_Minh: [00:00 ngày 1, 00:00 ngày 1 tháng sau) (nửa mở, BR-65). Phiên thuộc tháng của `started_at`. | `report_timezone` (**không** cấu hình) | GĐ1 §4.8 | EP-08 |
| BR-56 | Báo cáo tạo tự động lúc 02:00 **(đề xuất, Q-132)** ngày 1 tháng sau (sau khi chốt chuỗi ngày cuối), mỗi nhóm một báo cáo; số liệu đã tạo không đổi (bản chụp). Giải trình thêm sau khi tạo: xem BR-102. Lỗi khi tạo: BR-101. | `report_run_at = 02:00` (có) | GĐ1 §8, §11 | EP-08 |
| BR-57 | Người nhận: **chủ nhóm** của nhóm tại thời điểm tạo (D-10), qua app và email tóm tắt không kèm PDF (D-24, BR-105). Báo cáo không có chỉ số chuỗi (D-12, BR-53). Mỗi thành viên xem được dòng của chính mình; xem tổng nhóm chỉ khi nhóm ≥5 người, đếm theo BR-104 **(đề xuất, Q-24)**. Quyền xem kỳ cũ: BR-103. | — | D-10; GĐ1 §6; Q-24 | EP-08 |
| BR-58 | Chỉ tính phiên của **nhóm đó**, có trạng thái phiên COMPLETED; phiên CANCELLED (kể cả do sự cố) không vào mẫu số hay tử số. | — | — | EP-08 |
| BR-59 | Thành viên vào nhóm giữa tháng: chỉ tính phiên từ ngày vào; dòng ghi “vào ngày dd/mm”. Rời nhóm giữa tháng: giữ số liệu đến ngày rời, ghi “rời ngày dd/mm”, không ghi mới **(đề xuất, Q-20)**. Mọi chỉ số của dòng chỉ dùng phiên **của nhóm này** trong khoảng là thành viên; không dùng chỉ số cấp người dùng (chuỗi, tổng giờ huy hiệu) để tránh lộ hoạt động nhóm khác (D-12). | — | Q-20; D-12 | EP-08 |
| BR-60 | Báo cáo **không** có dòng cho chủ nhóm (chủ nhóm không tham gia phiên, D-25); chỉ có dòng thành viên. Mọi chỉ số nhóm (§3) không tính chủ nhóm. Người vừa là chủ nhóm B vừa là thành viên nhóm A (D-21) chỉ có dòng trong báo cáo nhóm A. Kiểm tra: báo cáo của nhóm có N thành viên trong kỳ có đúng N dòng, không dòng nào mang `user_id` của chủ nhóm. *(Sửa 2026-10-19.)* | — | D-25 | EP-08 |
| BR-115 | **Thứ tự hiển thị — không xếp hạng ngầm** (D-03): mọi danh sách người trong nhóm (dòng báo cáo tháng trong app/PDF, danh sách thành viên nhóm, danh sách người trong phiên, màn chi tiết phiên của chủ nhóm, màn kết quả phiên) sắp **theo tên hiển thị tăng dần** (so sánh không phân biệt hoa/thường, theo thứ tự chữ cái tiếng Việt), trùng tên thì theo **thời điểm vào nhóm** (sớm trước), vẫn trùng thì theo `user_id` (T-BA-126). **Ngoại lệ 1:** ở danh sách thành viên nhóm, dòng chủ nhóm hiện đầu tiên (theo vai trò, không theo chỉ số), các thành viên sắp như trên. **Ngoại lệ thứ hai** (T-BA-134): danh sách **sự kiện** — người rời app trong một phiên (màn chi tiết phiên của chủ nhóm, AC-08.10.1, AC-08.10.9), banner, hộp thông báo — sắp theo **giờ server** của sự kiện; đây là thứ tự thời gian, không phải danh sách người theo chỉ số nên không là xếp hạng. **Không** cho sắp/lọc theo bất kỳ chỉ số nào (phút, số lần thoát, tỉ lệ…); không tô màu/biểu tượng "cao nhất/thấp nhất"; không hiện số thứ tự hạng. Báo cáo đã tạo dùng tên tại lúc tạo (BR-97). **(đề xuất, Q-143)** *(Mới 2026-10-19, S4.)* | — | D-03; GĐ1 §6; Q-143 | EP-02, EP-03, EP-08 |
| BR-61 | Báo cáo không có Coins **(đề xuất, Q-23)**, không có tên app/nội dung máy (BR-34). EXITED kèm giải trình nếu có (Q-16). Hiển thị thông báo mục đích báo cáo **(đề xuất, Q-12)**. | — | Q-12, Q-23 | EP-08 |
| BR-62 | Nhóm giải tán giữa tháng: tạo báo cáo cho phần tháng đến ngày giải tán, gửi cho người từng là chủ nhóm **(đề xuất, Q-44)**. | — | Q-34; Q-44 | EP-08 |
| BR-101 | **Lỗi tạo báo cáo:** lần chạy thất bại được tự chạy lại tối đa `report_retry_max` lần, cách nhau 1 giờ, không quá `report_retry_deadline`. Tạo báo cáo idempotent theo khóa (nhóm, kỳ): không bao giờ có hai báo cáo cho cùng (nhóm, kỳ). Quá hạn vẫn lỗi → cảnh báo quản trị (hộp việc quản trị + log); quản trị chạy lại thủ công được **(đề xuất, Q-115)**. | `report_retry_max = 3`, `report_retry_deadline = 06:00` (có) | Q-115 | EP-08, EP-09 |
| BR-102 | **Bản chụp và giải trình:** số liệu đã tạo (và PDF nếu có, Should) không đổi (BR-56). Giải trình gửi/sửa **sau** lúc tạo báo cáo vẫn hiện khi xem báo cáo **trong app**, gắn nhãn “thêm sau khi tạo báo cáo”; PDF đã tạo không đổi. Miễn trừ sau khi tạo (BR-87) cũng chỉ hiện dạng ghi chú trong app, không sửa số liệu **(đề xuất, Q-112)**. *(Giải quyết xung đột BR-56 vs NFR-P10.)* | — | NFR-P10; Q-112 | EP-04, EP-08 |
| BR-103 | **Xem kỳ cũ:** chủ nhóm hiện tại của nhóm xem được mọi báo cáo của nhóm trong thời hạn lưu (13 tháng). Thành viên — kể cả đã rời nhóm — xem được **dòng của chính mình** ở các kỳ mình có dòng, trong thời hạn lưu **(đề xuất, Q-113)**. Người từng là chủ nhóm của nhóm đã giải tán xem được báo cáo cuối (BR-62). Mỗi lần chủ nhóm mở báo cáo ghi nhật ký truy cập (BR-73). | `retention_months = 13` (có) | Q-25; Q-113 | EP-08 |
| BR-104 | **Ngưỡng xem tổng nhóm:** đếm số **thành viên** (không gồm chủ nhóm) đang trong nhóm **tại lúc tạo báo cáo**; ≥ `group_report_min_members` thì thành viên được xem tổng nhóm của kỳ đó. Kết quả đếm lưu cùng bản chụp, không đổi khi sĩ số đổi sau đó **(đề xuất, Q-110)**. | `group_report_min_members = 5` (có) | Q-24; Q-110 | EP-08 |
| BR-105 | **Email báo cáo (Must, D-24):** sau khi tạo, gửi email (SES) cho chủ nhóm với **nội dung tóm tắt** trong thân thư: tên nhóm, kỳ, mục đích sử dụng báo cáo của nhóm (khớp AC-08.08.1), số phiên đã diễn ra, tỉ lệ hoàn thành phiên, tỉ lệ hoàn thành có thưởng, số phiên bị mất thưởng tập thể, so với tháng trước (§3), và link mở báo cáo trong app (yêu cầu đăng nhập). **Không** đính kèm PDF, **không** có dòng từng thành viên, không chuỗi/Coins (BR-53). Kỳ không có dữ liệu vẫn gửi email ngắn “không có phiên trong kỳ”. MVP không cho tắt email **(đề xuất, Q-114)**. Gửi lỗi: thử lại tối đa 3 lần trong 24 giờ, sau đó chỉ còn bản trong app **(giả định)**. **PDF (Should, D-24):** chỉ tải trong app; link tải ký hạn hết hạn sau `report_link_app_min` **(đề xuất, Q-111)**. | `report_link_app_min = 15` (có) | D-24; Q-111; Q-114 | EP-08 |

### 2. Định nghĩa chỉ số — mỗi thành viên (trong nhóm, trong kỳ)

| Chỉ số | Định nghĩa chính xác |
| --- | --- |
| Số ngày điểm danh (trong nhóm) | Số ngày khác nhau trong kỳ có ≥1 phiên **của nhóm này** mà người đó **hoàn thành** (COMPLETED, kể cả `forfeited`; D-11) **(đề xuất, Q-43)**. Chỉ đếm phiên của nhóm này; có thể khác “điểm danh” cấp người dùng (BR-46) khi người đó đổi nhóm trong tháng (D-21) |
| Số phiên hoàn thành | Số phiên của nhóm mà người đó **hoàn thành** (COMPLETED, kể cả `forfeited`; D-11) |
| Trong đó: hoàn thành có thưởng | Số phiên **hoàn thành có thưởng** (COMPLETED và phiên không `forfeited` tại lúc tạo báo cáo; D-11) |
| Tổng phút tập trung | Tổng phút FOCUSING (+GRACE đã hồi phục), không gồm PAUSED, của mọi phiên COMPLETED **và** phần đã tập trung trước khi EXITED/LOST **(giả định)**; làm tròn xuống phút |
| Số lần thoát | Số phiên có trạng thái cuối EXITED |
| Số lần gây mất thưởng tập thể | Số phiên mà người đó là `forfeit_trigger_user_id` (chỉ người khởi phát, BR-35) **(đề xuất, Q-42)** |
| Số phiên bị mất thưởng tập thể đã tham gia | Số phiên `forfeited` mà người đó nằm trong phạm vi BR-37 |
| Số lần mất kết nối | Số phiên có trạng thái cuối LOST (tách khỏi thoát) |
| Số lần vắng / vào muộn / tạm dừng | Đếm ABSENT; đếm cờ vào muộn; đếm lần PAUSED (kèm lý do) |
| ~~Chuỗi dài nhất~~ | **Bỏ** khỏi báo cáo (D-12): chuỗi là chỉ số cấp người dùng, chủ nhóm không được thấy. |

### 3. Định nghĩa chỉ số — mỗi nhóm

| Chỉ số | Định nghĩa chính xác |
| --- | --- |
| Số phiên đã diễn ra | Số phiên của nhóm có trạng thái COMPLETED trong kỳ |
| Lượt dự kiến | Tổng (phiên × thành viên là thành viên nhóm tại `started_at`), trừ lượt WITHDRAWN và VOID; **không** tính chủ nhóm (D-25) **(đề xuất, Q-141)** |
| Tỉ lệ hoàn thành phiên | Số lượt **hoàn thành** (COMPLETED, kể cả `forfeited`; D-11) / lượt dự kiến × 100%, làm tròn 1 chữ số thập phân. Không có lượt dự kiến → “không có dữ liệu”. Đây là chỉ số G-01 |
| Tỉ lệ hoàn thành có thưởng | Số lượt **hoàn thành có thưởng** (D-11) / lượt dự kiến × 100%, cùng cách làm tròn |
| Số phiên bị mất thưởng tập thể | Số phiên `forfeited = true`; kèm tỉ lệ trên số phiên đã diễn ra |
| Tổng phút tập trung nhóm | Tổng chỉ số “tổng phút tập trung” của mọi dòng thành viên |
| So với tháng trước | Với mỗi tỉ lệ: chênh lệch **điểm phần trăm** (vd. +5,2 đpt); với số đếm: chênh lệch tuyệt đối. Tháng trước không có báo cáo → “không có dữ liệu so sánh”. Không so sánh từng cá nhân (D-03) |

### 4. Tham số

| Tham số | Mặc định | Cấp | Nguồn |
| --- | --- | --- | --- |
| `report_timezone` | Asia/Ho_Chi_Minh | **Cố định** (BR-112) | BR-55 |
| `report_run_at` | 02:00 | Admin | BR-56 |
| `report_retry_max` / `report_retry_deadline` | 3 / 06:00 | Admin | BR-101, Q-115 |
| `group_report_min_members` | 5 | Admin | BR-104, Q-110 |
| `report_link_app_min` | 15 phút | Admin | BR-105, Q-111 |
| ~~`report_link_email_days`~~ | — | (Hủy — D-24: email không kèm link PDF) | BR-105 |
| `retention_months` | 13 | Admin | BR-103, Q-25 |

---

## §Tài khoản & đồng ý (EP-01)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-71 | **Phiên bản đồng ý của nhóm** tăng 1 khi (và chỉ khi) đổi: mục đích báo cáo, thời hạn lưu dữ liệu, hoặc nội dung điều khoản/quy tắc D-05 do hệ thống công bố. Đổi tên nhóm, lịch, mã mời **không** tăng phiên bản. Thành viên chưa đồng ý lại vẫn là thành viên nhưng không vào được phiên (BR-06). Thay đổi có hiệu lực từ phiên có `started_at` sau lúc lưu; phiên đang chạy giữ giá trị cũ **(đề xuất, Q-72)**. | — | NFR-P04; Q-72 | EP-01, EP-02, EP-04 |
| BR-72 | **Xóa tài khoản:** cần nhập lại mật khẩu; bị chặn khi đang có trạng thái chưa kết thúc trong một phiên (BR-70). Hiệu lực ngay, không thời gian chờ **(đề xuất, Q-69)**. Thứ tự xử lý: (1) rời mọi nhóm là thành viên như rút đồng ý (BR-26); (2) giải tán mọi nhóm mình là chủ nhóm (BR-80); (3) hủy đăng nhập mọi thiết bị; (4) xóa hồ sơ, avatar, nhật ký cá nhân, nhật ký thành tích; (5) sổ cái Coins (BR-44) **không xóa dòng**, thay `user_id` bằng mã ẩn danh **(đề xuất, Q-70)**; (6) dòng của người này trong báo cáo đã tạo hiển thị “Người dùng đã xóa”. Hoàn tất xóa mọi bản (kể cả sao lưu) trong 30 ngày **(đề xuất, Q-25)**. | `account_purge_days = 30` (có) | 04 §4; Q-25; Q-69; Q-70 | EP-01, EP-06, EP-08 |
| BR-73 | **Nhật ký truy cập** (NFR-P07): ghi mỗi lần chủ nhóm/quản trị xem hoặc xuất dữ liệu phiên/báo cáo/sổ cái của một người. Chỉ-thêm (không sửa/xóa qua UI hay API — trả 403/405). Các lượt xem **cùng người xem + cùng đối tượng dữ liệu** trong `access_log_merge_min` phút gộp thành một dòng (đếm số lần). Thành viên xem được nhật ký về mình **(đề xuất, Q-21)**. Xem hồ sơ công khai không ghi **(đề xuất, Q-106)**. Lưu `access_log_retention_months` tháng rồi xóa **(đề xuất, Q-121)**. | `access_log_merge_min = 10`, `access_log_retention_months = 12` (có) | NFR-P07; Q-21; Q-106; Q-121 | EP-01, EP-08, EP-09 |

Quy tắc đăng xuất/nhiều thiết bị trong phiên: BR-70 (§Phiên). Tên hiển thị và avatar: BR-97, BR-98 (§Hồ sơ).

---

## §Nhóm (EP-02)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-74 | **Sĩ số nhóm** (thay mã tạm BR-N1): sĩ số = số **thành viên** đang hoạt động (đã đồng ý, chưa rời), **không gồm chủ nhóm** (D-25) **(đề xuất, Q-141)**. Sàn 4, trần 10 **cố định theo D-02, không cấu hình** ở MVP. Ví dụ: CN + 10 TV là đầy; CN + 9 TV còn 1 chỗ; CN + 3 TV là dưới sàn. **Trần** `group_max_members` chặn cứng, kiểm tra **lúc người được mời bấm đồng ý** (không lúc gửi lời mời). **Sàn** `group_min_members` không chặn: nhóm dưới sàn (lúc tạo hoặc do rời/rút đồng ý/xóa tài khoản/bị xóa) vẫn đặt lịch và chạy phiên; chủ nhóm thấy cảnh báo “Nhóm dưới 4 người — mời thêm” **(đề xuất, Q-68)**. | `group_min_members = 4`, `group_max_members = 10` (**không** cấu hình, D-02) | D-02; Q-68 | EP-01, EP-02, EP-03 |
| BR-75 | **Giới hạn số nhóm (D-21):** (a) Một người là **thành viên** của tối đa **1** nhóm chưa giải tán tại một thời điểm — cố định, không cấu hình. Người đang là thành viên nhóm A nhập mã/nhận lời mời nhóm B: bị từ chối ở bước đồng ý với thông báo “Bạn đang ở nhóm A. Rời nhóm A trước khi tham gia nhóm khác.” Kiểm tra lúc bấm đồng ý (cùng thời điểm BR-74). (b) Một người là **chủ nhóm** của tối đa `max_groups_owned` nhóm chưa giải tán (D-21, D-25 — chủ nhóm chỉ quản lý nên sở hữu nhiều nhóm không xung đột); tạo thêm bị từ chối kèm thông báo. Nhóm mình làm chủ **không** tính vào giới hạn (a). (c) Người đang là thành viên nhóm A vẫn được tạo nhóm B và làm chủ nhóm B; người đó vẫn tham gia phiên nhóm A như thành viên, ở nhóm B chỉ quản lý **(giả định, Q-150)**. Không được tự mời mình làm thành viên nhóm mình làm chủ (từ chối ở bước đồng ý) **(giả định)**. | `max_groups_owned = 10` (có); số nhóm là thành viên = 1 (**không** cấu hình) | D-21; D-25; Q-71; Q-150 | EP-01, EP-02 |
| BR-76 | **Mã mời và lời mời** (thay BR-N3): mã nhóm 8 ký tự chữ-số (bỏ ký tự dễ nhầm), hiệu lực đến khi chủ nhóm đổi mã (mã cũ hết hiệu lực ngay). Lời mời email hết hạn sau `invite_email_ttl_days`. Nhập sai `invite_max_fail` lần trong 15 phút → khóa nhập mã 15 phút cho tài khoản đó. Nhập mã chỉ mở màn đồng ý; tư cách thành viên chỉ có sau khi đồng ý (BR-06, BR-74). Không giới hạn số lời mời đang chờ **(đề xuất, Q-74)**. Người đã rời/bị xóa vào lại phải được mời lại và đồng ý lại **(đề xuất, Q-75)** **(đề xuất, Q-73)**. | `invite_code_len = 8`, `invite_email_ttl_days = 7`, `invite_max_fail = 5`, `invite_lock_min = 15` (có) | Q-73; Q-74; Q-75 | EP-02 |
| BR-77 | **Xóa thành viên giữa phiên** (thay BR-N4): nếu người bị xóa đang có trạng thái chưa kết thúc trong một phiên COUNTDOWN/ACTIVE của nhóm, việc xóa có hiệu lực **sau `ends_at`** của phiên đó; kết quả phiên giữ nguyên (không thành WITHDRAWN, không gỡ/kích hoạt D-05). Ngoài phiên: hiệu lực ngay. Người bị xóa được báo “Bạn không còn trong nhóm X”; dữ liệu theo BR-59 **(đề xuất, Q-76)**. | — | Q-76; D-05 | EP-02, EP-03 |
| BR-78 | **Không chồng phiên trong cùng nhóm** (thay BR-N5): khoảng [giờ bắt đầu, giờ bắt đầu + `duration`) của hai phiên chưa hủy cùng một nhóm không được giao nhau; lưu bị từ chối “Trùng phiên khác của nhóm”. Không kiểm tra trùng với nhóm khác (BR-10 đã hủy), kể cả các nhóm cùng chủ nhóm hoặc nhóm mà chủ nhóm là thành viên (BR-114). | — | D-06; D-21; BR-09 | EP-02 |
| BR-79 | **Khoảng tối thiểu đặt/sửa lịch** (thay BR-N6): giờ bắt đầu của phiên mới hoặc phiên được sửa phải ≥ giờ server + `schedule_min_lead_min`. Sửa/hủy chỉ được khi phiên còn SCHEDULED (trước COUNTDOWN). Lịch lặp theo ngày trong tuần; sửa/hủy chọn “lần này” hoặc “lần này và sau” **(đề xuất, Q-78, Q-79)**. Nhắc thành viên trước giờ phiên `reminder_min` phút **(đề xuất, Q-80)**. | `schedule_min_lead_min = 1`, `reminder_min = 5` (có) | Q-78; Q-79; Q-80 | EP-02, EP-03 |
| BR-113 | **Lịch lặp lại** (US-02.10b, Should): chủ nhóm chọn ngày trong tuần, giờ bắt đầu, thời lượng (BR-02) và **bắt buộc** ngày kết thúc chuỗi; ngày kết thúc ≤ ngày bắt đầu + `recurrence_max_weeks` tuần, vượt bị từ chối kèm thông báo. Mỗi lần lặp là một phiên SCHEDULED riêng, phải qua BR-78 (không chồng phiên trong nhóm) và BR-79; lần lặp vi phạm BR-78 bị từ chối cả chuỗi kèm danh sách ngày trùng **(đề xuất, Q-78)**. | `recurrence_max_weeks = 12` (có) | Q-78 | EP-02 |
| BR-80 | **Giải tán nhóm** (chủ nhóm, hoặc quản trị qua BR-109): nếu nhóm có phiên COUNTDOWN/ACTIVE, nhóm chuyển CHỜ GIẢI TÁN (§Trạng thái nhóm) và giải tán có hiệu lực ngay sau `ends_at` của phiên đó (không ai bị tính thoát/WITHDRAWN do giải tán); phiên SCHEDULED còn lại → CANCELLED, thông báo thành viên. Nhóm giải tán không nhận phiên/thành viên mới; dữ liệu giữ theo thời hạn lưu; báo cáo theo BR-62. MVP không chuyển giao chủ nhóm **(đề xuất, Q-34, Q-77)**. | — | Q-34; Q-77 | EP-02, EP-08, EP-09 |

| BR-114 | **Chủ nhóm không tham gia phiên (D-25, viết lại 2026-10-19):** (a) Chủ nhóm không có trạng thái nào trong phiên của nhóm mình quản lý: không INVITED/ABSENT, không vào phòng chờ (yêu cầu vào bị từ chối “Chủ nhóm không tham gia phiên”), không Coins/chuỗi/điểm danh từ phiên đó, không tính “lượt dự kiến”, không có dòng trong báo cáo (BR-60). (b) Chủ nhóm chỉ quản lý: tạo nhóm, đặt lịch, nhận thông báo (`MEMBER_EXITED`, `SESSION_FORFEITED`, `SESSION_CANCELLED_OUTAGE` qua push + hộp thông báo, BR-27, D-20), xem báo cáo, xử lý khiếu nại. (c) Chủ nhóm được sở hữu nhiều nhóm theo BR-75(b); lịch các nhóm cùng chủ được trùng giờ, không chặn, không cảnh báo. (d) Người là chủ nhóm B đồng thời là thành viên nhóm A (BR-75(c)): trạng thái phiên chỉ phát sinh ở phiên nhóm A; lịch B trùng lịch A không chặn. | — | D-25; D-21; D-20; BR-09 | EP-02, EP-03, EP-08 |

Ghi chú: (Hủy — ghi chú trùng lịch giữa các nhóm thuộc BR-10, bỏ theo D-21; Q-81 không còn áp dụng.)

### Máy trạng thái NHÓM (T-BA-37) — tên chuẩn

Trạng thái: **HOẠT ĐỘNG**, **TẠM NGƯNG LỊCH**, **CHỜ GIẢI TÁN**, **ĐÃ GIẢI TÁN** (cuối). Giao diện dùng đúng các tên này.

| Trạng thái | Sự kiện | Điều kiện | Trạng thái kế | Hành động hệ thống |
| --- | --- | --- | --- | --- |
| (mới) | Người dùng tạo nhóm | Chưa vượt `max_groups_owned` (BR-75) | HOẠT ĐỘNG | Người tạo là chủ nhóm (D-10) |
| HOẠT ĐỘNG | Chủ nhóm/quản trị giải tán | Không có phiên COUNTDOWN/ACTIVE | ĐÃ GIẢI TÁN | Phiên SCHEDULED → CANCELLED; báo cáo BR-62 |
| TẠM NGƯNG LỊCH | Quản trị giải tán (BR-109) | Không có phiên COUNTDOWN/ACTIVE (không có phiên SCHEDULED vì đã hủy khi tạm ngưng) | ĐÃ GIẢI TÁN | Báo thành viên; báo cáo BR-62 *(T-BA-66)* |
| HOẠT ĐỘNG / TẠM NGƯNG LỊCH | Chủ nhóm/quản trị giải tán | Có phiên COUNTDOWN/ACTIVE | CHỜ GIẢI TÁN | Không nhận lịch/thành viên mới; phiên chạy đến `ends_at` |
| CHỜ GIẢI TÁN | Phiên đang chạy đến `ends_at` | — | ĐÃ GIẢI TÁN | Như dòng trên (BR-80) |
| HOẠT ĐỘNG / CHỜ GIẢI TÁN | Quản trị khóa tài khoản chủ nhóm | Đang CHỜ GIẢI TÁN thì giữ CHỜ GIẢI TÁN (giải tán vẫn diễn ra sau `ends_at`) **(giả định)** | TẠM NGƯNG LỊCH (nếu đang HOẠT ĐỘNG) | Phiên SCHEDULED → CANCELLED, báo thành viên, không đặt lịch mới (BR-108) **(đề xuất, Q-118)** |
| TẠM NGƯNG LỊCH | Mở khóa chủ nhóm | — | HOẠT ĐỘNG | Cho đặt lịch lại |
| TẠM NGƯNG LỊCH | `t ≥ locked_at + lock_dissolve_days` | — | ĐÃ GIẢI TÁN | BR-80, BR-62 |
| HOẠT ĐỘNG | Chủ nhóm xóa tài khoản | Không có phiên COUNTDOWN/ACTIVE | ĐÃ GIẢI TÁN | BR-72 |
| HOẠT ĐỘNG | Chủ nhóm xóa tài khoản | Có phiên COUNTDOWN/ACTIVE (chủ nhóm không tham gia phiên, D-25, nên BR-72 không chặn — trừ khi chủ nhóm đang trong phiên của nhóm khác với tư cách thành viên) | CHỜ GIẢI TÁN | Như BR-80 *(T-BA-66)* |
| ĐÃ GIẢI TÁN | Bất kỳ | — | ĐÃ GIẢI TÁN | Trạng thái cuối; mọi thao tác (mời, đặt lịch, mở khóa chủ nhóm) bị từ chối |

Sĩ số dưới sàn 4 **không** là trạng thái riêng; chỉ là cảnh báo trên nhóm HOẠT ĐỘNG (BR-74).

---

## §Thông báo & khiếu nại (EP-04)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-81 | **Hộp thông báo trong app:** mọi thông báo gửi cho một người (push hay không) đều lưu vào hộp thông báo của người đó, hiện khi mở app. Push lỗi (SNS lỗi, không có token) thử lại `push_retry` lần, sau đó chỉ còn bản trong hộp; lỗi ghi log. Sự kiện gốc luôn được ghi, không phụ thuộc kết quả push **(đề xuất, Q-89)**. | `push_retry = 1` (có) | Q-89 | EP-04 |
| BR-82 | **Kênh báo cho người đang trong phiên** (D-20): trong lúc người nhận có trạng thái chưa kết thúc, `MEMBER_EXITED`/`SESSION_FORFEITED` được giao qua socket phiên và hiện **banner trong app** (không chặn thao tác, tự ẩn sau vài giây, không âm thanh) nếu app đang ở tiền cảnh và màn hình mở. Nếu đang khóa màn hình (úp máy), GRACE hay PAUSED: **không** gửi push hệ thống và không bật thông báo cục bộ trên màn khóa; thông báo xếp hàng và hiện khi người đó quay lại app/mở khóa — không bao giờ bắt mở app để xem. Mọi thông báo vẫn vào hộp thông báo (BR-81). Push sau phiên theo BR-91 **(đề xuất, Q-87)**. | — | D-08; D-20; Q-87 | EP-03, EP-04 |
| BR-83 | (Hủy — D-20: không còn `notify_mode`; chỉ báo ngay.) | — | D-20 | — |
| BR-84 | (Hủy — D-20: không có bản gộp cuối phiên ở MVP; US-04.03, US-04.04 → Won't/sau MVP. Thông tin tạm dừng/LOST/ABSENT xem ở chi tiết phiên và báo cáo tháng.) | — | D-20 | — |
| BR-85 | **Giải trình** (chỉ cho sự kiện **EXITED** của chính mình; LOST không giải trình vì không phải thoát và không được báo cho ai — khớp AC-04.05.3, T-BA-55): tối đa `explanation_max_chars` ký tự; một giải trình/sự kiện; gửi được ngay sau khi sự kiện ghi (kể cả khi phiên còn ACTIVE) đến `ends_at` + `explanation_submit_days`; sửa được trong `explanation_edit_h` giờ kể từ lần gửi đầu, lưu lịch sử bản cũ; sau đó chỉ xem. Chủ nhóm nhận thông báo trong app (không push). Giải trình không đổi kết quả (BR-54) **(đề xuất, Q-90, Q-16)**. | `explanation_max_chars = 500`, `explanation_submit_days = 7`, `explanation_edit_h = 24` (có) | Q-16; Q-90 | EP-04, EP-08 |
| BR-86 | **Khiếu nại** (Should): chỉ cho EXITED của chính mình; hạn đến `ends_at` + `appeal_window_h`; một khiếu nại/sự kiện. Người xử lý mặc định: chủ nhóm. Chuyển quản trị khi (a) (Hủy — D-25: chủ nhóm không tham gia phiên nên không bao giờ có EXITED trong nhóm mình; ý "người khiếu nại là chủ nhóm" bị bỏ. Người vừa là chủ nhóm B vừa là thành viên nhóm A khiếu nại EXITED ở nhóm A với tư cách thành viên, người xử lý là chủ nhóm A theo quy tắc chung — không phải ngoại lệ. Story nào còn ca "chủ nhóm tự tham gia và EXITED rồi khiếu nại" (vd. AC-04.07.5) phải Hủy), (b) chủ nhóm không xử lý sau `appeal_escalate_h` giờ, hoặc (c) người khiếu nại hay chủ nhóm chọn “nghi lỗi hệ thống”. Kết quả: MIỄN TRỪ / BÁC (kèm lý do) — tên trạng thái theo máy trạng thái khiếu nại bên dưới. Quyết định là cuối cùng; quản trị chỉ được mở lại ca để **xem** (kèm lý do, ghi nhật ký truy cập) **(đề xuất, Q-37, Q-91)**. | `appeal_window_h = 24`, `appeal_escalate_h = 72` (có) | NFR-P14; Q-37; Q-91 | EP-04, EP-09 |
| BR-87 | **Miễn trừ — ngoại lệ của BR-35.** Khi khiếu nại được chấp nhận: EXITED của người đó được gắn cờ `exempted` (không xóa, BR-32). Server tính lại cờ phiên: nếu **không còn** EXITED nào chưa miễn trừ → `forfeited = false`, xóa `forfeited_at`/`forfeit_trigger_user_id`, khôi phục theo BR-88; nếu **còn** → giữ `forfeited = true`, `forfeit_trigger_user_id` = người có EXITED chưa miễn trừ **sớm nhất theo giờ server**, `forfeited_at` = thời điểm EXITED đó **(đề xuất, Q-92)**. Người được miễn trừ được tính như COMPLETED về Coins/điểm danh/chuỗi, nhưng phút tập trung chỉ tính đến lúc EXITED **(đề xuất, Q-124)**. Mọi thay đổi được thông báo (`EXEMPTION_GRANTED`) cho **đúng những người đã nhận `MEMBER_EXITED` của sự kiện EXITED đó** (không gửi cho người vào nhóm sau sự kiện) **(đề xuất, Q-138; khớp AC-04.08.9)**, **nêu tên** người được miễn trừ (D-22), kèm trạng thái `forfeited` mới. Đây là ngoại lệ của BR-27: danh sách người nhận lấy từ bản ghi gửi `MEMBER_EXITED`, **không** tính lại theo thành viên nhóm hiện tại (AC-04.08.1 phải dẫn BR-87, không dẫn BR-27 — T-BA-127). | — | NFR-P14; D-05; Q-37; Q-92; Q-124; Q-138 | EP-04, EP-05, EP-06, EP-08 |
| BR-88 | **Khôi phục hồi tố** khi phiên được gỡ `forfeited` do miễn trừ: (1) **Coins**: ghi dòng `SESSION_REWARD` mới cho từng người đủ điều kiện (`ref_id` = phiên, `reward_date` = ngày của phiên, `reason = APPEAL_RESTORE`); số tiền tính theo BR-40/42 và trần BR-43 **của ngày phiên** (cộng các SESSION_REWARD đã ghi cho ngày đó). Khóa duy nhất BR-45 chống ghi hai lần. Không dùng ADMIN_ADJUST. (2) **Chuỗi**: ghi dòng `STREAK_RESTORE` (BR-92) và tính lại `current_streak`/`longest_streak` bằng phát lại nhật ký từ ngày của phiên đến hôm nay như thể không có lần ngắt đó; `longest_streak` chỉ có thể tăng. (3) **Huy hiệu**: mốc đạt được sau khi tính lại được cấp ngay; không thu hồi huy hiệu nào. (4) Báo cáo tháng đã tạo không đổi (BR-102). **(đề xuất, Q-37)** | — | NFR-P14; BR-44; Q-37 | EP-04, EP-05, EP-06 |
| BR-116 | **Màn chi tiết phiên của chủ nhóm** (S2, S3; D-25): chủ nhóm chỉ thấy dữ liệu từ sự kiện **đã được server xác nhận và ghi** (trạng thái cuối từng người: COMPLETED/EXITED/LOST/ABSENT/WITHDRAWN/VOID, giờ EXITED, cờ vào muộn, số lần PAUSED kèm lý do, cờ `forfeited` và người khởi phát, giải trình/khiếu nại). Trong lúc phiên chưa kết thúc, chủ nhóm **không** xem được trạng thái từng người theo thời gian thực (đang FOCUSING/GRACE/PAUSED/mất kết nối, heartbeat, đồng hồ đếm); chỉ thấy trạng thái phiên (SCHEDULED/COUNTDOWN/ACTIVE/COMPLETED/CANCELLED) và các `MEMBER_EXITED` đã nhận (D-20). Màn chỉ-xem: chủ nhóm **không** có thao tác can thiệp phiên (dừng, kéo dài, đuổi người, đổi trạng thái thành viên, gửi tin vào phiên); hủy phiên chỉ áp cho phiên SCHEDULED theo quy tắc lịch. Không có tên app/nội dung máy (BR-34). Thứ tự dòng theo BR-115. Mỗi lần mở ghi nhật ký truy cập (BR-73) **(đề xuất, Q-144)**. *(Mới 2026-10-19.)* | — | D-20; D-25; GĐ1 §6; Q-144 | EP-03, EP-04, EP-05, EP-08 |
| BR-117 | **Chỉ số ở màn danh sách nhóm của chủ nhóm** (S5): mỗi nhóm hiện chỉ số **riêng** của nhóm đó (tỉ lệ hoàn thành phiên tháng hiện tại tính như §Báo cáo §3, tạm tính đến hôm qua); **không** cộng gộp các nhóm thành một con số tổng, không so sánh/xếp hạng nhóm; danh sách nhóm sắp theo tên nhóm (không phân biệt hoa/thường, chữ cái tiếng Việt; trùng tên theo thời điểm tạo nhóm) **(đề xuất, Q-145)**. Kiểm tra: mỗi dòng nhóm có chỉ số tỉ lệ hoàn thành tháng hiện tại; không có dòng/ô tổng; thứ tự đúng theo tên (AC-02.06.6 cần kiểm cả hai — T-BA-126). *(Mới 2026-10-19.)* | — | D-03; Q-145 | EP-02 |
| BR-118 | **Rời phiên chủ động** (S9, D-29): màn phiên (phòng chờ V-06, đang tập trung) có nút **"Rời phiên"**; màn đếm ngược 5s (V-07) **không** có nút (AC-03.04.10 (b); T-BA-132). Bấm → hộp xác nhận nêu hệ quả (cả phiên mất thưởng, ngắt chuỗi, cả nhóm thấy tên). Hủy hộp → giữ trạng thái cũ, không ghi sự kiện, hạn đang chạy (khoan hồng/tạm dừng) không dừng. Xác nhận → client gửi `session:leave` (05 §2); server xử lý theo trạng thái **lúc nhận**: (1) **FOCUSING / GRACE / PAUSED** (phiên ACTIVE) → EXITED ngay, không qua GRACE, không trừ lượt; áp đủ hệ quả thoát (`MEMBER_EXITED` D-20/D-22, kích hoạt D-05 theo BR-35, 0 Coins, ngắt chuỗi); GRACE bị hủy hẹn 3s. (2) **WAITING** (bấm ở phòng chờ V-06; server nhận khi phiên còn SCHEDULED hoặc đã sang COUNTDOWN nhưng trước `started_at`) → **ABSENT**, không gửi `MEMBER_EXITED`, không kích hoạt D-05, không vào lại được phiên đó (BR-32); hộp xác nhận ở trạng thái này nêu "bạn sẽ bị ghi vắng" thay cho câu hệ quả thoát. Khác BR-64 (rời *app* trong COUNTDOWN → GRACE từ `started_at`): BR-118 là thao tác chủ động nên ưu tiên **(giả định, Q-149)**. (3) **DISCONNECTED** → không gửi được; client báo "Không có kết nối, chưa rời phiên"; không xếp hàng gửi sau. (4) Trạng thái kết thúc → bỏ qua (BR-32). Server nhận `session:leave` cùng lúc hết hạn GRACE → sự kiện server nhận trước thắng (BR-33); kết quả đều là EXITED. `session:leave` idempotent theo `event_id` (BR-31). *(Mới 2026-10-19; sửa theo D-29, T-BA-123.)* | — | GĐ1 §4.3; D-05; D-20; D-29; Q-149 | EP-03, EP-04 |
| BR-119 | **Lịch sử phiên của tôi** (S10): người dùng chỉ xem phiên **của chính mình** (mọi nhóm đã tham gia, trong `retention_months`): ngày giờ, nhóm, thời lượng, trạng thái cuối của mình, `forfeited`, Coins nhận. Không hiện trạng thái chi tiết của người khác ngoài tên người khởi phát `forfeited` (D-22). Rời nhóm vẫn xem được lịch sử cũ **(giả định)**. *(Mới 2026-10-19.)* | dùng `retention_months` | D-22; GĐ1 §6 | EP-05, EP-06, EP-08 |
| BR-120 | **Ràng buộc riêng tư cho EP-10 (Bài viết, ngoài MVP)** (S11): khi làm EP-10, bài viết không được tự đính kèm dữ liệu phiên, Coins, số lần thoát, chuỗi hay huy hiệu; người dùng chỉ chia sẻ thành tích bằng thao tác chủ động từng lần; chủ nhóm không có quyền đọc bài ngoài phạm vi người viết chọn; áp nguyên BR-34, BR-99, BR-100 **(giả định, Q-05)**. *(Mới 2026-10-19.)* | — | GĐ1 §6; Q-05 | EP-10 |

### Máy trạng thái KHIẾU NẠI (T-BA-37) — tên chuẩn duy nhất

Trạng thái: **CHỜ XỬ LÝ**, **ĐANG XỬ LÝ**, **CHUYỂN QUẢN TRỊ**, **MIỄN TRỪ** (cuối), **BÁC** (cuối). Mọi story (EP-04, EP-09) dùng đúng các tên này; bỏ các tên "Mới", "Chấp nhận", "Từ chối", "Đã bác". Kết quả "Chấp nhận" = MIỄN TRỪ; "Từ chối" = BÁC. Không có trạng thái "hết hạn": khiếu nại chỉ tạo được trong hạn `appeal_window_h` (BR-86, BR-65).

| Trạng thái | Sự kiện | Điều kiện | Trạng thái kế | Hành động hệ thống |
| --- | --- | --- | --- | --- |
| (mới) | Người dùng gửi khiếu nại EXITED của mình | `t < ends_at + appeal_window_h`; chưa có khiếu nại cho sự kiện này; không chọn "nghi lỗi hệ thống" | CHỜ XỬ LÝ | Báo chủ nhóm trong app (không push) |
| (mới) | Như trên | Chọn "nghi lỗi hệ thống" (ca "người gửi là chủ nhóm" Hủy — D-25) | CHUYỂN QUẢN TRỊ | Vào hộp việc quản trị |
| CHỜ XỬ LÝ | Chủ nhóm mở ca | — | ĐANG XỬ LÝ | Ghi nhật ký truy cập (BR-73) |
| CHỜ XỬ LÝ / ĐANG XỬ LÝ | Chủ nhóm chọn "nghi lỗi hệ thống" | — | CHUYỂN QUẢN TRỊ | Chủ nhóm mất quyền xử lý (BR-110) |
| CHỜ XỬ LÝ / ĐANG XỬ LÝ | `t ≥ created_at + appeal_escalate_h` chưa có kết quả | — | CHUYỂN QUẢN TRỊ | Báo người khiếu nại |
| ĐANG XỬ LÝ / CHUYỂN QUẢN TRỊ | Người xử lý chấp nhận | Lý do bắt buộc | MIỄN TRỪ | BR-87, BR-88; báo người khiếu nại |
| ĐANG XỬ LÝ / CHUYỂN QUẢN TRỊ | Người xử lý bác | Lý do bắt buộc | BÁC | Báo người khiếu nại |
| MIỄN TRỪ / BÁC | Quản trị "mở lại để xem" | Lý do | (giữ nguyên) | Chỉ xem, ghi nhật ký truy cập; không đổi kết quả (BR-86) |
| CHỜ XỬ LÝ (chưa mở) | Chủ nhóm mở thẳng và quyết định | — | MIỄN TRỪ / BÁC (qua ĐANG XỬ LÝ trong cùng thao tác) | Như trên |

Ca biên: người khiếu nại rời nhóm/rút đồng ý khi ca đang mở → ca vẫn được xử lý (kết quả áp cho dữ liệu đã ghi) **(giả định)**; nhóm ĐÃ GIẢI TÁN khi ca đang CHỜ XỬ LÝ/ĐANG XỬ LÝ → CHUYỂN QUẢN TRỊ ngay **(giả định)**; chủ nhóm bị khóa tài khoản → các ca của nhóm → CHUYỂN QUẢN TRỊ **(giả định)**.

---

## §Shop (EP-06)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-93 | **Thuộc tính món:** `item_id`, loại ∈ {khung avatar, hình nền, danh hiệu}, tên (1–40 ký tự, **(đề xuất, Q-132)**), ảnh xem trước, giá nguyên dương trong [`shop_price_min`, `shop_price_max`], trạng thái ∈ {**ĐANG BÁN**, **ĐÃ ẨN**} — hai tên chuẩn duy nhất (EP-06, EP-09 không dùng "Hiển thị/Ẩn"). Chuyển trạng thái: tạo mới → ĐANG BÁN (hoặc ĐÃ ẨN nếu quản trị chọn lưu nháp ẩn); ĐANG BÁN ↔ ĐÃ ẨN do quản trị; xóa chỉ khi chưa ai mua. Thiếu trường bắt buộc thì không lưu được. Món đã có người mua không xóa được, chỉ ẩn. Danh hiệu không được trùng/giống tên huy hiệu thành tích **(đề xuất, Q-98, Q-100)**. Huy hiệu bán trong Shop là Could (Q-38). | `shop_price_min = 10`, `shop_price_max = 1000` (có) | GĐ1 §4.6; Q-98; Q-100 | EP-06, EP-09 |
| BR-94 | **Giao dịch mua** là một giao dịch nguyên tử: kiểm tra món ĐANG BÁN, chưa sở hữu, số dư ≥ giá **server lúc xác nhận** → ghi dòng `SHOP_PURCHASE` (âm) + bản ghi sở hữu, cùng thành công hoặc cùng hủy. Giá server khác giá đang hiển thị → báo “Giá đã thay đổi”, yêu cầu xác nhận lại. Mỗi món mua tối đa 1 lần/người (khóa duy nhất người–món). Không hoàn/trả **(đề xuất, Q-99, Q-119)**. Không tính vào trần ngày (trần chỉ áp SESSION_REWARD). | — | BR-44; BR-45; Q-99; Q-119 | EP-06 |
| BR-95 | **Trang bị:** mỗi loại tối đa 1 món đang dùng; chỉ trang bị món đã sở hữu hoặc món mặc định. Trang bị/gỡ miễn phí, không ghi sổ cái. Gỡ thì về món mặc định. Tài khoản mới có sẵn 1 khung + 1 hình nền mặc định, không bán trong Shop **(đề xuất, Q-103)**. | — | GĐ1 §4.6, §4.7; Q-103 | EP-06, EP-07 |
| BR-96 | **Món bị ẩn / đổi giá:** món ĐÃ ẨN không hiện trong Shop và không mua được; người đã mua vẫn giữ, vẫn trang bị và vẫn hiển thị trên hồ sơ. Đổi giá chỉ áp cho giao dịch xác nhận sau thời điểm đổi; dòng sổ cái cũ giữ nguyên số tiền. | — | BR-44 | EP-06, EP-07, EP-09 |
| BR-121 | **Không có cơ chế ngẫu nhiên trong Shop** (S6; D-01): mọi món bán theo giá cố định, người mua biết chính xác món nhận được trước khi xác nhận. Cấm hộp quà bí ẩn, quay thưởng, gacha, rơi đồ ngẫu nhiên, giảm giá ngẫu nhiên. Kiểm tra: mọi giao dịch `SHOP_PURCHASE` ứng đúng một `item_id` hiển thị lúc xác nhận. *(Mới 2026-10-19.)* | — | D-01; BR-93 | EP-06, EP-09 |
| BR-122 | **Email không theo dõi** (D-27): email báo cáo/thông báo **không** chứa ảnh theo dõi mở thư (tracking pixel, ảnh tải từ server kèm mã người nhận) và **không** chứa link theo dõi (link chuyển hướng gắn mã người nhận/tham số đo lường). Kiểm tra: mã nguồn email không có thẻ `<img>` tải từ xa kèm định danh; mọi link trỏ thẳng tới đích, không có tham số theo dõi. *(Mới 2026-10-19, T-BA-136.)* | — | D-27; GĐ1 §6 | EP-08 |
| BR-123 | **Chi tiết phiên của chủ nhóm không tự làm mới** (D-28; bổ sung BR-116): V-46 **không** nhận đẩy (socket/push) và **không** tự làm mới theo chu kỳ; dữ liệu chỉ cập nhật khi chủ nhóm mở màn hoặc kéo xuống để làm mới. Kiểm tra: để màn mở, có `MEMBER_EXITED` mới → màn không đổi cho đến khi kéo làm mới. *(Mới 2026-10-19, T-BA-136.)* | — | D-28; BR-116 | EP-08 |

Coins bù khi miễn trừ: BR-88. ADMIN_ADJUST: BR-107.

---

## §Hồ sơ & nhật ký (EP-07)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-97 | **Tên hiển thị:** sau khi cắt khoảng trắng đầu/cuối, độ dài trong [`display_name_min`, `display_name_max`] ký tự; không chứa ký tự điều khiển; không bắt buộc duy nhất. Báo cáo đã tạo giữ tên cũ (BR-56) **(đề xuất, Q-126)**. | `display_name_min = 2`, `display_name_max = 30` (có) | GĐ1 §4.7; Q-126 | EP-01, EP-07 |
| BR-98 | **Avatar:** chỉ JPG/PNG/WebP, dung lượng ≤ `avatar_max_mb` MB (đúng giới hạn: nhận; vượt 1 byte: từ chối). Server cắt vuông, thu về ≤ 512×512 px, **xóa EXIF** (vị trí), lưu S3 với khóa theo `user_id`; tệp cũ bị xóa khi thay. Chỉ đọc qua URL ký hạn bởi người có quyền xem phần công khai **(đề xuất, Q-126)**. | `avatar_max_mb = 5` (có) | GĐ1 §4.7; NFR-P01; Q-126 | EP-01, EP-07 |
| BR-99 | **Phần công khai & trưng bày:** người cùng nhóm chỉ thấy tên, avatar, khung, hình nền đang trang bị, và huy hiệu/chuỗi **do người đó chọn hiện**; mặc định ẩn huy hiệu/chuỗi **(đề xuất, Q-94, Q-104)**. Trưng bày tối đa `showcase_max_badges` huy hiệu, chỉ huy hiệu đã đạt. Không bao giờ công khai Coins, số lần thoát. Xem hồ sơ công khai không ghi nhật ký truy cập (BR-73). | `showcase_max_badges = 3` (có) | D-03; Q-94; Q-104 | EP-05, EP-07 |
| BR-100 | **Nhật ký cá nhân:** tối đa 1 mục/ngày **(đề xuất, Q-107)**; ≤ `journal_max_chars` ký tự; ngày của mục xác định theo thời điểm **server nhận** quy ra `day_timezone`. Sửa không giới hạn thời gian, không lưu phiên bản cũ; xóa là xóa thẳng **(đề xuất, Q-108)**. Mã hóa phía server **(đề xuất, Q-109)**. Không có màn hay API nào cho người khác (kể cả chủ nhóm, quản trị) đọc nhật ký — mọi yêu cầu như vậy trả 403; nhãn giao diện: "Chủ nhóm và quản trị không xem được trong app" (không hứa "chỉ mình bạn đọc được" vì mã hóa phía server). Không dùng cho Coins/chuỗi/báo cáo. | `journal_max_chars = 5000` (có) | GĐ1 §4.7, §6; NFR-P05 | EP-07 |

---

## §Quản trị (EP-09)

| Mã | Quy tắc (kiểm tra được) | Tham số (cấu hình?) | Nguồn | Áp dụng |
| --- | --- | --- | --- | --- |
| BR-106 | **Danh mục Shop:** chỉ quản trị tạo/sửa/ẩn món, theo BR-93; hiệu lực theo BR-96. Mọi thay đổi ghi nhật ký quản trị (ai, lúc, giá trị cũ → mới). | — | GĐ1 §4.6; BR-93 | EP-06, EP-09 |
| BR-107 | **ADMIN_ADJUST:** bắt buộc lý do; **không** tính vào trần ngày; không được làm số dư âm; \|amount\| > `admin_adjust_confirm` cần xác nhận lần hai; không thông báo cho chủ nhóm (BR-53); người được điều chỉnh thấy dòng trong lịch sử Coins. Mở sổ cái của người dùng ghi nhật ký truy cập (BR-73) **(đề xuất, Q-120)**. | `admin_adjust_confirm = 500` (có) | BR-44; BR-45; Q-120 | EP-06, EP-09 |
| BR-108 | **Khóa tài khoản:** bắt buộc lý do; thu hồi mọi phiên đăng nhập ngay. Người bị khóa đang trong phiên → WITHDRAWN (`reason = ACCOUNT_LOCKED`): không tính thoát, không báo như thoát, không kích hoạt D-05, không Coins, không ngắt chuỗi; **không** rời nhóm **(đề xuất, Q-117)**. Số dư Coins, đồ đã mua giữ nguyên; mở khóa thì dùng lại bình thường. Người bị khóa là chủ nhóm: phiên SCHEDULED của nhóm → CANCELLED và thành viên được báo; không đặt lịch mới; khóa quá `lock_dissolve_days` ngày → giải tán nhóm (BR-80) **(đề xuất, Q-118)**. | `lock_dissolve_days = 30` (có) | Q-117; Q-118 | EP-02, EP-03, EP-09 |
| BR-109 | **Báo cáo lạm dụng nhóm / hồ sơ** (Should): thành viên hiện tại của nhóm được báo cáo nhóm, hoặc báo cáo tên/avatar của người cùng nhóm. Báo cáo trùng (cùng đối tượng) trong `abuse_merge_h` giờ gộp một ca. Người báo cáo luôn ẩn danh với chủ nhóm/người bị báo cáo. Quyết định: Bác / Cảnh báo chủ nhóm (Could) / Giải tán nhóm (BR-80) / Đặt lại tên-avatar mặc định **(đề xuất, Q-63, Q-77, Q-105)**. | `abuse_merge_h = 24` (có) | Q-63; Q-77; Q-105 | EP-02, EP-07, EP-09 |
| BR-110 | **Quản trị xử lý khiếu nại:** chỉ thấy sự kiện thoát chi tiết của người trong ca đang mở và được gán cho mình; ngoài ra 403 **(đề xuất, Q-22)**. Mỗi lần mở ghi nhật ký truy cập. Ca đã chuyển quản trị thì chủ nhóm không xử lý được nữa. Miễn trừ của quản trị có hiệu lực như của chủ nhóm (BR-87, BR-88); khôi phục Coins theo BR-88, **không** dùng ADMIN_ADJUST. | — | Q-22; Q-91 | EP-04, EP-09 |
| BR-111 | **Đổi tham số cấu hình:** chỉ quản trị; giá trị phải trong miền BR-112, ngoài miền bị từ chối kèm thông báo miền. Mọi thay đổi ghi nhật ký quản trị. Tham số phiên áp cho phiên vào COUNTDOWN sau lúc đổi (phiên đang chạy giữ giá trị cũ). Tham số Coins áp cho phiên có `ends_at` sau lúc đổi; trần theo giá trị hiện hành **(đề xuất, Q-102)**. | — | Q-102; Q-122 | EP-06, EP-09 |
| BR-112 | **Miền giá trị hợp lệ** (bao gồm hai biên) — bảng dưới **(đề xuất, Q-122)**. | xem bảng | Q-122 | EP-09 |

Miền giá trị (BR-112):

| Tham số | Min | Max | Ràng buộc thêm |
| --- | --- | --- | --- |
| `duration` | 25 | 50 | **Không cấu hình**: tập cố định {25, 50} (BR-02, D-09) |
| `countdown_s` | 3 | 10 | |
| `lobby_open_min` | 0 | 30 | |
| `late_join_max_min` | 0 | 10 | (< 25) |
| `grace_s` | 2 | 10 | |
| `grace_max_per_session` | 0 | 3 | |
| `pause_max_count` | 0 | 3 | |
| `pause_max_min` | 1 | 10 | |
| `pause_reasons` | 1 mục | 8 mục | mỗi mục 1–30 ký tự |
| `heartbeat_s` | 2 | 15 | |
| `heartbeat_timeout_s` | 2 × `heartbeat_s` | 30 | |
| `disconnect_hold_s` | 5 | 60 | tính từ `disconnected_at` (BR-19) |
| `outage_ratio` | 50% | 100% | |
| `outage_window_s` | 5 | 60 | |
| `coins_25` / `coins_50` | 0 | 100 | `coins_50` ≥ `coins_25` |
| `coins_daily_cap` | 25 | 500 | ≥ `coins_50` |
| `shop_price_min` / `shop_price_max` | 1 | 10000 | min < max |
| `admin_adjust_confirm` | 50 | 5000 | |
| `group_min_members` / `group_max_members` | 4 / 10 | 4 / 10 | **Không cấu hình**: cố định 4 và 10 (D-02, BR-74) |
| `max_groups_owned` | 1 | 50 | |
| `explanation_max_chars` | 100 | 2000 | |
| `appeal_window_h` | 1 | 168 | |
| `report_run_at` | 00:00 | 05:00 | trước `report_retry_deadline` |
| `group_report_min_members` | 3 | 10 | |
| `recurrence_max_weeks` | 1 | 26 | BR-113 (đề xuất, Q-122) |
| `badge_milestones` | 1 mốc/loại | 10 mốc/loại | số nguyên dương, tăng dần, không trùng trong cùng loại (BR-52, BR-90) |
| `day_timezone` / `report_timezone` | — | — | **Cố định** Asia/Ho_Chi_Minh ở MVP (không cấu hình) |
| `report_retry_max` | 0 | 5 | |
| `report_retry_deadline` | `report_run_at` + 1 giờ | 08:00 | |
| `report_link_app_min` | 5 | 60 | |
| `retention_months` | 13 | 24 | ≥ 13 để luôn so được tháng trước và xem đủ 12 kỳ |
| `account_purge_days` | 1 | 30 | ≤ 30 (cam kết 04 §4) |
| `access_log_merge_min` | 1 | 60 | |
| `access_log_retention_months` | 6 | 24 | |
| `invite_code_len` | 8 | 8 | **Cố định** 8 (BR-76) |
| `invite_email_ttl_days` | 1 | 30 | |
| `invite_max_fail` | 3 | 10 | |
| `invite_lock_min` | 5 | 60 | |
| `schedule_min_lead_min` | 0 | 60 | |
| `reminder_min` | 0 | 30 | 0 = không nhắc; < `lobby_open_min` + 30 |
| `push_retry` | 0 | 3 | |
| `explanation_submit_days` | 1 | 30 | |
| `explanation_edit_h` | 0 | 72 | 0 = không cho sửa |
| `appeal_escalate_h` | 24 | 168 | > `appeal_window_h` không bắt buộc |
| `display_name_min` / `display_name_max` | 1 / 10 | 5 / 50 | min < max |
| `avatar_max_mb` | 1 | 10 | |
| `showcase_max_badges` | 0 | 6 | |
| `journal_max_chars` | 500 | 10000 | |
| `lock_dissolve_days` | 7 | 90 | |
| `abuse_merge_h` | 1 | 72 | |
| `notify_latency_s` | — | — | Ngưỡng NFR, **không** cấu hình |

Mọi tham số Admin trong tệp này đều có dòng ở bảng trên; tham số không có dòng thì **không** cấu hình được ở MVP (T-BA-64) **(đề xuất, Q-122)**.

### Tham số mới (bổ sung 2026-10-06)

| Tham số | Mặc định | Cấp | Nguồn |
| --- | --- | --- | --- |
| `account_purge_days` | 30 | Admin | BR-72, Q-25 |
| `access_log_merge_min` / `access_log_retention_months` | 10 / 12 | Admin | BR-73, Q-121 |
| `group_min_members` / `group_max_members` | 4 / 10 | **Cố định** (không cấu hình) | BR-74, D-02, Q-68 |
| `max_groups_owned` | 10 | Admin | BR-75, Q-71 |
| `invite_code_len` / `invite_email_ttl_days` / `invite_max_fail` / `invite_lock_min` | 8 / 7 / 5 / 15 | Admin | BR-76, Q-73 |
| `schedule_min_lead_min` / `reminder_min` | 1 / 5 | Admin (`reminder_min`: chủ nhóm theo nhóm) | BR-79, Q-79, Q-80 |
| `recurrence_max_weeks` | 12 | Admin | BR-113, Q-78 (đề xuất) |
| `push_retry` | 1 | Admin | BR-81, Q-89 |
| ~~`batch_send_within_s`~~ | — | (Hủy — D-20, BR-84 hủy) | BR-84 |
| `explanation_max_chars` / `explanation_submit_days` / `explanation_edit_h` | 500 / 7 / 24 | Admin | BR-85, Q-90 |
| `appeal_window_h` / `appeal_escalate_h` | 24 / 72 | Admin | BR-86, Q-91 |
| `shop_price_min` / `shop_price_max` | 10 / 1000 | Admin | BR-93, Q-98 |
| `display_name_min` / `display_name_max` | 2 / 30 | Admin | BR-97 |
| `avatar_max_mb` | 5 | Admin | BR-98 |
| `showcase_max_badges` | 3 | Admin | BR-99 |
| `journal_max_chars` | 5000 | Admin | BR-100 |
| `admin_adjust_confirm` | 500 | Admin | BR-107, Q-120 |
| `lock_dissolve_days` | 30 | Admin | BR-108, Q-118 |
| `abuse_merge_h` | 24 | Admin | BR-109, Q-77 |
