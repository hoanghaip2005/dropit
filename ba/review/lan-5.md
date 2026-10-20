# Báo cáo review lần 5 — xác nhận cổng G2

Phạm vi review: `srs/00-SRS.md` và mọi tệp nó liên kết (`srs/01-pham-vi.md`, 9 tệp `srs/02-ep0*.md`, `srs/03-quy-tac.md`, `srs/04-nfr-rieng-tu.md`, `srs/05-tham-chieu-ky-thuat.md`, `views/*`, `backlog.md`, `02-so-quyet-dinh.md` D-01…D-29 và Q-01…Q-152, `03-truy-vet.md`, `review/lan-4.md`); đối chiếu GĐ1 bản 1.1, Quy trình, `CLAUDE.md` · Ngày: 2026-10-19 · Người review: ba-reviewer

Ghi chú:
- Lỗi mới đánh số từ **T-BA-132**.
- **Chỉ đạo người dùng:** Q-140, Q-141, Q-142, Q-149…Q-152 và việc duyệt quy tắc riêng tư **không** chặn cổng — coi là giả định đã gắn nhãn; báo cáo chỉ ghi chú.
- Việc lần này **không** phải T-BA-21: không sửa `03-truy-vet.md`. Chỉ sửa số liệu và liên kết trong `srs/00-SRS.md` §4, §5 (xem mục E).

## A. Lỗi lan-4 (T-BA-123…131) — kiểm trên tệp thật

| Việc | Mức cũ | Tình trạng | Bằng chứng / phần còn lại |
| --- | --- | --- | --- |
| T-BA-123 | TB | **Đã sửa (phần chính), phát sinh lệch** | D-29; BR-118 (1)–(4); §2.2 thêm dòng WAITING → ABSENT và FOCUSING/GRACE/PAUSED → EXITED; AC-03.04.7–10; V-06, V-07; 05 §2 `session:leave`; K-16. Lệch còn lại: BR-118 nói màn **đếm ngược** có nút, AC-03.04.10 (b) và V-07 nói không → T-BA-132; số dòng §3 trùng → T-BA-133 |
| T-BA-124 | TB | Đã sửa | NFR-01 chỉ đo push cho người không có trạng thái chưa kết thúc; máy 3 khóa màn hình "0 push", banner ≤ 2 s. Dòng SNS ở 04 Ánh xạ AWS, 05 §2 đoạn cuối, K-02 khớp BR-27/BR-82, AC-03.09.9, AC-04.01.7 |
| T-BA-125 | TB | Đã sửa | Không AC/dòng Liên quan nào còn dẫn BR-25/BR-69 (chỉ còn trong ghi chú lịch sử sửa). Còn câu D-25 "BR-25, BR-69, BR-114 viết lại" chưa có ghi chú "Hủy" → gộp vào T-BA-135 |
| T-BA-126 | Thấp | Đã sửa, phát sinh lệch | BR-115 tie-break (tên → thời điểm vào nhóm → `user_id`) + ngoại lệ CN đứng đầu; AC-02.06.7, AC-08.02.11 khớp; BR-117 có tiêu chí kiểm; AC-02.06.6 có chỉ số riêng từng nhóm + thứ tự tên nhóm. Lệch mới: "ngoại lệ duy nhất" của BR-115 trái AC-08.10.1/.9 → T-BA-134 |
| T-BA-127 | Thấp | Đã sửa | AC-03.10.7 và ghi chú US-03.10 gỡ "cần BR mới"; AC-04.07.5, AC-04.08.1, AC-04.08.9 theo BR-87; AC-06.03.8 dẫn BR-121; US-03.14 dẫn BR-119; bảng Q- EP-08 "đã ghi sổ". Sót: ghi chú US-08.10 "US-05.09 'lối vào duy nhất' theo 04 §3" → T-BA-138 |
| T-BA-128 | Thấp | **Một phần** | Đã sửa: EP-04 "P18 (D-22)"; ghi chú US-04.01 "≥ 3 máy"; cấp **NFR-P19** thay "NFR-P04a". Còn: 01 A-16 vẫn "(thay NFR-P18, BR-38)"; 01 dòng nguồn vẫn "D-01…D-24"; mã "NFR-P04a" vẫn được dẫn ở US-08.10 (Liên quan, AC-08.10.2, Truy vết), US-05.09 (Truy vết EP-05), `03-truy-vet.md` (US-01.05, US-05.09, US-08.10), `views/V46` → T-BA-135 |
| T-BA-129 | Thấp | **Một phần** | Đã sửa: Q-150 (Chờ); BR-75 (c) dẫn Q-150; 00-SRS §7. Còn: 01 §2 dòng ND vẫn "theo đề xuất Q-135 — D-25 chưa nêu rõ"; AC-02.01.4 không gắn (giả định, Q-150); 01 A-15 vẫn "(giả định, Q-14, Q-32)" (đã chốt D-19/D-20); truy vết US-05.09 (EP-05) vẫn dẫn Q-135 → T-BA-135 |
| T-BA-130 | Thấp | Đã sửa | AC-03.03.1: nút "Tạm dừng" *(chỉ kiểm khi US-03.06 trong phạm vi)*; thêm nút "Rời phiên" (AC-03.04.7) |
| T-BA-131 | Thấp | **Một phần** | Đã sửa trong `srs/*` (03 dòng 8, 9; EP-04 dòng 5, 9; EP-05, EP-06). Còn: `01-viec-ba.md` dòng 39, 42, 48, 52, 56 (T-BA-22 vẫn ghi đầu ra `review/lan-2.md`); `review/mockup-tong-hop.md` dòng 4; EP-07 AC-07.08.5 và ghi chú US-07.10 ("lan-1 #20", "lan-1 #17") không kèm "(nguồn cũ đã xóa)". Không chặn |

