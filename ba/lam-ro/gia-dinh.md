# Danh sách giả định — DropIt! (T-BA-03)

Nguồn: GĐ1 bản 1.1. Câu hỏi mở: `ba/02-so-quyet-dinh.md`. Câu phỏng vấn: `ba/lam-ro/kich-ban-phong-van.md`.

**Mức rủi ro nếu sai:** Cao = đổi phạm vi MVP / hỏng mục tiêu sản phẩm; TB = đổi BR/US; Thấp = chỉnh thông số.
**Người phụ trách:** (đề xuất) — nhóm phân công lại. Vai trò: BA, Mobile, Backend, PO (trưởng nhóm).
**Kết quả:** Chưa kiểm / Ủng hộ / Bác bỏ / Chưa đủ.

**Thuật ngữ (T-BA-53):** "Trưởng phòng" trong tệp này là **người thật ngoài đời** (đối tượng phỏng vấn). Trong app, người đó dùng vai trò **chủ nhóm** của nhóm mình tạo; hệ thống không có vai trò "Trưởng phòng" (D-10). Mọi giả định nói "trưởng phòng" áp vào app là "chủ nhóm".

## 1. Vấn đề và người dùng

| Mã | Giả định | Nguồn | Rủi ro | Cách kiểm chứng | Phụ trách | Câu PV | Q- | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-01 | Điện thoại là nguyên nhân chính làm đứt mạch làm việc ở văn phòng | §2 | Cao | Phỏng vấn | BA | TP-01, TP-06, NV-01, NV-02 | — | Chưa kiểm |
| A-02 | Trưởng phòng muốn có số liệu về mức tập trung của nhóm | §2, §3 | Cao | Phỏng vấn | BA | TP-01, TP-05 | — | Chưa kiểm |
| A-03 | Nhắc nhở trực tiếp gây mất lòng, trưởng phòng ngại nhắc | §2 | TB | Phỏng vấn | BA | TP-02, TP-03, NV-04 | — | Chưa kiểm |
| A-04 | Nhân viên thiếu ghi nhận tích cực và muốn được ghi nhận | §2, §3 | TB | Phỏng vấn | BA | TP-04, NV-05 | — | Chưa kiểm |
| A-05 | Đánh giá cuối tháng hiện dựa vào cảm tính, thiếu dữ liệu | §2 | TB | Phỏng vấn | BA | TP-05 | — | Chưa kiểm |
| A-06 | Trưởng phòng sợ bị coi là giám sát quá mức | §3 | TB | Phỏng vấn | BA | TP-12 | — | Chưa kiểm |
| A-07 | Nhân viên chấp nhận việc trưởng phòng được báo khi rời app, nếu có minh bạch + đồng ý + chỉ ghi trong phiên | §6, §10.2 | **Cao** | Phỏng vấn; thử dùng | BA | TP-09, TP-12, NV-06, NV-07, NV-09 | — | Chưa kiểm |
| A-07b | (T-BA-72) Nhân viên chấp nhận **bị nêu tên trước cả nhóm** khi thoát (D-22) và **phạt tập thể** — cả phiên mất Coins, ngắt chuỗi (D-05) — nếu được báo trước rõ ở màn đồng ý minh bạch. Ngược GĐ1 §9 "không bêu tên"; nếu bác bỏ phải xem lại D-05/D-22 | D-05, D-22; §6, §9; 04 R-P12 | **Cao** | Phỏng vấn riêng từng người; thử dùng | BA | TP-11b, TP-12b, NV-07b, NV-07c, NV-15 | — | Chưa kiểm |
| A-08 | Minh bạch hai chiều (nhân viên thấy đúng dữ liệu trưởng phòng thấy) làm giảm phản đối | §5, §6 | TB | Phỏng vấn | BA | NV-08 | — | Chưa kiểm |
| A-09 | DropIt! khác biệt so với app tập trung / chặn app / theo dõi thời gian / chế độ tập trung của HĐH | §5 | TB | Thử dùng 3–4 app tương tự | BA + PO | — | — | Chưa kiểm |

## 2. Tổ chức nhóm và phiên

