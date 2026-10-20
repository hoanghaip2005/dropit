# Báo cáo review lần 3 — review cuối trước cổng G2 (T-BA-21 + review)

Phạm vi review: toàn bộ `ba/` (`00`, `01`, `02` với D-01…D-24 và Q-01…Q-140, `03-truy-vet.md` vừa dựng lại, `backlog.md`, `srs/01…04`, 9 tệp `srs/02-ep0*.md`, `lam-ro/*`); đối chiếu GĐ1 bản 1.1, đặc tả 1.0 (chỉ kỹ thuật; nguồn cũ đã xóa), Quy trình, `CLAUDE.md`, `review/lan-2.md` · Ngày: 2026-10-07 · Người review: ba-reviewer

Ghi chú: lỗi mới đánh số từ T-BA-69. Không liệt kê lại Q- đang Chờ trừ khi có mâu thuẫn. Việc lần 2 còn "Một phần" giữ mã cũ, ghi rõ phần còn lại.

## A. Tình trạng lỗi lần 2 còn mở (T-BA-24…T-BA-68)

| Việc | Mức cũ | Tình trạng | Bằng chứng / phần còn lại |
| --- | --- | --- | --- |
| T-BA-24 / T-BA-60 | TB | Đã sửa | `00-dieu-phoi.md` §3: EP-03 Should (tạm dừng, vào muộn, sự cố), EP-04 gộp Won't (D-20), EP-08 PDF Should / Excel Could, EP-09 bỏ "kiểm duyệt" |
| T-BA-40 / T-BA-59 | TB | Đã sửa | 01 §5 Must EP-07 và backlog US-07.10 dùng "không xem được trong app", có câu người vận hành hạ tầng |
| T-BA-44 | TB | **Còn** | Phiên tự do (Should) vẫn chưa có story. Không chặn cổng (đã ghi MỒ CÔI Should trong truy vết) |
| T-BA-45 | TB | **Còn** | Chưa quyết định dùng FR- hay không; chưa cấp TC-. Không chặn cổng |
| T-BA-52 | Thấp | Đã sửa | NFR-20 dẫn Q-134 |
| T-BA-53 | Thấp | Đã sửa | `gia-dinh.md` có ghi chú thuật ngữ; A-10, A-13, A-18b ghi "trong app: chủ nhóm" |
| T-BA-55 | TB | Đã sửa | BR-85 chỉ EXITED, khớp AC-04.05.3 |
| T-BA-56 | TB | Đã sửa | AC-05.03.7, .14, .15; AC-05.07.6, .9 theo D-23 |
| T-BA-57 | TB | Đã sửa | D-24; US-08.07 không PDF, không phụ thuộc US-08.06; AC-08.07.6 |
| T-BA-58 | TB | **Một phần** | Đã gắn nhãn ở EP-03/04/05/06. Còn: AC-08.02.4 (US-08.02 Must) bắt "mỗi thành viên thấy 'chủ nhóm đã xem…'" — thuộc US-01.11 (Should), chưa gắn nhãn; AC-04.01.9 (US-04.01 Must) kiểm CN tham gia phiên — thuộc US-03.13 (Should), chỉ gắn "giả định" chưa gắn "chỉ kiểm khi US-03.13 trong phạm vi"; AC-01.07.2 liệt kê PAUSED (US-03.06 Should) |
| T-BA-61 | Thấp | Đã sửa | Backlog §2, §7: Should 37 US / 62 điểm, cộng lại khớp |
| T-BA-62 | Thấp | **Một phần** | Các tham chiếu ở EP-09, EP-04, NFR-20 đã sửa. Còn: bảng "Nhóm câu ưu tiên" trong `02-so-quyet-dinh.md` vẫn có #1 Q-97, #9 Q-96 (đã chốt D-11, D-12); dòng ghi chú phía trên đã liệt kê câu thay thế nhưng bảng chưa đổi |
| T-BA-63 | Thấp | Đã sửa | AC-02.06.2 "chỉ thấy phần công khai người đó tự bật (BR-99)" |
| T-BA-64 | Thấp | Đã sửa | BR-112 đủ miền mọi tham số Admin. Phát sinh lệch nhỏ → T-BA-77 |
| T-BA-65 | Thấp | Đã sửa | 01 §8 "Huy hiệu" theo BR-52; A-29 "≥5 thành viên, không gồm CN" |
| T-BA-66 | Thấp | Đã sửa | Máy trạng thái NHÓM có TẠM NGƯNG LỊCH → ĐÃ GIẢI TÁN; AC-09.06.2 |
| T-BA-67 | Thấp | Đã sửa | AC-04.05.5, AC-09.06.6 dùng `hạn − 1 ms` / `hạn` |
| T-BA-68 | Thấp | **Một phần** | NFR-P17 có trong 04 §3 và EP-07. Còn: US-05.06 (nơi có màn bật, EP-05) **chưa có AC** kiểm câu cảnh báo và "không bật được khi chưa hiện cảnh báo" |