Tổng lan-4: **Đã sửa 6** (T-BA-123 phần chính, 124, 125, 126, 127, 130) · **Một phần 3** (T-BA-128, 129, 131).

### A2. Lỗi lần 3 còn mở (ghi lại, không chặn)

| Việc | Tình trạng lần 5 | Ghi chú |
| --- | --- | --- |
| T-BA-44 | Còn | Phiên tự do (Should) chưa có story |
| T-BA-45 | Còn | Chưa cấp FR-/TC-; 05 §6 K-01…K-16 làm gốc được |
| T-BA-62 | Còn | Bảng "Nhóm câu ưu tiên" vẫn #1 Q-97, #9 Q-96 (đã chốt); dòng 151 "Ưu tiên còn lại: Q-135" (đã chốt D-25) |
| T-BA-69 | Còn (không chặn) | Gắn Q-140 PA-C |
| T-BA-76 | Một phần | 04 §2 và dòng SNS đã sửa. Còn: EP-01 ghi chú US-01.06 "nếu BR-71 còn liệt kê `notify_mode`…"; sổ Q-72 vẫn "Đổi `notify_mode`…" không ghi "(không còn áp dụng — D-20)"; `01-viec-ba.md` T-BA-10 "EP-04 Thông báo chủ nhóm" |
| T-BA-77 | Còn | 03 bảng "Tham số mới": `invite_code_len` vẫn "Admin" (BR-112: cố định 8); `reminder_min` vẫn "chủ nhóm theo nhóm" |
| T-BA-78 | Một phần | Không đổi so với lần 4: backlog T-02 "EC2+ALB … ElastiCache", US-06.03 "T-05 (S3+CloudFront)", US-08.01 "(EventBridge + Lambda)", backlog §6 Sprint 3, 01 §5 EP-08, 01 C-02 |
| T-BA-79 | Một phần | Q-87 có đề xuất "không push, banner khi quay lại" nhưng chưa nêu đây là diễn giải "báo ngay" của D-20 |

