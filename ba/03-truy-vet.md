# Bảng truy vết yêu cầu

Mỗi dòng nối nguồn → yêu cầu → kiểm thử. `ba-reviewer` báo lỗi khi có US/FR không có nguồn, hoặc nguồn Must không có US.

Cập nhật: T-BA-21 lần 4 (2026-10-19, ba-reviewer). Dựng lại từ mục "## Truy vết" mới nhất của 9 tệp `ba/srs/02-ep0*.md` (đã áp D-17…D-26 và `review/mockup-tong-hop.md` §3 S1–S11). MoSCoW hiện tại theo D-13, D-15, D-16, D-17, D-20, D-21, D-24, D-25; đề xuất còn Chờ: Q-140 (US-07.04, US-06.02, US-01.02, gộp US-04.06 — **không chặn cổng theo chỉ đạo người dùng**). Story Hủy: D-14 (US-02.05, US-02.07, US-04.02, US-07.02), D-16 (US-07.05), D-21 (US-02.12), D-25 (US-03.13). Won't (sau MVP): D-20 (US-04.03, US-04.04). Chưa cấp FR- và TC- → cột "Ca kiểm thử" để `—` (T-BA-45 còn mở); ca kỹ thuật tham khảo K-01…K-15 ở `srs/05-tham-chieu-ky-thuat.md` §6 ghi ở cột Ghi chú khi có.

Cột **Cờ nguồn**: `OK` = có mục GĐ1 hoặc D- trực tiếp (hoặc qua mã A- của `01-pham-vi.md` vốn đã dẫn GĐ1/D-) · `GIÁN TIẾP` = chỉ có nguồn SRS, `05-tham-chieu-ky-thuat.md`, Q- Chờ, review mockup, hoặc story tự ghi "ngoài nguồn GĐ1" · `Hủy` = story đã gộp/bỏ, không phát triển, không kiểm thử · `Won't` = có nguồn nhưng để sau MVP.

Quy ước lần 4: BR-25, BR-69 đã **Hủy** (D-25) — bảng này thay bằng BR-114 (chủ nhóm không tham gia phiên) và BR-60 (không có dòng báo cáo cho chủ nhóm). Các tệp EP đã thay BR-25/BR-69 (T-BA-125, đã sửa).

## 1. US → nguồn

