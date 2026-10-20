# Bảng việc BA

Trạng thái: `Sẵn sàng` · `Đang làm` · `Review` · `Xong` · `Chặn`

**DoD chung cho mọi việc:** đúng mẫu trong `ba/mau/`; mã định danh đúng quy ước; mỗi mục có nguồn; giả định/đề xuất được gắn nhãn và có Q- tương ứng; đã cập nhật `03-truy-vet.md`.

## Đợt 1 — Nền tảng

| Mã | Luồng | Việc | Agent | Phụ thuộc | Đầu ra | Trạng thái |
| --- | --- | --- | --- | --- | --- | --- |
| T-BA-01 | L1 | Chuẩn hóa câu hỏi mở (GĐ1 §13, câu hỏi đặc tả 1.0 còn áp dụng (nguồn cũ đã xóa), câu phát sinh); mỗi câu có phương án, ưu/nhược, đề xuất | ba-elicitation | — | `02-so-quyet-dinh.md` | Review |
| T-BA-02 | L1 | Soạn kịch bản phỏng vấn đồng nghiệp (trưởng phòng, nhân viên) kiểm chứng bảng Vấn đề GĐ1 mục 2 | ba-elicitation | — | `lam-ro/kich-ban-phong-van.md` | Review |
| T-BA-03 | L1 | Danh sách giả định cần kiểm chứng (mọi mục gắn “giả định” ở GĐ1) | ba-elicitation | — | `lam-ro/gia-dinh.md` | Review |
| T-BA-04 | L2 | Phạm vi, vai trò & quyền, danh sách epic, MoSCoW, ngoài phạm vi | ba-scope | T-BA-01 | `srs/01-pham-vi.md` | Review |
| T-BA-05 | L5 | Quy tắc riêng tư & minh bạch, luồng đồng ý, ma trận “ai thấy gì” | ba-nfr | — | `srs/04-nfr-rieng-tu.md` | Review |
| T-BA-06 | L4 | Máy trạng thái phiên bản văn phòng (thay “nổ phòng”), sự kiện thoát/khoan hồng/tạm dừng/mất mạng | ba-rules | T-BA-01 (Q-01, Q-02) | `srs/03-quy-tac.md` §Phiên | Review |

## Đợt 2 — Story theo epic (chạy song song)

| Mã | Epic | Agent | Phụ thuộc | Đầu ra | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| T-BA-07 | EP-01 Tài khoản & vai trò | ba-stories | T-BA-04, T-BA-05 | `srs/02-ep01-tai-khoan.md` | Review |
| T-BA-08 | EP-02 Nhóm | ba-stories | T-BA-04 | `srs/02-ep02-nhom.md` | Review |
| T-BA-09 | EP-03 Phiên & Lockdown | ba-stories | T-BA-06 | `srs/02-ep03-phien.md` | Review |
| T-BA-10 | EP-04 Thông báo chủ nhóm | ba-stories | T-BA-06 | `srs/02-ep04-thong-bao.md` | Review |
| T-BA-11 | EP-05 Thành tích | ba-stories | T-BA-12 | `srs/02-ep05-thanh-tich.md` | Review |
| T-BA-12 | Quy tắc Coins, chuỗi, điểm danh, huy hiệu | ba-rules | T-BA-06 | `srs/03-quy-tac.md` §Thưởng | Review |
| T-BA-13 | EP-06 Coins & Shop | ba-stories | T-BA-12 | `srs/02-ep06-shop.md` | Review |
| T-BA-14 | EP-07 Hồ sơ & Nhật ký | ba-stories | T-BA-05 | `srs/02-ep07-ho-so.md` | Review |
| T-BA-15 | Quy tắc báo cáo tháng (công thức chỉ số, kỳ, múi giờ) | ba-rules | T-BA-06 | `srs/03-quy-tac.md` §Báo cáo | Review |
| T-BA-16 | EP-08 Báo cáo tháng | ba-stories | T-BA-15 | `srs/02-ep08-bao-cao.md` | Review |
| T-BA-17 | EP-09 Quản trị | ba-stories | T-BA-04 | `srs/02-ep09-quan-tri.md` | Review |
| T-BA-18 | NFR (hiệu năng, độ trễ thông báo, pin, bảo mật) + ánh xạ AWS có lý do | ba-nfr | T-BA-04 | `srs/04-nfr-rieng-tu.md` §NFR | Review |

## Đợt 3 — Gộp & cổng

