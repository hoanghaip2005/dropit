# Tổng hợp review mockup (đợt 1–3)

Ngày: 2026-10-19 · Người tổng hợp: ba-reviewer (độc lập)
Nguồn: `review/mockup-1-thanh-vien-phien.md` (bản 1), `review/mockup-2-chu-nhom-quan-tri.md` (bản 2), `review/mockup-3-shop-ho-so-xa-hoi.md` (bản 3) (nguồn cũ đã xóa); căn cứ `02-so-quyet-dinh.md` (D-01…D-26).
Mockup là **dữ liệu tham khảo**. Ở đâu mockup lệch D-/BR/NFR thì SRS thắng. Tệp này không sửa tệp yêu cầu.

Dải mã chính thức: **T-BA-81 … T-BA-122** (42 việc; 29 Cao, 11 TB, 2 Thấp). Mã tạm trong 3 bản gốc đã được thay bằng mã chính thức.

## 1. Bảng việc chính thức

Loại: **MS** = Mockup sửa · **SRS** = SRS sửa · **SM** = Story mới · **QĐ** = Quyết định cần chốt (tạo Q-, trạng thái `Chờ`).

| Mã chính thức | Mã tạm | Mức | Loại | Màn | Nội dung | Căn cứ |
| --- | --- | --- | --- | --- | --- | --- |
| T-BA-81 | M01; bản 2 T-BA-81 (phần cảm biến) | Cao | MS | c_04, schedule_focus, session_lobby_1/2, lockdown_mode*, n_07, t_09, t_11, a_02, a_04, s_06, x_05 | Bỏ mọi cảm biến úp máy/con quay/góc 180°/"lật máy"/anti-cheat dao động; chỉ diễn đạt "rời app" | NFR-P01, NFR-P15, D-03, D-08 |
| T-BA-82 | M02; bản 2 T-BA-81 (phần vai trò) | Cao | MS | c_03, c_04, lockdown_mode_active_focus_1, n_07, n_09, alert_details, t_02, t_03, t_07, t_09, a_02, a_04, a_05, danh mục `screenshot_*` | Đổi "Trưởng phòng/Manager/Lead/Công ty" thành "chủ nhóm"; bỏ phân hệ "Trưởng phòng", "Phân quyền" | D-10 |
| T-BA-83 | M03; bản 2 T-BA-81 (điểm chuyên cần/uy tín) | Cao | MS | session_lobby_1/2, alert_details, schedule_focus, lockdown_mode_active_focus_1, t_07 | Bỏ cược, pool, phí, multiplier, "at risk", "trừ điểm chuyên cần/uy tín"; thay câu D-05 | D-01, D-05, BR-41, BR-44 |
| T-BA-84 | M04 | Cao | MS | lockdown_mode_active_focus_1, n_07, n_09 | Câu cảnh báo: "Rời app sẽ báo tên bạn cho cả nhóm và làm cả phiên mất thưởng" | D-05, D-20, D-22, NFR-P18 |
| T-BA-85 | M05; bản 2 T-BA-81 (a_05) | Cao | MS | employee_home*, schedule_focus, session_lobby_1, *success_reward, n_09, a_05 | Coins đúng D-09 (25'=10, 50'=25, trần 100/ngày); bỏ thưởng chuỗi, hệ số streak, ngưỡng 80%, thưởng Squad, quỹ Lead | D-09, D-05, Q-17 |
| T-BA-86 | M06; M3-03 | Cao | MS + SRS | splash, n_09, n_10, session_lobby_2, the_shop, social_feed, s_02, s_06, x_05 | Thuật ngữ UI: chỉ "Coins" (không Xu/pts/XP/EXP/Drops), "DropIt!", "nhóm" (không squad/room/văn phòng), "chủ nhóm"; bổ sung `01` §8 | D-01, D-10, 01 §8 |
| T-BA-87 | M07 | TB | MS | employee_home_dashboard, n_09, n_10, t_11, `N-11` | Bỏ phiên Solo/tự do (hoặc mở Q- mới) | D-06, BR-01, Q-02 |
| T-BA-88 | M08 | Cao | MS | employee_home, employee_home_dashboard | Trang chủ chỉ phiên kế tiếp của nhóm mình; bỏ Live Rooms, Domains, tìm phòng | D-21, D-06 |
| T-BA-89 | M09; bản 2 T-BA-81 (xếp hạng) | Cao | MS | session_success_reward, success_reward, team_hub, manager_analytics_report, t_11, a_02 | Bỏ leaderboard, bục xếp hạng, điểm 96/100, "Hạng A", "Độ kỷ luật", "Session Efficiency", "Drop Score"; team_hub không dùng | D-03, NFR-P06 |
| T-BA-90 | bản 2 T-BA-81 (chuỗi/Coins) | Cao | MS | manager_dashboard, manager_analytics_report, team_hub, t_03, t_07, t_11, a_02 | Bỏ chuỗi và Coins trên mọi màn chủ nhóm/quản trị; chủ nhóm không cấp Coins | D-12, BR-53, BR-61, Q-23 |
| T-BA-91 | bản 2 T-BA-81 (t_09, t_07) | Cao | MS | t_09, t_07, manager_dashboard | Bỏ theo dõi trực tiếp từng người, trạng thái online/offline, báo khi mới vào GRACE, nút Nhắc/Rung/Tạm dừng; bỏ bước chủ nhóm "duyệt/hoàn tất phiên" và "bảo lưu streak" | BR-23, BR-28, BR-29, BR-54, BR-82, NFR-P02, D-25 |
| T-BA-92 | M10 | Cao | MS | splash_onboarding | Bỏ "real-world rewards", XP | D-03 |
| T-BA-93 | M11 | TB | SRS + QĐ | sign_in_login, a_01, user_profile | Kiểm AC quên mật khẩu/ghi nhớ đăng nhập trong US-01.01; tạm bỏ Google/Apple/SSO/Passkey đến khi chốt Q-65 | US-01.01, Q-65 |
| T-BA-94 | M12 | Cao | MS | c_03, t_02, t_03 | Bỏ QR (hoặc Could); sĩ số ≤10; mã theo Q-73 (8 ký tự, theo nhóm, không hết hạn 24h) | D-02, BR-74, BR-76, Q-73 |
| T-BA-95 | M13 | Cao | MS | c_04 | Viết lại màn đồng ý theo 04 §2: thêm D-05, D-22, mục đích báo cáo, quyền rút đồng ý; công tắc mặc định tắt; bỏ "mã hóa đầu cuối", bỏ "chỉ ghi tổng phút" | NFR-P04, NFR-P05, US-01.05, Q-109 |
| T-BA-96 | M14 | TB | QĐ | session_lobby_1 | Chốt nút "Sẵn sàng" (thêm AC US-03.01 hoặc bỏ); bỏ việc thành viên chọn thời lượng | D-06, US-03.01 |
| T-BA-97 | M15 | Cao | MS + SRS | lockdown_mode, lockdown_mode_active_focus_1 | Thêm chỉ báo "Phiên đang được ghi"; xác nhận AC "rời chủ động = EXITED" trong US-03.04/03.08 | NFR-P08, US-03.03 |
| T-BA-98 | M16 | Thấp | MS | lockdown_mode_active_focus_2 | Vẽ lại hoặc bỏ màn trống | — |
| T-BA-99 | M17 | TB | MS | n_02 | Bỏ "điểm danh ca/chấm công"; nếu là nhắc phiên thì theo US-02.14 | Q-17, US-02.14 |
| T-BA-100 | M18 | TB | QĐ | n_07 | Nút "việc khẩn cấp": nối tạm dừng (US-03.06) hay ghi rõ là thoát | US-03.05, US-03.06, D-05 |
| T-BA-101 | M19 | Cao | MS + SRS | n_09 | Hiện mất thưởng tập thể và ngắt chuỗi; giải trình có ô chữ; bỏ "biên bản làm việc"; chip lý do thêm vào AC US-04.05 hoặc bỏ | D-05, US-03.10, US-04.05, Q-12, Q-90 |
| T-BA-102 | M20 | TB | SM | n_10 | Story Should "Lịch sử phiên của tôi"; hiện trạng thái forfeited/LOST/ABSENT/CANCELLED | D-11, D-19 |
| T-BA-103 | M21 | TB | MS | success_reward | "Session mood": bỏ hoặc gộp vào nhật ký riêng tư US-07.07 | D-15, US-07.10 |
| T-BA-104 | M22 | Cao | MS | alert_details | Bỏ tên app "Opened Slack", stake, "discipline audit log", "Ghi nhận vi phạm"; thêm giải trình | NFR-P01, NFR-P02, D-03, Q-12, US-04.06 |
| T-BA-105 | bản 2 T-BA-82 | Cao | SM + QĐ | t_07, t_09, t_11 | Story màn "chi tiết phiên đã kết thúc" và "thành viên nhóm" của chủ nhóm; AC phủ định (không thời gian thực, không nút can thiệp, chỉ EXITED đã xác nhận). Q- mới: có màn phiên đang chạy cho chủ nhóm ở MVP không | AC-04.06.1, AC-08.02.9, US-05.09, BR-28, 04 §3 |
| T-BA-106 | bản 2 T-BA-83 | TB | SRS | manager_analytics_report | BR/AC thứ tự dòng báo cáo (tên A→Z, không sắp theo chỉ số) để tránh xếp hạng ngầm | D-03, BR-57, AC-08.05.4 |
| T-BA-107 | bản 2 T-BA-84 | Thấp | SRS | t_02 | AC US-02.06: màn danh sách nhóm không cộng chỉ số nhiều nhóm (đề xuất), chỉ trạng thái cấp nhóm | AC-08.02.10, D-25 |
| T-BA-108 | bản 2 T-BA-85 | Cao | SRS | — | Sửa AC-04.07.5 và BR-86 (a) theo D-25 (chủ nhóm không tham gia phiên của nhóm mình) | D-25 |
| T-BA-109 | M23; bản 2 T-BA-86; M3-12 | Cao | MS | (màn mới) | Vẽ màn cho story Must ở §4, kèm ca lỗi/biên theo AC | §4 |
| T-BA-110 | bản 2 T-BA-87 | TB | MS + SRS | t_03, t_11, mọi màn chủ nhóm | Kiểm NFR-P04a: mọi trường hiển thị phải có trong 04 §2 mục 2; bỏ "ghi chú đánh giá của chủ nhóm" | NFR-P03, NFR-P04a |
| T-BA-111 | M3-01 | Cao | MS | rewards_shop, the_shop | Shop: bỏ "Double Coin Surge"; chỉ 2 tab Khung/Hình nền; giá theo Q-98; nhãn Đã sở hữu/Đang dùng/Thiếu N Coins | D-09, BR-40, BR-43, AC-06.03.1, Q-98 |
| T-BA-112 | M3-02 | Cao | SRS | the_shop | AC cấm cơ chế ngẫu nhiên (hộp bí ẩn, quay thưởng) ở US-06.03 hoặc BR-93 | D-01, AC-06.03.7 |
| T-BA-113 | M3-04 | Cao | MS | s_02 | Bỏ đặc quyền "+5% Xu", "Prime", "142 đồng nghiệp đã sở hữu", tặng vật phẩm; thêm ca lỗi AC-06.04.2/.3/.7/.8 | GĐ1 §4.6, D-03, AC-06.05.5, BR-44 |
| T-BA-114 | M3-05 | Cao | MS | s_06 | Bỏ Level/XP/Hạng/Điểm cống hiến, huy hiệu cộng Coins, huy hiệu "Đội trưởng dẫn dắt phòng", huy hiệu ngoài BR-52; thêm công tắc hiển thị và cảnh báo NFR-P17 | D-03, D-25, BR-51, BR-52 |
| T-BA-115 | M3-06 | Cao | MS | write_journal | Đúng câu nhãn AC-07.10.7; bỏ E2E, công tắc riêng tư, chia sẻ Feed, gắn phiên, ảnh/ghi âm, tâm trạng | AC-07.10.7, BR-100, Q-06, Q-109 |
| T-BA-116 | M3-07 | Cao | SRS | social_feed, x_01, x_03, x_05 | Ràng buộc riêng tư cho EP-10 (sau MVP): không hiện diện ngoài phiên, không thông báo vào phiên, không phạm vi toàn công ty, không hiện chuỗi/Coins mặc định, 1 nhóm | NFR-P02, Q-87, D-12, D-21, GĐ1 §9 |
| T-BA-117 | M3-08 | Cao | SRS | x_01, x_03 | Thêm `01` §6: không đọc danh bạ/thư mục công ty/tài khoản Google, Slack | GĐ1 §6, D-03 |
| T-BA-118 | M3-09 | Cao | QĐ | x_05, s_02 | Q- mới: có cho chuyển Coins/quà giữa người dùng ở EP-10 không (đề xuất: không) | BR-44 |
| T-BA-119 | M3-10 | Cao | MS + SRS | design system, mọi màn | Chọn `dropit/DESIGN.md` làm nguồn; sửa token chữ phụ/cam/xanh đạt 4.5:1; viền Lockdown ≥3:1; Lockdown tĩnh; 1 thanh điều hướng | NFR-20, NFR-08 |
| T-BA-120 | M3-11 | TB | MS | user_profile, employee_profile_inventory | Bỏ LVL/chức danh/danh hiệu/Tier; 1 khung đang dùng; thêm chuỗi hiện tại, huy hiệu, hình nền, nút Gỡ, lối vào "Dữ liệu của tôi"; chặn đăng xuất trong phiên | BR-95, BR-97, Q-104, Q-66, NFR-P03 |
| T-BA-121 | (mới, từ bản 2 §2.9–2.13) | TB | MS | a_01…a_05 | Màn quản trị: bỏ hạ tầng trước đăng nhập, loại hàng ngoài MVP, giới hạn số lượng, "hoàn Xu"; thêm Khóa/Mở có lý do, nút Xóa, `coins_daily_cap`, ô lý do + nhật ký tham số; a_04 thêm luồng báo cáo nhóm | NFR-11, BR-93, Q-99, AC-09.02, AC-09.03.4, AC-09.06, AC-09.08.1 |
| T-BA-122 | (mới, từ bản 2 §2.5) | Cao | MS | t_03 | Tạo nhóm: thêm trường bắt buộc "mục đích sử dụng báo cáo"; bỏ "mời ban đầu" thêm thẳng vào nhóm (phải qua màn đồng ý); bỏ chọn khoan hồng, "tự động +25 Xu", công tắc báo động | NFR-P09, NFR-P04, US-01.05, BR-11, BR-112, D-09, D-20 |