## B. Lỗi mới (từ T-BA-132)

| # | Mức (Cao/TB/Thấp) | Tệp:mục | Vấn đề | Loại (mâu thuẫn / thiếu / không kiểm tra được / sai nguồn / vi phạm riêng tư) | Đề xuất sửa | Việc mới |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | TB | `03-quy-tac.md` BR-118 (câu mở đầu, mục (2)), §3 dòng "45 · WAITING (COUNTDOWN)"; `05-tham-chieu-ky-thuat.md` K-16 (c); sổ Q-149 ↔ EP-03 AC-03.04.10 (b) (Must); `views/V07` dòng 58; `views/00-danh-muc-man.md` dòng 144 | BR-118: "màn phiên (phòng chờ, **đếm ngược**, đang tập trung) có nút 'Rời phiên'"; mục (2) "WAITING (phiên SCHEDULED/COUNTDOWN)"; K-16 (c) kiểm "WAITING trong COUNTDOWN → xác nhận". Ngược lại AC-03.04.10 (b), V-07, danh mục: màn đếm ngược 5s **không** có nút. Người kiểm thử theo BR sẽ tìm nút ở V-07; theo AC thì không có | mâu thuẫn | BR-118: bỏ "đếm ngược" khỏi danh sách màn; ghi "V-07 không có nút; `session:leave` bấm ở V-06 mà server nhận khi phiên đã COUNTDOWN (trước `started_at`) vẫn → ABSENT". Sửa §3 dòng tương ứng và K-16 (c) thành "WAITING ở V-06"; Q-149 bỏ chữ "đếm ngược" | T-BA-132 |
| 2 | TB | `03-quy-tac.md` §3 bảng quyết định (dòng 187–196); dẫn từ BR-118 ghi chú đầu tệp ("§3 dòng 45–49"), EP-03 US-03.12 Liên quan "§3 … #45", AC-03.12.2 "§3 #28, #45", `views/V11` "§3 #46, #47" | Đợt sửa T-BA-123 thêm 5 dòng mang số **45–49**, trong khi bảng đã có dòng 45–49 (EXITED trước sự cố; banner FOCUSING; GRACE/PAUSED; người ngoài phiên; người đã kết thúc). Mỗi số 45–49 nay chỉ hai ca khác nhau, vd. "#45" vừa là "Rời phiên ở WAITING → ABSENT" vừa là "EXITED trước sự cố". Tham chiếu từ US-03.12 và V-11 không còn xác định được | mâu thuẫn (tham chiếu mơ hồ) | Đánh lại 5 dòng mới thành #53–#57 (không đổi số cũ, theo quy ước "không đổi số đã cấp"); sửa ghi chú đầu 03 và mọi dẫn "§3 #45–49" của luồng "Rời phiên" (BR-118, `03-truy-vet.md` nếu có) | T-BA-133 |
| 3 | TB | `03-quy-tac.md` BR-115 ↔ EP-08 AC-08.10.1, AC-08.10.9 (US-08.10, Must); `views/V46`; `views/V11` (xếp hàng banner) | BR-115: **mọi** danh sách người trong nhóm, **kể cả màn chi tiết phiên của chủ nhóm**, sắp theo tên; "**Ngoại lệ duy nhất**: CN đứng đầu danh sách thành viên". AC-08.10.1 và AC-08.10.9 lại yêu cầu "danh sách rời app theo **giờ server** tăng dần". Sắp theo giờ không phải xếp hạng, nhưng chữ "ngoại lệ duy nhất" làm hai yêu cầu Must trái nhau khi kiểm | mâu thuẫn | BR-115 thêm ngoại lệ thứ hai: "danh sách **sự kiện** (rời app, banner, thông báo) sắp theo giờ server; danh sách **người** sắp theo tên". Hoặc AC-08.10.1/.9 đổi sang sắp theo tên — chọn một, ghi rõ | T-BA-134 |
| 4 | Thấp | `srs/01-pham-vi.md` dòng 3, 23, A-15, A-16; EP-02 AC-02.01.4; EP-05 bảng Truy vết US-05.09; EP-08 US-08.10 (Liên quan, AC-08.10.2, Truy vết); `03-truy-vet.md` dòng US-01.05, US-05.09, US-08.10 (thiếu dòng NFR-P19); `views/V46` dòng 3; `02-so-quyet-dinh.md` D-25 | Phần còn lại của T-BA-128/129/125: mã **NFR-P04a** (đã đổi thành NFR-P19) vẫn được dẫn — trỏ tới mã không còn trong 04 §1; A-16 "(thay NFR-P18…)" sai mã (đúng: NFR-P16); nguồn 01 "D-01…D-24" (đã có D-29); 01 dòng ND và US-05.09 dẫn Q-135 (đã chốt) thay Q-150; AC-02.01.4 dùng giả định Q-150 mà không gắn nhãn; A-15 dẫn Q-14/Q-32 (đã chốt); D-25 ghi "BR-25, BR-69 viết lại" trong khi 03 ghi Hủy | sai nguồn / giả định không gắn nhãn | Thay NFR-P04a → NFR-P19 ở mọi chỗ, thêm dòng NFR-P19 vào `03-truy-vet.md` (T-BA-21 lần sau); A-16 → "D-22 (thay NFR-P16, BR-38 bản cũ)"; 01 nguồn → D-01…D-29; dòng ND, US-05.09 → Q-150; AC-02.01.4 gắn "(giả định, Q-150)"; A-15 → D-19, D-20; D-25 thêm ghi chú "(BR-25, BR-69 Hủy; BR-114 viết lại)" | T-BA-135 |
| 5 | Thấp | `02-so-quyet-dinh.md` D-27, D-28, Q-147, Q-148 ↔ `03-quy-tac.md` BR-105, BR-116; EP-08 US-08.07, US-08.10; `04-nfr-rieng-tu.md`; `views/00-danh-muc-man.md` dòng 181–182 | D-27 (email không tracking pixel/link theo dõi) và D-28 (V-46 không tự làm mới, chỉ kéo để làm mới) chỉ có ở `views/V50`, `views/V46`; **không** có trong BR, NFR hay AC nào → không có tiêu chí kiểm ở cấp yêu cầu. Q-147/Q-148 ghi "Đã chốt → xem D-" không có số; danh mục màn vẫn liệt kê như câu hỏi mở | thiếu (D- chưa áp) | BR-105 + AC mới ở US-08.07: "email không có ảnh/link theo dõi (D-27)"; BR-116 + AC mới ở US-08.10: "không đẩy/không tự làm mới, chỉ kéo để làm mới (D-28)"; Q-147 → "D-27", Q-148 → "D-28"; danh mục ghi "đã chốt" | T-BA-136 |
| 6 | Thấp | `views/00-danh-muc-man.md` dòng 80 | "Tổng: **40** màn thành viên/chủ nhóm (V-01…V-35, V-40…V-50)" — thực tế 35 + 11 = **46** (46 + 5 quản trị = 51 mã). (00-SRS ghi "27 màn có đặc tả", thực tế 26 tệp — đã sửa ở mục E) | sai số liệu | Sửa thành 46 | T-BA-137 |
| 7 | Thấp | EP-08 ghi chú US-08.10 ("US-05.09 (Should, 'lối vào duy nhất' theo 04 §3)"); `02-so-quyet-dinh.md` dòng 151 | Ghi chú lỗi thời: 04 §3 đã đổi lối vào chính sang US-08.10 (Q-146); dòng 151 còn ghi Q-135 là "ưu tiên còn lại" dù đã chốt D-25 | mâu thuẫn (nhẹ) | Sửa ghi chú US-08.10 theo 04 §3 hiện hành; gộp sửa dòng 151 với T-BA-62 | T-BA-138 |
| 8 | Thấp | EP-04 AC-04.01.1 (Must) ↔ `03-quy-tac.md` dòng 15–16 (`MEMBER_EXITED` chuẩn), BR-38; AC-03.09.1; `views/V11`, `V16` | AC-04.01.1 kiểm câu "A đã rời app – phiên <tên lịch> lúc hh:mm:ss" cho O và D, trong khi câu chuẩn là "‹Tên› đã rời phiên lúc hh:mm:ss" và A là người EXITED **đầu tiên** nên O, D phải nhận **một** thông báo gộp có `SESSION_FORFEITED` (BR-38, AC-03.09.1). Hai AC Must kiểm hai câu chữ khác nhau cho cùng sự kiện | mâu thuẫn (câu chữ) | AC-04.01.1 dùng câu chuẩn và nêu rõ phần `SESSION_FORFEITED` gộp (hoặc dẫn AC-03.09.1 cho nội dung, chỉ giữ kiểm người nhận + độ trễ) | T-BA-139 |
| 9 | Thấp | `03-quy-tac.md` §2.2; BR-19, BR-63; `views/V06` dòng 38 | Mất kết nối khi đang **WAITING** chưa có dòng trong máy trạng thái (DISCONNECTED chỉ từ FOCUSING/PAUSED). V-06 tự đặt hành vi "nối lại trước `started_at` giữ WAITING; không nối được đến hạn vào → như 'Đã qua hạn vào'" gắn (giả định) nhưng không có Q-; chưa rõ đến `started_at` mà vẫn mất mạng thì WAITING → GRACE (BR-64), DISCONNECTED hay ABSENT | giả định không có Q- / thiếu | Tạo Q- mới (Chờ) và thêm dòng §2.2 "WAITING · mất kết nối" theo đề xuất | T-BA-140 |

