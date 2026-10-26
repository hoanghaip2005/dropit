# DropIt! — app Flutter (iOS + Android)

Org `com.bakhi.dropit`, tên `dropit`. Riverpod 3, go_router, dio, socket_io_client, theme theo `mockup/dropit/DESIGN.md`.
Package native `packages/focus_lifecycle` tách từ `spike/t01-lifecycle` (Kotlin/Swift + bộ phân loại LOCK/LEAVE bằng Dart).

## Xem trên trình duyệt

```powershell
cd D:\DropIt!\backend
npm run db:up
npm run dev
# Terminal khác:
cd D:\DropIt!\app
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8080 --dart-define=API_BASE_URL=http://localhost:3000
```

Mở http://127.0.0.1:8080. Đăng nhập dev bằng tài khoản mẫu An (thành viên) hoặc Lan (chủ nhóm).
Bản web dùng để xem giao diện và luồng dữ liệu; phát hiện khóa màn hình native vẫn cần kiểm tra trên Android/iOS.

## Chạy trên Windows

Dấu `!` trong `D:\DropIt!` làm hỏng Gradle → dùng ổ ảo và TEMP ngắn:

```powershell
subst X: "D:\DropIt!"
cd X:\app
$env:TEMP='C:\t'; $env:TMP='C:\t'     # tránh lỗi "loopback connection" của Gradle
flutter pub get
flutter analyze
flutter test                            # unit + widget; test/integration tự bỏ qua nếu backend tắt
flutter build apk --debug
```

`android/gradle.properties` có `kotlin.incremental=false` (pub cache ở C:, dự án ở X: → Kotlin không đóng được cache incremental).

## Chạy với backend local

```powershell
cd D:\DropIt!\backend; npm run db:up; npm run dev   # http://localhost:3000/health
cd X:\app
flutter run                                          # Android emulator mặc định http://10.0.2.2:3000
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:3000   # máy thật
```

Biến `--dart-define`: `API_BASE_URL` (không có `/v1`), `API_PREFIX` (mặc định `/v1`), `SOCKET_NAMESPACE` (mặc định `/session`).
Hợp đồng đã khớp với backend: REST nghiệp vụ dưới `/v1` (`/health`, `/dev/token` thì không); socket `/session`, chỉ websocket,
handshake `auth: { token, v: 1, device_id }` — `device_id` sinh một lần, lưu SharedPreferences.

Đăng nhập dev: chọn user seed (`backend/db/seed.sql`) → `POST /dev/token {email}`.
`lan@dropit.dev` là chủ nhóm 2 nhóm; an, binh, chi, dung, em, giang, hoa là thành viên.

## Màn đã có (Must)

| Màn | V-xx | File |
| --- | --- | --- |
| Giới thiệu, đăng nhập dev | V-01, V-02 | `features/auth/auth_screens.dart` |
| Trang chủ | V-03 | `features/home/home_screen.dart` |
| Tham gia bằng mã, đồng ý (công tắc mặc định tắt) | V-04, V-05 | `features/groups/group_screens.dart` |
| Nhóm của tôi, chi tiết nhóm | V-19, V-20 | như trên |
| Chủ nhóm: tạo nhóm, mã mời, lịch 25/50, thành viên (theo tên), chi tiết phiên chỉ đọc + kéo làm mới, không Coins/chuỗi | V-42, V-43, V-44, V-46 | như trên |
| Phòng chờ (Rời → ABSENT), đếm ngược 5s không nút, Lockdown đen tĩnh "Phiên đang được ghi" + "Rời phiên" có hộp xác nhận + banner MEMBER_EXITED có tên, khoan hồng 3s, mất kết nối | V-06…V-11 | `features/session/session_screen.dart`, `session_controller.dart` |
| Kết quả phiên | V-12…V-14 | `features/session/result_screen.dart` |
| Coins của tôi, hồ sơ (khung + hình nền đang trang bị; chủ nhóm không có Coins/chuỗi), sửa tên + đổi avatar (`image_picker` → `PUT /me/avatar` → PUT thân ảnh), hộp thông báo điều hướng theo loại | V-16, V-22, V-23, V-29 | `features/profile/profile_screens.dart` |
| Shop 3 tab (khung/hình nền/danh hiệu), chi tiết + mua (`Idempotency-Key` giữ nguyên khi bấm lại/thử lại; thiếu Coins; đã sở hữu), Đồ của tôi, trang bị/gỡ | V-30, V-31 | `features/shop/shop_screen.dart` |
| Thành tích: chuỗi hiện tại/dài nhất, mốc kế tiếp, lịch điểm danh tháng, huy hiệu, công tắc hiện trên hồ sơ (cảnh báo khi bật) | V-26, V-27, V-28 | `features/achievements/achievements_screen.dart` |
| Lịch sử phiên (tuần/tháng) + chi tiết kết quả (người trong phiên A→Z, giải trình, khiếu nại) | V-17 | `features/history/history_screen.dart`, `session/result_screen.dart` (`fromHistory`) |
| Nhật ký: 1 mục/ngày, ≤ 5.000 ký tự có bộ đếm, xem lại/sửa/xóa, "Chủ nhóm và quản trị không xem được trong app." | V-33 | `features/journal/journal_screens.dart` |
| Giải trình (V-15), khiếu nại (tạo từ kết quả), chủ nhóm xem giải trình (V-47), mở ca → miễn trừ/bác có lý do | V-15, V-47 | `features/appeals/appeal_screens.dart` |
| Báo cáo tháng chủ nhóm (V-48, mục đích ở đầu, A→Z, không Coins/chuỗi), chi tiết thành viên (V-49/t_11), báo cáo của tôi (V-34); tab Lịch chủ nhóm | V-34, V-35, V-48, V-49 | `features/reports/report_screens.dart` |
| Lịch lặp (ngày trong tuần + ngày kết thúc ≤ 12 tuần) trong màn đặt lịch | V-44 | `features/groups/group_screens.dart` |

