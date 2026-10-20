# EP-06 Coins & Shop

Nguồn: GĐ1 §4.5, §4.6, §7 (MVP: Shop cơ bản khung + hình nền); D-01, D-03, D-05, D-09; `03-quy-tac.md` §Thưởng (BR-40…BR-45, BR-52, BR-53); `04-nfr-rieng-tu.md` §3  ·  MoSCoW: Must (cơ bản); danh hiệu/huy hiệu bán trong Shop: Could  ·  Phụ trách: ba-stories (T-BA-13)

Phạm vi: nhận Coins sau phiên, xem số dư và lịch sử, duyệt Shop, mua, trang bị/gỡ. **Chỉ đồ thẩm mỹ** — không bán lợi thế (GĐ1 §4.6), không nạp tiền thật, không quy đổi Coins ra tiền (D-03), không cược (D-01).
Vai trò: mọi **Người dùng** (A-22, A-23 trong `01-pham-vi.md` §3). Chủ nhóm **không** thấy Coins của thành viên (BR-53, Q-23).
Tên trạng thái/sự kiện theo `03-quy-tac.md`: COMPLETED, EXITED, LOST, ABSENT, WITHDRAWN, VOID; cờ phiên `forfeited`; loại dòng sổ cái `SESSION_REWARD`, `SHOP_PURCHASE`, `ADMIN_ADJUST`; trạng thái món Shop **ĐANG BÁN** / **ĐÃ ẨN** (BR-93 — không dùng "Hiển thị/Ẩn").
Thuật ngữ (D-11): Coins chỉ ghi khi **hoàn thành có thưởng** (COMPLETED và phiên không `forfeited`); **hoàn thành** trong phiên `forfeited` được điểm danh nhưng 0 Coins.

Sửa 2026-10-06 theo `ba/review/lan-1.md` (nguồn cũ đã xóa): T-BA-26 (thuật ngữ D-11), T-BA-29 (AC-06.01.11 ngoại lệ BR-68), T-BA-37 (trạng thái món ĐANG BÁN / ĐÃ ẨN), T-BA-33 (thời điểm áp tham số Coins theo BR-111), cập nhật BR-88 (Coins bù khi MIỄN TRỪ) và D-12 (chủ nhóm không thấy Coins, chuỗi).

Sửa 2026-10-07: D-19 (LOST không làm cả phiên mất thưởng), D-20 (bỏ bản gộp), D-21 (trần Coins không còn "cộng mọi nhóm"), D-22 (nêu tên người khởi phát), D-23 (WITHDRAWN sau `forfeited_at`); `ba/review/lan-2.md` (nguồn cũ đã xóa) T-BA-58 (nhãn AC phụ thuộc story Should).

Sửa 2026-10-19: D-25 (câu story US-06.01 bỏ "kể cả chủ nhóm khi tham gia phiên").

---

## US-06.01 Nhận Coins sau phiên

