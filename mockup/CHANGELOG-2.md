# CHANGELOG mockup — đợt 2 (2026-10-19)

Căn cứ: `ba/review/mockup-tong-hop.md` §1–§2, `ba/02-so-quyet-dinh.md` (D-01…D-26). Token giữ theo `dropit/DESIGN.md` (T-BA-119). Đã xóa `screen.png` của mọi màn được sửa; cần chụp lại.

## Xóa

- `t_09_phi_n_ang_di_n_ra_theo_d_i_tr_c_ti_p`: theo dõi trực tiếp từng người, vi phạm riêng tư. (T-BA-91, T-BA-105)
- `team_hub`: bảng xếp hạng. (T-BA-89, T-BA-90)
- `screenshot_2026_10_06_111438.png`, `screenshot_2026_10_06_112002.png`: ảnh danh mục có phân hệ "Trưởng phòng" và "Phiên đang diễn ra (theo dõi trực tiếp)". (T-BA-82, T-BA-91)
- Giữ: 5 ảnh `screenshot_*` còn lại (C, N, S, X, A — không chứa nội dung đã bỏ) và `1790829993561_*` (biểu tượng ứng dụng).

## Sửa

- **manager_dashboard** — Trang chủ chủ nhóm: bỏ "pts", chuỗi, chức danh Lead, trạng thái online/trong phiên, mốc "team meal". Hiện phiên kế tiếp, tỉ lệ hoàn thành / hoàn thành có thưởng, phiên gần đây có tên người thoát; thành viên sắp A→Z. (T-BA-82, T-BA-90, T-BA-91, T-BA-106)
- **manager_analytics_report** — Báo cáo tháng: mục đích sử dụng ở đầu; bỏ giờ tập trung, chuỗi, Session Efficiency; thêm người thoát từng phiên, tỉ lệ hoàn thành / hoàn thành có thưởng (D-11); bảng thành viên sắp theo tên. Email tóm tắt không PDF, nút "Tải PDF (tùy chọn)" (D-24). (T-BA-89, T-BA-90, T-BA-106, T-BA-109)
- **t_02** — Danh sách nhóm: "Trưởng phòng" → chủ nhóm; bỏ úp máy, giờ tập trung, chỉ số cộng nhiều nhóm, Squad. Mỗi nhóm chỉ trạng thái riêng; sĩ số 4–10. (T-BA-81, T-BA-82, T-BA-94, T-BA-107)
- **t_03** — Tạo nhóm: thêm "Mục đích sử dụng báo cáo" bắt buộc (kèm ca lỗi); sĩ số 4–10 thành viên không tính chủ nhóm; lịch 25/50 phút. Mã mời 8 ký tự theo nhóm (BR-76), bỏ QR, "toàn văn phòng", hạn 24h; bỏ khoan hồng lật máy, báo động, "+25 Xu", thêm thẳng thành viên. (T-BA-94, T-BA-122)
- **t_07** — Đổi thành "Chi tiết phiên" chỉ xem: bỏ phê duyệt, "Bảo lưu Streak", "Trừ điểm chuyên cần", Xu thưởng, nút hoàn tất. Hiện người thoát có tên; D-05: cả phiên, kể cả người ở lại, 0 Coins và ngắt chuỗi. (T-BA-83, T-BA-90, T-BA-91, T-BA-105)
- **t_11** — Chi tiết báo cáo thành viên: bỏ "Hạng A", "96/100", lật máy, Xu, ghi chú đánh giá của chủ nhóm, nút khen thưởng Xu. Còn có mặt, số lần thoát, tỉ lệ hoàn thành / có thưởng, danh sách phiên. (T-BA-89, T-BA-90, T-BA-110)
- **a_01** — Đăng nhập quản trị: bỏ SSO Google, OTP, trạng thái máy chủ trước đăng nhập; thêm ca lỗi sai mật khẩu. (T-BA-93, T-BA-121)
- **a_02** — Người dùng: bỏ Trưởng phòng, "Phân quyền", Drop Score, Xu, chuỗi, lật máy. Thêm Khóa/Mở có lý do, nút Xóa. (T-BA-82, T-BA-89, T-BA-121)
- **a_03** — Danh mục Shop: "Xu" → Coins; chỉ Khung/Hình nền; bỏ âm thanh, giới hạn số lượng, "hoàn Xu", doanh thu. (T-BA-86, T-BA-111, T-BA-121)
- **a_04** — Báo cáo vi phạm: bỏ Anti-Cheat con quay, "Yêu cầu Trưởng phòng xác minh", trừ Xu. Thêm luồng báo cáo nhóm, ô lý do, nhật ký xử lý. (T-BA-81, T-BA-82, T-BA-121)
- **a_05** — Tham số Coins: chỉ `coins_25`=10, `coins_50`=25, `coins_daily_cap`=100, giá Shop, có miền giá trị BR-112. Bỏ hệ số chuỗi, thưởng Squad, phiên tự do, luật 80%, quỹ Lead. Thêm ô lý do, nhật ký. (T-BA-85, T-BA-121)
