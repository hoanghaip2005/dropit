# Spike T-01 — Phát hiện rời app / khóa màn hình (DropIt!)

Hạng mục backlog: **T-01** (phần iOS phụ thuộc **T-06**, D-26). Nguồn: `ba/srs/05-tham-chieu-ky-thuat.md` §1, §2, §5, §6; BR-11…15, BR-19, BR-31, BR-34, BR-64, BR-65, BR-66; NFR-03, NFR-04, NFR-08, NFR-19, NFR-24, NFR-P01, NFR-P15; D-07, D-08, D-26.

Đây là **mã thử nghiệm**, không phải app thật. Không có đăng nhập, nhóm, Coins.

## 1. Mục tiêu

Đo trên **máy thật** (≥ 2 Android khác hãng + ≥ 1 iPhone, NFR-19):

1. Bắt được rời app (chuyển app, kéo thông báo, về Home, vuốt tắt app) đủ nhanh (NFR-03: client gửi ≤ 1 s).
2. **Phân biệt khóa màn hình với rời app** trên iOS và Android (BR-15, D-08, NFR-P15).
3. Khoan hồng 3 s: quay lại < 3 s không tính; ≥ 3 s → EXITED (BR-11…14, BR-65).
4. Heartbeat 5 s khi màn hình tắt; không sinh DISCONNECTED giả (BR-19, BR-66).
5. Độ trễ client → server và server → client khác (`MEMBER_EXITED`).

**Quyền riêng tư (ràng buộc cứng, BR-34, NFR-P01):** chỉ ghi sự kiện vòng đời của chính app + thời điểm. Không đọc app khác, không `UsageStatsManager`, không quyền Usage Access, không cảm biến (không phát hiện úp máy). Manifest Android chỉ có `INTERNET`. Native chỉ lắng nghe khi bấm **Bắt đầu** (NFR-P02).

## 2. Cấu trúc

| Đường dẫn | Nội dung |
| --- | --- |
| `lib/main.dart` | Màn hình phiên tối, tĩnh: URL server, tên máy, nút Bắt đầu/Kết thúc, nút Đánh dấu ca, Xuất log (JSON qua share sheet), bảng log có timestamp |
| `lib/session_controller.dart` | `AppLifecycleListener` + EventChannel native, **bộ phân loại LOCK/LEAVE**, heartbeat 5 s, socket.io, đồng bộ giờ (ping) |
| `android/.../MainActivity.kt` | `ACTION_SCREEN_OFF/ON`, `ACTION_USER_PRESENT` (đăng ký động), `ProcessLifecycleOwner` ON_START/ON_STOP kèm `PowerManager.isInteractive` + `KeyguardManager.isKeyguardLocked` |
| `ios/Runner/AppDelegate.swift` | `LifecyclePlugin`: `protectedDataWillBecomeUnavailable/DidBecomeAvailable`, `UIScene.willDeactivate/didEnterBackground/willEnterForeground/didActivate`, `willTerminate`, kèm `isProtectedDataAvailable` |
| `server/server.js` | Node + socket.io: gắn giờ server, máy trạng thái BR, ghi JSONL `server/logs/` |
| `server/selftest.js` | Tự kiểm với 3 client giả |
| `.github/workflows/build.yml` | CI: APK debug (ubuntu) + IPA → TestFlight (macOS) |

### Logic phân loại (client)

- Android: `ON_STOP` + `isInteractive == false` (hoặc keyguard đang khóa) → **LOCK**; `SCREEN_OFF` → **LOCK**; `USER_PRESENT` → mở khóa.
- iOS: `didEnterBackground` + `isProtectedDataAvailable == false` → **LOCK**; `protectedDataWillBecomeUnavailable` → **LOCK**; `protectedDataDidBecomeAvailable` → mở khóa. `inactive`/`willResignActive` đơn thuần (kéo Trung tâm thông báo) **không tính**.
- Còn lại `paused`/`hidden`/vào nền → chờ `lockWaitMs = 600 ms` xem có tín hiệu khóa không; không có → **LEAVE** (`member:left_app`). `resumed` → `member:returned`.
- `detached` (vuốt tắt) → gửi `left_app` ngay (cố gắng).