**Thống kê lỗi mới:** Cao **0** · TB **3** (T-BA-132…134) · Thấp **6** (T-BA-135…140) · tổng 9.

Kiểm tra không phát hiện lỗi:
- **Sót bản cũ:** cược, nổ phòng, Host/Guest, phòng 2–6 người, Điểm Uy Tín chỉ còn ở câu phủ định (05 dòng 6, 88; 03 dòng 5, 248; 01 §6, §8.1; EP-04, EP-06 đầu tệp; V-07, V-45). Hợp lệ.
- **Riêng tư (ràng buộc cứng):** `session:leave` chỉ gửi trong phiên, không thêm dữ liệu; BR-118 (3) không xếp hàng gửi sau. NFR-01 mới đo "0 push" cho người đang úp máy (không dụ rời app, D-08). Không yêu cầu nào thu thập ngoài phiên, đọc nội dung máy, hay cho CN/quản trị đọc nhật ký (BR-05, BR-34, BR-100, NFR-P01, NFR-P02, NFR-P05). D-27 (không tracking pixel) đã có ở V-50 — chỉ thiếu ở cấp BR (T-BA-136, không phải vi phạm).
- **BR-82 / NFR-01 / 05:** khớp nhau và khớp AC-03.09.3, .6, .9, AC-04.01.1, .2, .7, K-02.
- **BR-118 / D-29 ở trạng thái ACTIVE:** BR-118 (1), §2.2, AC-03.04.7–9, AC-03.04.10 (c), V-06, 05 §2, K-16 (a)(b)(d)(e)(f) khớp. WAITING → ABSENT là giả định Q-149 (không chặn theo chỉ đạo).
- **D-25…D-29:** D-25 (BR-114, BR-60, AC-03.01.3, AC-04.01.9, AC-08.10.9), D-26 (NFR-19, NFR-24, T-06), D-29 (như trên) đã áp. D-27, D-28 chỉ ở views → T-BA-136.
- **Số liệu backlog (đếm lại):** 92 US = Must 44 + Should 37 + Could 2 + Won't 2 + Hủy 7. Must story 74 điểm + T-01…T-06 12 điểm = 86. Sprint 19 / 25 / 26 / 16 (cộng lại từng dòng: khớp). Should 62 điểm.
- **BR:** 121 mã (BR-01…BR-121, không thiếu số), **116 còn hiệu lực**, 5 Hủy (BR-10, BR-25, BR-69, BR-83, BR-84); BR-86 (a) Hủy một phần.
- **NFR:** 44 mã (NFR-01…NFR-24, NFR-15a, NFR-P01…NFR-P19), **42 còn hiệu lực**, 2 Hủy (NFR-15a, NFR-P16).
- **Màn:** 51 mã V- (V-01…V-35, V-40…V-50, V-60…V-64); 26 tệp đặc tả trong `views/` (không kể `00-danh-muc-man.md`).
- **Liên kết 00-SRS:** mọi đích tồn tại (`srs/*`, `views/00-danh-muc-man.md`, `backlog.md`, `03-truy-vet.md`, `02-so-quyet-dinh.md`, `lam-ro/*`, `review/lan-4.md`, `review/mockup-tong-hop.md`, `mockup/`, `spike/t01-lifecycle/README.md`). Không có liên kết hỏng.
- **AC kiểm tra được:** AC mới (AC-03.04.7–10, K-16) có điều kiện và kết quả đo được; không có "nhanh", "dễ dùng".
- **Truy vết:** không thêm US mới; 0 US không nguồn, 0 mục Must GĐ1 §7 mồ côi (như lần 4). Mã NFR-P04a là tham chiếu sai, không làm US mồ côi (T-BA-135).