| Mã | Việc | Agent | Phụ thuộc | Đầu ra | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| T-BA-19 | Review giữa kỳ (sau đợt 1 + EP-03) | ba-reviewer | T-BA-09 | `review/lan-1.md` (nguồn cũ đã xóa) | Review |
| T-BA-20 | Product Backlog: gom story, ước lượng (S/M/L), xếp 4 sprint, rủi ro cao làm trước | ba-scope | Đợt 2 | `backlog.md` | Review |
| T-BA-21 | Hoàn thiện bảng truy vết | ba-reviewer | Đợt 2 | `03-truy-vet.md` | Review |
| T-BA-22 | Review cuối, kiểm checklist cổng G2 | ba-reviewer | T-BA-20, T-BA-21 | `review/lan-2.md` (nguồn cũ đã xóa) | Review |
| T-BA-23 | Gộp SRS hoàn chỉnh (mục lục + liên kết các tệp) | điều phối | T-BA-22 | `srs/00-SRS.md` | Review |


## Đợt 4 — Sửa lỗi review lần 1

Xem `review/lan-1.md` (nguồn cũ đã xóa): T-BA-24…T-BA-54 (5 Cao, 17 TB, 9 Thấp).

## Đợt 5 — Sửa lỗi review lần 2

Xem `review/lan-2.md` (nguồn cũ đã xóa): còn 5 việc lần 1 làm một phần, 1 việc chưa làm (T-BA-53), lỗi mới T-BA-55…68 (0 Cao, 6 TB, 8 Thấp). Cổng G2: Chưa đạt — chờ người dùng trả lời 8 câu + duyệt quy tắc riêng tư.

## Đợt 6 — Mockup

Xem `review/mockup-tong-hop.md`: T-BA-81…T-BA-122 (42 việc: 29 Cao, 11 TB, 2 Thấp), gộp từ `review/mockup-1-thanh-vien-phien.md`, `review/mockup-2-chu-nhom-quan-tri.md`, `review/mockup-3-shop-ho-so-xa-hoi.md` (nguồn cũ đã xóa). Việc sửa SRS: T-BA-86, 93, 97, 101, 105–108, 110, 112, 116, 117, 119. Quyết định cần chốt: T-BA-93, 96, 100, 105, 118. Kết luận mockup: Chưa đạt.

## Đợt 7 — Sửa lỗi lần 4 & gộp SRS

Nguồn: `review/lan-4.md`, D-29. Chưa có review lần 5 xác nhận.

| Mã | Việc | Trạng thái |
| --- | --- | --- |
| T-BA-123 | Nút "Rời phiên" (D-29): BR-118, AC-03.04.7–10, V-06/V-07/V-08 | Review |
| T-BA-124 | NFR-01 khớp BR-82 | Review |
| T-BA-125 | Thay BR-25/BR-69 (Hủy) bằng BR-114/BR-60 | Review |
| T-BA-126 | BR-115 tie-break, chủ nhóm đứng đầu; BR-117; AC-02.06.6–7, AC-08.02.11, V-20 | Review |
| T-BA-127 | Gỡ "cần BR mới", dẫn BR-87/BR-119/BR-121 | Review |
| T-BA-128 | Sửa tham chiếu cũ (NFR-P16 ở EP-04, A-16, NFR-01 số máy, NFR-P04a) | Review |
| T-BA-129 | BR-75 (c), Q-150 | Review |
| T-BA-130 | Nhãn phạm vi nút "Tạm dừng" (AC-03.03.1) | Review |
| T-BA-131 | Xóa ghi chú nguồn | Review |

## Đợt 8 — Sửa lỗi lần 5

Nguồn: `review/lan-5.md`. Cần kiểm lại 3 chỗ chặn (T-BA-132…134).

| Mã | Việc | Trạng thái |
| --- | --- | --- |
| T-BA-132 | Màn đếm ngược không có nút "Rời phiên": BR-118, §3 #53, K-16 (c), Q-149 | Review |
| T-BA-133 | §3: 5 dòng mới trùng số đánh lại #53–#57 | Review |
| T-BA-134 | BR-115 ngoại lệ thứ hai (danh sách sự kiện theo giờ server); AC-08.10.1, .9 | Review |
| T-BA-135 | Tham chiếu cũ: A-15, A-16, D-01…D-29, NFR-P04a → NFR-P19, Q-135 → Q-150, AC-02.01.4 | Review |
| T-BA-136 | BR-122 (D-27), BR-123 (D-28); AC-08.07.8, AC-08.10.12; Q-147, Q-148 đã chốt | Review |
| T-BA-137 | Danh mục màn: tổng 46 + 5 = 51 | Review |
| T-BA-138 | Gỡ ghi chú lỗi thời US-08.10; sổ dòng "Ưu tiên còn lại" | Review |
| T-BA-139 | AC-04.01.1 dùng câu chuẩn MEMBER_EXITED + SESSION_FORFEITED gộp | Review |
| T-BA-140 | Q-153 WAITING mất kết nối; §2.2 thêm dòng | Review |