Mỗi màn dữ liệu dùng `AsyncBody` (khung xương tải / rỗng / lỗi / "Không có kết nối mạng" + Thử lại).
Truy vết US: xem `ba/views/00-danh-muc-man.md` (mỗi V-xx ghi US tương ứng).

## Design system

Nguồn: `mockup/dropit/DESIGN.md` + lớp Tailwind của `mockup/*/code.html`. Font Inter 400/500/600/700 đóng gói trong `assets/fonts/` (kèm OFL), không tải font mạng lúc chạy.

Ảnh nguồn mockup được lưu local tại `assets/mockup/`; URL gốc trong `sources.json`. Onboarding dùng ảnh nguồn. Shop, xem thử, Đồ của tôi và hồ sơ dùng SVG gốc trong `assets/cosmetics/` (3 khung trong suốt, 3 cảnh nền, 2 huy hiệu danh hiệu), cùng renderer trong `cosmetics.dart`. Avatar thật được giữ dưới lớp khung. Tái tạo SVG bằng `python app/scripts/generate_cosmetics.py` từ thư mục gốc.

- `lib/core/theme/tokens.dart` — `DT`: màu (canvas `#F4F5F7`, thẻ trắng, đen nhám `#1C1C1E`, accent `#B02F00` cho Coins, success `#1B7F3B`, warning `#BA1A1A` chỉ cho lỗi/thoát, Lockdown đen/`#5C5C5C`/`#A1A1A6`), bo góc (8/16/24/32/pill), khoảng cách (4/8/16/24/32, lề màn 16), chiều cao nút 56/48, bóng (`cardShadow`, `softShadow`, `navShadow`, `heroShadow`).
- `lib/core/theme/app_theme.dart` — `buildLightTheme()` (ColorScheme, TextTheme Inter, nút/ô nhập/dialog/snackbar), `DropItColors` (ThemeExtension, `context.dropit`), `context.text`.
- `lib/app/theme.dart` re-export để giữ import cũ; `lib/core/widgets.dart` export mọi component.

| Component (`lib/core/widgets/`) | Dùng cho |
| --- | --- |
| `AppScaffold(header, children/body, footer, onRefresh)` | Khung màn: nền canvas, lề 16, khoảng cách 16, nút dính đáy |
| `PageList(children, onRefresh)` | ListView chuẩn trong `AsyncBody.builder`, chừa thanh điều hướng |
| `AppHeader.back / .large / .brand` | Header: nút tròn + tiêu đề giữa · lời chào + chip phải · biểu tượng cam + nhãn vai trò |
| `CircleIconButton` | Nút tròn trắng 40 (quay lại, thông báo, có chấm `badge`) |
| `AppBottomNav(light)`, `NavItem` | Thanh viên thuốc nổi, 2 bộ: thành viên trắng (Trang chủ · Nhóm · Shop · Hồ sơ), chủ nhóm đen (Nhóm · Lịch · Báo cáo · Hồ sơ) — chọn theo `ownerOnlyProvider` |
| `cosmetics.dart`: `previewColor`, `ItemPreview`, `FramedAvatar`, `PurposeCard` (V-35), `CountedTextArea` (bộ đếm "n/max ký tự") | Shop/hồ sơ, báo cáo, nhật ký/giải trình/khiếu nại |
| `PrimaryButton` (+`.accent`, `compact`, `loading`, icon) / `SecondaryButton` (`destructive`) / `LinkButton` | Nút pill |
| `AppCard(child/children, gap, onTap)` | Thẻ trắng bo 16 bóng mềm |
| `SectionHeader` (`SectionTitle`), `InfoRow`, `ListRow`, `ReceiptRow`, `ProgressBar` | Nội dung trong thẻ |
| `StatTile`, `StatRow` | Ô số liệu 2 cột |
| `StatusBadge(tone: neutral/accent/success/danger/dark)`, `CoinChip(onCard)`, `PersonChip`, `FilterChipPill`, `PillToggle`/`PillOption`, `PageDots` | Chip, huy hiệu, bộ chọn |
| `InitialAvatar`, `MemberTile` | Thành viên có avatar chữ cái |
| `StateMessage`/`EmptyState(tone)`, `ErrorState`, `SkeletonList`, `AsyncBody`, `ComingSoonScreen` | Trạng thái rỗng/lỗi/tải/placeholder |
| `AppBanner(tone)`, `HintText`, `showSnack` | Thông báo trong luồng |
| `showConfirmDialog` / `ConfirmDialog(destructive, dark)` | Hộp xác nhận (biến thể tối cho Lockdown) |
| `PillTextField`, `FieldLabel`, `inCardInput()` | Ô nhập |
| `LockdownButton`, `RecordingPill`, `CountdownRing` (tĩnh), `LockChip`, `lockPanelDecoration`, `lockWhite/lockGrey` | Bối cảnh Lockdown đen tĩnh |
| `format.dart`: `hhmm`, `ddmm`, `mmss`, `dayLabel`… | Giờ VN |

