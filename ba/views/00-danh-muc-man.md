# Danh mục màn MVP (V-xx)

Ngày: 2026-10-19 · Việc: T-BA-109 (vẽ màn cho story Must ở `review/mockup-tong-hop.md` §4) · Người viết: BA
Căn cứ: `02-so-quyet-dinh.md` (D-01…D-26), `srs/02-ep0*.md`, `srs/03-quy-tac.md` (đến BR-121), `srs/04-nfr-rieng-tu.md`, `mockup/CHANGELOG-1/2/3.md`, `mockup/dropit/DESIGN.md`.

Quy ước:
- Cột "Nguồn": `mockup/<thư mục>` = đã có mockup HTML (đã sửa ở 3 đợt); `views/Vxx.md` = đặc tả tài liệu trong thư mục này (chưa có HTML). Có cả hai = mockup có một phần, tệp `views` bổ sung phần thiếu và **thắng** khi lệch.
- Token giao diện: chỉ dùng `mockup/dropit/DESIGN.md`. Tên API trong các tệp `Vxx` là **(giả định)**, chờ đặc tả API.
- Câu hỏi mới chưa có số chính thức ghi dạng **VQ-xx** (đề xuất); điều phối viên cấp số `Q-` khi ghi sổ.
- Mọi danh sách người: sắp theo BR-115 (tên A→Z, trùng tên theo thời điểm vào nhóm rồi `user_id`; chủ nhóm đứng đầu danh sách thành viên). Mọi màn chủ nhóm: không Coins, không chuỗi (BR-53), không thời gian thực (BR-116).

## 1. Bảng màn

### 1.1 Chung / thành viên