## C. Checklist cổng G2 (`00-dieu-phoi.md` §6)

| Mục | Kết quả | Lý do |
| --- | --- | --- |
| Q-01…Q-08 đã thành D- (hoặc có giả định được cả nhóm chấp nhận) | **Đạt** | Không đổi so với lần 4: Q-01 → D-05, Q-02 → D-06, Q-03 → D-20, Q-04 → D-21, Q-07 → D-07; Q-05, Q-06, Q-08 có giả định gắn nhãn |
| Mọi epic Must có story kèm AC (bình thường + lỗi) | **Đạt** | 44 story Must đều có AC Bình thường và Lỗi; US-03.04 thêm AC-03.04.8 (Bình thường), .9 (Lỗi), .10 (Biên) |
| Quy tắc phiên/Coins/chuỗi/báo cáo không mâu thuẫn với story | **Chưa đạt** | Lỗi chặn của lần 4 (T-BA-123, 125) đã sửa. Còn 3 lệch mới do đợt sửa: BR-118 cho nút ở màn đếm ngược, AC-03.04.10 (b) cấm (T-BA-132); số dòng §3 45–49 trùng làm tham chiếu từ US-03.12, V-11 mơ hồ (T-BA-133); BR-115 "ngoại lệ duy nhất" trái AC-08.10.1/.9 (T-BA-134). Cả ba đều sửa một dòng |
| Bản quy tắc riêng tư & minh bạch được cả nhóm đồng ý | **Đạt (theo chỉ đạo)** | Chưa có D- duyệt 04 §1–§5; người dùng cho coi là giả định gắn nhãn. Vẫn là điều kiện GĐ1 §12 trước khi dùng thật |
| Bảng truy vết không còn FR/US mồ côi | **Đạt** | 92 US, 0 không nguồn, 0 Must mồ côi. Ghi chú: còn dẫn mã NFR-P04a, thiếu dòng NFR-P19 (T-BA-135, Thấp) |
| Báo cáo `ba-reviewer` không còn lỗi mức **Cao** | **Đạt** | Lần 5: 0 lỗi Cao |
| Backlog đã ước lượng sơ bộ và xếp vào 4 sprint | **Đạt (theo chỉ đạo)** | Đủ ước lượng, 4 sprint, cộng đúng (86 = 19 + 25 + 26 + 16). 86 > 83 (D-17) chờ Q-140 — không chặn theo chỉ đạo |