Gộp trùng: thuật ngữ (M06 + M3-03 → T-BA-86); vẽ màn thiếu (M23 + bản 2 T-BA-86 + M3-12 → T-BA-109); bản 2 T-BA-81 tách vào T-BA-81, 82, 83, 85, 89, 90, 91 theo chủ đề.

## 2. Hướng dẫn sửa mockup cho nhóm thiết kế

### Bỏ

- Cảm biến úp máy, con quay, góc 180°, "lật máy", "nhấc máy", anti-cheat dao động. App chỉ biết **rời app**. (T-BA-81)
- Đọc tên app khác ("Opened Slack"), đọc danh bạ/Google Workspace/Slack. (T-BA-104, T-BA-117)
- Cược, phí, STAKE, pool, bounty, multiplier, "at risk", "pts", điểm chuyên cần/uy tín. (T-BA-83, T-BA-86)
- Leaderboard, bục xếp hạng, điểm 96/100, Hạng, Level/XP, độ kỷ luật, "Session Efficiency", "Drop Score". (T-BA-89, T-BA-114)
- "Trưởng phòng", "Manager", "Lead", "Công ty", "Phân quyền". (T-BA-82)
- Live Rooms, Domains, tìm phòng, phòng 8 chỗ, phiên Solo/tự do. (T-BA-87, T-BA-88)
- Chủ nhóm tham gia hoặc điều khiển phiên: theo dõi trực tiếp, Nhắc, Rung cả đội, Tạm dừng, duyệt/hoàn tất phiên, bảo lưu streak. (T-BA-91)
- Chuỗi và Coins hiện cho chủ nhóm/quản trị; chủ nhóm cấp Coins. (T-BA-90)
- Double Coin, Mystery Box, bán lợi thế (+5%), Prime, tặng Coins/vật phẩm. (T-BA-111, T-BA-112, T-BA-113)
- "E2E encrypted", "Only you can see", công tắc riêng tư/chia sẻ nhật ký. (T-BA-115, T-BA-95)
- Màn EP-10 (social_feed, x_01, x_03, x_05): không thuộc MVP. (T-BA-116)

