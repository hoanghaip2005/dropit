# 11 — Tương phản control và khôi phục quyền nhóm

28/10/2026. Phạm vi: shared PrimaryButton, ConfirmDialog, owner selected checkbox/date/time; nhóm detail/leave/removal. Không redesign toàn bộ các view.

## Nguồn / phân xử

- Yêu cầu người dùng: button chủ nhóm trùng màu chữ/nền, controls hai vai trò thiếu nhất quán, thành viên bị xóa hiển thị lỗi thô.
- Agent contrast_audit đọc reference/app source và phân xử. PrimaryButton dùng DT.onPrimary đen cho nền owner đen; ConfirmDialog ép trắng trên nền member cam (thiếu tương phản). Owner date/time đổi nền mà không đổi chữ.
- SỬA: ghép nền/chữ theo ColorScheme, owner nền đen/chữ trắng, member cam/chữ đen; explicit accent vẫn giữ cặp cam/đen. Hộp xác nhận thường kế thừa cặp theme, destructive vẫn trắng trên đỏ. Chữ ngày/giờ và dấu tick owner được đổi tương ứng.
- GIỮ: điều hướng/quyền riêng theo vai trò. Không coi thay primitives là toàn bộ UI admin/member đã đồng nhất.
- THÍCH NGHI: FORBIDDEN_GROUP có nội dung trung tính, nút về danh sách nhóm; không hiện controls owner cũ, không retry vô hạn. Lỗi mạng vẫn retry. Không tự xóa lịch sử cá nhân.

## Ownership / kiểm tra

- root: shared primitives/theme/tests; group_ui_fix: group_screens,membership_screens,group_access_recovery_test; contrast_audit: kiểm độc lập, không triển khai.
- Tests contrast kiểm tỉ lệ >=4.5 cho primary/dialog owner+member và selected date/time; group tests kiểm access-loss/offline/recovery. Báo build/runtime cụ thể sau deploy, chưa coi test thay ảnh.
- CHƯA XÁC MINH HÌNH ẢNH ở thời điểm lập hồ sơ.

## Tác vụ hành vi đi kèm

- reload_session agent sửa auth/session storage/main và tests riêng. Web giữ refresh credential trong sessionStorage cùng tab, không mật khẩu/access token/localStorage/SharedPreferences; refresh Cognito trước runApp; logout xóa, chống restore trễ. Giới hạn tối đa một ngày theo client hiện tại. Native chưa bổ sung lưu phiên.
- sessionStorage đọc được bởi JavaScript; đây không phải cookie HttpOnly, không tuyên bố chống XSS. Không ghi credential vào audit.
- User yêu cầu cấp Coins: đã xác định Cognito sub của email mục tiêu, cộng chênh lệch qua ADMIN_ADJUST tới 10000; actor service:dropit-operations, idempotency riêng chống lặp; số dư đọc lại10000. Không thay cấu trúc ledger hay dữ liệu người khác. Không lưu khóa/token/mật khẩu tại đây.

## Kết quả production

- Build `controls-session-20261028`, deploy 28/10/2026; index dùng bootstrap/main có version, kèm assets/font cùng build.
- Flutter analyze sạch; 58 tests auth/registration/session/group/contrast đạt.
- Browser production: owner đăng nhập rồi reload vẫn ở groups và tải dữ liệu; member demo sau removal HTTP204 reload vẫn đăng nhập, nhóm đã xóa không còn. Chỉ fixture DEMO QA Removed bị xóa membership.
- Ảnh: `artifacts/controls-session/owner-button.png`, `member-after-reload.png` (1280x720). Form owner chỉ nhập dữ liệu mẫu, không submit tạo nhóm.
- Verifier contrast_audit độc lập xem hai ảnh: không blocking contrast, owner trắng/đen và member đen/cam rõ. Canvas khác nhau theo vai trò còn giữ; không tuyên bố đồng nhất toàn app.
- CHƯA XÁC MINH HÌNH ẢNH màn access-loss trực tiếp/dialog/loading/disabled/date-time; các nhánh này có test source, không suy diễn là nghiệm thu hình ảnh.
- Bản mới cần đăng nhập lại một lần để khởi tạo sessionStorage; giữ cùng tab, tối đa một ngày.

## Vòng sửa tái diễn 28/10

- Người dùng yêu cầu mọi button nền đen có chữ trắng; PrimaryButton cưỡng chế cặp này cả icon/spinner, resolve màu theo FilledButtonTheme. Audit độc lập các control đen feature chưa thấy Text con override đen.
- Tái hiện production: thành viên test vào phòng chờ thất bại một lần, lần sau vào được trước giờ. DB các phiên trước CANCELLED NO_ATTENDEE, joined_at null; phiên demo cc7f7d91-ee33-4e3d-a5c1-baf4523ba84a COMPLETED, thành viên từng vào LOST DISCONNECT_TIMEOUT sau browser interruption. Không coi đây là bằng chứng giải quyết toàn bộ lỗi mạng.
- Sửa nhánh ack timeout: retry join/resume sau2s dù socket còn connected; hủy timer khi dispose. Test thật timeout2 lần rồi join thành công.
- Auth phân biệt lỗi mạng/5xx/rate limit với credential bị từ chối; không xóa refresh credential khi lỗi tạm thời. SessionGate chặn router, hiển thị retry khi refresh không tới server. Không lưu access token. Lỗi credential thật vẫn về login.
- Analyze sạch; 48 tests auth/session/contrast đạt trước thêm1 test retry; controller16 tests đạt sau bổ sung.
- CHƯA XÁC MINH HÌNH ẢNH build mới tại thời điểm ghi; ảnh lobby-before chỉ chứng minh build cũ vào được phòng chờ.

### Build cuối vòng tái diễn

- Production `session-retry-final-20261028`, deploy index/bootstrap/main version riêng và assets/font đồng bộ. Analyze sạch; bộ auth/contrast/restore/controller trước bổ sung48 đạt; controller sau bổ sung17 đạt; session screen16 đạt.
- Thêm guard terminal sau ack và trước retry, test hủy trong lúc chờ không gửi lại. Verifier độc lập đóng P2 source.
- Phân xử/sửa copy CANCELLED: NO_ATTENDEE không đổ lỗi chủ nhóm, OWNER_CANCEL riêng, unknown trung tính; thông báo late join/không còn quyền/token rõ. Test mapping từng reason đạt.
- Browser owner đăng nhập và reload hai lần giữ groups/data, gồm reload build cuối. Ảnh `artifacts/session-regression/owner-final.png` 1280x720: verifier contrast_audit thấy nút Tạo nhóm enabled trắng/đen rõ. Dữ liệu form mẫu không submit.
- CHƯA XÁC MINH HÌNH ẢNH các control còn lại/cancelled/access-loss/gate/loading. Không tuyên bố nguyên nhân mạng production đã sửa hoàn toàn: HTTPS/SSH từng timeout không ổn định; demo vào được lobby và phiên COMPLETED, browser interruption làm member LOST.
- SSH /32 mở phục vụ deploy đã đóng lại thành công. Không sửa phiên thật hoặc cấp thêm coin.