| Mã | Giả định | Nguồn | Rủi ro | Cách kiểm chứng | Phụ trách | Câu PV | Q- | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-10 | Mỗi trưởng phòng (trong app: chủ nhóm) quản lý nhiều nhóm 4–10 thành viên; chủ nhóm chỉ quản lý, **không tham gia phiên** (D-25); mỗi thành viên chỉ thuộc tối đa 1 nhóm (D-21) | §0, §4 (D-02, D-21, D-25; Q-141) | TB | Phỏng vấn | BA | TP-07 | Q-04 (đã chốt D-21) | Chưa kiểm |
| A-11 | Một người có thể thuộc nhiều nhóm | §13.4 | TB | Phỏng vấn | BA | TP-07 | Q-04 | Chưa kiểm |
| A-12 | Văn phòng có/chấp nhận khung giờ tập trung chung 25 hoặc 50 phút | §1, §4.1 | **Cao** | Phỏng vấn; thử dùng | BA | C-03, TP-08 | Q-02 | Chưa kiểm |
| A-13 | Trưởng phòng (trong app: chủ nhóm) muốn được báo ngay khi có người rời app; D-20 báo ngay cho cả nhóm và người trong phiên | §4.3, §13.3 | TB | Phỏng vấn | BA | TP-10 | Q-03 (đã chốt D-20) | Chưa kiểm |
| A-14 | (Sửa theo D-05, T-BA-72) Khi một người thoát, phiên vẫn chạy đến hết giờ nhưng **cả phiên mất thưởng tập thể**; cách này được chấp nhận và tạo áp lực đồng đội vừa phải, không gây đổ lỗi | §4.3, §9; D-05 | TB | Phỏng vấn | BA | TP-11, TP-11b, NV-07c | Q-01 (đã chốt D-05) | Chưa kiểm |
| A-15 | Việc đột xuất (cuộc gọi công việc…) đủ thường xuyên để cần miễn trừ/tạm dừng | §3, §6 | **Cao** | Phỏng vấn | BA | TP-13, NV-10 | Q-11 | Chưa kiểm |
| A-16 | "Tạm dừng có lý do" (1 lần, ≤5 phút) đủ để tránh phạt oan | §6, Q-11 | TB | Phỏng vấn; thử dùng | BA | NV-11 | Q-11 | Chưa kiểm |
| A-17 | Người dùng úp máy và tắt màn hình; khóa màn hình không nên tính là thoát | Q-09 | TB | Phỏng vấn; spike máy thật | BA + Mobile | NV-12 | Q-09 | Chưa kiểm |

## 3. Kỹ thuật

| Mã | Giả định | Nguồn | Rủi ro | Cách kiểm chứng | Phụ trách | Câu PV | Q- | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-18 | HĐH cho phép phát hiện rời app đủ nhanh, đáng tin, phân biệt được khóa màn hình / cuộc gọi đến | §10.1, §8 | **Cao nhất** | Spike máy thật (iOS + Android) | Mobile | — | Q-09, Q-10 | Chưa kiểm |
| A-18b | Chủ nhóm (trưởng phòng ngoài đời) và người trong phiên (D-20) nhận thông báo trong vài giây (SNS push) | §11 | **Cao** | Spike máy thật | Backend + Mobile | — | Q-03 | Chưa kiểm |
| A-18c | Khoan hồng 3 giây đủ giảm phát hiện nhầm | §4.2, §10.3 | Cao | Spike; thử dùng | Mobile | — | Q-10 | Chưa kiểm |
| A-18d | Phát hiện thoát hoạt động mà không đọc nội dung/app đang dùng | §6 (D-03) | Cao | Spike + rà quyền ứng dụng | Mobile | — | — | Chưa kiểm |
| A-18e | Hệ thống chịu được tải dồn đầu giờ khi nhiều nhóm bắt đầu cùng lúc | §10.5 | TB | Thử tải | Backend | — | — | Chưa kiểm |
| A-18f | Chi phí AWS (≈14 dịch vụ) nằm trong hạn mức | §8, §10.8 | TB | Ước tính + cảnh báo ngân sách | Backend | — | — | Chưa kiểm |

## 4. Động lực, báo cáo, xã hội