| Nguồn (GĐ1 § / D-) | Epic | US | FR / BR / NFR | Tiêu chí chấp nhận (mã AC) | Ca kiểm thử | MoSCoW | Cờ nguồn | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GĐ1 §7, §8; D-07; A-01; Q-65 | EP-01 | US-01.01 | NFR-09, NFR-10, NFR-18 | AC-01.01.1–10 | — (K-14) | Must | OK | AC-01.01.7–10 quên mật khẩu (mockup S9, T-BA-93) |
| A-01 (→ GĐ1 §7) | EP-01 | US-01.02 | BR-05, BR-26, BR-70, NFR-10 | AC-01.02.1–3 | — (K-12) | Must | OK (qua A-01) | Q-140 PA-A dời sang S4 |
| GĐ1 §4.7; D-14, D-17; A-02, A-03 | EP-01 | US-01.03 | BR-97, BR-98, NFR-11, NFR-P11 | AC-01.03.1–4 | — | Must (D-17) | OK | Nhận US-07.02 (D-14) |
| D-10, D-21, D-25; A-04, A-05; 04 §3 | EP-01 | US-01.04 | BR-75, BR-114, NFR-11 | AC-01.04.1–5 | — | Must | OK | Đã sửa theo lan-4 |
| GĐ1 §6; D-02, D-05, D-08, D-14, D-20, D-21, D-22, D-25; A-08; 04 §2; Q-141 | EP-01 | US-01.05 | BR-06, BR-27, BR-33, BR-38, BR-74, BR-75, BR-76, NFR-P04, NFR-P19, NFR-P09, NFR-P18 | AC-01.05.1–11 | — | Must | OK | Nhận US-02.05 (D-14) |
| GĐ1 §6; D-13, D-20; 04 §2 | EP-01 | US-01.06 | BR-06, BR-26, BR-71, NFR-P04 | AC-01.06.1–4 | — | Should (D-13) | OK | |
| GĐ1 §6; D-05, D-14, D-23; A-09; 04 §2; Q-20, Q-60, Q-141 | EP-01 | US-01.07 | BR-26, BR-32, BR-36, BR-37, BR-48, BR-59, BR-74, BR-76 | AC-01.07.1–7 | — | Must | OK | Nhận US-02.07 (D-14) |
| GĐ1 §5, §6; D-22; A-31; 04 §3, §5 | EP-01 | US-01.08 | BR-38, NFR-P03, NFR-P06, NFR-P11, NFR-P18, NFR-11 | AC-01.08.1–5 | — | Must | OK | |
| GĐ1 §5, §6; D-22; A-31; 04 §5 | EP-01 | US-01.09 | NFR-P12, NFR-P18 | AC-01.09.1–4 | — | Should | OK | |
| GĐ1 §6; D-10, D-21, D-25; A-31; 04 §4, §5; Q-25, Q-34, Q-69 | EP-01 | US-01.10 | NFR-P13, BR-26, BR-44, BR-62, BR-70, BR-72, BR-80 | AC-01.10.1–5 | — | Should | OK | |
| GĐ1 §5; A-32; Q-21, Q-22 | EP-01 | US-01.11 | NFR-P07, BR-73 | AC-01.11.1–4 | — | Should | OK | |
| GĐ1 §4.1; D-02, D-10, D-21, D-25; A-04, A-06; Q-71, Q-141 | EP-02 | US-02.01 | BR-74, BR-75, BR-114, NFR-P09, NFR-11 | AC-02.01.1–6 | — | Must | OK | Đã sửa theo lan-4 |
| GĐ1 §6; D-10, D-13, D-20; A-05; 04 §2 | EP-02 | US-02.02 | BR-06, BR-71, NFR-P04, NFR-P09, NFR-11 | AC-02.02.1–5 | — | Should (D-13) | OK | |
| GĐ1 §4.1; D-02, D-21; A-07; Q-141 | EP-02 | US-02.03 | BR-74, BR-75, BR-76, BR-80, NFR-11 | AC-02.03.1–7 | — | Must | OK | |
| GĐ1 §4.1; D-02, D-13, D-21; A-07 | EP-02 | US-02.04 | BR-65, BR-74, BR-75, BR-76, NFR-11 | AC-02.04.1–8 | — | Should (D-13) | OK | |
| D-14 | EP-02 | US-02.05 | — | AC-02.05.x → AC-01.05.x | — | — | Hủy — gộp vào US-01.05 (D-14) | |
| D-03, D-10, D-12, D-21, D-25; A-03; 04 §3; Q-145 | EP-02 | US-02.06 | BR-99, BR-115, BR-117, NFR-P06, NFR-11 | AC-02.06.1–7 | — | Must | OK | AC-02.06.6, .7 (mockup S4, S5) |
| D-14 | EP-02 | US-02.07 | — | AC-02.07.x → AC-01.07.x | — | — | Hủy — gộp vào US-01.07 (D-14) | |
| GĐ1 §4.1; D-10; A-07 | EP-02 | US-02.08 | BR-32, BR-59, BR-74, BR-77, NFR-11 | AC-02.08.1–6 | — | Must | OK | |
| D-10, D-13; A-05, A-09; Q-34, Q-44, Q-77 | EP-02 | US-02.09 | BR-29, BR-62, BR-80; §Trạng thái nhóm | AC-02.09.1–7 | — | Should (D-13) | OK | |
| GĐ1 §4.1; D-06, D-13, D-17; A-10 | EP-02 | US-02.10 | BR-01, BR-02, BR-03, BR-04, BR-74, BR-78, BR-79, BR-80, BR-108, NFR-21 | AC-02.10.1–8 | — | Must | OK | Chỉ lịch một lần; ước M (D-17) |
| GĐ1 §4.1 (khung giờ chung, gián tiếp); D-06, D-13; Q-78 | EP-02 | US-02.10b | BR-02, BR-29, BR-78, BR-79, BR-113 | AC-02.10b.1–5 | — | Should | GIÁN TIẾP | Story tự ghi "ngoài nguồn GĐ1 trực tiếp" |
| D-06, D-21; A-10 | EP-02 | US-02.11 | BR-02, BR-04, BR-29, BR-33, BR-65, BR-78, BR-79 | AC-02.11.1–5 | — | Must | OK | |
| D-21 | EP-02 | US-02.12 | — | AC-02.12.1–5 (không dùng lại) | — | — | Hủy — D-21 | Q-81 Hủy |
| GĐ1 §6; D-10; Q-63, Q-105 | EP-02 | US-02.13 | BR-65, BR-80, BR-109, NFR-11 | AC-02.13.1–5 | — | Should | OK | Đầu vào US-09.06 |
| GĐ1 §4.1; D-06; Q-80 | EP-02 | US-02.14 | BR-04, BR-63, BR-79 | AC-02.14.1–4 | — | Should | OK | |
| GĐ1 §4.1, §4.2; D-06, D-25 | EP-03 | US-03.01 | BR-01, BR-02, BR-06, BR-09, BR-29, BR-63, BR-114; NFR-P04 | AC-03.01.1–5 | — | Must | OK | Đã sửa theo lan-4 |
| GĐ1 §4.2; `05-tham-chieu-ky-thuat.md` §1.5, §2 | EP-03 | US-03.02 | BR-03, BR-04, BR-05, BR-07, BR-22, BR-33, BR-64 | AC-03.02.1–7 | — | Must | OK | AC-03.02.7 Lỗi trong phạm vi Must (T-BA-73) |
| GĐ1 §4.2, §6; D-08 | EP-03 | US-03.03 | BR-05, BR-15, BR-34, BR-66, BR-116; NFR-08, NFR-P02, NFR-P08 | AC-03.03.1–5 | — (K-06, K-13) | Must | OK | Đã sửa theo lan-4 |
| GĐ1 §4.2, §10 #1; D-05, D-07, D-08, D-29; Q-61, Q-149 | EP-03 | US-03.04 | BR-11, BR-13, BR-14, BR-15, BR-26, BR-31, BR-34, BR-118; NFR-03, NFR-04, NFR-P01, NFR-P15, NFR-19 | AC-03.04.1–10 | — (K-02…K-06) | Must | OK | Đã sửa theo lan-4 |
| GĐ1 §4.3; `05-tham-chieu-ky-thuat.md` §1; D-05 | EP-03 | US-03.05 | BR-11…BR-14, BR-32, BR-33, BR-35, BR-65; NFR-03 | AC-03.05.1–7 | — (K-03…K-05) | Must | OK | |
| GĐ1 §6; D-13; Q-11, Q-15, Q-26 | EP-03 | US-03.06 | BR-16, BR-17, BR-18, BR-36, BR-67 | AC-03.06.1–7 | — | Should (D-13) | OK | |
| GĐ1 §10 #3; D-05, D-08, D-19; `05-tham-chieu-ky-thuat.md` §5; Q-30, Q-31 | EP-03 | US-03.07 | BR-19, BR-20, BR-21, BR-24, BR-32, BR-36, BR-48, BR-65, BR-66; NFR-23 | AC-03.07.1–10 | — (K-07, K-08) | Must | OK | NFR-23 thay NFR-15a (Hủy) |
| D-05, D-19; GĐ1 §4.3 | EP-03 | US-03.08 | BR-14, BR-21, BR-27, BR-35, BR-36, BR-37, BR-39, BR-118 | AC-03.08.1–9 | — (K-09) | Must | OK | AC-03.08.9 rời chủ động (mockup S9) |
| D-05, D-14, D-20, D-22; GĐ1 §4.3, §6; Q-87, Q-136, Q-137 | EP-03 | US-03.09 | BR-12, BR-21, BR-26, BR-27, BR-28, BR-34, BR-36, BR-38, BR-39, BR-41, BR-47, BR-53, BR-81, BR-82; NFR-02, NFR-P03, NFR-P06, NFR-P18 | AC-03.09.1–10, .12 (.11 → AC-03.12.6) | — (K-02) | Must (ước M) | OK | Nhận US-04.02 (D-14); trùng phạm vi US-04.01 — T-BA-69 (Q-140 PA-C) |
| GĐ1 §4.5; D-05, D-09, D-11, D-19, D-22, D-25 | EP-03 | US-03.10 | BR-05, BR-08, BR-23, BR-24, BR-30, BR-32, BR-33, BR-36, BR-37, BR-38, BR-41, BR-46, BR-47, BR-112 | AC-03.10.1–8 | — (K-01) | Must | OK | AC-03.10.7–8 ABSENT trong Must (T-BA-70; BR-08 đã sửa) |
| GĐ1 §4.1; D-05, D-06, D-13; Q-18, Q-41 | EP-03 | US-03.11 | BR-04, BR-07, BR-08, BR-09, BR-30, BR-37, BR-65 | AC-03.11.1–5 | — | Should (D-13) | OK | |
| GĐ1 §10 #3; D-05, D-13, D-19; `05-tham-chieu-ky-thuat.md` §5; Q-28, Q-123 | EP-03 | US-03.12 | BR-22, BR-32, BR-35, BR-68; NFR-15 | AC-03.12.1–6 | — (K-11) | Should (D-13) | OK | |
| D-25 | EP-03 | US-03.13 | — | AC-03.13.1–5 (không dùng lại) | — | — | Hủy — D-25 (chủ nhóm không tham gia phiên) | Thay bằng AC-03.01.3, AC-03.09.1/.10, BR-114 |
| GĐ1 §4.5, §6; D-05, D-11, D-12, D-19, D-21, D-22; mockup S10 (T-BA-102); Q-101 | EP-03 | US-03.14 | BR-21, BR-22, BR-23, BR-24, BR-32, BR-34, BR-38, BR-41, BR-53, BR-103, BR-119; NFR-P03, NFR-P06, NFR-P11, NFR-P18, NFR-11 | AC-03.14.1–8 | — | Should (giả định) | OK | Mới 2026-10-19 |
| GĐ1 §4.3, §11; D-05, D-10, D-19, D-20, D-22, D-25; Q-141 | EP-04 | US-04.01 | BR-12, BR-14, BR-19, BR-27, BR-28, BR-34, BR-35, BR-36, BR-38, BR-39, BR-74, BR-81, BR-82, BR-114; NFR-01, NFR-02, NFR-11, NFR-P18 | AC-04.01.1–11 | — (K-02) | Must | OK | Đã sửa theo lan-4 |
| D-05, D-14; GĐ1 §6 | EP-04 | US-04.02 | — | AC-04.02.x → AC-03.09.x | — | — | Hủy — gộp vào US-03.09 (D-14) | |
| GĐ1 §4.3; D-20 | EP-04 | US-04.03 | BR-27; NFR-11 (BR-83 Hủy) | AC-04.03.1–5 (tham khảo) | — | Won't (D-20) | Won't | Sau MVP |
| GĐ1 §4.3; D-20 | EP-04 | US-04.04 | BR-23, BR-34, BR-35, BR-53 (BR-84 Hủy) | AC-04.04.1–8 (tham khảo) | — | Won't (D-20) | Won't | Sau MVP |
| GĐ1 §10 #3; Q-16 | EP-04 | US-04.05 | BR-32, BR-54, BR-65, BR-85; NFR-P10, NFR-P13, NFR-P18 | AC-04.05.1–8 | — | Must | OK | |
| GĐ1 §10 #3; Q-16; T-BA-105 | EP-04 | US-04.06 | BR-61, BR-85; NFR-P07, NFR-P10, NFR-P18 | AC-04.06.1–6 | — | Must | OK | Q-140 PA-A đề xuất gộp vào US-08.10 |
| GĐ1 §10 #3; D-05, D-25; NFR-P14; Q-37; R-P02 | EP-04 | US-04.07 | BR-32, BR-35, BR-65, BR-68, BR-86; máy trạng thái KHIẾU NẠI | AC-04.07.1–8 | — | Should | OK | AC-04.07.5 viết lại theo D-25 (S1, T-BA-108) |
| GĐ1 §10 #3; D-05, D-22; NFR-P14; Q-37, Q-138 | EP-04 | US-04.08 | BR-27, BR-32, BR-35, BR-43, BR-44, BR-86, BR-87, BR-88, BR-110; máy trạng thái KHIẾU NẠI | AC-04.08.1–9 | — | Should | OK | |
| GĐ1 §6; D-13, D-19, D-22 | EP-04 | US-04.09 | BR-22, BR-29, BR-48, BR-68, BR-81; NFR-15, NFR-P18 | AC-04.09.1–7 | — | Should (D-13) | OK | |
| GĐ1 §4.4; D-05, D-11, D-21 | EP-05 | US-05.01 | BR-22, BR-23, BR-31, BR-35, BR-46, BR-68; NFR-21 | AC-05.01.1–7 | — | Must | OK | |
| GĐ1 §4.4; D-12, D-13, D-21 | EP-05 | US-05.02 | BR-46, BR-53; A-21, NFR-P03, NFR-P11, NFR-11, NFR-20, NFR-21 | AC-05.02.1–6 | — | Should (D-13) | OK | |
| GĐ1 §4.3, §4.4; D-05, D-11, D-12, D-19, D-21, D-23 | EP-05 | US-05.03 | BR-22, BR-26, BR-33, BR-36, BR-37, BR-47…BR-51, BR-54, BR-68, BR-87, BR-88, BR-108; NFR-21 | AC-05.03.1–15 | — | Must | OK | |
| GĐ1 §4.4; D-03, D-12 | EP-05 | US-05.04 | BR-49, BR-51, BR-52, BR-53; A-21, NFR-P03, NFR-P06 | AC-05.04.1–5 | — | Must | OK | |
| GĐ1 §4.4; D-01, D-05, D-11 | EP-05 | US-05.05 | BR-23, BR-31, BR-47, BR-51, BR-52, BR-89, BR-90 | AC-05.05.1–8 | — | Must | OK | |
| GĐ1 §4.4, §4.7, §6; D-03, D-12, D-13, D-16, D-22 | EP-05 | US-05.06 | BR-47, BR-51, BR-52, BR-99; A-03, A-21, NFR-P06, NFR-P17, NFR-P18 | AC-05.06.1–11 | — | Should (D-13, D-16) | OK | Nhận US-07.05 (D-16); AC-05.06.10, .11 kiểm NFR-P17 (T-BA-68 đã sửa) |
| GĐ1 §4.3, §9; D-05, D-13, D-19, D-22, D-23, D-25 | EP-05 | US-05.07 | BR-22, BR-36, BR-37, BR-38, BR-47, BR-48, BR-68, BR-81, BR-82, BR-91; NFR-P18, NFR-02, A-16 | AC-05.07.1–10 (.4 Hủy, D-25) | — | Should (D-13) | OK | Đã sửa theo lan-4 |
| GĐ1 §4.4; D-12, D-13, D-22 | EP-05 | US-05.08 | BR-38, BR-46, BR-47, BR-49, BR-50, BR-52, BR-53, BR-68, BR-92; NFR-P03, NFR-P11, NFR-P12, NFR-P18, NFR-11 | AC-05.08.1–6 | — | Should (D-13) | OK | |
| GĐ1 §4.4, §6; D-10, D-12, D-13, D-21; 01 A-21; Q-146 | EP-05 | US-05.09 | BR-28, BR-46, BR-53, BR-57, BR-59, BR-73, BR-99, BR-115, BR-116; NFR-P02, NFR-P03, NFR-P19, NFR-P06, NFR-P07, NFR-11 | AC-05.09.1–9 | — | Should (D-13) | OK | Lối vào phụ; lối vào chính là US-08.10 (04 §3, Q-146) |
| GĐ1 §4.5; D-05, D-09, D-11, D-19, D-21, D-22, D-25 | EP-06 | US-06.01 | BR-21, BR-22, BR-23, BR-24, BR-36, BR-37, BR-38, BR-40…BR-45, BR-68, BR-87, BR-88, BR-111 | AC-06.01.1–13 | — (K-01, K-02) | Must | OK | |
| GĐ1 §4.5; D-09, D-12, D-17, D-20; 04 §3 | EP-06 | US-06.02 | BR-43, BR-44, BR-53, BR-61 | AC-06.02.1–7 | — | Must (D-17) — **Should nếu Q-140 PA-A** | OK | |
| GĐ1 §4.6, §7; D-01, D-03, D-09; T-BA-112 | EP-06 | US-06.03 | BR-93, BR-94, BR-96, BR-121 | AC-06.03.1–8 | — | Must | OK | AC-06.03.8 cấm ngẫu nhiên (S6) |
| GĐ1 §4.6; D-03 | EP-06 | US-06.04 | BR-44, BR-45, BR-93, BR-94, BR-96 | AC-06.04.1–9 | — | Must | OK | |
| GĐ1 §4.6, §4.7; 04 §3; D-21 | EP-06 | US-06.05 | BR-93, BR-95, BR-96, BR-99 | AC-06.05.1–8 | — | Must | OK | |
| GĐ1 §4.6; Q-38 | EP-06 | US-06.06 | BR-44, BR-45, BR-52, BR-93 | AC-06.06.1–4 | — | Could | OK | |
| GĐ1 §4.7; A-02 | EP-07 | US-07.01 | BR-51, BR-52, BR-53, BR-95; NFR-P03 | AC-07.01.1–5 | — | Must | OK | |
| D-14 | EP-07 | US-07.02 | BR-97 | AC-07.02.x (không dùng) | — | — | Hủy — gộp vào US-01.03 (D-14) | |
| GĐ1 §4.7; D-13 | EP-07 | US-07.03 | BR-98; NFR-P01, NFR-09, NFR-12 | AC-07.03.1–6 | — | Should (D-13) | OK | |
| GĐ1 §4.6, §4.7; D-17; A-02 | EP-07 | US-07.04 | BR-95, BR-96 | AC-07.04.1–4 | — | Must (D-17) — **Should nếu Q-140 PA-A** | OK | |
| GĐ1 §4.4, §6; D-12, D-16 | EP-07 | US-07.05 | — | AC-07.05.1–5 → AC-05.06.5–9 | — | — | Hủy — gộp vào US-05.06 (D-16) | |
| GĐ1 §4.7, §6; D-10, D-12, D-13, D-22; Q-137 | EP-07 | US-07.06 | BR-26, BR-53, BR-73, BR-99; NFR-P05, NFR-P06, NFR-P17, NFR-11 | AC-07.06.1–5 | — | Should (D-13) | OK | |
| GĐ1 §4.7, §6, §7; D-15; Q-06 | EP-07 | US-07.07 | BR-100; NFR-P05, NFR-12, NFR-21 | AC-07.07.1–6 | — | Must (D-15) | OK | Q-06 (chỉ riêng tư) là giả định có nhãn |
| GĐ1 §4.7; D-15 | EP-07 | US-07.08 | BR-100; NFR-P05, NFR-P11, NFR-P12 | AC-07.08.1–5 | — | Should (D-15) | OK | AC-07.08.5 ngoài nguồn, đã gắn nhãn |
| GĐ1 §6; D-15 | EP-07 | US-07.09 | BR-72, BR-100; NFR-P13; 04 §4 | AC-07.09.1–5 | — | Should (D-15) | OK | |
| GĐ1 §6, §7; D-15; Q-06 | EP-07 | US-07.10 | BR-100; NFR-P05, NFR-11, NFR-12; R-P04, R-P10 | AC-07.10.1–7 | — | Must (D-15) | OK | |
| GĐ1 §4.8, §8, §11; D-05, D-11, D-12, D-25 | EP-08 | US-08.01 | BR-35, BR-37, BR-46, BR-55…BR-60, BR-62, BR-101, BR-102, BR-114; NFR-17 | AC-08.01.1–11 | — | Must | OK | lịch tự động: cron EC2 (Must) theo 04 — T-BA-78 |
| GĐ1 §4.8; D-03, D-10, D-12, D-21, D-22, D-25; Q-141 | EP-08 | US-08.02 | BR-34, BR-53, BR-57, BR-59, BR-60, BR-61, BR-73, BR-102, BR-103, BR-115; NFR-P07, NFR-P10 | AC-08.02.1–12 | — | Must | OK | AC-08.02.4 đã gắn nhãn US-01.11 (T-BA-58 đã sửa); AC-08.02.11, .12 thứ tự theo tên (S4) |
| GĐ1 §6; D-12, D-21, D-22; 04 §3 | EP-08 | US-08.03 | BR-57, BR-59, BR-61, BR-103; §2; NFR-P07, NFR-P10 | AC-08.03.1–5 | — | Must | OK | |
| GĐ1 §4.8, §6; D-03, D-22; 04 §3; R-P06 | EP-08 | US-08.04 | BR-57, BR-104 | AC-08.04.1–5 | — | Should | OK | |
| GĐ1 §4.8; D-03, D-11 | EP-08 | US-08.05 | §3 So với tháng trước; BR-56, BR-115 | AC-08.05.1–5 | — | Should | OK | |
| GĐ1 §4.8; 01 A-30; D-13, D-24 | EP-08 | US-08.06 | BR-57, BR-61, BR-73, BR-102, BR-105; NFR-P07; 04 §4 | AC-08.06.1–7 | — | Should (D-13, D-24) | OK | |
| GĐ1 §11; 01 G-02; D-21, D-24 | EP-08 | US-08.07 | BR-53, BR-56, BR-57, BR-62, BR-105; NFR-17 | AC-08.07.1–7 | — | Must (D-24) | OK | Email tóm tắt, không PDF |
| GĐ1 §6; R-P03 | EP-08 | US-08.08 | BR-61, BR-71; NFR-P09 | AC-08.08.1–3 | — | Must | OK | |
| GĐ1 §4.8; D-13 | EP-08 | US-08.09 | BR-56, BR-58, BR-105; §3 | AC-08.09.1–4 | — | Should (D-13) | OK | |
| GĐ1 §4.3, §6, §10 #3; D-03, D-10, D-12, D-19, D-22, D-25; mockup S2, S3 (T-BA-105); Q-144, Q-146 | EP-08 | US-08.10 | BR-23, BR-27, BR-28, BR-29, BR-32, BR-34, BR-35, BR-38, BR-39, BR-53, BR-61, BR-73, BR-85, BR-87, BR-115, BR-116; NFR-P02, NFR-P19, NFR-P06, NFR-P07, NFR-P10, NFR-P18, NFR-11 | AC-08.10.1–11 | — | Must (ước S, giả định) | OK | Mới 2026-10-19; lối vào chính cho dữ liệu phiên của CN (04 §3) |
| D-10; 04 §Cognito | EP-09 | US-09.01 | NFR-11 | AC-09.01.1–3 | — | Should | OK | |
| GĐ1 §3; A-33 | EP-09 | US-09.02 | BR-09, BR-19, BR-80, BR-108, BR-114; máy trạng thái NHÓM; NFR-P07 | AC-09.02.1–8 | — | Should | OK | Đã sửa theo lan-4 |
| GĐ1 §4.6; D-09 | EP-09 | US-09.03 | BR-44, BR-93, BR-94, BR-96, BR-106, BR-121 | AC-09.03.1–7 | — | Should | OK | |
| D-09 | EP-09 | US-09.04 | BR-44, BR-45, BR-53, BR-107; NFR-P07 | AC-09.04.1–8 | — | Should | OK | |
| GĐ1 §3, §6, §10 #3; NFR-P14; A-17, A-20 | EP-09 | US-09.05 | BR-34, BR-35, BR-37, BR-44, BR-54, BR-73, BR-86, BR-87, BR-88, BR-110; máy trạng thái KHIẾU NẠI; NFR-P05, NFR-P07 | AC-09.05.1–8 | — | Should | OK | |
| GĐ1 §6; D-10; R-P09 | EP-09 | US-09.06 | BR-62, BR-65, BR-80, BR-109; máy trạng thái NHÓM; NFR-P07 | AC-09.06.1–6 | — | Should | OK | Đầu vào phía thành viên: US-02.13 |
| GĐ1 §5, §6; NFR-P07; R-P05 | EP-09 | US-09.07 | BR-73; NFR-11 | AC-09.07.1–5 | — | Should | OK | |
| D-09, D-24; 01 EP-09; 03 bảng thông số | EP-09 | US-09.08 | BR-02, BR-04, BR-11, BR-19, BR-74, BR-76, BR-111, BR-112 | AC-09.08.1–8 | — | Could | OK | MVP seed (T-05, C-09) |