### Logic server

- `left_app` khi FOCUSING → GRACE, hạn = giờ server + 3000 ms; lượt 2 → EXITED ngay (BR-13).
- `returned` khi `t < hạn` → FOCUSING (`grace_recovered`); `t ≥ hạn` → EXITED (BR-65).
- Hết hạn → EXITED, phát `MEMBER_EXITED` cho **mọi** client; `forfeited` đặt 1 lần.
- `screen_locked` → cờ khóa: bỏ ngưỡng heartbeat, socket đóng không tính (BR-66). `screen_unlocked` → `last_seen_at = now`.
- **(đề xuất spike)** `screen_locked` đến **trong GRACE** → về FOCUSING, hoàn lượt (`lock_reclassified`). Lý do: tín hiệu khóa iOS có thể đến trễ. Tắt bằng `LOCK_RECLASSIFY=0`. Rủi ro lách luật → cần `Q-` mới nếu giữ.
- Không báo khóa: `t ≥ last_seen_at + 10 s` hoặc socket đóng → DISCONNECTED; `+ 10 s` nữa → LOST, **không** `MEMBER_EXITED` (BR-19, D-19).
- `event_id` trùng → bỏ qua (BR-31). GRACE không chuyển DISCONNECTED (tham chiếu §5).

Tham số qua biến môi trường: `PORT` (3000), `GRACE_MS`, `GRACE_MAX`, `HB_TIMEOUT_MS`, `HOLD_MS`, `LOCK_RECLASSIFY`, `LOG_HB=1` (in từng heartbeat).

## 3. Chạy server (Windows)

```powershell
cd "D:\DropIt!\spike\t01-lifecycle\server"
npm install
npm run selftest     # tự kiểm, phải in "TẤT CẢ PASS"
npm start            # nghe 0.0.0.0:3000, log ở server\logs\t01-*.jsonl
```

- Laptop và điện thoại cùng Wi-Fi. Lấy IP LAN bằng `ipconfig`, nhập `http://<IP>:3000` vào app.
- Lần đầu Windows Firewall hỏi: cho phép Node.js trên mạng **Private**.
- Kiểm nhanh: mở `http://<IP>:3000` trên trình duyệt điện thoại → JSON trạng thái.

## 4. Cài app

### Android (APK debug)