**Là một** Thành viên (chủ nhóm không tham gia phiên nên không nhận Coins từ phiên nhóm mình làm chủ — D-25), **tôi muốn** nhận Coins tự động khi phiên kết thúc và biết vì sao được bao nhiêu **để** thấy công sức tập trung được ghi nhận.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.5; D-05, D-09 · Liên quan: BR-23, BR-24, BR-37, BR-40, BR-41, BR-42, BR-43, BR-44, BR-45, BR-21

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.01.1 | Bình thường | Phiên 25 phút, `forfeited = false`; tôi COMPLETED; hôm nay tôi đã nhận 0 Coins | Đến `ends_at` | Sổ cái thêm 1 dòng `SESSION_REWARD` +10, `ref_id` = mã phiên (BR-40, BR-44); màn kết quả phiên hiện “+10 Coins”; số dư tăng 10 |
| AC-06.01.2 | Bình thường | Phiên 50 phút, `forfeited = false`; tôi COMPLETED; hôm nay đã nhận 0 | Đến `ends_at` | Ghi +25 (BR-40) |
| AC-06.01.3 | Lỗi | Phiên có `forfeited = true`; tôi COMPLETED (hoàn thành nhưng **không** hoàn thành có thưởng, D-11) | Đến `ends_at` | Không ghi dòng sổ cái nào; màn kết quả hiện “0 Coins — phiên mất thưởng tập thể do ‹Tên người khởi phát› rời phiên” (BR-41, BR-38, D-22) |
| AC-06.01.4 | Lỗi | Tôi có trạng thái cuối EXITED, LOST, ABSENT, WITHDRAWN hoặc VOID | Phiên kết thúc / bị hủy | Không ghi dòng sổ cái; nếu có màn kết quả thì hiện 0 Coins kèm lý do đúng trạng thái (BR-24, BR-21, BR-41) |
| AC-06.01.13 | Bình thường (D-19) | Phiên 25 phút; B LOST (mất mạng quá hạn), không ai EXITED; tôi COMPLETED; hôm nay đã nhận 0 | Đến `ends_at` | Phiên không `forfeited` (BR-36); tôi nhận +10 (BR-40); B nhận 0 (BR-24) |
| AC-06.01.5 | Biên | Hôm nay (UTC+7) tôi đã nhận 95 Coins; phiên 50 phút không `forfeited`, tôi COMPLETED | Đến `ends_at` | Ghi +5 (không phải +25); màn kết quả hiện “+5 Coins — đã đạt trần ngày” (BR-43) |
| AC-06.01.6 | Biên | Hôm nay đã nhận đúng 100 Coins | Phiên tiếp theo tôi COMPLETED | Ghi 0 (không tạo dòng `amount = 0` **(giả định)**); hiện “đã đạt trần ngày” (BR-43) |
| AC-06.01.7 | Biên | Hôm nay đã nhận 90 Coins | Phiên 25 phút COMPLETED | Ghi +10, tổng ngày = 100 đúng trần (BR-43) |
| AC-06.01.8 | Biên | Phiên 25 phút, tôi vào muộn 4 phút (có mặt 21 phút), COMPLETED, không `forfeited` | Đến `ends_at` | Ghi `floor(10 × 21 / 25)` = 8 Coins (BR-42) *(chỉ kiểm khi US-03.11 trong phạm vi, T-BA-58)* |
| AC-06.01.9 | Biên | Phiên `started_at` = 23:40 ngày N (UTC+7), kết thúc 00:05 ngày N+1 | Đến `ends_at` | Coins tính vào trần **ngày N** (ngày của `started_at`, §Thưởng) |
| AC-06.01.10 | Lỗi | Server xử lý ghi thưởng cho cùng phiên hai lần (thử lại sau lỗi) | Lần ghi thứ hai | Bị chặn bởi khóa duy nhất (`type`, `ref_id`, `user_id`); số dư không đổi (BR-45) |
| AC-06.01.11 | Lỗi | Phiên bị CANCELLED do sự cố (BR-22); tôi đang FOCUSING | Server hủy phiên | Tôi ở VOID, không ghi Coins. *Phần chỉ kiểm khi US-03.12 trong phạm vi (T-BA-58):* người đã EXITED trước sự cố cũng 0 Coins, giữ EXITED (ngoại lệ BR-68) |
| AC-06.01.12 | Bình thường *(chỉ kiểm khi US-04.08 trong phạm vi, T-BA-58)* | Phiên 25 phút `forfeited` chỉ do A EXITED; tôi COMPLETED; hôm nay tôi đã nhận 0 | Khiếu nại của A được **MIỄN TRỪ**, phiên gỡ `forfeited` (BR-87) | Sổ cái thêm dòng `SESSION_REWARD` +10, `reason = APPEAL_RESTORE`, `reward_date` = ngày của phiên; ghi lại lần hai bị chặn (BR-88, BR-45) |

**Ghi chú / giả định:**
- Trần ngày tính trên mọi `SESSION_REWARD` của người đó trong ngày (BR-43); theo D-21 mỗi người chỉ là thành viên 1 nhóm nên thực tế là các phiên của nhóm đó; tham số `coins_25`, `coins_50`, `coins_daily_cap` áp cho phiên có `ends_at` sau lúc đổi, trần theo giá trị hiện hành (BR-111; Q-102).
- Phiên tự do (Should, Q-02) dùng cùng quy tắc khi được làm.
- Khiếu nại được MIỄN TRỪ (NFR-P14, Q-37 — Should): Coins bù theo **BR-88** (dòng `SESSION_REWARD` mới, `reason = APPEAL_RESTORE`, trần theo ngày của phiên; không dùng `ADMIN_ADJUST`) — AC-06.01.12.

---

## US-06.02 Xem số dư và lịch sử Coins