Ảnh chụp emulator: `docs/screenshots/`.

## Thay đổi đợt này (lệch mockup đã sửa)

- Thanh điều hướng tách 2 bộ theo mockup; chủ nhóm vào `/home` hoặc `/shop` tự về tab Nhóm.
- Trang chủ: thẻ "Coins hôm nay x/100" (tổng `SESSION_REWARD` có `reward_date` = hôm nay giờ VN).
- Phòng chờ: Back hệ thống / nút quay lại → hộp xác nhận "Rời phiên?" (ghi vắng). Socket `session:state` chỉ có `participant_count` (03-api-socket: không danh sách người) → giữ số người, không chip tên.
- Khoan hồng: câu chữ + nút "Tôi có việc khẩn cấp — thoát phiên" theo `n_07`, nhưng giữ nền đen tĩnh, vòng tĩnh, không Coins (quy tắc Lockdown thắng mockup).

## Placeholder "Sắp có"

Dữ liệu của tôi (V-25), Rút đồng ý và rời nhóm (V-21). `member:pause/resume/withdraw` (Should) backend trả `NOT_SUPPORTED` — app không gọi.

## Giả định đợt này

- Shop: 8 vật phẩm mẫu dùng SVG riêng; món chưa có thiết kế dùng preview dự phòng.
- Công tắc "Hiện chuỗi và huy hiệu" ánh xạ vào `PUT /me/badges/{code}/display` (bật = 3 huy hiệu mới nhất, BR-99); API chưa có cờ riêng cho chuỗi công khai.
- Tiến độ huy hiệu phiên/giờ chưa có số đo từ API → chỉ hiện "Chưa đạt"; tiến độ chuỗi dùng `longest_streak`.
- Không có API đọc lại giải trình của chính mình → màn V-15 chỉ hiện trạng thái sau lần gửi trong phiên màn.
- URL tuyệt đối của server (`localhost`) được đổi sang gốc app gọi được (`fixHost`, emulator `10.0.2.2`).

## Test

- `packages/focus_lifecycle/test/classifier_test.dart`: phân loại LOCK/LEAVE (12 ca).
- `test/session_controller_test.dart`: notifier phiên với socket giả.
- `test/widgets_test.dart`: Lockdown, khoan hồng, mất kết nối, LOST, đếm ngược, phòng chờ, đồng ý, nhóm rỗng/mất mạng, chi tiết phiên chủ nhóm, nhãn kết quả.
- `test/features_test.dart`: Shop mua (một `Idempotency-Key`, bấm hai lần trừ một lần, đổi sang "Trang bị"), thiếu Coins, nhật ký giới hạn 5.000 ký tự, chủ nhóm không có Coins/chuỗi ở hồ sơ, báo cáo chủ nhóm (mục đích ở đầu, A→Z, không Coins), sắp tên tiếng Việt.
- `test/integration/backend_contract_test.dart`: `/dev/token` → `/v1/me`, `/v1/me/groups` (Lan ≥ 2 nhóm, parse `MyGroup`). Đã chạy qua với backend local ngày 19/10/2026.

## Giả định

- Token dev lưu SharedPreferences (bản thật: Cognito + flutter_secure_storage).
- Riverpod tự thử lại bị tắt (`retry: null`) để màn lỗi hiện nút "Thử lại" rõ ràng.
- Giờ hiển thị cố định UTC+7.

## Việc còn thiếu

- Đã chạy trên emulator với backend local (an, dung, lan) ngày 19/10/2026 — ảnh `docs/screenshots/1x–8x`; chưa build iOS (cần macOS). Chưa chụp phòng chờ/khoan hồng mới (cần phiên đang chạy).
- Chưa kiểm phân loại LOCK/LEAVE trên máy thật trong app (chỉ ở spike).
- Đăng nhập Cognito, đẩy thông báo (FCM/APNs), các màn Should/Could.