**Tổng: 92 US** — Must **44** (gồm US-07.04, US-06.02 đang chờ Q-140) · Should **37** · Could **2** · Won't **2** (US-04.03, US-04.04) · Hủy **7** (US-02.05, 02.07, 02.12, 03.13, 04.02, 07.02, 07.05).
Khớp `backlog.md` §2 (44 US + 6 T = 86 điểm Must — vượt D-17 83 điểm, chờ Q-140; Should 37 US / 62 điểm; Could 2; Won't 2; Hủy 7).
Cờ GIÁN TIẾP: **1** (US-02.10b, Should). US không có nguồn: **0**. FR-: chưa cấp. TC-: chưa cấp.

### 1b. Hạng mục kỹ thuật → nguồn

| Mã | Nguồn | NFR / BR | MoSCoW | Ghi chú |
| --- | --- | --- | --- | --- |
| T-01 | GĐ1 §10 #1; D-07, D-08, D-26; 01 C-03, C-04 | NFR-03, NFR-04, NFR-19, NFR-P15; BR-11, BR-15, BR-66 | Must | iOS phụ thuộc T-06 và ≥1 iPhone thật (giả định, Q-142 — không chặn cổng theo chỉ đạo) |
| T-02 | GĐ1 §8; D-04; 01 C-02, C-05; 04 Ánh xạ AWS | NFR-09, NFR-12, NFR-13, NFR-14, NFR-22 | Must | Backlog còn ghi ALB, ElastiCache (Should) — T-BA-78 |
| T-03 | Quy trình §12; D-07, D-26 | — | Must | Backend + Android |
| T-04 | Quy trình §11 #4; EP-03 | BR-31, BR-118 | Must | Đã sửa theo lan-4 |
| T-05 | 01 §4 EP-09; D-09; C-09 | BR-111, BR-112 | Must | |
| T-06 | D-07, D-18, D-26; 01 C-03, C-10 | NFR-24, NFR-13 | Must | Mới (D-26) |

### 1c. BR / NFR mới (2026-10-19) → US

| Mã | Nội dung tóm tắt | US / hạng mục phủ | Nguồn | Ghi chú |
| --- | --- | --- | --- | --- |
| BR-115 | Thứ tự danh sách người theo tên, không xếp hạng ngầm | US-02.06 (AC-02.06.7), US-08.02 (AC-08.02.11, .12), US-08.05 (AC-08.05.4), US-08.10 (AC-08.10.2), US-05.09 | D-03; Q-143 (đề xuất) | Đã sửa theo lan-4 |
| BR-116 | Chi tiết phiên của CN chỉ đọc, không thời gian thực | US-08.10 (AC-08.10.4, .5), US-05.09; ghi chú US-03.03 | D-20, D-25; Q-144 (đề xuất) | |
| BR-117 | Chỉ số từng nhóm ở danh sách nhóm của CN, không cộng gộp | US-02.06 (AC-02.06.6) | D-03; Q-145 (đề xuất) | Đã sửa theo lan-4 |
| BR-118 | Rời phiên chủ động: ACTIVE/GRACE/PAUSED → EXITED; WAITING → ABSENT; mất kết nối → không gửi, không xếp hàng | US-03.04 (AC-03.04.6–10), US-03.08 (AC-03.08.9) | GĐ1 §4.3; D-05, D-20, D-29; Q-149 | Đã sửa theo lan-4 |
| BR-119 | Lịch sử phiên của tôi | US-03.14 | D-22; GĐ1 §6 | |
| BR-120 | Ràng buộc riêng tư cho EP-10 | — (EP-10 Won't ở MVP; ràng buộc ghi sẵn, 04 §3) | GĐ1 §6; Q-05 | Không cần US ở MVP |
| BR-121 | Shop không có cơ chế ngẫu nhiên | US-06.03 (AC-06.03.8), US-09.03 | D-01 | |
| BR-122 | Email không ảnh/link theo dõi | US-08.07 (AC-08.07.8) | D-27 | T-BA-136 |
| BR-123 | Chi tiết phiên của CN không tự làm mới, chỉ kéo để làm mới | US-08.10 (AC-08.10.12) | D-28 | T-BA-136 |
| NFR-23 | Mất mạng → LOST, không mất thưởng tập thể (thay NFR-15a) | US-03.07 (AC-03.07.3, .10), US-03.08 (AC-03.08.8) | D-19 | K-08 |
| NFR-24 | Build iOS không cần Mac (GitHub Actions macOS) | T-06, T-01 | D-26 | |
| NFR-P18 | Tên người thoát cho CN, cả nhóm, cả phiên; LOST không nêu tên | US-01.05, 01.08, 01.09, 03.09, 03.14, 04.01, 04.05, 04.06, 04.09, 05.06–05.08, 08.10 | D-22, D-20, D-19, D-25 | Thay NFR-P16 (Hủy) |

Mục Hủy hiện tại (không truy vết tiếp): BR-10, BR-25, BR-69, BR-83, BR-84 · NFR-P16, NFR-15a · A-14 (01 §3) · tham số `notify_mode`, `batch_send_within_s`, `report_link_email_days`.

## 2. Mục Must (GĐ1 §7 MVP + §11 + `01-pham-vi.md` §5 Must) → US Must

| Mục Must | Nguồn | US Must phủ | Trạng thái |
| --- | --- | --- | --- |
| Đăng nhập và vai trò (CN/TV theo nhóm, QT) | GĐ1 §7; D-10 | US-01.01, US-01.02, US-01.04 | Có US |
| Màn đồng ý minh bạch, rút đồng ý, "Dữ liệu của tôi" | 01 §5 EP-01; GĐ1 §6 | US-01.05, US-01.07, US-01.08 | Có US |
| Sửa hồ sơ cơ bản | 01 §5 EP-01; D-17 | US-01.03 | Có US |
| Tạo nhóm 4–10 thành viên (không gồm CN — giả định Q-141), TV tối đa 1 nhóm, CN quản lý nhiều nhóm, khai mục đích | GĐ1 §7; D-02, D-10, D-21, D-25 | US-02.01 | Có US |
| Mời thành viên | GĐ1 §4.1, §7 | US-02.03 (mã); email là Should (US-02.04) | Có US |
| Xem nhóm, xóa thành viên | 01 §5 EP-02 | US-02.06, US-02.08 | Có US |
| CN đặt lịch phiên 25/50' (một lần), sửa/hủy | GĐ1 §4.1; D-06 | US-02.10, US-02.11 | Có US |
| Phiên + Lockdown (đếm ngược 5s, giao diện tối, chỉ báo ghi) | GĐ1 §4.2, §7 | US-03.01, US-03.02, US-03.03 | Có US |
| Phát hiện thoát app iOS + Android, khóa màn hình không tính | GĐ1 §7; D-07, D-08, D-26 | US-03.04 (+ T-01, T-06) | Có US |
| Khoan hồng 3s | GĐ1 §4.2, §7 | US-03.05 | Có US |
| Phiên tiếp tục khi có người thoát, mất thưởng tập thể, báo có tên người thoát | D-05, D-22 | US-03.08, US-03.09, US-03.10 | Có US |
| Mất kết nối ghi riêng, không phạt cả phiên | 01 §5 EP-03; D-19 | US-03.07 | Có US |
| Thông báo ngay cho cả nhóm và mọi người trong phiên | GĐ1 §7, §11; D-20, D-22 | US-04.01 (+ US-03.09 kênh trong phiên) | Có US (trùng phạm vi — T-BA-69) |
| Giải trình sau phiên | 01 §5 EP-04; GĐ1 §10 #3 | US-04.05, US-04.06 | Có US |
| Điểm danh, chuỗi, huy hiệu mốc | GĐ1 §4.4, §7 | US-05.01, US-05.03, US-05.04, US-05.05 | Có US |
| Coins (25'=10, 50'=25, trần 100) + mất thưởng tập thể; xem số dư/lịch sử | GĐ1 §4.5; D-05, D-09, D-11, D-17 | US-06.01, US-06.02 | Có US (US-06.02 có thể sang Should theo Q-140 — mục "xem số dư" khi đó chỉ còn ở US-01.08) |
| Shop cơ bản (khung, hình nền), mua, trang bị | GĐ1 §4.6, §7 | US-06.03, US-06.04, US-06.05 | Có US |
| Hồ sơ (xem; hiển thị khung, hình nền) | GĐ1 §4.7, §7; D-17 | US-07.01, US-07.04 | Có US (US-07.04 có thể sang Should theo Q-140 — mục vẫn được US-07.01 phủ) |
| Nhật ký riêng tư đơn giản | GĐ1 §4.7, §7; D-15 | US-07.07, US-07.10 | Có US |
| Báo cáo tháng cơ bản (tự động, chỉ số TV/nhóm, mục đích) | GĐ1 §4.8, §7 | US-08.01, US-08.02, US-08.03, US-08.08 | Có US |
| Gửi email tóm tắt báo cáo cho CN (không PDF) | GĐ1 §11; D-24 | US-08.07 | Có US |
| CN xem chi tiết phiên đã kết thúc, chỉ đọc (lối vào dữ liệu phiên của CN) | 01 §5 EP-08; GĐ1 §6; D-25; BR-116 | US-08.10 | Có US (mới) |
| Demo 1 CN quản lý ≥2 nhóm | GĐ1 §11; D-25 | US-02.01 (AC-02.01.4, .6), US-08.02 (AC-08.02.1, .10), US-04.01 (AC-04.01.9) | Có US — D-25 đã chốt (không còn phụ thuộc Q-135) |

**MỒ CÔI (Must không có US Must): không có.**

Mục GĐ1 không còn Must (ghi để theo dõi, không phải mồ côi): tạm dừng có lý do (GĐ1 §6 → US-03.06 Should, D-13); xuất PDF (GĐ1 §4.8 → US-08.06 Should, D-24); so với tháng trước (GĐ1 §4.8 → US-08.05 Should); tùy chọn gộp báo cuối phiên (GĐ1 §4.3 → US-04.03, US-04.04 Won't, D-20).

Mục ngoài Must không có US:

| Mục | Nguồn | MoSCoW | Trạng thái |
| --- | --- | --- | --- |
| Phiên tự do cá nhân (A-11) | 01 §5 Should; Q-02 B | Should | MỒ CÔI (Should) — T-BA-44 còn mở |
| Huy hiệu nhóm khi 100% hoàn thành; chuyển giao chủ nhóm; khoan hồng theo thời lượng; xuất Excel; huy hiệu bán trong Shop; chia sẻ nhật ký | 01 §5 Could | Could | Chưa có US (chấp nhận được) |

Thay đổi so với lần 3: US-03.13 Should → **Hủy** (D-25); thêm US-03.14 (Should, giả định) và US-08.10 (Must); BR-25, BR-69 Hủy → thay BR-114/BR-60; thêm BR-115…BR-121, NFR-23 (thay NFR-15a), NFR-24, NFR-P18 (thay NFR-P16); thêm bảng 1b (T-01…T-06) và 1c; cập nhật dải AC US-01.01 (1–10), US-02.06 (1–7), US-03.02 (1–7), US-03.04 (1–7), US-03.08 (1–9), US-03.10 (1–8), US-05.06 (1–11), US-06.03 (1–8), US-08.02 (1–12); tổng 92 US / 44 Must / 86 điểm.

Cập nhật 2026-10-19 (sau sửa lần 4): US-03.04 dải AC 1–10, thêm D-29, Q-149; BR-118 nối AC-03.04.6–10; gỡ ghi chú lỗi T-BA-123…131 đã sửa; AC-02.06.7, AC-08.02.11 khớp tie-break BR-115. Chưa có review lần 5 xác nhận.