**Là một** Người dùng, **tôi muốn** xem số dư Coins, Coins đã nhận hôm nay so với trần, và lịch sử từng lần cộng/trừ **để** biết mình có bao nhiêu và từ đâu ra.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.5; D-09; 04 §3 · Liên quan: BR-43, BR-44, BR-53; A-22

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.02.1 | Bình thường | Sổ cái của tôi có các dòng +10, +25, +25, −40 | Mở màn “Coins của tôi” | Số dư hiện 20 = tổng `amount` (BR-44); “Hôm nay: x/100” = tổng `SESSION_REWARD` của ngày hiện tại (UTC+7) |
| AC-06.02.2 | Bình thường | Có lịch sử | Mở “Lịch sử” | Danh sách mới nhất trước; mỗi dòng: thời điểm (UTC+7), số Coins (±), loại (Thưởng phiên / Mua đồ / Điều chỉnh), mô tả (tên nhóm + thời lượng phiên, hoặc tên món đồ, hoặc lý do điều chỉnh) |
| AC-06.02.3 | Bình thường | Tài khoản mới, chưa có dòng nào | Mở màn Coins | Số dư 0, lịch sử trống kèm gợi ý “Hoàn thành phiên để nhận Coins” |
| AC-06.02.4 | Lỗi | Tôi là chủ nhóm, thành viên B ở nhóm tôi | Tôi tìm xem Coins của B (hồ sơ, màn "Thành viên nhóm", thông báo `MEMBER_EXITED`, báo cáo, API) | Không có chỗ hiển thị; API Coins của B trả 403; phản hồi API chủ nhóm không chứa trường Coins (BR-53 (a), Q-23; 04 §3) |
| AC-06.02.5 | Lỗi | Mất mạng | Mở màn Coins | Hiện số dư lần tải gần nhất kèm nhãn “có thể chưa cập nhật”; không cho mua (US-06.04) **(giả định)** |
| AC-06.02.6 | Biên | Hôm nay đã nhận 100 Coins | Mở màn Coins | Hiện “Hôm nay: 100/100 — đã đạt trần, phiên tiếp theo hôm nay không cộng Coins” (BR-43) |
| AC-06.02.7 | Biên | Phiên hôm nay bị `forfeited` | Mở lịch sử | Không có dòng cho phiên đó (BR-41); lý do 0 Coins chỉ xem ở kết quả phiên **(giả định)** → Q-101 |

**Ghi chú / giả định:**
- Dòng `ADMIN_ADJUST` hiện cho chính người dùng kèm lý do (BR-45).
- Coins không xuất hiện trong báo cáo tháng (BR-61) và không có trong hồ sơ công khai (04 §3).
- Lịch sử nằm trong phạm vi xuất dữ liệu của tôi (NFR-P12).

---

## US-06.03 Duyệt Shop

**Là một** Người dùng, **tôi muốn** xem danh mục khung avatar và hình nền hồ sơ kèm giá và bản xem trước **để** chọn món mình thích.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.6, §7 · Liên quan: A-23, A-24; FR- (chưa cấp)

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.03.1 | Bình thường | Danh mục có món trạng thái ĐANG BÁN thuộc loại “Khung avatar” và “Hình nền” | Mở Shop | Thấy 2 tab theo loại; mỗi món: ảnh, tên, giá Coins, nhãn “Đã sở hữu” / “Đang dùng” nếu có; số dư hiện ở đầu màn |
| AC-06.03.2 | Bình thường | — | Chạm một món | Xem trước trên avatar/hồ sơ của chính tôi; chưa trừ Coins, chưa trang bị |
| AC-06.03.3 | Bình thường | Số dư nhỏ hơn giá món | Xem món | Nút mua vẫn hiện nhưng ghi “Thiếu N Coins” (N = giá − số dư) **(giả định)** |
| AC-06.03.4 | Lỗi | Quản trị đã chuyển một món sang ĐÃ ẨN | Mở Shop | Món đó không hiện trong Shop; người đã mua vẫn thấy trong “Đồ của tôi” (BR-93, BR-96) |
| AC-06.03.5 | Lỗi | Không tải được danh mục / ảnh (mạng, S3) | Mở Shop | Hiện thông báo lỗi + nút “Thử lại”; không hiện giá cũ như giá hiện hành |
| AC-06.03.6 | Biên | Danh mục rỗng ở một loại | Mở tab đó | Hiện “Chưa có món nào” |
| AC-06.03.7 | Lỗi | — | Rà toàn bộ danh mục | Không có món nào thay đổi luật phiên, Coins, chuỗi, khoan hồng hay tạm dừng; không có mục nạp tiền / mua Coins (GĐ1 §4.6; D-03) |
| AC-06.03.8 | Lỗi | — | Rà Shop, danh mục và API mua | Không có cơ chế ngẫu nhiên: hộp bí ẩn, quay thưởng, rương, gói "ngẫu nhiên 1 trong N", tỉ lệ rơi; mỗi lần mua trả **đúng** món đã chọn với giá hiện trước (BR-121, D-01, BR-93, BR-94). Không có ưu đãi thời hạn kiểu "Double Coin", "x2 Coins" (D-09) |

