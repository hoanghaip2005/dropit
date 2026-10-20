# Kế hoạch điều phối BA — Giai đoạn 2 (Yêu cầu)

Mục tiêu: trong **Sprint 1** có bộ yêu cầu đủ để thiết kế và code lõi, đồng thời qua được cổng GĐ1→GĐ2 (mục 12 tài liệu GĐ1).

## 1. Các luồng công việc (workstream)

| Luồng | Nội dung | Agent | Người chịu trách nhiệm (đề xuất) | Đầu ra |
| --- | --- | --- | --- | --- |
| **L0 Điều phối** | Lập kế hoạch, giao việc, gộp, giữ sổ quyết định | agent chính | Trưởng nhóm / PO | `00`, `01`, `02` |
| **L1 Làm rõ** | Chốt 8 câu hỏi mở, phỏng vấn đồng nghiệp, xác nhận giả định | `ba-elicitation` | Trưởng nhóm | `02-so-quyet-dinh.md`, `ba/lam-ro/*` |
| **L2 Phạm vi & Epic** | Vai trò, epic, MoSCoW, ngoài phạm vi | `ba-scope` | Trưởng nhóm | `ba/srs/01-pham-vi.md` |
| **L3 User story & FR** | Story + tiêu chí chấp nhận theo epic | `ba-stories` | chia theo epic (mục 3) | `ba/srs/02-*.md`, `ba/backlog.md` |
| **L4 Quy tắc & trạng thái** | Quy tắc nghiệp vụ, máy trạng thái phiên, Coins, chuỗi, báo cáo | `ba-rules` | Backend | `ba/srs/03-quy-tac.md` |
| **L5 Phi chức năng & riêng tư** | NFR, quyền riêng tư, đồng ý, giữ dữ liệu, ánh xạ AWS | `ba-nfr` | Cloud/DevOps | `ba/srs/04-nfr-rieng-tu.md` |
| **L6 Kiểm duyệt chéo** | Nhất quán, truy vết, thiếu sót, mâu thuẫn với nguồn | `ba-reviewer` | QA (luân phiên) | `ba/review/*.md` |

## 2. Thứ tự và phụ thuộc

```
L1 Làm rõ ──┬─► L2 Phạm vi ──► L3 Story/FR ──┐
            │                                ├─► L6 Review ─► Cổng G2
            └─► L4 Quy tắc ─────────────────►┤
                L5 NFR/riêng tư (song song) ─┘
```

- L1 chặn L2/L4 ở các mục phụ thuộc câu hỏi (Q-01, Q-02, Q-03, Q-04). Các mục khác chạy song song, ghi **(giả định)** theo phương án đề xuất.
- L4 và L3 phải khớp tên trạng thái/sự kiện — L4 làm trước phần “Phiên”.
- L6 chạy **2 lần**: giữa chừng (sau đợt 1) và trước cổng.

## 3. Chia epic cho từng người (song song L3)

| Epic | Nội dung (theo GĐ1 mục 4, 7) | MoSCoW | Gợi ý phụ trách |
| --- | --- | --- | --- |
| EP-01 Tài khoản & vai trò | Đăng nhập (Cognito), vai trò hệ thống Người dùng/Quản trị, vai trò Chủ nhóm/Thành viên theo nhóm (D-10), đồng ý minh bạch, rút đồng ý, "Dữ liệu của tôi" | Must | Backend |
| EP-02 Nhóm | Người dùng tạo nhóm 4–10 người và trở thành chủ nhóm (D-10); thành viên thuộc tối đa 1 nhóm (D-21); mời bằng mã (email: Should); đặt lịch một lần 25/50’ | Must | Backend |
| EP-03 Phiên & Lockdown | Vào phiên theo lịch, đếm ngược 5s, giao diện tối, khoan hồng 3s, phát hiện thoát (khóa màn hình không tính), mất kết nối, kết quả phiên. Tạm dừng có lý do, vào muộn, sự cố server: Should | Must | iOS + Android |
| EP-04 Thông báo thoát | Báo **ngay** cho cả nhóm và người trong phiên, có tên người thoát (D-20, D-22); giải trình. Khiếu nại: Should. Chế độ gộp: Won't (D-20) | Must | Backend |
| EP-05 Thành tích | Điểm danh, chuỗi, huy hiệu mốc | Must | Backend |
| EP-06 Coins & Shop | Quy đổi Coins, trần/ngày, mua khung/hình nền | Must (cơ bản) | Web/Mobile |
| EP-07 Hồ sơ & Nhật ký | Hồ sơ trang trí, nhật ký riêng tư (viết) | Must (đơn giản) | Mobile |
| EP-08 Báo cáo tháng | Chỉ số thành viên/nhóm, xem trong app, email tóm tắt (SES, D-24). PDF: Should; Excel: Could | Must (cơ bản) | Backend/Cloud |
| EP-09 Quản trị | Tài khoản, danh mục Shop, khiếu nại chuyển lên, lạm dụng nhóm (MVP: dữ liệu nạp sẵn T-05) | Should | Web Admin |
| EP-10 Xã hội | Kết bạn, bảng tin bài viết, kiểm duyệt | Won't ở MVP (giai đoạn sau) | — |

## 4. Vòng làm việc của điều phối viên

1. Mở `01-viec-ba.md`, chọn các việc `Sẵn sàng` (phụ thuộc đã xong).
2. Giao cho agent tương ứng, kèm: mã việc, tệp nguồn, tệp đầu ra, DoD.
3. Nhận kết quả → cập nhật trạng thái việc, thêm `Q-`/`D-` mới vào sổ quyết định.
4. Sau mỗi đợt: chạy `ba-reviewer`, chuyển lỗi thành việc mới `T-BA-xx`.
5. Khi mọi việc của cổng xong → kiểm checklist mục 6.

Mẫu câu giao việc:

> Thực hiện **T-BA-07** (L3, EP-03). Nguồn: GĐ1 mục 4.2–4.3, 6; `05-tham-chieu-ky-thuat.md` §1, §2, §5 (chỉ phần kỹ thuật); `02-so-quyet-dinh.md`. Ghi vào `ba/srs/02-ep03-phien.md` theo `ba/mau/user-story.md`. DoD: xem `01-viec-ba.md`.

## 5. Nhịp họp (Scrum nhẹ)

| Khi | Việc | Thời lượng |
| --- | --- | --- |
| Đầu tuần | Chốt quyết định Q- đang chờ, giao việc | 30’ |
| 3 lần/tuần | Đứng nhanh: xong gì, kẹt gì | 10’ |
| Cuối đợt | Đọc báo cáo review, sửa | 45’ |

## 6. Cổng G2 — Yêu cầu sẵn sàng sang Thiết kế

- [ ] Q-01…Q-08 đã thành D- (hoặc có giả định được cả nhóm chấp nhận)
- [ ] Mọi epic Must có story kèm tiêu chí chấp nhận (bình thường + lỗi)
- [ ] Quy tắc nghiệp vụ phiên/Coins/chuỗi/báo cáo không mâu thuẫn với story
- [ ] Bản quy tắc riêng tư & minh bạch được cả nhóm đồng ý
- [ ] Bảng truy vết không còn FR/US mồ côi
- [ ] Báo cáo `ba-reviewer` không còn lỗi mức **Cao**
- [ ] Backlog đã ước lượng sơ bộ và xếp vào 4 sprint