| Mã | Tên màn | Vai trò dùng | Story phục vụ | Ưu tiên | Nguồn |
| --- | --- | --- | --- | --- | --- |
| V-01 | Giới thiệu (splash) | Khách | US-01.01 | Must | mockup/splash_onboarding |
| V-02 | Đăng nhập / đăng ký | Khách | US-01.01 | Must | mockup/sign_in_login |
| V-03 | Trang chủ thành viên (phiên kế tiếp của nhóm) | Thành viên | US-03.01, US-05.04 (tóm tắt), US-06.02 (tóm tắt) | Must | mockup/employee_home, mockup/employee_home_dashboard |
| V-04 | Nhập mã nhóm | Người dùng | US-01.05, US-02.03 (phía người được mời) | Must | mockup/c_03_nh_p_m_tham_gia_v_n_ph_ng_nh_m |
| V-05 | Đồng ý minh bạch | Người được mời | US-01.05 | Must | mockup/c_04_ng_quy_t_c_minh_b_ch_v_quy_n_ri_ng_t (+ khối V-35) + views/V05-dong-y-trang-thai-loi.md |
| V-06 | Phòng chờ | Thành viên | US-03.01 | Must | mockup/session_lobby_1, mockup/session_lobby_2 + views/V06-phong-cho-trang-thai.md |
| V-07 | Đếm ngược 5 giây | Thành viên | US-03.02 | Must | views/V07-dem-nguoc.md |
| V-08 | Màn phiên (Lockdown) | Thành viên | US-03.03, US-03.04 | Must | mockup/lockdown_mode, mockup/lockdown_mode_active_focus_1 |
| V-09 | Khoan hồng 3 giây | Thành viên | US-03.05 | Must | mockup/n_07_c_nh_b_o_khoan_h_ng_3_gi_y |
| V-10 | Mất kết nối / LOST | Thành viên | US-03.07 | Must | views/V10-mat-ket-noi.md |
| V-11 | Banner người thoát (trong phiên) | Thành viên đang trong phiên | US-03.08, US-03.09, US-04.01 | Must | views/V11-banner-nguoi-thoat.md |
| V-12 | Kết quả — hoàn thành có thưởng | Thành viên | US-03.10, US-06.01 | Must | mockup/session_success_reward, mockup/success_reward |
| V-13 | Kết quả — bạn đã rời phiên (EXITED) | Thành viên | US-03.10, US-03.09 (AC-03.09.8), lối vào US-04.05 | Must | mockup/n_09_k_t_qu_r_i_phi_n_s_m |
| V-14 | Kết quả — các biến thể (hoàn thành nhưng mất thưởng, mất kết nối, vắng, đạt trần, hủy) | Thành viên | US-03.08, US-03.10, US-03.07 | Must | views/V14-ket-qua-bien-the.md |
| V-15 | Gửi / sửa giải trình | Thành viên (người EXITED) | US-04.05 | Must | views/V15-gui-giai-trinh.md |
| V-16 | Hộp thông báo và mẫu push | Thành viên, chủ nhóm | US-04.01, US-03.09, US-04.06 (AC-04.06.2), US-05.05, US-02.08, US-01.07 | Must | views/V16-hop-thong-bao.md |
| V-17 | Lịch sử phiên của tôi | Thành viên | US-03.14 | Should | mockup/n_10_l_ch_s_phi_n |
| V-18 | Nhắc phiên sắp bắt đầu | Thành viên | US-02.14 | Should | mockup/n_02_i_m_danh_h_p_tho_i |
| V-19 | Nhóm của tôi (vai trò theo nhóm) | Người dùng | US-01.04, US-02.06 | Must | views/V19-nhom-cua-toi.md |
| V-20 | Thành viên nhóm (+ xóa thành viên cho chủ nhóm) | Thành viên, chủ nhóm | US-02.06, US-02.08 | Must | views/V20-thanh-vien-nhom.md |
| V-21 | Rời nhóm / rút đồng ý | Thành viên | US-01.07 | Must | views/V21-roi-nhom-rut-dong-y.md |
| V-22 | Hồ sơ của tôi + Đồ của tôi | Người dùng | US-07.01, US-07.04, US-06.05 | Must | mockup/user_profile, mockup/employee_profile_inventory |
| V-23 | Sửa hồ sơ | Người dùng | US-01.03 (US-07.03 Should) | Must | views/V23-sua-ho-so.md |
| V-24 | Đăng xuất (xác nhận / bị chặn) | Người dùng | US-01.02 | Must | views/V24-dang-xuat.md |
| V-25 | Dữ liệu của tôi | Người dùng | US-01.08 (US-01.09, US-01.11 Should) | Must | views/V25-du-lieu-cua-toi.md |
| V-26 | Thành tích: chuỗi và mốc kế tiếp | Người dùng | US-05.04 | Must | views/V26-chuoi-moc-ke-tiep.md |
| V-27 | Nhận huy hiệu (trong app) | Người dùng | US-05.05 | Must | views/V27-nhan-huy-hieu.md |
| V-28 | Bộ sưu tập huy hiệu, công tắc hiện trên hồ sơ | Người dùng | US-05.06 | Should | mockup/s_06_huy_hi_u_v_th_nh_t_ch |
| V-29 | Coins của tôi và lịch sử | Người dùng | US-06.02 | Must | views/V29-coins-lich-su.md |
| V-30 | Shop | Người dùng | US-06.03, US-06.05 | Must | mockup/rewards_shop, mockup/the_shop |
| V-31 | Chi tiết món và xác nhận mua | Người dùng | US-06.04 | Must | mockup/s_02_chi_ti_t_v_t_ph_m_v_x_c_nh_n_mua |
| V-32 | Hồ sơ công khai người cùng nhóm | Thành viên, chủ nhóm | US-07.04 (góc nhìn người khác), US-07.06 (Should) | Must (phần US-07.04) | views/V32-ho-so-cong-khai.md |
| V-33 | Nhật ký | Người dùng | US-07.07, US-07.10 | Must | mockup/write_journal |
| V-34 | Báo cáo của tôi (dòng của mình) | Thành viên | US-08.03, US-08.08 | Must | views/V34-bao-cao-cua-toi.md |
| V-35 | Khối "Mục đích sử dụng báo cáo" (thành phần dùng chung) | Mọi vai trò xem báo cáo | US-08.08 | Must | views/V35-muc-dich-bao-cao.md |

### 1.2 Chủ nhóm