```powershell
# Đường dẫn có dấu "!" làm hỏng Gradle wrapper → map sang ổ ảo:
subst T: "D:\DropIt!\spike\t01-lifecycle"
cd T:\
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Hoặc tải artifact `t01-lifecycle-debug-apk` từ GitHub Actions. Trên máy: tắt tối ưu pin cho app nếu muốn đo riêng ảnh hưởng của hãng (ghi rõ bật/tắt khi đo).

### iOS (chỉ qua TestFlight — không có Mac, D-26)

1. Chạy workflow `t01-lifecycle-build` (workflow_dispatch, `ios = true`).
2. Job iOS build IPA, ký, đẩy TestFlight. Sau 5–30 phút xử lý, thêm người thử nội bộ trong App Store Connect.
3. Cài app TestFlight trên iPhone → cài bản T-01.
4. Debug không có Xcode: dùng nút **Xuất log** (chia sẻ JSON qua AirDrop/Zalo/Mail) + log server.
5. iPhone phải **đặt mã khóa** (protectedData chỉ phát khi có mã khóa). Ghi rõ cài đặt "Yêu cầu mật mã: Ngay lập tức".

#### Secrets cần tạo (Settings → Secrets and variables → Actions)

| Secret | Nội dung | Cách lấy |
| --- | --- | --- |
| `APPLE_TEAM_ID` | Team ID 10 ký tự | developer.apple.com → Membership |
| `IOS_DIST_P12_BASE64` | Chứng chỉ **Apple Distribution** (.p12) dạng base64 | Tạo CSR (có thể bằng OpenSSL trên Windows), tải .cer, ghép key → .p12; `certutil -encode` hoặc `base64` |
| `IOS_DIST_P12_PASSWORD` | Mật khẩu .p12 | tự đặt |
| `IOS_PROFILE_BASE64` | Provisioning profile **App Store** cho `com.bakhi.dropit.t01Lifecycle`, base64 | developer.apple.com → Profiles (tạo App ID trước) |
| `KEYCHAIN_PASSWORD` | Mật khẩu keychain tạm trên runner | chuỗi ngẫu nhiên |
| `ASC_KEY_ID` | Key ID của App Store Connect API key | App Store Connect → Users and Access → Integrations → Keys (vai trò App Manager) |
| `ASC_ISSUER_ID` | Issuer ID | cùng trang trên |
| `ASC_KEY_P8_BASE64` | File `AuthKey_<ID>.p8` dạng base64 | chỉ tải được một lần |

Cũng cần tạo app (bundle ID trên) trong App Store Connect trước lần tải đầu. Tải lên dùng `xcrun altool --upload-app` với API key (`notarytool` chỉ dành cho notarize macOS, không dùng cho TestFlight). Workflow chỉ chạy khi `workflow_dispatch` để tiết kiệm phút macOS (C-10).

**Lưu ý:** GitHub chỉ đọc `.github/workflows` ở **gốc repo**. Nếu repo gốc là `D:\DropIt!`, chép `build.yml` lên `<gốc>/.github/workflows/` và đổi `APP_DIR: spike/t01-lifecycle`.

## 5. Kịch bản đo trên máy thật

Chuẩn bị: server chạy; ≥ 2 máy vào cùng server (máy B làm "người quan sát" để đo `MEMBER_EXITED`). Đồng hồ: app tự đồng bộ giờ bằng 5 ping (`clock_sync` trong log). Trước mỗi lượt bấm **Đánh dấu ca** để log có mốc `MARK`. Sau mỗi ca dùng lượt khoan hồng hoặc EXITED, bấm Kết thúc → Bắt đầu lại để có trạng thái sạch (lượt khoan hồng chỉ hồi khi trạng thái cũ đã kết thúc; nếu chưa, đổi tên máy, ví dụ `pixel-03`).

Mỗi tình huống **20 lần × mỗi nền tảng** (NFR-04). Ghi tên máy, hãng, OS, bật/tắt tối ưu pin.

| Mã | Ca (liên quan K-) | Thao tác | Kết quả mong đợi | Android: đạt/20, ghi chú | iOS: đạt/20, ghi chú |
| --- | --- | --- | --- | --- | --- |
| S-01 | Chuyển app (K-02) | Mở app khác bằng thanh đa nhiệm, ở lại > 3 s | Client `CLASSIFY:LEAVE` ≤ 1 s; server GRACE → EXITED ở ~3000 ms; máy B nhận `MEMBER_EXITED` | | |
| S-02 | Về Home (K-02) | Vuốt/bấm Home, chờ > 3 s | Như S-01 | | |
| S-03 | Kéo thông báo (K-03) | Kéo thanh thông báo xuống 5 s rồi đóng | iOS: chỉ `inactive`, **không** LEAVE. Android: ghi lại thực tế (thường không có ON_STOP) | | |
| S-04 | Trung tâm điều khiển (iOS) | Mở Control Center 5 s | Không LEAVE | — | |
| S-05 | Vuốt tắt app (K-02) | Mở đa nhiệm, vuốt tắt app | Đã LEAVE khi vào đa nhiệm (hoặc `detached`); server EXITED sau 3 s. Ghi nếu chỉ thấy socket đóng → DISCONNECTED/LOST (lệch BR) | | |
| S-06 | Quay lại < 3 s (K-03) | Về Home, quay lại sau ~1,5 s | Server `grace_recovered`, không `MEMBER_EXITED` | | |
| S-07 | Lượt khoan hồng thứ 2 (K-04) | Sau S-06, rời app lần nữa | EXITED ngay | | |
| S-08 | Biên 3 s (K-05) | Rời app, quay lại ~2,8–3,2 s (bấm giờ) | Server so `returned` với hạn: `t ≥ hạn` → EXITED. Ghi `msBeforeDeadline` | | |
| S-09 | **Khóa màn hình nhanh** (K-06, NFR-P15) | Bấm nút nguồn, chờ 10 s, mở khóa (sinh trắc/mã) | `CLASSIFY:LOCK`, **0** LEAVE, 0 EXITED, sau mở khóa FOCUSING | | |
| S-10 | Khóa tự động (timeout màn hình) | Để máy tự tắt màn hình, rồi mở khóa | Như S-09 | | |
| S-11 | Khóa rồi mở khóa và rời app (BR-15, ca #17) | Khóa, mở khóa, về Home > 3 s | LOCK → UNLOCK → LEAVE → EXITED | | |
| S-12 | Đo độ trễ tín hiệu khóa | Trong S-09: lấy chênh `flutter:paused`/`scene_did_enter_background` → `CLASSIFY:LOCK` | Ghi phân bố; nếu > `lockWaitMs` thì xem có `lock_reclassified` ở server | | |
| S-13 | Khóa dài (K-06, NFR-08) | Khóa 50 phút (1 lần/máy) | 0 EXITED, 0 DISCONNECTED; ghi % pin trước/sau; đếm `HB` server nhận lúc khóa | (1 lần) | (1 lần) |
| S-14 | Tắt Wi-Fi 5 s (K-07) | Tắt Wi-Fi 5 s rồi bật (app ở tiền cảnh) | Không DISCONNECTED (hoặc reconnected), trạng thái giữ nguyên | | |
| S-15 | Tắt Wi-Fi ≥ 20 s (K-08) | Tắt Wi-Fi 25 s | DISCONNECTED ~10 s sau heartbeat cuối, LOST +10 s; **không** `MEMBER_EXITED` | | |
| S-16 | Sự kiện trùng (K-10) | `npm run selftest` | `dup: true`, bỏ qua | đã tự kiểm | |
| S-17 | Rà quyền riêng tư (K-13) | Đọc log client + JSONL server, xem quyền app trong Cài đặt | Không có tên app khác, nội dung, vị trí; không xin Usage Access | | |
| S-18 | Độ trễ C→S và S→C (NFR-03, NFR-02) | Lấy từ S-01/S-02: `lagMs` (server, trừ `offsetMs`), `latencyMs` ở máy B | Tính p50/p95 | | |

K-01, K-09, K-11, K-12, K-14, K-15 thuộc backend thật (T-02/T-03), **không** trong spike này.

Cách tính:
- **Tỉ lệ phát hiện** = số lượt S-01/02/05 có EXITED đúng / tổng lượt.
- **Khóa bị tính oan** = số lượt S-09/S-10 có `CLASSIFY:LEAVE` hoặc EXITED.
- **Độ trễ C→S** = `RECV.lagMs − offsetMs` (offset từ `clock_sync` của máy đó). Độ trễ phát hiện = `CLASSIFY:LEAVE.clientWallMs − flutter:paused.clientWallMs` (gồm `lockWaitMs`).
- **Độ trễ S→C** = `latencyMs` trong `recv:MEMBER_EXITED` ở máy B.

## 6. Tiêu chí đạt / không đạt

| # | Tiêu chí | Ngưỡng đạt | Nguồn |
| --- | --- | --- | --- |
| 1 | Phát hiện rời app thật (S-01, S-02, S-05) | ≥ 95% mỗi nền tảng | NFR-04 |
| 2 | Khóa màn hình không bị tính rời (S-09, S-10) | **20/20** mỗi nền tảng, 0 EXITED | NFR-P15, NFR-04 |
| 3 | Kéo thông báo/Control Center không tính (S-03, S-04) | ≥ 19/20 (ghi lại mọi lần sai) | §1.3 |
| 4 | Client gửi sau sự kiện vòng đời | ≤ 1 s p95 | NFR-03 |
| 5 | Server kết luận EXITED sau hạn 3 s | ≤ 0,5 s | NFR-03 |
| 6 | Độ trễ client → server (LAN/4G) | p95 ≤ 2 s | NFR-02 (đề xuất cho spike) |
| 7 | Khóa 50 phút | 0 EXITED, 0 DISCONNECTED giả, pin ≤ 5% | NFR-08, K-06 |
| 8 | Mất mạng ≥ 20 s | LOST, không `MEMBER_EXITED` | BR-19, D-19 |
| 9 | Quyền riêng tư | 0 vi phạm | BR-34, NFR-P01 |

Spike **đạt** khi 1, 2, 4, 9 đạt trên cả Android (2 hãng) và iOS; các tiêu chí khác ghi số đo làm đầu vào cho T-02.

## 7. Nếu spike thất bại — cần cập nhật SRS

| Phát hiện | Cập nhật đề xuất (tạo `Q-` mới, không tự chốt) |
| --- | --- |
| iOS không phân biệt được khóa vs rời app (protectedData trễ/không có khi không đặt mã) | Sửa BR-15/D-08: yêu cầu đặt mã khóa, hoặc khoan hồng riêng cho "vào nền" trên iOS (ví dụ `lock_detect_wait_ms`); ghi giới hạn vào NFR-04/NFR-P15 |
| Cần `lock_reclassified` (khóa đến trong GRACE) | Thêm BR mới + tham số; đánh giá lách luật ở §5 (Q-61) |
| Vuốt tắt app chỉ thấy socket đóng → LOST thay vì EXITED | Sửa BR-19/BR-66: socket đóng ngay sau `left_app` = EXITED; hoặc chấp nhận và ghi giới hạn |
| Kéo thông báo trên Android sinh ON_STOP ở một số hãng | Ghi ngoại lệ theo hãng, cân nhắc nâng `grace_s` (BR-11) |
| Heartbeat ngừng khi tắt màn hình (Android Doze / iOS suspend) mà không báo khóa | Xác nhận BR-66 (miễn heartbeat khi đã báo khóa), cân nhắc Foreground Service Android (§1.4) và thông báo thường trực (BR-05) |
| Pin > 5% / 50 phút | Giảm heartbeat khi khóa, sửa NFR-08 |
| Độ trễ > ngưỡng | Sửa NFR-02/NFR-03, BR-28 `notify_latency_s` |
| Không có iPhone thật (Q-142) | T-01 chỉ đạt phần Android; R- rủi ro iOS giữ mở, chặn US-03.04 trên iOS |

## 8. Trạng thái build cục bộ (2026-10-19, Windows)

- `flutter analyze`: **sạch**.
- `flutter build apk --debug`: **build được** (qua `subst T:` vì dấu `!` trong đường dẫn làm Gradle wrapper lỗi; `kotlin.incremental=false` trong `android/gradle.properties` vì pub cache và dự án khác ổ). Trên máy này còn cần đặt `TEMP/TMP` ngắn (vd. `C:\t01tmp`) nếu Gradle báo "Unable to establish loopback connection".
- `flutter test`: **không chạy được** trên máy này (Windows App Control chặn `impellerc.exe`).
- Server: `npm install`, `npm run selftest` (**TẤT CẢ PASS**), `npm start` khởi động được.
- iOS (Swift) và workflow CI: **chưa build/chạy** — không có Mac; chỉ kiểm được khi chạy GitHub Actions có secrets. YAML đã kiểm cú pháp.
- **Chưa thử trên máy thật** — toàn bộ mục 5 chờ đo.