**Ghi chú / giả định:**
- Danh mục MVP do quản trị nạp sẵn (seed, EP-09 Should). Giá cụ thể chưa có → Q-98.
- Danh hiệu, huy hiệu bán trong Shop: Could, xem US-06.06 (Q-38).

---

## US-06.04 Mua đồ trong Shop

**Là một** Người dùng, **tôi muốn** dùng Coins mua một món thẩm mỹ **để** trang trí hồ sơ.

- Ưu tiên: Must · Ước lượng: M · Nguồn: GĐ1 §4.6 · Liên quan: BR-44, BR-45; A-23

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.04.1 | Bình thường | Số dư 120; món “Khung Lá” giá 80, chưa sở hữu | Bấm Mua → xác nhận | Trong một giao dịch: thêm dòng `SHOP_PURCHASE` −80, `ref_id` = mã đơn (BR-44) và ghi quyền sở hữu; số dư còn 40; món hiện “Đã sở hữu”; hỏi “Trang bị ngay?” |
| AC-06.04.2 | Lỗi | Số dư 50; món giá 80 | Bấm Mua | Từ chối, hiện “Thiếu 30 Coins”; không ghi sổ cái, không ghi sở hữu (BR-45) |
| AC-06.04.3 | Lỗi | Đã sở hữu món | Gửi yêu cầu mua lại (kể cả gọi API trực tiếp) | Từ chối “Bạn đã có món này”; không trừ Coins → **BR-94** |
| AC-06.04.4 | Biên | Số dư = giá = 80 | Mua | Thành công; số dư = 0 (BR-45: không âm) |
| AC-06.04.5 | Biên | Số dư = giá − 1 | Mua | Từ chối như AC-06.04.2 |
| AC-06.04.6 | Lỗi | Số dư 100; bấm mua hai món giá 80 gần như cùng lúc (2 máy hoặc bấm đúp) | Hai yêu cầu đến server | Chỉ một yêu cầu thành công; yêu cầu kia bị từ chối thiếu Coins; số dư không bao giờ âm (BR-45). Bấm đúp cùng một món chỉ tạo một đơn (idempotent theo mã yêu cầu) **(giả định)** |
| AC-06.04.7 | Lỗi | Quản trị đổi giá hoặc chuyển món sang ĐÃ ẨN sau khi tôi mở màn hình | Tôi xác nhận mua | Server dùng giá và trạng thái hiện hành: nếu giá đổi thì báo “Giá đã thay đổi” và yêu cầu xác nhận lại; nếu món ĐÃ ẨN thì từ chối “Món này không còn bán”, không trừ Coins (BR-94, BR-96) |
| AC-06.04.8 | Lỗi | Mất kết nối khi đang gửi lệnh mua | Kết nối lại | App hỏi lại trạng thái đơn; không trừ hai lần; hiện đúng kết quả |
| AC-06.04.9 | Lỗi | Tôi muốn trả lại món đã mua | Tìm chức năng hoàn | Không có; màn xác nhận ghi rõ “Không hoàn Coins” (BR-94, **đề xuất, Q-99**) |

**Ghi chú / giả định:**
- Mua không tính vào trần ngày (trần chỉ áp cho `SESSION_REWARD`, BR-43).
- Quản trị xem được lịch sử giao dịch Shop của tôi (04 §3); chủ nhóm không.

---

## US-06.05 Trang bị và gỡ đồ

**Là một** Người dùng, **tôi muốn** trang bị hoặc gỡ khung avatar / hình nền đã sở hữu **để** đổi diện mạo hồ sơ khi muốn.