| Mã | Tên màn | Vai trò dùng | Story phục vụ | Ưu tiên | Nguồn |
| --- | --- | --- | --- | --- | --- |
| V-40 | Trang chủ chủ nhóm | Chủ nhóm | US-02.06, lối vào US-08.10 | Must | mockup/manager_dashboard |
| V-41 | Danh sách nhóm của chủ nhóm | Chủ nhóm | US-02.06, US-01.04 | Must | mockup/t_02_danh_s_ch_nh_m (quy tắc gộp chỉ số: V-19) |
| V-42 | Tạo nhóm | Người dùng | US-02.01 | Must | mockup/t_03_t_o_s_a_nh_m |
| V-43 | Mời thành viên (mã mời) | Chủ nhóm | US-02.03 | Must | views/V43-moi-ma-chu-nhom.md |
| V-44 | Đặt lịch một lần | Chủ nhóm | US-02.10 | Must | mockup/schedule_focus |
| V-45 | Sửa / hủy lịch | Chủ nhóm | US-02.11 | Must | views/V45-sua-huy-lich.md |
| V-46 | Chi tiết phiên của nhóm | Chủ nhóm | US-08.10, US-04.06 | Must | views/V46-chi-tiet-phien-chu-nhom.md (thắng mockup/t_07_xem_l_i_v_x_c_nh_n_phi_n) |
| V-47 | Giải trình của thành viên (chủ nhóm xem) | Chủ nhóm | US-04.06 | Must | views/V47-chu-nhom-xem-giai-trinh.md (thắng mockup/alert_details) |
| V-48 | Báo cáo nhóm — trạng thái và mục đích | Chủ nhóm | US-08.01, US-08.02, US-08.08 | Must | mockup/manager_analytics_report + views/V48-bao-cao-nhom-trang-thai.md |
| V-49 | Chi tiết dòng báo cáo thành viên | Chủ nhóm | US-08.02 | Must | mockup/t_11_chi_ti_t_b_o_c_o_th_nh_vi_n |
| V-50 | Email tóm tắt báo cáo tháng | Chủ nhóm (hộp thư) | US-08.07 | Must | views/V50-email-tom-tat.md |

### 1.3 Quản trị (EP-09, Should — không chặn MVP)

| Mã | Tên màn | Vai trò | Story | Ưu tiên | Nguồn |
| --- | --- | --- | --- | --- | --- |
| V-60 | Đăng nhập quản trị | Quản trị | US-09.01 | Should | mockup/a_01_admin_ng_nh_p |
| V-61 | Người dùng (khóa/mở/xóa) | Quản trị | US-09.02 | Should | mockup/a_02_admin_ng_i_d_ng |
| V-62 | Danh mục Shop | Quản trị | US-09.03 | Should | mockup/a_03_admin_danh_m_c_shop |
| V-63 | Báo cáo lạm dụng / khiếu nại | Quản trị | US-09.05, US-09.06 | Should | mockup/a_04_admin_b_o_c_o_vi_ph_m_n_i_dung |
| V-64 | Tham số kinh tế | Quản trị | US-09.08 | Should | mockup/a_05_admin_tham_s_kinh_t |

Tổng: 46 màn thành viên/chủ nhóm (V-01…V-35, V-40…V-50) + 5 màn quản trị = 51 mã (T-BA-137). Tệp đặc tả trong `views/`: 26 (23 màn chưa có mockup + 3 tệp bổ sung trạng thái cho mockup: V05, V06, V48).

## 2. Story Must ở `mockup-tong-hop.md` §4 → màn

| Story | Màn | Ghi chú |
| --- | --- | --- |
| US-01.02 | V-24, V-22 | Chặn trong phiên (BR-70) |
| US-01.03 | V-23 | |
| US-01.04 | V-19, V-41 | |
| US-01.05 | V-05 | Mockup đã viết lại (đợt 1); trạng thái lỗi ở views/V05 |
| US-03.01 | V-06 | Mockup đợt 1; trạng thái lỗi/biên ở views/V06 |
| US-01.07 | V-21 | Có ca giữa phiên (D-23) |
| US-01.08 | V-25 | |
| US-02.01 | V-42 | Mockup đã thêm trường mục đích (đợt 2) |
| US-02.03 | V-43 (phía chủ nhóm), V-04 (phía người nhập) | |
| US-02.06 | V-19, V-20, V-41 | |
| US-02.08 | V-20 | |
| US-02.10 | V-44 | Mockup đã sửa (đợt 1) |
| US-02.11 | V-45 | |
| US-03.02 | V-07 | |
| US-03.07 | V-10, V-14 | |
| US-03.08 | V-11, V-14 | Hiện `forfeited` |
| US-03.09 | V-11, V-16 | Phía thành viên |
| US-03.10 | V-12, V-13, V-14 | |
| US-04.01 | V-16 | Mẫu có tên nhóm + tên lịch (AC-04.01.9) |
| US-04.05 | V-15 | |
| US-04.06 | V-46, V-47 | |
| US-05.04 | V-26 | |
| US-05.05 | V-27 | |
| US-06.02 | V-29 | |
| US-06.05 | V-22, V-30 | Mockup đã thêm nút Gỡ (đợt 3) |
| US-07.01 | V-22 | Mockup đã sửa (đợt 3) |
| US-07.04 | V-22, V-32 | V-32 là góc nhìn người cùng nhóm |
| US-07.07, US-07.10 | V-33 | Mockup đã sửa (đợt 3) |
| US-08.01 | V-48 | Trạng thái "báo cáo đầu tiên sẽ có vào…" |
| US-08.03 | V-34 | |
| US-08.07 | V-50 | |
| US-08.08 | V-35 (dùng ở V-05, V-34, V-48, V-49, V-50) | |
| US-08.02 | V-48, V-49 | Thứ tự dòng BR-115 |
| US-08.10 | V-46 | Story mới (T-BA-105); chỉ đọc, không thời gian thực (BR-116) |