Tổng: **Đã sửa 15 · Một phần 3 (T-BA-58, 62, 68) · Còn 2 (T-BA-44, 45).** Không còn lỗi Cao/TB nào của lần 2 ở dạng mâu thuẫn trong story Must.

## B. Lỗi mới (sau đợt áp D-17…D-24)

| # | Mức (Cao/TB/Thấp) | Tệp:mục | Vấn đề | Loại (mâu thuẫn / thiếu / không kiểm tra được / sai nguồn / vi phạm riêng tư) | Đề xuất sửa | Việc mới |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | TB | EP-04 US-04.01 (Must, M) ↔ EP-03 US-03.09 (Must, M); `backlog.md` §2, §5.5 | Hai story Must cùng đặc tả một việc: gửi `MEMBER_EXITED` + `SESSION_FORFEITED` có tên cho cả nhóm và cả phiên. AC-04.01.1 ≈ AC-03.09.1/.3 (push ngoài phiên), AC-04.01.2 ≈ AC-03.09.6 (banner), AC-04.01.3 ≈ AC-03.09.5, AC-04.01.7 ≈ AC-03.09.9, AC-04.01.8 ≈ AC-03.09.12. US-03.09 tăng S→M với lý do "gửi cả nhóm + cả phiên, hai kênh" — đúng phần US-04.01 đã ước M. Điểm bị tính hai lần; chính lần tăng này tạo Must 84 > 83 và sinh Q-140 | mâu thuẫn (phạm vi, ước lượng) | Chia rõ: US-04.01 = người nhận + push SNS + hộp thông báo (ngoài phiên); US-03.09 = banner trong phiên (BR-82) + màn kết quả có tên khởi phát. Xóa AC trùng ở một bên (giữ ánh xạ mã). Ước lại US-03.09 về S → Must 83, Q-140 có thể đóng mà không cắt US-07.04 | T-BA-69 |
| 2 | TB | `03-quy-tac.md` BR-08, BR-30; EP-03 US-03.11 (Should); AC-03.09.1, AC-04.01.8, US-08.01 (chỉ số "Số lần vắng", "Lượt dự kiến"); 04 §2 mục 2 | Trạng thái ABSENT (vắng) chỉ được tạo bởi BR-08 "quá hạn vào muộn", và vào muộn/vắng mặt là US-03.11 **Should**. Trong phạm vi Must không có quy tắc nào nói người INVITED không vào phòng chờ thì thành gì tại `started_at` (ABSENT? giữ INVITED?). Story Must vẫn dùng ABSENT (AC-03.09.1, báo cáo tháng, màn đồng ý) | thiếu (phạm vi) | Thêm vào phạm vi Must (BR-08 hoặc BR mới): khi không làm US-03.11, người INVITED chưa vào lúc `started_at` → ABSENT ngay (`late_join_max_min = 0`, BR-112 cho phép 0). Ghi rõ ở US-03.01 hoặc US-03.10 một AC "vắng" Must | T-BA-70 |
| 3 | TB | `04-nfr-rieng-tu.md` §3 dòng "Kết quả phiên", cột "Thành viên khác" = ✔ | Ô ✔ không nói rõ là kết quả **cấp phiên** (mất thưởng tập thể + tên khởi phát) hay kết quả **từng người** (ai COMPLETED, ai LOST, phút tập trung). Hiểu theo nghĩa thứ hai thì mâu thuẫn dòng "Vắng/LOST ✖", NFR-P06, AC-08.03.5, ghi chú US-03.03 "không hiện danh sách trạng thái của người khác"; ma trận là nguồn để thiết kế API | không kiểm tra được (riêng tư) | Đổi thành "~ chỉ cấp phiên: phiên có mất thưởng tập thể không và tên người khởi phát (D-05, D-22); không thấy kết quả từng người" và thêm cách kiểm tra (schema API kết quả phiên của người khác) | T-BA-71 |
| 4 | TB | `lam-ro/gia-dinh.md` A-07, A-14; `lam-ro/kich-ban-phong-van.md`; 04 R-P12 (Cao) | D-05 (phạt cả phiên) và D-22 (nêu tên người thoát cho cả nhóm) là thay đổi lớn nhất về riêng tư (04 ghi chú: ngược GĐ1 §9 "không bêu tên"; R-P12 mức Cao), nhưng không có giả định nào kiểm chứng việc nhân viên chấp nhận điều này. A-07 vẫn chỉ nói "trưởng phòng được báo"; A-14 vẫn kiểm "phiên tiếp tục được chấp nhận hơn nổ phòng" (mô hình trước D-05). Kịch bản phỏng vấn không có câu về việc bị nêu tên trước đồng nghiệp hay phạt tập thể | thiếu | Thêm giả định mới (vd. A-07b: nhân viên chấp nhận bị nêu tên trước cả nhóm + phạt tập thể nếu được báo trước ở màn đồng ý) mức Cao, gắn D-05, D-22, R-P12; thêm câu NV/TP tương ứng; sửa A-14 theo D-05 | T-BA-72 |
| 5 | Thấp | EP-03 US-03.02 (Must) | AC Lỗi duy nhất (AC-03.02.5, sự cố khi COUNTDOWN) đã gắn "chỉ kiểm khi US-03.12 trong phạm vi" (T-BA-58). Ở MVP story Must này không còn ca lỗi nào — trái luật "luôn có ca bình thường và ca lỗi" | thiếu | Thêm AC Lỗi trong phạm vi Must, vd. client mất kết nối trong COUNTDOWN → tại `started_at` xử lý theo BR-64/BR-19; hoặc client gửi `start` sớm hơn mốc server → bị bỏ qua (BR-03) | T-BA-73 |
| 6 | Thấp | `04-nfr-rieng-tu.md` NFR-15a | Cách đo "ngắt Wi-Fi 1 máy quá ngưỡng `heartbeat_timeout_s`" chỉ đưa máy vào DISCONNECTED; LOST cần `heartbeat_timeout_s + disconnect_hold_s` (= 20 giây, BR-19 mục 5). Test có thể đạt mà không kiểm LOST. Mã "NFR-15a" lệch quy ước đánh số | không kiểm tra được | Sửa cách đo: ngắt Wi-Fi ≥ 20 giây (`heartbeat_timeout_s + disconnect_hold_s`) trước `ends_at`; cấp mã NFR mới thay "15a" | T-BA-74 |
| 7 | Thấp | `04-nfr-rieng-tu.md` NFR-P16, NFR-P17 | NFR-P16 ghi "(Hủy …)" rồi dùng lại chính mã đó cho nội dung mới — trái `CLAUDE.md` "không đổi số đã cấp; mục bị bỏ ghi Hủy". NFR-P17 chỉ được định nghĩa trong một ô của ma trận §3, không có dòng ở bảng §1 | sai nguồn (quy ước) | Giữ NFR-P16 = Hủy; cấp NFR-P18 cho bản D-22 và cập nhật tham chiếu (hoặc ghi rõ ngoại lệ có D-); thêm dòng NFR-P17 vào §1 | T-BA-75 |
| 8 | Thấp | `backlog.md` §5.1 ("US-03.09 Thông báo mất thưởng không nêu tên"); 04 Ánh xạ AWS dòng SNS ("đối chiếu lại BR-82/BR-84/BR-91" — BR-84 Hủy); 04 §2 "Khi nội dung đồng ý thay đổi (ví dụ đổi chế độ báo)"; `01-viec-ba.md` T-BA-10 "EP-04 Thông báo chủ nhóm"; sổ Q-72 ("Đổi `notify_mode`…"), Q-32 (phương án "chỉ hiện trong bản gộp"); EP-01 ghi chú US-01.06 ("nếu BR-71 còn liệt kê `notify_mode`" — BR-71 không liệt kê); AC-01.10.1 ("Thành viên của ≥1 nhóm", "rời mọi nhóm" — D-21: tối đa 1) | Tham chiếu cũ sau D-20, D-21, D-22: "không nêu tên", `notify_mode`/bản gộp, "chủ nhóm" là người nhận duy nhất, "nhiều nhóm" cho thành viên | mâu thuẫn | Cập nhật câu chữ theo D-20/D-21/D-22; ở sổ ghi chú "(không còn áp dụng — D-20)" cho Q-72, Q-32 thay vì sửa lịch sử | T-BA-76 |
| 9 | Thấp | `03-quy-tac.md` bảng "Tham số mới" ↔ BR-112 | `invite_code_len` ghi cấp "Admin" ở bảng Tham số mới nhưng BR-112 và AC-09.08.5 ghi **cố định** 8; `reminder_min` ghi "chủ nhóm theo nhóm" nhưng BR-112 chỉ có dòng Admin và không story nào cho CN sửa | mâu thuẫn | Bảng Tham số mới: `invite_code_len` → Cố định; `reminder_min` → Admin (hoặc thêm story CN cấu hình, Should) | T-BA-77 |
| 10 | Thấp | `backlog.md` T-02, US-06.03 (phụ thuộc "S3+CloudFront"), US-08.01 tên "(EventBridge + Lambda)"; 01 §5 Must EP-08 ↔ 04 Ánh xạ AWS | Hạng mục/story Must kéo theo dịch vụ 04 xếp Should/Could: ALB, ElastiCache (Should) trong T-02; CloudFront (Could) trong US-06.03; EventBridge + Lambda (Should, "có thể cron EC2") trong tên US-08.01 và 01 §5 Must | mâu thuẫn (phạm vi) | Ghi T-02 chỉ dịch vụ Must; US-06.03 phụ thuộc S3; US-08.01 "lịch tự động (EventBridge + Lambda, hoặc cron EC2)" | T-BA-78 |
| 11 | Thấp | `03-quy-tac.md` BR-82 ↔ D-20 | D-20 ghi báo **ngay** cho mọi người trong phiên. BR-82 hoãn thông báo cho người đang khóa màn hình/GRACE/PAUSED đến khi họ mở khóa/quay lại. Hợp lý theo D-08 và đã gắn (đề xuất, Q-87), nhưng là diễn giải lại một quyết định vừa chốt | giả định cần chốt | Đưa Q-87 vào nhóm câu ưu tiên, nêu rõ "ngay" với người đang úp máy nghĩa là "xếp hàng, hiện khi mở khóa" | T-BA-79 |
| 12 | Thấp | `02-so-quyet-dinh.md` D-18 | D-18 chứa phần "(giả định) có iPhone/Mac — cần xác nhận" nhưng không có Q- mở tương ứng (Q-61 đã đổi "Đã chốt"). T-01 (Must, Sprint 1) và NFR-19 phụ thuộc phần này | giả định không có Q- | Tạo Q- mới cho phần thiết bị iPhone/Mac, trạng thái Chờ; NFR-19, C-03, T-01 dẫn Q- đó | T-BA-80 |