**Kết luận:** **Chưa đạt** cổng G2 · Số lỗi Cao: **0** (TB: 3, Thấp: 6; lan-4 còn 3 Một phần; lần 3 còn 4 Còn, 3 Một phần — đều không chặn).

Để qua cổng chỉ cần sửa mục 3 checklist, cả ba đều nằm trong `03-quy-tac.md` (cộng một dòng ở 05 và Q-149):
1. **T-BA-132** — bỏ "đếm ngược" khỏi câu mở BR-118; sửa §3 dòng tương ứng, K-16 (c), Q-149.
2. **T-BA-133** — đánh lại 5 dòng §3 mới thành #53–#57.
3. **T-BA-134** — BR-115 thêm ngoại lệ "danh sách sự kiện theo giờ server" (hoặc sửa AC-08.10.1/.9).

Sau ba sửa này, mục 3 đạt; không cần chạy lại toàn bộ review, chỉ cần kiểm lại ba chỗ trên. Các lỗi Thấp (T-BA-135…140) và lỗi cũ còn mở không chặn cổng.

Giả định đã gắn nhãn, không chặn (chỉ đạo người dùng): Q-140 (Must 86 > 83), Q-141 (sĩ số không gồm CN), Q-142 (≥1 iPhone thật), Q-149 (Rời phiên ở phòng chờ → ABSENT), Q-150 (TV nhóm A làm chủ nhóm B), Q-151, Q-152 (chờ spike T-01), duyệt quy tắc riêng tư 04 §1–§5.