Kiểm đủ: mọi story Must ở §4 và US-08.10 đều có ít nhất một màn có nguồn tồn tại. Story Must thiếu màn: **0**.

## 3. Sơ đồ điều hướng

Thanh điều hướng (DESIGN.md: một thanh, viên thuốc đen nổi) — **(đề xuất, VQ-01)**:
- Người chỉ là thành viên: **Trang chủ** (V-03) · **Nhóm** (V-19) · **Hồ sơ** (V-22).
- Người là chủ nhóm (có thể đồng thời là thành viên nhóm khác, BR-75 c): **Trang chủ** (V-03 nếu là thành viên; khối "Nhóm tôi quản lý" dẫn V-40) · **Nhóm** (V-19) · **Hồ sơ** (V-22).
- Biểu tượng chuông ở đầu V-03/V-40 mở V-16. Không có tab Shop riêng: vào từ V-22 và V-29.
- Màn V-07…V-11 (trong phiên) **không** có thanh điều hướng.

Luồng:

1. **Vào app**
   - V-01 → V-02 → (đăng nhập xong) → V-03 nếu là thành viên; V-40 nếu chỉ là chủ nhóm; V-19 trạng thái trống nếu chưa có nhóm.
2. **Tham gia nhóm**
   - V-19 (trống) → "Nhập mã" → V-04 → V-05 → "Đồng ý và vào nhóm" → V-03.
   - V-05 "Không đồng ý" → V-19.
3. **Phiên**
   - V-03 / V-18 (nhắc) → V-06 → (đến `started_at − 5s`) V-07 → (đến `started_at`) V-08.
   - V-08 → rời app → V-09 → quay lại trước hạn → V-08; hết hạn → (sau `ends_at`) V-13.
   - V-08 → mất mạng → V-10 → nối lại trong hạn → V-08; quá hạn → V-14 (biến thể Mất kết nối).
   - V-08 ↔ V-11 (banner chồng lên V-08, không chuyển màn).
   - V-08 → liên kết "Rút đồng ý và rời nhóm" → V-21 (đề xuất, VQ-04).
   - V-08 → nút "Rời phiên" → hộp xác nhận nêu hệ quả → "Xác nhận": EXITED ngay → V-13; "Hủy": ở lại V-08 (D-29, BR-118, AC-03.04.7–10). V-06 → nút "Rời phiên" → xác nhận → ABSENT → V-03 (BR-118 (2), Q-149). V-07 không có nút. Mất kết nối: báo "Chưa rời phiên — không có kết nối", không xếp hàng (BR-118 (3)).
   - Đến `ends_at` → V-12 / V-13 / V-14 theo kết quả → (nếu có huy hiệu mới) V-27 → V-03.
   - V-13 → "Gửi giải trình" → V-15.
4. **Hồ sơ và dữ liệu**
   - V-22 → "Sửa hồ sơ" → V-23.
   - V-22 → "Coins" → V-29 → "Shop" → V-30 → V-31.
   - V-22 → "Thành tích" → V-26 → (Should) V-28.
   - V-22 → "Nhật ký" → V-33.
   - V-22 → "Dữ liệu của tôi" → V-25 → (từng mục) V-13/V-14/V-15/V-34/(Should) V-17.
   - V-22 → "Đăng xuất" → V-24.