### Thêm

- Các màn còn thiếu theo story Must ở §4, mỗi màn kèm ca lỗi/biên. (T-BA-109)
- Chỉ báo "Phiên đang được ghi" trên màn phiên. (T-BA-97)
- Trường "mục đích sử dụng báo cáo" ở tạo nhóm. (T-BA-122)

### Sửa

- Thông báo thoát: có tên, gửi cho **cả nhóm và mọi người trong phiên**, kèm câu "cả phiên mất Coins và ngắt chuỗi". (T-BA-84, T-BA-101)
- Màn đồng ý c_04: theo 04 §2, công tắc mặc định tắt. (T-BA-95)
- Mục đích báo cáo hiện ở đầu mọi màn báo cáo; dòng thành viên sắp theo tên. (T-BA-106, T-BA-109)
- Coins đúng D-09: 25' = 10, 50' = 25, trần 100/ngày; chuỗi không cộng Coins. (T-BA-85)
- Tương phản ≥ 4.5:1 cho chữ, ≥ 3:1 cho viền thành phần. (T-BA-119)
- Dùng `dropit/DESIGN.md` làm nguồn duy nhất; sửa YAML cho khớp văn bản. (T-BA-119)
- Mã mời: theo nhóm, độ dài theo Q-73; sĩ số ≤ 10. (T-BA-94)