## D. Câu hỏi người dùng nên trả lời trước thiết kế

| # | Mã | Câu hỏi | Vì sao |
| --- | --- | --- | --- |
| 1 | (T-BA-134) | Màn chi tiết phiên của chủ nhóm: danh sách người rời app sắp theo giờ (như AC-08.10.1) hay theo tên (như BR-115)? | Chặn mục 3 G2; đề xuất: theo giờ, vì là danh sách sự kiện |
| 2 | Q- mới (T-BA-140) | Thành viên đang ở phòng chờ mà mất mạng đến `started_at`: GRACE, DISCONNECTED hay ABSENT? | Chưa có trong máy trạng thái |
| 3 | Q-140 | Chọn PA-A / PA-A2 / PA-B / PA-C | Không chặn; cần trước Sprint 1 |

## E. Sửa số liệu và liên kết trong `srs/00-SRS.md` (được phép)

| Chỗ | Trước | Sau |
| --- | --- | --- |
| §4 dòng Review | chỉ có `lan-4`, `mockup-tong-hop` | thêm liên kết `../review/lan-5.md` |
| §5 tiêu đề | "theo `backlog.md` và lan-4" | "theo `backlog.md` và lan-5" |
| §5 User story | "số còn lại là Hủy (gộp theo D-14, D-25)" | "Hủy 7 (D-14 ×4, D-16, D-21, D-25)" |
| §5 Quy tắc nghiệp vụ | "121 mã …, một số mã đã Hủy (vd. BR-25, BR-69)" | "121 mã; 116 còn hiệu lực; 5 Hủy (BR-10, BR-25, BR-69, BR-83, BR-84)" |
| §5 NFR | "44 mã NFR" | "44 mã (NFR-01…24, NFR-15a, NFR-P01…P19); 42 còn hiệu lực; 2 Hủy (NFR-15a, NFR-P16)" |
| §5 Màn hình | "27 màn có đặc tả chi tiết" | "26 tệp đặc tả" (đếm lại `views/`) |

Không sửa §8 (trạng thái cổng) vì không thuộc phần số liệu/liên kết — điều phối viên cập nhật theo kết luận trên.
