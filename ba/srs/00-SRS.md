# DropIt! — Đặc tả yêu cầu phần mềm (SRS) — tệp dẫn đường

Việc: T-BA-23. Tệp này **không chép lại** nội dung. Nó chỉ dẫn tới các tệp nguồn. Khi các tệp mâu thuẫn nhau, thứ tự ưu tiên theo `CLAUDE.md`: sổ quyết định → GĐ1 → tham chiếu kỹ thuật.

## 1. Thông tin tài liệu

| Mục | Giá trị |
| --- | --- |
| Dự án | DropIt! (bản văn phòng 1.1) |
| Nhóm | Bá Khí — 5 người, 4 sprint × 2 tuần, bắt buộc ≥ 3 dịch vụ AWS |
| Giai đoạn | 2 — Yêu cầu |
| Phiên bản SRS | 1.0 |
| Ngày | 2026-10-19 |
| Trạng thái | **Chờ cổng G2** |

## 2. Tóm tắt sản phẩm

DropIt! là ứng dụng di động (iOS + Android) giúp nhóm văn phòng tập trung cùng lúc. Chủ nhóm tạo nhóm và đặt lịch phiên, nhưng không tham gia phiên. Thành viên vào phiên đúng giờ. Nếu một người rời app quá 3 giây (khóa màn hình không tính) thì người đó bị ghi thoát. Cả phiên mất thưởng, cả nhóm thấy tên người thoát. Hoàn thành phiên thì nhận Coins, giữ chuỗi và huy hiệu. Chủ nhóm nhận báo cáo tháng (không xếp hạng). App không đọc nội dung điện thoại và không ghi dữ liệu ngoài phiên (GĐ1 §6).

## 3. Quyết định then chốt

Chi tiết xem [`../02-so-quyet-dinh.md`](../02-so-quyet-dinh.md).

| Mã | Nội dung tóm tắt |
| --- | --- |
| D-05 | 1 người thoát → phiên vẫn chạy, nhưng cả phiên mất Coins và mọi người bị ngắt chuỗi |
| D-10 / D-25 | Không có vai trò "Trưởng phòng". Ai tạo nhóm là chủ nhóm. Chủ nhóm không tham gia phiên và được quản lý nhiều nhóm |
| D-12 | Chủ nhóm không thấy chuỗi. Chỉ thấy điểm danh và kết quả phiên trong nhóm mình |
| D-20 / D-22 | Có người thoát → báo ngay cho cả nhóm và cả phiên, nêu tên người thoát |
| D-21 | Mỗi người là thành viên của tối đa 1 nhóm (giả định) |
| D-29 | Màn phiên có nút "Rời phiên" kèm hộp xác nhận (BR-118): ACTIVE/GRACE/PAUSED → EXITED; ở phòng chờ → ABSENT (Q-149); khi mất kết nối thì không gửi và không xếp hàng gửi sau |

## 4. Mục lục

| Phần | Tệp |
| --- | --- |
| Phạm vi, vai trò, epic, thuật ngữ | [01-pham-vi.md](01-pham-vi.md) |
| EP-01 Tài khoản | [02-ep01-tai-khoan.md](02-ep01-tai-khoan.md) |
| EP-02 Nhóm | [02-ep02-nhom.md](02-ep02-nhom.md) |
| EP-03 Phiên tập trung | [02-ep03-phien.md](02-ep03-phien.md) |
| EP-04 Thông báo | [02-ep04-thong-bao.md](02-ep04-thong-bao.md) |
| EP-05 Thành tích | [02-ep05-thanh-tich.md](02-ep05-thanh-tich.md) |
| EP-06 Shop | [02-ep06-shop.md](02-ep06-shop.md) |
| EP-07 Hồ sơ | [02-ep07-ho-so.md](02-ep07-ho-so.md) |
| EP-08 Báo cáo | [02-ep08-bao-cao.md](02-ep08-bao-cao.md) |
| EP-09 Quản trị | [02-ep09-quan-tri.md](02-ep09-quan-tri.md) |
| Quy tắc nghiệp vụ (BR), máy trạng thái | [03-quy-tac.md](03-quy-tac.md) |
| NFR và quyền riêng tư | [04-nfr-rieng-tu.md](04-nfr-rieng-tu.md) |
| Tham chiếu kỹ thuật (chỉ để tham khảo) | [05-tham-chieu-ky-thuat.md](05-tham-chieu-ky-thuat.md) |
| Danh mục màn hình | [../views/00-danh-muc-man.md](../views/00-danh-muc-man.md) |
| Product Backlog | [../backlog.md](../backlog.md) |
| Truy vết | [../03-truy-vet.md](../03-truy-vet.md) |
| Sổ quyết định và câu hỏi | [../02-so-quyet-dinh.md](../02-so-quyet-dinh.md) |
| Làm rõ | [../lam-ro/gia-dinh.md](../lam-ro/gia-dinh.md), [../lam-ro/kich-ban-phong-van.md](../lam-ro/kich-ban-phong-van.md) |
| Review | [../review/lan-5.md](../review/lan-5.md), [../review/lan-4.md](../review/lan-4.md), [../review/mockup-tong-hop.md](../review/mockup-tong-hop.md) |
| Mockup | [../../mockup/](../../mockup/) |
| Spike vòng đời app | [../../spike/t01-lifecycle/README.md](../../spike/t01-lifecycle/README.md) |