## 3. Lỗi trong SRS phát hiện qua mockup

| # | Lỗi | Mức | Vị trí | Việc |
| --- | --- | --- | --- | --- |
| S1 | AC-04.07.5 "Chủ nhóm tự tham gia và EXITED… gửi khiếu nại" mâu thuẫn D-25; BR-86 (a) cần kiểm lại | Cao | `02-ep04-thong-bao.md`, `03-quy-tac.md` | T-BA-108 |
| S2 | Không story nào đặc tả màn "chi tiết phiên đã kết thúc" của chủ nhóm dù AC-04.06.1, AC-08.02.9 tham chiếu; US-05.09 là Should nhưng 04 §3 gọi là "lối vào duy nhất" | Cao | EP-04, EP-05, EP-08 | T-BA-105 |
| S3 | Thiếu câu phủ định "chủ nhóm không xem trạng thái từng người theo thời gian thực trong phiên" | TB | EP-03/EP-04, 04 §3 | T-BA-105 |
| S4 | Thiếu BR thứ tự hiển thị dòng báo cáo (tránh xếp hạng ngầm) | TB | BR-57, US-08.02 | T-BA-106 |
| S5 | Chưa có quy tắc cộng chỉ số nhiều nhóm ở màn danh sách nhóm của chủ nhóm | Thấp | US-02.06 | T-BA-107 |
| S6 | Chưa có AC cấm cơ chế ngẫu nhiên trong Shop | Cao | US-06.03, BR-93 | T-BA-112 |
| S7 | `01` §6 chưa liệt kê "không đọc danh bạ/thư mục công ty" | Cao | `01-pham-vi.md` §6 | T-BA-117 |
| S8 | Bảng thuật ngữ chưa có cột tên UI cấm dùng (Xu, pts, squad, Lead…) | TB | `01` §8 | T-BA-86 |
| S9 | Chưa rõ AC "rời chủ động = EXITED" ở US-03.04/03.08; chưa rõ AC quên mật khẩu ở US-01.01 | TB | EP-03, EP-01 | T-BA-97, T-BA-93 |
| S10 | Chưa có story Lịch sử phiên của tôi | TB | EP-05/06/08 | T-BA-102 |
| S11 | Chưa có ràng buộc riêng tư ghi sẵn cho EP-10 | Cao | `04-nfr-rieng-tu.md` | T-BA-116 |