**Thống kê lỗi mới:** Cao **0** · TB **4** (T-BA-69…72) · Thấp **8** (T-BA-73…80) · tổng 12.

Kiểm tra không phát hiện lỗi:
- **Sót bản cũ:** không còn cược, nổ phòng, Host/Guest, 2–6 người, Điểm Uy Tín trong SRS/story/BR/NFR (chỉ ở Ngoài phạm vi, lịch sử quyết định, kịch bản phỏng vấn — hợp lệ).
- **Riêng tư (ràng buộc cứng):** không có yêu cầu thu thập ngoài phiên (BR-05, NFR-P02), đọc nội dung máy (BR-34, NFR-P01), hay cho chủ nhóm/quản trị đọc nhật ký (BR-100, AC-07.10.2/.3). Việc nêu tên người thoát là theo D-22, đã có ở màn đồng ý (04 §2 mục 2b, AC-01.05.1, .9).
- **D-19:** LOST không đặt `forfeited` ở BR-21, BR-36, AC-03.07.3/.10, AC-03.08.3/.8, AC-06.01.13, AC-05.03.6, NFR-15a (chỉ sai cách đo — T-BA-74).
- **D-20:** không còn `notify_mode`/bản gộp trong phạm vi MVP (BR-83, BR-84 Hủy; US-04.03/04.04 Won't; A-14 Hủy); người nhận là cả nhóm + cả phiên ở BR-27, AC-04.01.1, AC-03.09.1, NFR-01, 04 §2 mục 6. Chỉ còn tham chiếu cũ ở T-BA-76.
- **D-21:** BR-75(a), AC-01.05.10/.11, AC-02.03.7, AC-02.04.8; US-02.12, BR-10 Hủy; báo cáo không có màn "mọi nhóm" (AC-08.02.10, AC-08.03.2).
- **D-22:** BR-38, NFR-P16 bản mới, AC-03.09.x, AC-04.01.x, AC-05.07.1, AC-06.01.3; bảng US-04.02 Hủy có ghi chú "đã lỗi thời". Chỉ còn "không nêu tên" ở backlog §5.1 (T-BA-76).
- **D-23:** BR-26, BR-37 (mốc biên nghiêm ngặt), BR-48, AC-01.07.5/.7, AC-05.03.14/.15.
- **D-24:** BR-57, BR-105, NFR-17, AC-08.07.1/.6, 04 SES/S3; không còn link PDF trong email; `report_link_email_days` Hủy.
- **Truy vết:** 90 US, 0 US không nguồn, 0 mục Must mồ côi; 1 US gián tiếp (US-02.10b, Should). Số liệu khớp backlog (43 Must / 37 Should / 2 Could / 2 Won't / 6 Hủy).
- **Backlog:** cộng lại điểm từng sprint khớp 18/25/25/16 = 84 (11 kỹ thuật + 73 story).

## C. Checklist cổng G2 (`00-dieu-phoi.md` §6)

| Mục | Kết quả | Lý do |
| --- | --- | --- |
| Q-01…Q-08 đã thành D- (hoặc có giả định được cả nhóm chấp nhận) | **Đạt** | Q-01 → D-05, Q-02 → D-06, Q-03 → D-20, Q-04 → D-21, Q-07 → D-07. Còn Chờ: Q-05 (Bài viết — Won't, không Must nào phụ thuộc); Q-06 (nhật ký chỉ riêng tư) — chặn US-07.07/07.10 (Must) nhưng có giả định rõ ở 2 story, BR-100, NFR-P05; Q-08 (đồng nghiệp dùng thử) là việc kiểm chứng, không phải quyết định thiết kế. Theo tiêu chí điều phối: chấp nhận. Lưu ý: D-21 có phần giả định (CN quản lý nhiều nhóm, Q-135) mà tiêu chí demo GĐ1 §11 phụ thuộc |
| Mọi epic Must có story kèm AC (bình thường + lỗi) | **Đạt** | 43 story Must ở EP-01…EP-08 đều có AC Bình thường và Lỗi. Ngoại lệ nhỏ: Lỗi của US-03.02 chỉ kiểm khi US-03.12 trong phạm vi (T-BA-73, Thấp) |
| Quy tắc phiên/Coins/chuỗi/báo cáo không mâu thuẫn với story | **Đạt** | Ba mâu thuẫn lần 2 (T-BA-55, 56, 57) đã đóng; D-19…D-24 áp nhất quán ở BR và story. Còn vấn đề phạm vi (không phải mâu thuẫn quy tắc): ABSENT trong Must (T-BA-70), trùng US-04.01/US-03.09 (T-BA-69), AC Must phụ thuộc story Should (T-BA-58) — nên sửa trước thiết kế |
| Bản quy tắc riêng tư & minh bạch được cả nhóm đồng ý | **Chưa đạt** | Đã kiểm sổ D-01…D-24: **không có D- nào** ghi nhóm Bá Khí đã duyệt bản quy tắc riêng tư (04 §1–§5). D-20, D-22, D-23 do "Người dùng" chốt từng điểm, không phải duyệt cả bản; đây cũng là điều kiện GĐ1 §12. Cần một D- "cả nhóm duyệt 04 §1–§5 phiên bản 2026-10-07" |
| Bảng truy vết không còn FR/US mồ côi | **Đạt** | `03-truy-vet.md` lần 3: 90 US, 0 US không nguồn, 0 mục Must mồ côi; 1 US gián tiếp (Should). FR-/TC- chưa cấp (T-BA-45, không chặn) |
| Báo cáo `ba-reviewer` không còn lỗi mức **Cao** | **Đạt** | Lần 3: 0 lỗi Cao; lần 2: 0; lỗi Cao lần 1 đã đóng |
| Backlog đã ước lượng sơ bộ và xếp vào 4 sprint | **Chưa đạt** | Đã ước lượng và xếp đủ, nhưng Must 84 > năng lực 83 đã chốt ở D-17 (Sprint 4 = 16/15); Q-140 còn Chờ. Có thể đạt mà không cắt tính năng nếu áp T-BA-69 (US-03.09 về S → 83) |

**Kết luận:** **Chưa đạt** cổng G2 · Số lỗi Cao: **0** (TB: 4, Thấp: 8; lỗi lần 2 còn mở: 3 Một phần, 2 Còn).

Để qua cổng cần: (1) cả nhóm ghi một D- duyệt quy tắc riêng tư & minh bạch (04 §1–§5); (2) khép backlog về 83 điểm — chọn Q-140 (PA-A hoặc PA-B, nếu PA-B thì sửa D-17) hoặc áp T-BA-69. Nên sửa T-BA-69…72 và phần còn lại của T-BA-58 trước khi gộp SRS (T-BA-23). Các lỗi Thấp không chặn cổng.

## D. Câu hỏi người dùng PHẢI trả lời trước thiết kế

| # | Mã | Câu hỏi | Vì sao chặn thiết kế |
| --- | --- | --- | --- |
| 1 | (D- mới) | Cả nhóm đã duyệt bản quy tắc riêng tư & minh bạch (04 §1–§5, gồm việc nêu tên người thoát cho cả nhóm) chưa? | Mục cổng G2 và GĐ1 §12 |
| 2 | Q-140 (+ T-BA-69) | Must 84 > 83: hạ US-07.04, giữ 84 (sửa D-17), hay chấp nhận gộp phạm vi US-04.01/US-03.09 để US-03.09 về S? | Mục backlog của cổng G2 |
| 3 | Q-135 | Chủ nhóm được sở hữu nhiều nhóm nhưng chỉ tham gia phiên của 1 "nhóm tham gia"? Thành viên nhóm A được tạo nhóm làm chủ? | Phần giả định trong D-21; tiêu chí demo GĐ1 §11 "1 người quản lý ≥2 nhóm"; mô hình dữ liệu |
| 4 | Q- mới (T-BA-80) | Nhóm có iPhone + Mac để build và thử iOS ngay Sprint 1 không? | Phần giả định trong D-18; T-01 spike (rủi ro #1 GĐ1) |
| 5 | Q-87 | Người đang úp máy trong phiên nhận tin thoát khi mở khóa (không push trên màn khóa) — có đúng ý "báo ngay" của D-20? | Kênh socket/SNS cho người trong phiên (BR-82) |
| 6 | Q-136, Q-137 | Không nêu tên người LOST/ABSENT và không hiện số lần thoát tích lũy cho người khác? | Payload thông báo và API báo cáo (US-03.09, US-04.01, US-08.03 Must) |