## 5. Số liệu (theo `backlog.md` và lan-5, ngày 2026-10-19)

| Chỉ số | Giá trị |
| --- | --- |
| User story | 92 US: Must 44 (+ 6 việc kỹ thuật T-01…T-06), Should 37, Could 2, Won't 2, Hủy 7 (D-14 ×4, D-16, D-21, D-25) |
| Điểm Must | 86 (74 điểm story + 12 điểm T-01…T-06). Năng lực là 83 (D-17), vượt 3 điểm, chờ Q-140 |
| Điểm Must theo sprint | S1 = 19 · S2 = 25 · S3 = 26 · S4 = 16 (năng lực: 18 / 25 / 25 / 15) |
| Quy tắc nghiệp vụ | 123 mã BR (BR-01…BR-123); 118 còn hiệu lực; 5 Hủy (BR-10, BR-25, BR-69, BR-83, BR-84) |
| NFR | 44 mã trong `04-nfr-rieng-tu.md` (NFR-01…NFR-24, NFR-15a, NFR-P01…NFR-P19); 42 còn hiệu lực; 2 Hủy (NFR-15a, NFR-P16) |
| Màn hình | 51 mã V- trong danh mục (46 màn thành viên/chủ nhóm + 5 màn quản trị); 26 tệp đặc tả chi tiết trong `views/` |

## 6. Thuật ngữ

Xem [01-pham-vi.md §8](01-pham-vi.md). Các thuật ngữ chính gồm: phiên, phòng chờ, khoan hồng (GRACE), tạm dừng (PAUSED), thoát (EXITED), mất kết nối (LOST), vắng (ABSENT), `forfeited`, Coins, chuỗi, chủ nhóm, thành viên.

## 7. Câu hỏi còn Chờ quan trọng

| Mã | Nội dung | Đang xử lý ra sao |
| --- | --- | --- |
| Q-140 | Must 86 > 83: chọn phương án cắt | Người dùng cho phép không chặn cổng |
| Q-141 | Sĩ số 4–10 có tính chủ nhóm không | Giả định: không tính |
| Q-142 | Có iPhone thật cho spike T-01 không | Giả định: cần có, nếu không thì mượn/thuê máy |
| Q-149 | Bấm "Rời phiên" ở phòng chờ → ABSENT | Giả định trong BR-118 (2) |
| Q-150 | Thành viên nhóm A có được làm chủ nhóm B không | Giả định: có |
| Q-151 | Tín hiệu khóa màn hình đến muộn khi đang khoan hồng | Chờ spike T-01 |
| Q-152 | Vuốt tắt app thành LOST — có thành lối lách luật không | Chờ spike T-01 |

Người dùng cho phép để các mục sau ở dạng giả định có gắn nhãn, không chặn G2: bản quy tắc riêng tư 04 §1–§5 và Q-140 (lan-4 mục C).

## 8. Trạng thái cổng G2

- Theo lan-4: **Chưa đạt**. Có 0 lỗi Cao. Mục còn chặn là T-BA-123 (nút "Rời phiên").
- Đã sửa sau lan-4:
  - T-BA-123 → D-29 và BR-118; AC-03.04.7–10, V-06, V-07 khớp BR-118.
  - T-BA-125: thay BR-25/BR-69 bằng BR-114/BR-60.
  - T-BA-126: AC-02.06.7, AC-08.02.11, V-20 khớp BR-115.
  - T-BA-124, T-BA-127…T-BA-131.
- Review lần 5 (`../review/lan-5.md`): 0 Cao; 3 TB chặn (T-BA-132…134) đã sửa ngày 2026-10-19 và đã kiểm lại cùng ngày (BR-118 khớp V-07/AC-03.04.10; bảng §3 không còn số trùng; BR-115 có ngoại lệ 2 cho danh sách sự kiện). **Cổng G2: Đạt** — với các giả định đã gắn nhãn theo chỉ đạo người dùng (Q-140…142, Q-149…153, duyệt quy tắc riêng tư).
- Đã sửa thêm các lỗi Thấp T-BA-135…140 và phần còn lại T-BA-131; thêm BR-122 (D-27), BR-123 (D-28), Q-153.