## 4. Story Must chưa có màn (gộp 3 bản)

| Epic | Story | Tình trạng |
| --- | --- | --- |
| EP-01 | US-01.02 Đăng xuất | Chưa có (kèm ca chặn trong phiên, Q-66) |
| EP-01 | US-01.03 Sửa hồ sơ cơ bản | Chưa có |
| EP-01 | US-01.04 Vai trò theo từng nhóm | Chưa có |
| EP-01 | US-01.05 Đồng ý minh bạch | Có c_04 nhưng phải viết lại (T-BA-95) |
| EP-01 | US-01.07 Rút đồng ý và rời nhóm | Chưa có (kèm ca rời giữa phiên, D-23) |
| EP-01 | US-01.08 Dữ liệu của tôi | Chưa có |
| EP-02 | US-02.01 Tạo nhóm | t_03 thiếu trường mục đích (T-BA-122) |
| EP-02 | US-02.03 Mời bằng mã (phía chủ nhóm) | t_03 lệch BR-76 |
| EP-02 | US-02.06 Xem nhóm và thành viên | Chỉ t_02 một phần |
| EP-02 | US-02.08 Xóa thành viên | Chưa có |
| EP-02 | US-02.10 Đặt lịch một lần | schedule_focus phải sửa (T-BA-81, T-BA-83) |
| EP-02 | US-02.11 Sửa/hủy lịch | Chưa có (ca không sửa khi COUNTDOWN/ACTIVE) |
| EP-03 | US-03.02 Đếm ngược 5 giây | Chưa có |
| EP-03 | US-03.07 Mất kết nối giữa phiên | Chưa có |
| EP-03 | US-03.08 Mất thưởng tập thể | Chưa có màn hiện `forfeited` |
| EP-03 | US-03.09 Thông báo người thoát có tên | Chưa có phía thành viên |
| EP-03 | US-03.10 Kết quả phiên — ca "hoàn thành nhưng mất thưởng" | Chưa có |
| EP-04 | US-04.01 Báo ngay cho cả nhóm | Thiếu push phía thành viên và mẫu có tên nhóm + lịch (AC-04.01.9) |
| EP-04 | US-04.05 Thành viên giải trình | Chưa có màn gửi |
| EP-04 | US-04.06 Chủ nhóm xem giải trình | t_07 trái quy tắc (T-BA-91) |
| EP-05 | US-05.04 Xem chuỗi | Một phần |
| EP-05 | US-05.05 Nhận huy hiệu theo mốc | Chưa có thông báo trong app |
| EP-06 | US-06.02 Số dư và lịch sử Coins | Chưa có |
| EP-06 | US-06.05 Trang bị và gỡ | Thiếu nút Gỡ, ca lỗi |
| EP-07 | US-07.01 Hồ sơ của tôi | Một phần |
| EP-07 | US-07.04 Khung và hình nền | Thiếu hình nền, góc nhìn người cùng nhóm |
| EP-07 | US-07.07 Viết nhật ký | Thiếu ca lỗi |
| EP-07 | US-07.10 Nhật ký riêng tư | Sai câu chữ (T-BA-115) |
| EP-08 | US-08.01 Báo cáo tự động | Thiếu trạng thái "báo cáo đầu tiên sẽ có vào…" |
| EP-08 | US-08.03 Báo cáo của tôi | Chưa có |
| EP-08 | US-08.07 Email tóm tắt | Chưa có mẫu thân thư |
| EP-08 | US-08.08 Thông báo mục đích báo cáo | Chưa có trên màn báo cáo nào |

EP-09 toàn Should/Could; màn a_* không chặn MVP.

## 5. Kết luận

**Chưa đạt.** Bộ mockup vẫn theo mô hình đặc tả 1.0 cũ (nguồn cũ đã xóa) và mô hình "Trưởng phòng giám sát". Có vi phạm riêng tư cứng ở alert_details ("Opened Slack"), t_09 (cảm biến, theo dõi trực tiếp), x_01/x_03 (danh bạ, hiện diện ngoài phiên). SRS cần sửa 1 lỗi Cao (T-BA-108) và bổ sung story/AC phủ định cho màn chủ nhóm (T-BA-105).