5. **Nhóm (thành viên)**
   - V-19 → chạm nhóm → V-20 → chạm người → V-32.
   - V-20 → "Cài đặt nhóm" → V-21.
   - V-19 → "Báo cáo của tôi" → V-34.
6. **Nhóm (chủ nhóm)**
   - V-40 / V-41 → "Tạo nhóm" → V-42 → V-43.
   - V-41 → chạm nhóm → V-20 (có nút xóa) / V-43 / V-44 / V-48.
   - V-40 → chạm phiên sắp tới → V-46 (trạng thái SCHEDULED) → "Sửa / hủy" → V-45.
   - V-40 / V-16 (chạm thông báo `MEMBER_EXITED`) / V-48 (chạm phiên) → V-46 → chạm dòng rời app → V-47.
   - V-16 (chạm "‹Tên› đã gửi giải trình") → V-47 → "Xem phiên" → V-46.
   - V-48 → chạm thành viên → V-49 → chạm phiên → V-46; chạm sự kiện thoát → V-47.
   - V-05 lỗi "đang ở nhóm khác" → V-21; V-06 chưa đồng ý điều khoản mới → V-05.
   - Email V-50 → link → (đăng nhập nếu cần) → V-48.

## 4. Câu hỏi mới (đề xuất, chưa ghi sổ)

| Mã tạm | Câu hỏi | Đề xuất | Màn |
| --- | --- | --- | --- |
| VQ-01 | Thanh điều hướng cho người vừa là thành viên vừa là chủ nhóm: một trang chủ gộp hay hai trang chủ? | 3 mục chung; V-03 có khối "Nhóm tôi quản lý" | V-03, V-40 |
| VQ-02 | Màn đếm ngược có hiện danh sách người đã vào phòng chờ không? | Chỉ hiện số người ("5 người đã sẵn sàng"), không tên, không trạng thái từng người | V-07 |
| VQ-03 | Client có hiện đồng hồ đếm "giữ chỗ còn N giây" khi mất mạng? | Không: client không biết `disconnected_at` của server; chỉ hiện "Đang kết nối lại…" | V-10 |
| VQ-04 | Lối vào "Rút đồng ý và rời nhóm" từ màn phiên (AC-03.04.7, AC-01.07.2) đặt ở đâu? | Liên kết chữ nhỏ ở cuối V-08, mở V-21 trong app (không rời app) | V-08, V-21 |
| VQ-05 | DESIGN.md chưa có token cảnh báo trên nền tối: `#BA1A1A` trên `#000000` chỉ 3.25:1, không đạt 4.5:1 cho chữ | Banner trong Lockdown dùng chữ trắng, viền `#5C5C5C`; cần thêm token `lockdown-warning` nếu muốn màu | V-09, V-10, V-11 |
| VQ-06 | Nhóm đã đủ 10 thành viên: màn mời của chủ nhóm có ẩn mã không? | Vẫn hiện mã, kèm câu "Nhóm đã đủ 10 thành viên — người mới sẽ bị từ chối khi đồng ý" | V-43 |
| VQ-07 | Màn huy hiệu mới hiện ở đâu khi người dùng đang úp máy lúc `ends_at`? | Hiện sau màn kết quả, lần mở app kế tiếp; không push (Q-95, BR-91) | V-27 |
| VQ-08 | `alert_details` hiện "thời lượng ngoài app"; trường này chưa có trong BR-116 và 04 §2 mục 2 chỉ có "giờ rời và giờ quay lại" | Bỏ "thời lượng ngoài app"; chỉ hiện giờ rời (giờ server) | V-47 |
| VQ-09 | Mã mời: chia sẻ bằng nút chia sẻ hệ thống có cần câu mẫu không? | Có câu mẫu ngắn, không chứa dữ liệu thành viên | V-43 |
| Q-147 | Email báo cáo có dùng ảnh theo dõi mở thư (tracking pixel) không? | Không — ngoài phạm vi dữ liệu phiên | V-50 — **Đã chốt → D-27** (BR-122) |
| Q-148 | Chủ nhóm đang mở V-46 khi phiên ACTIVE: có tự làm mới không? | Không đẩy theo thời gian thực; chỉ kéo để làm mới | V-46 — **Đã chốt → D-28** (BR-123) |
| VQ-10 | Thông báo `MEMBER_EXITED` khi nhận lúc chưa đăng nhập (đã đăng xuất) | Không gửi: đăng xuất đã hủy token push (AC-01.02.1) | V-16, V-24 |