| Mã | Giả định | Nguồn | Rủi ro | Cách kiểm chứng | Phụ trách | Câu PV | Q- | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-19 | Coins + đồ trang trí thẩm mỹ là động lực đủ với nhân viên văn phòng | §1, §4.5–6 | **Cao** | Phỏng vấn; thử dùng | BA | NV-13, NV-14 | Q-13 | Chưa kiểm |
| A-20 | Điểm danh, chuỗi ngày, huy hiệu tạo động lực (không cần cược) | §4.4 | TB | Phỏng vấn | BA | NV-13, NV-15 | — | Chưa kiểm |
| A-21 | Mức quy đổi 25’=10, 50’=25, trần/ngày là hợp lý | §4.5 | Thấp | Thử dùng; cấu hình | PO | NV-14 | Q-13 | Chưa kiểm |
| A-22 | Nhân viên muốn đồng nghiệp thấy thành tích/hồ sơ (kết bạn) | §4.7 | TB | Phỏng vấn | BA | NV-16 | Q-05 | Chưa kiểm |
| A-23 | Các chỉ số báo cáo tháng (§4.8) là đúng và đủ với trưởng phòng | §4.8 | TB | Phỏng vấn | BA | TP-15 | — | Chưa kiểm |
| A-24 | Báo cáo được coi là khích lệ; công ty sẽ quy định rõ có dùng để đánh giá/kỷ luật hay không | §6 | **Cao** | Phỏng vấn | BA + PO | TP-14, NV-17 | Q-12 | Chưa kiểm |
| A-25 | Nhân viên muốn viết nhật ký hằng ngày trong app công ty | §4.7 | TB | Phỏng vấn | BA | NV-18, NV-19 | Q-06 | Chưa kiểm |
| A-26 | Nhật ký riêng tư mặc định (trưởng phòng không đọc) đủ để người dùng yên tâm | §6 | TB | Phỏng vấn | BA | NV-19 | Q-06 | Chưa kiểm |
| A-27 | Đồng nghiệp/văn phòng sẵn sàng dùng thử | §12, §13.8 | Cao | Phỏng vấn | BA | TP-16, NV-20 | Q-08 | Chưa kiểm |

## 5. Ràng buộc dự án

| Mã | Giả định | Nguồn | Rủi ro | Cách kiểm chứng | Phụ trách | Câu PV | Q- | Kết quả |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A-28 | Có 4 sprint; hạn nộp tương ứng | §8 | **Cao** | Hỏi giảng viên | PO | — | Q-07 | Chưa kiểm |
| A-29 | Yêu cầu ≥3 dịch vụ AWS, "nhiều hơn càng tốt" là tiêu chí chấm | §8 | Cao | Hỏi giảng viên | PO | — | Q-07 | Chưa kiểm |
| A-30 | Nền tảng (iOS/Android/cả hai) làm được trong 4 sprint với 5 người | §8, §13.7 | **Cao** | Hỏi giảng viên + spike | PO + Mobile | — | Q-07 | Chưa kiểm |
| A-31 | Nhóm có đủ máy thật để thử nghiệm: ≥1 máy Android và **≥1 iPhone thật** (T-BA-80). Không có Mac: build/ký IPA qua GitHub Actions macOS, cài qua TestFlight (D-26) | §8; D-18, D-26 | **Cao** (spike T-01 iOS phụ thuộc) | Kiểm kê thiết bị tuần đầu Sprint 1; chạy thử 1 bản TestFlight lên iPhone | PO | — | Q-142 | Chưa kiểm |
| A-32 | Ghi sự kiện rời app trong phiên phù hợp quy định bảo vệ dữ liệu cá nhân VN khi có đồng ý rõ ràng | §6 | Cao | Hỏi giảng viên / người có chuyên môn | PO | — | Q-12 | Chưa kiểm |
| A-33 | Tách giai đoạn (§7) đủ để không phình phạm vi | §7, §10.4 | Cao | Ước lượng backlog (L-backlog) | PO | — | Q-05 | Chưa kiểm |

## 6. Ưu tiên kiểm chứng

1. **A-18, A-18b, A-18c, A-31** — spike máy thật ngay (cổng §12); A-31 phải xác nhận trước (Q-142).
2. **A-07, A-07b, A-15, A-24** — phỏng vấn đợt 1; nếu bác bỏ phải thiết kế lại cơ chế báo trưởng phòng.
3. **A-28, A-29, A-30** — hỏi giảng viên trong tuần này.
4. **A-12, A-19, A-27** — phỏng vấn + thử dùng; ảnh hưởng giá trị cốt lõi.
