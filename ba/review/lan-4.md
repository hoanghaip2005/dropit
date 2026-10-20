# Báo cáo review lần 4 — review cuối trước cổng G2 (T-BA-21 + review)

Phạm vi review: `srs/01-pham-vi.md`, 9 tệp `srs/02-ep0*.md`, `srs/03-quy-tac.md` (gồm BR-115…BR-121), `srs/04-nfr-rieng-tu.md` (gồm NFR-23, NFR-24, NFR-P18), `srs/05-tham-chieu-ky-thuat.md` (mới), `backlog.md`, `02-so-quyet-dinh.md` (D-01…D-26, Q-01…Q-146), `03-truy-vet.md` (dựng lại lần này), `review/lan-3.md`, `review/mockup-tong-hop.md` §3; đối chiếu GĐ1 bản 1.1, Quy trình, `CLAUDE.md` · Ngày: 2026-10-19 · Người review: ba-reviewer

Ghi chú:
- Lỗi mới đánh số từ **T-BA-123**. SquadFocus gốc, `lan-1`, `lan-2`, `mockup-1…3` đã xóa có chủ đích; tham chiếu có ghi "(nguồn cũ đã xóa)" là hợp lệ.
- **Chỉ đạo người dùng:** Q-140, Q-141, Q-142 và việc duyệt quy tắc riêng tư **không** là điểm chặn cổng — coi là giả định đã gắn nhãn; báo cáo chỉ ghi chú.
- T-BA-21: đã cập nhật `ba/03-truy-vet.md` (US-03.13 → Hủy; thêm US-03.14, US-08.10; BR-115…BR-121; NFR-23, NFR-24, NFR-P18; bảng hạng mục kỹ thuật T-01…T-06; thay BR-25/BR-69 Hủy bằng BR-114/BR-60; tổng 92 US / 44 Must / 86 điểm). Không sửa tệp yêu cầu nào khác.

## A. Tình trạng lỗi còn mở từ lần 3 (T-BA-44, 45, 55…80)

