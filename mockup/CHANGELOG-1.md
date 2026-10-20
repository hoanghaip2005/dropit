# CHANGELOG mockup — đợt sửa 1

Ngày: 2026-10-19. Căn cứ: `ba/review/mockup-tong-hop.md` §1–§2, `ba/02-so-quyet-dinh.md` (D-01…D-26).
Cách sửa: giữ nguyên `<head>` (token Tailwind theo `dropit/DESIGN.md`), viết lại phần `<body>` bằng tiếng Việt, `lang="vi"`. Đã xóa `screen.png` của mọi màn dưới đây (ảnh cũ không còn đúng).

| Màn | Đã bỏ / sửa | T-BA |
| --- | --- | --- |
| splash_onboarding | Bỏ "FocusLoop", "real-world rewards", "+120 XP", "FocusCoins". Thay bằng "DropIt!", "+10 Coins", câu mô tả phiên theo lịch nhóm. | 86, 92 |
| sign_in_login | Việt hóa. Bỏ đăng nhập Google/Apple đến khi chốt Q-65; giữ "Ghi nhớ đăng nhập", "Quên mật khẩu?", thêm ca lỗi sai mật khẩu. | 93 |
| c_03 (nhập mã nhóm) | Bỏ "văn phòng", "Trưởng phòng/Công ty", QR, "14 thành viên trực tuyến". Mã 8 ký tự theo nhóm (Q-73), sĩ số 7/10, ca lỗi mã sai/nhóm đủ 10, câu "bạn chỉ thuộc 1 nhóm". | 82, 94 |
| c_04 (đồng ý minh bạch) | Bỏ cảm biến úp máy/con quay/tiệm cận, "mã hóa đầu cuối", "chỉ ghi tổng phút". Thêm: phát hiện = rời app, khoan hồng 3s, báo tên cả nhóm (D-20, D-22), mất thưởng tập thể + ngắt chuỗi (D-05), mục đích báo cáo, chỉ 1 nhóm (D-21), rút đồng ý (D-23). Công tắc mặc định tắt, nút khóa đến khi bật. | 81, 82, 95 |
| employee_home | Bỏ Domains, tìm kiếm, Live Rooms, "lunch reward". Chỉ còn phiên kế tiếp của nhóm, Coins hôm nay /100, chuỗi (không cộng Coins); điều hướng 3 mục. | 85, 88 |
| employee_home_dashboard | Bỏ "Squad", danh sách phòng, Solo Quick Drop, Coins sai (50/75/30). Thay bằng phiên kế tiếp + lịch còn lại hôm nay; Coins 25'=10, 50'=25. | 85, 87, 88 |
| schedule_focus | Bỏ cảm biến úp máy, "Reward Bounty/Pool". Ghi rõ màn của chủ nhóm, chủ nhóm không tham gia phiên (D-25); Coins theo D-09; nêu quy tắc rời app/D-05. | 81, 83, 85 |
| session_lobby_1 | Bỏ "2x Multiplier", "+50 Focus Coins", chọn thời lượng của thành viên, "8 chỗ", cảm biến. Thời lượng do chủ nhóm đặt, +10 Coins, 4/7 người, quy tắc rời app/D-05/D-08. Nút "Sẵn sàng" giữ tạm, chờ chốt. | 81, 83, 85, 96 |
| session_lobby_2 | Bỏ "Live Room", "Streak Pool/Drops", phí phạt 15 coin, chọn thời lượng, slot 8. Thay như lobby_1 với phiên 50' = +25 Coins, sĩ số ≤10. | 81, 83, 86, 94, 96 |
| lockdown_mode | Bỏ "úp điện thoại". Thêm chỉ báo "Phiên đang được ghi", cảnh báo D-05, cho tắt màn hình (D-08), giữ 3s để thoát = EXITED. Màn tĩnh (bỏ vòng tiến độ chạy). | 81, 97, 119 |
| lockdown_mode_active_focus_1 | Bỏ "COINS AT RISK", cảm biến con quay/ánh sáng, "Manager Sarah Jenkins", "trừ tiến độ". Thêm "Phiên đang được ghi" và câu "Rời app sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng". | 81, 82, 83, 84, 97 |
| lockdown_mode_active_focus_2 | Xóa thư mục (màn trống). | 98 |
| n_02 | Bỏ điểm danh ca/chấm công, hiệu suất, đơn hàng, tâm trạng, "Xu", rương vàng. Viết lại thành thông báo nhắc phiên sắp bắt đầu (US-02.14). | 86, 99 |
| n_07 (khoan hồng 3s) | Bỏ "Úp điện thoại", cảm biến, "vi phạm tới Trưởng phòng/bảng quản lý". Thay: rời app, đếm 3s, hết hạn báo tên cho cả nhóm + mọi người trong phiên, D-05. Nút khẩn cấp ghi rõ là thoát phiên (chờ chốt). | 81, 82, 84, 100 |
| n_09 (rời phiên sớm) | Bỏ ngưỡng 80%, "50 Xu", "Trưởng phòng", "biên bản làm việc", chip lý do, "phiên cá nhân mới". Thêm: cả phiên mất thưởng, ngắt chuỗi, đã báo tên cả nhóm, ô giải trình. | 82, 84, 85, 87, 101 |
| n_10 (lịch sử phiên) | Bỏ Solo/Cá nhân, "Squad", "Xu", phiên 60', tỷ lệ % và "kỷ lục". Thêm các trạng thái: hoàn thành có thưởng, hoàn thành nhưng phiên mất thưởng, rời phiên, mất kết nối, vắng, bị hủy. | 85, 86, 87, 102 |
| session_success_reward | Bỏ "Bonus Streak +10", "Team Integrity", 25' = 25 Coins, "View Team Leaderboard". 25' = +10 Coins, chuỗi không cộng Coins, Coins hôm nay /100. | 85, 89 |
| success_reward | Bỏ thưởng chuỗi, "Session mood", leaderboard, "Protocol #". Phiên 50' = +25 Coins. | 85, 89, 103 |
| alert_details | Viết lại thành "Chi tiết sự kiện rời phiên": tên, phiên, giờ rời, thời lượng ngoài app, kết quả D-05, giải trình (nếu có). Bỏ "Opened Slack", stake, "Ghi nhận vi phạm/Miễn trừ", "discipline audit log", danh sách Squads. | 82, 83, 104 |

Còn chờ chốt (không tự quyết): nút "Sẵn sàng" (T-BA-96), nút việc khẩn cấp có nối tạm dừng không (T-BA-100), chip lý do giải trình (T-BA-101/Q-90).