- Ưu tiên: Must · Ước lượng: S · Nguồn: GĐ1 §4.6, §4.7 · Liên quan: A-02, A-03, A-23; 04 §3 (“đồ đang trang bị”); EP-07

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.05.1 | Bình thường | Sở hữu “Khung Lá”, chưa trang bị khung nào | Mở “Đồ của tôi” → Trang bị | Avatar của tôi hiện khung này ở hồ sơ và mọi nơi hiện avatar trong nhóm; không trừ Coins |
| AC-06.05.2 | Bình thường | Đang dùng “Khung Lá”, sở hữu “Khung Sao” | Trang bị “Khung Sao” | “Khung Sao” thay thế; mỗi loại chỉ 1 món đang dùng (khung 1, hình nền 1) → **BR-95** |
| AC-06.05.3 | Bình thường | Đang dùng hình nền | Bấm Gỡ | Hồ sơ về hình nền mặc định; món vẫn trong “Đồ của tôi” |
| AC-06.05.4 | Lỗi | Chưa sở hữu món X | Gửi yêu cầu trang bị X (gọi API) | Từ chối, không đổi hồ sơ |
| AC-06.05.5 | Bình thường | Thành viên khác cùng nhóm / chủ nhóm | Xem hồ sơ của tôi | Chỉ thấy món **đang trang bị**; không thấy danh sách đồ đã mua, giá, số dư (04 §3) |
| AC-06.05.6 | Lỗi | Người ngoài nhóm của tôi (D-21) | Xem hồ sơ tôi | Không được (A-03) |
| AC-06.05.7 | Biên | Món đang trang bị được quản trị chuyển sang ĐÃ ẨN | Xem hồ sơ; gỡ rồi trang bị lại | Vẫn hiển thị bình thường; gỡ và trang bị lại được (BR-96) |
| AC-06.05.8 | Lỗi | Ảnh món không tải được | Xem hồ sơ | Hiện avatar/hình nền mặc định, không lỗi màn hình |

**Ghi chú / giả định:**
- Khi xóa tài khoản: đồ đã mua bị xóa cùng tài khoản (04 §4).
- Giao diện Lockdown trong phiên là màn tối tĩnh, không hiện hình nền Shop **(giả định)**.

---

## US-06.06 Danh hiệu trong Shop (Could)

**Là một** Người dùng, **tôi muốn** mua và gắn một danh hiệu ngắn dưới tên hồ sơ **để** thể hiện cá tính.

- Ưu tiên: Could · Ước lượng: S · Nguồn: GĐ1 §4.6; Q-38 · Liên quan: BR-44, BR-45, BR-52; US-06.04, US-06.05

**Tiêu chí chấp nhận**

| Mã | Ca | Cho trước (Given) | Khi (When) | Thì (Then) |
| --- | --- | --- | --- | --- |
| AC-06.06.1 | Bình thường | Shop có loại “Danh hiệu”; đủ Coins | Mua rồi trang bị | Danh hiệu hiện dưới tên trên hồ sơ; quy tắc mua/trang bị như US-06.04/US-06.05 |
| AC-06.06.2 | Lỗi | Thiếu Coins hoặc đã sở hữu | Mua | Từ chối như AC-06.04.2 / AC-06.04.3 |
| AC-06.06.3 | Lỗi | — | Rà danh mục danh hiệu | Không có danh hiệu trùng tên huy hiệu thành tích (BR-52) hoặc gợi ý xếp hạng / so sánh với người khác (D-03, NFR-P06) **(đề xuất)** → Q-100 |
| AC-06.06.4 | Biên | Đang trang bị danh hiệu | Trang bị danh hiệu khác | Thay thế; tối đa 1 danh hiệu |