| Việc | Mức cũ | Tình trạng | Bằng chứng / phần còn lại |
| --- | --- | --- | --- |
| T-BA-44 | TB | **Còn** | Phiên tự do (Should) chưa có story; 01 §5 Should ghi "Chưa có story". Không chặn cổng |
| T-BA-45 | TB | **Còn** | Chưa cấp FR-/TC-. Không chặn cổng. 05 §6 có K-01…K-15 (tham khảo) — có thể làm gốc cho TC- |
| T-BA-55…57 | TB | Đã sửa | Đã xác nhận ở lần 3; không tái phát |
| T-BA-58 | TB | Đã sửa | AC-08.02.4 gắn nhãn US-01.11; AC-04.01.9 viết lại theo D-25 (không còn phụ thuộc US-03.13); AC-01.07.2 gắn nhãn PAUSED. Phát sinh ca mới tương tự ở AC-03.03.1 → T-BA-130 |
| T-BA-62 | Thấp | **Còn** | Bảng "Nhóm câu ưu tiên" `02-so-quyet-dinh.md` vẫn #1 Q-97, #9 Q-96 (đã chốt D-11, D-12) |
| T-BA-68 | Thấp | Đã sửa | AC-05.06.10, .11 kiểm câu cảnh báo NFR-P17 và mặc định tắt |
| T-BA-69 | TB | **Còn (không chặn)** | US-03.09 vẫn M, US-04.01 vẫn M; trùng phạm vi chưa tách. Gắn với Q-140 PA-C — theo chỉ đạo, chỉ ghi chú |
| T-BA-70 | TB | Đã sửa | BR-08 định nghĩa `late_join_max_min = 0` khi chưa làm US-03.11; AC-03.10.7, .8. Ghi chú cũ "cần BR mới" còn sót → T-BA-127 |
| T-BA-71 | TB | Đã sửa | 04 §3 dòng "Kết quả phiên" → "~ chỉ cấp phiên", có cách kiểm qua API |
| T-BA-72 | TB | Đã sửa | `gia-dinh.md` A-07b (Cao), A-14 sửa theo D-05; kịch bản TP-11b, TP-12b, NV-07b, NV-07c |
| T-BA-73 | Thấp | Đã sửa | AC-03.02.7 (Lỗi, Must) |
| T-BA-74 | Thấp | Đã sửa | NFR-15a Hủy; NFR-23 đo ngắt Wi-Fi ≥ 20 giây, kiểm LOST |
| T-BA-75 | Thấp | Đã sửa | NFR-P16 Hủy, NFR-P18 mới, NFR-P17 có dòng ở 04 §1. Còn sót "NFR-P16 bản mới" ở EP-04 → T-BA-128 |
| T-BA-76 | Thấp | **Một phần** | Đã sửa: backlog §5.1 ("có tên"), AC-01.10.1 (tối đa 1 nhóm). Còn: 04 §2 "Khi nội dung đồng ý thay đổi (ví dụ đổi chế độ báo)"; 04 Ánh xạ AWS dòng SNS "đối chiếu lại BR-82/BR-84/BR-91" (BR-84 Hủy); EP-01 ghi chú US-01.06 "nếu BR-71 còn liệt kê `notify_mode`"; sổ Q-72 câu hỏi vẫn "Đổi `notify_mode`…" không có ghi chú "(không còn áp dụng — D-20)"; `01-viec-ba.md` T-BA-10 "EP-04 Thông báo chủ nhóm" |
| T-BA-77 | Thấp | **Còn** | `03-quy-tac.md` bảng "Tham số mới": `invite_code_len` vẫn "Admin" (BR-112: cố định 8); `reminder_min` vẫn "chủ nhóm theo nhóm" (BR-112 chỉ Admin) |
| T-BA-78 | Thấp | **Một phần** | 04 Ánh xạ AWS đã có "Quy tắc Must ↔ dịch vụ". Còn: backlog T-02 vẫn "EC2+ALB … ElastiCache"; US-06.03 phụ thuộc "T-05 (S3+CloudFront)"; US-08.01 tên "(EventBridge + Lambda)"; backlog §6 Sprint 3 "EventBridge + Lambda"; 01 §5 Must EP-08 "Báo cáo tháng tự động (EventBridge + Lambda)". Chính 04 ghi "Kiểm tra: rà backlog — không story Must nào ghi dịch vụ Should/Could" → hiện không đạt |
| T-BA-79 | Thấp | **Một phần** | Q-87 đã ở nhóm ưu tiên (#5). Câu Q-87 trong sổ chưa nêu rõ diễn giải "báo ngay (D-20) với người đang úp máy = xếp hàng, hiện khi mở khóa" |
| T-BA-80 | Thấp | Đã sửa | D-26 + Q-142; NFR-19, C-04, T-01 dẫn Q-142 |

Tổng lần 3: **Đã sửa 11 · Một phần 3 (T-BA-76, 78, 79) · Còn 5 (T-BA-44, 45, 62, 69, 77)**.

### A2. Lỗi SRS từ mockup (`mockup-tong-hop.md` §3)

| # | Việc | Tình trạng | Bằng chứng / phần còn lại |
| --- | --- | --- | --- |
| S1 | T-BA-108 | Đã sửa | AC-04.07.5 viết lại thành ca Lỗi (CN không khiếu nại được); BR-86 (a) Hủy, máy trạng thái khiếu nại bỏ ca "người gửi là CN". Ghi chú cũ "BR-86 (a) chờ ba-rules sửa" còn sót → T-BA-127 |
| S2 | T-BA-105 | Đã sửa | US-08.10 (Must, S, giả định) với AC-08.10.1–11; 04 §3 đổi lối vào chính sang US-08.10; Q-146 Chờ |
| S3 | T-BA-105 | Đã sửa | BR-116; AC-08.10.4 (phủ định thời gian thực), AC-08.10.5 (không can thiệp); ghi chú US-03.03; 01 §6 "Ngoài phạm vi" |
| S4 | T-BA-106 | Đã sửa | BR-115; AC-08.02.11, .12; AC-02.06.7; AC-08.05.4. Lệch quy tắc trùng tên → T-BA-126 |
| S5 | T-BA-107 | Đã sửa | BR-117; AC-02.06.6. Lệch nội dung hiển thị → T-BA-126 |
| S6 | T-BA-112 | Đã sửa | BR-121; AC-06.03.8 (chưa dẫn BR-121 → T-BA-127) |
| S7 | T-BA-117 | Đã sửa | 01 §6 dòng "Đọc / đồng bộ danh bạ…" |
| S8 | T-BA-86 | Đã sửa | 01 §8.1 bảng Tên UI / Cấm dùng |
| S9 | T-BA-97, T-BA-93 | Đã sửa, **phát sinh mâu thuẫn** | AC-01.01.7–10 (quên mật khẩu); AC-03.04.6, AC-03.08.9; BR-118. Nhưng BR-118 mâu thuẫn AC-03.04.7 → T-BA-123 |
| S10 | T-BA-102 | Đã sửa | US-03.14 (Should, giả định), BR-119 |
| S11 | T-BA-116 | Đã sửa | BR-120; 04 §3 "Ràng buộc ghi sẵn cho EP-10" |

Tổng S1–S11: **Đã sửa 11/11** (S4, S5, S9 có lỗi phát sinh ghi ở mục B).

## B. Lỗi mới (từ T-BA-123)

| # | Mức (Cao/TB/Thấp) | Tệp:mục | Vấn đề | Loại (mâu thuẫn / thiếu / không kiểm tra được / sai nguồn / vi phạm riêng tư) | Đề xuất sửa | Việc mới |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | TB | `03-quy-tac.md` BR-118 ↔ EP-03 AC-03.04.7 (Must); `views/V07-dem-nguoc.md`; `05-tham-chieu-ky-thuat.md` §2 | BR-118: "thành viên bấm **'Rời phiên'** và xác nhận → EXITED ngay (không qua GRACE)". AC-03.04.7: "**Không có nút 'Thoát phiên'/'Rời phòng'**… Khi bấm Back, app hiện xác nhận…". V07 cũng ghi "Không nút hủy/thoát". Ngoài ra: (a) BR-118 ca COUNTDOWN "coi như không vào, xử lý theo BR-08" — máy trạng thái §2.2 không có chuyển WAITING → INVITED/ABSENT, và BR-64 lại xử lý rời app trong COUNTDOWN thành GRACE; (b) BR-118 chỉ nói "khi phiên ACTIVE", không nói trạng thái GRACE/PAUSED/DISCONNECTED; (c) 05 §2 không có sự kiện socket cho "Rời phiên" | mâu thuẫn | Chốt một cách: hoặc (A) có nút "Rời phiên" + hộp xác nhận → sửa AC-03.04.7 và V07; hoặc (B) không có nút, chỉ hộp xác nhận khi bấm Back → sửa BR-118 thành "xác nhận rời khi bấm Back". Thêm dòng máy trạng thái §2.2 (WAITING + rời phiên chủ động → ?) cho khớp BR-64; thêm sự kiện `member:leave` ở 05 §2 nếu chọn (A) | T-BA-123 |
| 2 | TB | `04-nfr-rieng-tu.md` NFR-01, Ánh xạ AWS dòng SNS; `05-tham-chieu-ky-thuat.md` K-02 ↔ `03-quy-tac.md` BR-27, BR-82; AC-03.09.9, AC-04.01.7 | NFR-01 đo push ≤ 5 s cho "người trong phiên **đang không mở app**"; dòng SNS cũng gửi push tới "người trong phiên không đang mở app". BR-82, AC-03.09.9, AC-04.01.7: người có trạng thái chưa kết thúc (khóa màn hình, GRACE, PAUSED) **không** nhận push hệ thống, chỉ banner khi quay lại. Bộ đo NFR-01 sẽ bắt đúng hành vi mà BR-82 cấm (dụ rời app, D-08). K-02 "mọi người khác + chủ nhóm nhận ≤ 5 giây" cũng mơ hồ cho người đang úp máy | mâu thuẫn | NFR-01: người nhận push = người **không** có trạng thái chưa kết thúc trong phiên (CN, TV không trong phiên, người đã kết thúc) — theo BR-27; người đang trong phiên đo theo NFR-02 khi ở tiền cảnh, và đo "không có push" khi khóa màn hình. Sửa dòng SNS và K-02 tương ứng | T-BA-124 |
| 3 | TB | AC-03.01.3, AC-04.01.9, AC-08.01.7, AC-08.02.7 (đều Must); dòng Liên quan/Truy vết US-01.04, US-02.01, US-03.01, US-04.01, US-05.07, US-08.01, US-08.02, US-09.02; đầu EP-01, EP-04 "Quy tắc tham chiếu"; `02-so-quyet-dinh.md` D-25 ("BR-25, BR-69, BR-114 viết lại") | Story Must còn dẫn **BR-25, BR-69 đã Hủy** (D-25), có chỗ ghi "BR-69 bản viết lại theo D-25" trong khi BR-69 là "(Hủy …)". Kiểm thử theo AC sẽ trỏ tới quy tắc không còn hiệu lực. D-25 ghi "viết lại" nhưng `03-quy-tac.md` ghi Hủy | mâu thuẫn (tham chiếu mục Hủy) | Thay BR-25 → BR-114; BR-69 → BR-114 (a) và BR-60. Sửa câu D-25 thành "BR-25, BR-69 Hủy; BR-114 viết lại" (ghi chú, không sửa lịch sử quyết định) | T-BA-125 |
| 4 | Thấp | `03-quy-tac.md` BR-115, BR-117 ↔ AC-08.02.11, AC-02.06.6, AC-02.06.7 | (a) BR-115: trùng tên thì theo `user_id`; AC-08.02.11: trùng tên thì "theo thời điểm vào nhóm". (b) BR-115: danh sách thành viên sắp theo tên; AC-02.06.7: "CN hiện đầu, sau đó TV…". (c) BR-117: mỗi nhóm hiện **tỉ lệ hoàn thành phiên tháng hiện tại** và danh sách nhóm sắp theo tên nhóm; AC-02.06.6 liệt kê trường hiển thị không có chỉ số này và không kiểm thứ tự nhóm | mâu thuẫn | Thống nhất tie-break (một quy tắc); ghi ngoại lệ "CN đứng đầu" vào BR-115 hoặc bỏ khỏi AC; AC-02.06.6 thêm/bỏ chỉ số theo BR-117 và thêm kiểm thứ tự theo tên nhóm | T-BA-126 |
| 5 | Thấp | AC-03.10.7 + ghi chú US-03.10 + dòng Truy vết US-03.10 ("cần BR mới"); ghi chú US-08.10 ("ba-rules đang thêm BR-116, BR-115"); bảng Q- EP-08 ("Q-144, Q-146 mới, chưa ghi sổ" — đã có trong sổ); AC-04.07.5 ("BR-86 (a) chờ ba-rules sửa"); AC-04.08.9 ("người nhận BR-87 tính theo thời điểm miễn trừ" — BR-87 nay đã là "đúng người đã nhận") và AC-04.08.1 ("cùng nhóm người nhận như BR-27", lệch BR-87); AC-06.03.8 và ghi chú EP-06 chưa dẫn BR-121; US-03.14 chưa dẫn BR-119; EP-04 "tổng Must 83 điểm" (nay 86); EP-08 ghi chú US-08.01 | Ghi chú/nhãn lỗi thời sau khi BR mới đã cấp; một chỗ (AC-04.08.1 vs BR-87) là lệch người nhận đính chính | mâu thuẫn (nhẹ) | Gỡ nhãn "cần BR mới", dẫn đúng BR-08/BR-115/BR-116/BR-119/BR-121; AC-04.08.1 đổi "cùng nhóm người nhận như BR-27" → "đúng người đã nhận `MEMBER_EXITED` của sự kiện (BR-87)"; cập nhật số Must | T-BA-127 |
| 6 | Thấp | EP-04 dòng "Quy tắc tham chiếu" ("NFR-P16 bản mới D-22"); 01 §3 A-16 ("D-22 (thay NFR-P18, BR-38)"); ghi chú US-04.01 ("NFR-01 (2 máy thật, 30 lần)" — NFR-01 ghi ≥ 3 máy); 04 "NFR-P04a" chỉ định nghĩa trong §2, không có dòng §1 (cùng loại lỗi NFR-15a); 01 dòng nguồn "D-01…D-24" (đã dùng D-25, D-26) | Mã NFR/D- sai hoặc lệch số liệu | sai nguồn | EP-04 → NFR-P18; A-16 → "D-22 (thay NFR-P16, BR-38 bản cũ)"; ghi chú US-04.01 dẫn NFR-01 (≥3 máy); cấp NFR-P19 cho kiểm tra đầy đủ màn đồng ý (hoặc thêm dòng NFR-P04a vào §1); 01 nguồn D-01…D-26 | T-BA-128 |
| 7 | Thấp | 01 §2 dòng ND ("giả định, theo đề xuất Q-135 — D-25 chưa nêu rõ"); BR-75 (c) ("đề xuất, D-25; Q-135 đã đóng"); AC-02.01.4; 01 §3 A-15 ("giả định, Q-14, Q-32"); 03 §4 dòng "Tạm dừng có lý do" ("đề xuất, Q-32"); US-05.09 truy vết dẫn Q-135 | Giả định "thành viên nhóm A được tạo nhóm B làm chủ" không có Q- mở (Q-135 đã đóng bằng D-25, D-25 không nêu ý này). Một số nhãn dẫn Q- đã chốt (Q-14, Q-32) | giả định không có Q- | Tạo Q- mới (Chờ) cho "TV nhóm A tạo nhóm B làm chủ"; BR-75 (c), AC-02.01.4, 01 §2 dẫn Q- đó. A-15, 03 §4 dẫn D-19/D-20 thay Q-14/Q-32 | T-BA-129 |
| 8 | Thấp | EP-03 AC-03.03.1 (US-03.03 Must) | Then yêu cầu màn phiên có nút "Tạm dừng" — thuộc US-03.06 (Should, D-13); chưa gắn "chỉ kiểm khi US-03.06 trong phạm vi" như cách T-BA-58 | thiếu (phạm vi) | Gắn nhãn phạm vi cho phần nút "Tạm dừng" | T-BA-130 |
| 9 | Thấp | `01-viec-ba.md` dòng 39, 42, 48, 52, 56; `03-quy-tac.md` dòng 8, 9; EP-04 dòng 5, 9; EP-05 dòng 5, 6; EP-06 dòng 10, 12; `review/mockup-tong-hop.md` dòng 4; `review/lan-3.md` dòng 3 | Tham chiếu tới `review/lan-1.md`, `review/lan-2.md`, `review/mockup-1…3-*.md` (đã xóa) **không** kèm ghi chú "(nguồn cũ đã xóa)" | sai nguồn | Thêm "(nguồn cũ đã xóa)" sau mỗi tham chiếu; `01-viec-ba.md` T-BA-22 đổi đầu ra sang `review/lan-4.md` | T-BA-131 |

**Thống kê lỗi mới:** Cao **0** · TB **3** (T-BA-123…125) · Thấp **6** (T-BA-126…131) · tổng 9.

Kiểm tra không phát hiện lỗi:
- **Sót bản cũ:** cược, nổ phòng, Host/Guest, phòng 2–6 người, Điểm Uy Tín chỉ còn ở câu phủ định ("không cược", "Đã bỏ hẳn" ở 05, Ngoài phạm vi 01 §6, §8.1 Cấm dùng, `views/V07`, `V45`) — hợp lệ. 05 ghi rõ toàn tệp là "(tham khảo thiết kế, không phải yêu cầu)" và BR/NFR thắng khi mâu thuẫn.
- **Riêng tư (GĐ1 §6, ràng buộc cứng):** không yêu cầu nào thu thập ngoài phiên (BR-05, NFR-P02; 05 §1.1, R-K01 log từ xa "chỉ trong phiên"), đọc nội dung máy (BR-34, NFR-P01, 05 §1.4 cấm UsageStatsManager, 01 §6 cấm danh bạ), hay cho chủ nhóm/quản trị đọc nhật ký (BR-100, NFR-P05, A-27). Mới: BR-116 / AC-08.10.4–5 cấm CN xem thời gian thực và can thiệp; BR-119 / AC-03.14.3–4 chỉ dữ liệu của chính mình; BR-120 ghi sẵn ràng buộc EP-10; BR-117 cấm cộng gộp nhóm. Việc nêu tên người thoát theo D-22 đã có ở màn đồng ý 04 §2 mục 2b và giả định A-07b (Cao).
- **D-17…D-26:** D-18/D-26 (NFR-19, NFR-24, T-06, C-03, C-10, R-K01); D-19 (BR-21, BR-36, NFR-23, AC-03.07.3/.10, AC-03.08.8); D-20 (BR-27, BR-82, không `notify_mode` trong Must — ngoại lệ NFR-01: T-BA-124; tàn dư chữ: T-BA-76); D-21 (BR-75 a); D-22 (BR-38, NFR-P18, AC-03.09.x); D-23 (BR-37, AC-01.07.5/.7); D-24 (BR-105, NFR-17, US-08.07); D-25 (BR-114, BR-60, US-03.13 Hủy, AC-03.01.3, AC-08.01.7 — tàn dư BR-25/BR-69: T-BA-125). D-17 (83 điểm) **chưa** khớp backlog 86 điểm — thuộc Q-140, không chặn theo chỉ đạo.
- **AC kiểm tra được:** không thấy AC dùng "nhanh", "dễ dùng" không đo; ngưỡng thời gian đều có số (≤ 2 s, ≤ 5 s p95, ≤ 15 s). US-08.10 và US-03.14 có đủ ca Bình thường, Lỗi, Biên.
- **Truy vết:** 92 US, 0 US không nguồn, 0 mục Must mồ côi (mục mới "CN xem chi tiết phiên" phủ bởi US-08.10); 1 GIÁN TIẾP (US-02.10b, Should). Số liệu khớp backlog: 44 Must / 37 Should / 2 Could / 2 Won't / 7 Hủy.
- **Backlog:** cộng lại đúng — Must 74 điểm story + 12 điểm kỹ thuật = 86; sprint 19/25/26/16; Should 62 điểm.

## C. Checklist cổng G2 (`00-dieu-phoi.md` §6)

| Mục | Kết quả | Lý do |
| --- | --- | --- |
| Q-01…Q-08 đã thành D- (hoặc có giả định được cả nhóm chấp nhận) | **Đạt** | Q-01 → D-05, Q-02 → D-06, Q-03 → D-20, Q-04 → D-21, Q-07 → D-07. Q-05 (EP-10 Won't), Q-06 (giả định có nhãn ở US-07.07/07.10, BR-100), Q-08 (việc kiểm chứng) — chấp nhận theo tiêu chí |
| Mọi epic Must có story kèm AC (bình thường + lỗi) | **Đạt** | 44 story Must ở EP-01…EP-08 đều có AC Bình thường và Lỗi trong phạm vi Must (US-03.02 đã có AC-03.02.7; US-08.10 mới có AC-08.10.4–7) |
| Quy tắc phiên/Coins/chuỗi/báo cáo không mâu thuẫn với story | **Chưa đạt** | BR-118 (nút "Rời phiên" → EXITED) mâu thuẫn trực tiếp AC-03.04.7 (Must: "không có nút Thoát phiên"), kèm ca COUNTDOWN không khớp BR-64 (T-BA-123). AC Must còn dẫn BR-25/BR-69 đã Hủy (T-BA-125). NFR-01 đo push trái BR-82 (T-BA-124, không thuộc đúng mục này nhưng cần sửa cùng lúc) |
| Bản quy tắc riêng tư & minh bạch được cả nhóm đồng ý | **Đạt (theo chỉ đạo)** | Chưa có D- duyệt bản 04 §1–§5. Theo chỉ đạo người dùng: coi là giả định đã gắn nhãn, không chặn cổng. Ghi chú: vẫn là điều kiện GĐ1 §12 trước khi dùng thật |
| Bảng truy vết không còn FR/US mồ côi | **Đạt** | `03-truy-vet.md` lần 4: 92 US, 0 không nguồn, 0 Must mồ côi. FR-/TC- chưa cấp (T-BA-45, không chặn) |
| Báo cáo `ba-reviewer` không còn lỗi mức **Cao** | **Đạt** | Lần 4: 0 lỗi Cao; lỗi Cao S1, S2, S6, S7, S11 của mockup đã đóng |
| Backlog đã ước lượng sơ bộ và xếp vào 4 sprint | **Đạt (theo chỉ đạo)** | Đủ ước lượng, xếp 4 sprint, cộng đúng. Must 86 > 83 (D-17) chờ Q-140 — theo chỉ đạo không chặn. Ghi chú: Q-140 PA-A/PA-C về được 83 |

**Kết luận:** **Chưa đạt** cổng G2 · Số lỗi Cao: **0** (TB: 3, Thấp: 6; lỗi lần 3 còn mở: 3 Một phần, 5 Còn — đều không chặn).

Để qua cổng chỉ cần sửa mục 3 checklist: **T-BA-123** (chốt một cách cho "rời phiên chủ động", sửa BR-118 hoặc AC-03.04.7 + V07, bổ sung máy trạng thái) và **T-BA-125** (thay BR-25/BR-69 bằng BR-114/BR-60 trong AC Must). Nên sửa **T-BA-124** cùng đợt vì NFR-01 là tiêu chí demo GĐ1 §11. Các lỗi Thấp và T-BA-69, 76–79 không chặn cổng.

Giả định đã gắn nhãn, không chặn (chỉ đạo người dùng): Q-140 (Must 86 > 83), Q-141 (sĩ số không gồm CN — đã dùng nhất quán ở BR-74, AC-02.03.5, AC-04.01.11, AC-08.10.9, NFR-07), Q-142 (≥1 iPhone thật cho T-01), duyệt quy tắc riêng tư 04 §1–§5.

## D. Câu hỏi người dùng nên trả lời trước thiết kế

| # | Mã | Câu hỏi | Vì sao |
| --- | --- | --- | --- |
| 1 | (T-BA-123) | Màn phiên có nút "Rời phiên" (xác nhận → bị tính thoát) hay chỉ hộp xác nhận khi bấm Back? | Chặn mục 3 checklist G2; ảnh hưởng BR-118, AC-03.04.7, V07, sự kiện socket |
| 2 | Q- mới (T-BA-129) | Thành viên nhóm A có được tạo nhóm B và làm chủ nhóm B không? | Giả định trong BR-75 (c), AC-02.01.4 không có Q- mở |
| 3 | Q-87 (T-BA-79) | "Báo ngay" (D-20) với người đang úp máy nghĩa là xếp hàng, hiện khi mở khóa — đúng ý? | Quyết định NFR-01/BR-82 (T-BA-124) |
| 4 | Q-140 | Chọn PA-A / PA-A2 / PA-B / PA-C | Không chặn theo chỉ đạo; cần trước Sprint 1 |