**Ghi chú / giả định:** Danh hiệu do quản trị tạo sẵn; người dùng không tự gõ (tránh nội dung cần kiểm duyệt, EP-10 Won't) **(giả định)**. Huy hiệu bán trong Shop: chưa viết story, chờ Q-38.

---

## Truy vết

Dòng đề xuất để điều phối viên chép vào `ba/03-truy-vet.md` (tệp này không sửa tệp đó).

| US | Epic | Nguồn | BR | MoSCoW |
| --- | --- | --- | --- | --- |
| US-06.01 | EP-06 | GĐ1 §4.5; D-05, D-09, D-11, D-19, D-21, D-22, D-25 | BR-21, BR-22, BR-23, BR-24, BR-36, BR-37, BR-38, BR-40…BR-45, BR-68, BR-87, BR-88, BR-111 | Must |
| US-06.02 | EP-06 | GĐ1 §4.5; D-09, D-12, D-20; 04 §3 | BR-43, BR-44, BR-53, BR-61 | Must |
| US-06.03 | EP-06 | GĐ1 §4.6, §7; D-01, D-03, D-09; T-BA-112 | BR-93, BR-94, BR-96, BR-121 | Must |
| US-06.04 | EP-06 | GĐ1 §4.6; D-03 | BR-44, BR-45, BR-93, BR-94, BR-96 | Must |
| US-06.05 | EP-06 | GĐ1 §4.6, §4.7; 04 §3; D-21 | BR-93, BR-95, BR-96, BR-99 | Must |
| US-06.06 | EP-06 | GĐ1 §4.6; Q-38 | BR-44, BR-45, BR-52, BR-93 | Could |

Sửa 2026-10-06: AC-06.01.3, .11, AC-06.01.12 (mới); AC-06.02.4; AC-06.03.1, .4; AC-06.04.7, .9; AC-06.05.7.
Sửa 2026-10-07: AC-06.01.3 (D-22), .8, .11, .12 (nhãn T-BA-58), AC-06.01.13 (mới, D-19); ghi chú trần ngày (D-21); AC-06.02.4 (D-20); AC-06.05.6 (D-21).
Sửa 2026-10-19 theo `review/mockup-tong-hop.md` S6: AC-06.03.8 (mới, cấm cơ chế ngẫu nhiên, T-BA-112). Quy tắc đã cấp: BR-121.

Sửa 2026-10-19 theo `review/lan-4.md`: T-BA-127 (AC-06.03.8 và dòng US-06.03 dẫn BR-121); T-BA-131 (nhãn "nguồn cũ đã xóa").

**Ước lượng Must EP-06:** không đổi (US-06.01 giữ M).

### BR đã cấp (`03-quy-tac.md` §Shop)

Ánh xạ: BR-mới-1 → BR-94; BR-mới-2 → BR-95; BR-mới-3 → BR-96; BR-mới-4 → BR-88; BR-mới-5 → BR-93.

| Đề xuất | Nội dung cần chốt | Story |
| --- | --- | --- |
| BR-94 (BR-mới-1) | Mua hàng: một giao dịch nguyên tử (ghi `SHOP_PURCHASE` + sở hữu); dùng giá server lúc xác nhận; mỗi món chỉ mua 1 lần/người; không hoàn Coins | US-06.04, US-06.06 |
| BR-95 (BR-mới-2) | Trang bị: mỗi loại (khung, hình nền, danh hiệu) tối đa 1 món đang dùng; chỉ trang bị món đã sở hữu; trang bị/gỡ không tốn Coins | US-06.05, US-06.06 |
| BR-96 (BR-mới-3) | Món ĐÃ ẨN: không bán nữa, người đã mua giữ và vẫn trang bị được; giá đổi không ảnh hưởng đơn cũ | US-06.03, US-06.04, US-06.05 |
| BR-88 (BR-mới-4) | Coins bù khi khiếu nại MIỄN TRỪ: dòng `SESSION_REWARD` mới (`reason = APPEAL_RESTORE`), trần theo ngày của phiên; không dùng `ADMIN_ADJUST` (đã chốt trong BR-88) | US-06.01 |
| BR-93 (BR-mới-5) | Danh mục Shop: thuộc tính bắt buộc; trạng thái ĐANG BÁN / ĐÃ ẨN | US-06.03 |

## Q- liên quan (đã ghi sổ)

Đã cấp số chính thức trong `ba/02-so-quyet-dinh.md`, trạng thái `Chờ`.

| Mã | Câu hỏi | Đề xuất | Ảnh hưởng |
| --- | --- | --- | --- |
| Q-98 | Giá đồ Shop bao nhiêu? | Khung 60–150, hình nền 100–250 Coins (≈ 1–3 ngày đạt trần); danh hiệu 50 | US-06.03, 06.04 |
| Q-99 | Có cho hoàn/trả đồ đã mua? | Không hoàn; xác nhận trước khi mua | US-06.04 |
| Q-100 | Danh hiệu bán trong Shop có được trùng/giống huy hiệu thành tích? | Không; danh hiệu chỉ mang tính trang trí, không gợi ý thành tích hay xếp hạng | US-06.06 |
| Q-101 | Lịch sử Coins có hiện dòng “0 Coins — mất thưởng tập thể / đạt trần” để người dùng hiểu? | Không ghi vào sổ cái (BR-41); hiện ở kết quả phiên và lịch sử phiên | US-06.02 |
| Q-102 | Quản trị đổi `coins_25`/`coins_50`/`coins_daily_cap` giữa ngày thì áp từ khi nào? | Áp cho phiên có `ends_at` sau thời điểm đổi; trần tính theo giá trị hiện hành (đã ghi ở BR-111) | US-06.01 |
| Q-103 | Có đồ mặc định miễn phí cho tài khoản mới? | Có 1 khung + 1 hình nền mặc định, không hiện trong Shop | US-06.03, 06.05 |
