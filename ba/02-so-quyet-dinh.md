# Sổ câu hỏi & quyết định

Quy trình: `Q-` (Chờ) → nhóm họp → ghi `D-` (Đã chốt) kèm lý do, ngày, người chốt. Không xóa câu hỏi; chỉ đổi trạng thái.

## Câu hỏi mở

| Mã | Câu hỏi | Phương án đề xuất | Ảnh hưởng | Trạng thái |
| --- | --- | --- | --- | --- |
| Q-01 | Khi một người thoát, phiên người còn lại tiếp tục hay cả nhóm bị ảnh hưởng? | Tiếp tục; chỉ người thoát mất Coins phiên + ngắt chuỗi (GĐ1 §4.3) | EP-03, EP-04, BR phiên | Đã chốt → xem D- |
| Q-02 | Ai bắt đầu phiên: lịch chủ nhóm hay thành viên tự mở? | Lịch do chủ nhóm đặt + phiên tự do vẫn tính Coins | EP-02, EP-03 | Đã chốt → xem D- |
| Q-03 | Báo chủ nhóm ngay hay gộp cuối phiên? | Mặc định ngay, cho chọn gộp | EP-04 | Đã chốt → xem D- |
| Q-04 | Một người ở nhiều nhóm? Nhiều chủ nhóm/văn phòng? | Nhiều nhóm: có (nhưng 1 phiên tại 1 thời điểm); nhiều văn phòng: giai đoạn sau | EP-01, EP-02, mô hình dữ liệu | Đã chốt → xem D- |
| Q-05 | Bài viết: nội dung gì, ai xem, kiểm duyệt? | Hoãn ngoài MVP (EP-10) | EP-10 | Chờ |
| Q-06 | Nhật ký chỉ riêng tư hay chia sẻ bạn bè? | MVP: chỉ riêng tư | EP-07 | Chờ |
| Q-07 | iOS, Android hay cả hai? Hạn nộp? | Cần giảng viên/nhóm xác nhận | Toàn dự án | Đã chốt → xem D- |
| Q-08 | Đồng nghiệp có sẵn sàng dùng thử? | Phỏng vấn ≥3 người (T-BA-02) | Kiểm chứng giả định | Chờ |
| Q-09 | Giữ màn hình sáng hay cho tắt (úp máy)? (nguồn cũ đã xóa) | Cho tắt màn hình; khóa màn hình không tính là thoát | EP-03, NFR pin | Đã chốt → xem D- |
| Q-10 | Giới hạn số lần khoan hồng 3s mỗi phiên? (nguồn cũ đã xóa) | 1 lần/người/phiên | BR phiên | Chờ |
| Q-11 | “Tạm dừng có lý do” hoạt động thế nào (số lần, thời lượng, ai duyệt)? | Tối đa 1 lần, ≤5 phút, lý do chọn sẵn, chủ nhóm thấy lý do | EP-03, EP-04 | Chờ |
| Q-12 | Báo cáo tháng có dùng để đánh giá/kỷ luật không? | Công ty quyết; app hiển thị thông báo mục đích cho nhân viên | Riêng tư, EP-08 | Chờ |
| Q-13 | Thông số Coins: 25’=10, 50’=25, trần/ngày bao nhiêu? | Trần 100 Coins/ngày, cấu hình được | BR thưởng | Đã chốt → xem D- |
| Q-14 | Mất mạng giữa phiên: giữ chỗ bao lâu, khi nào tính là thoát? Sự cố server thì sao? (`05-tham-chieu-ky-thuat.md` §5) | Giữ 10 giây; quá hạn ghi “mất kết nối” (khác “thoát”), không báo như thoát; sự cố server: hủy phiên, không ngắt chuỗi | EP-03, EP-04, BR phiên | Đã chốt → xem D- |
| Q-15 | Cuộc gọi đến trong phiên có tự miễn trừ không? (GĐ1 §6) | MVP không tự miễn trừ; dùng “tạm dừng có lý do” (Q-11) + giải trình (Q-16) | EP-03 | Chờ |
| Q-16 | Nhân viên có được giải trình sau khi bị báo thoát? (GĐ1 §10 #3) | Có: ghi chú lý do sau phiên, chủ nhóm thấy kèm sự kiện; không hoàn Coins | EP-04, EP-08 | Chờ |
| Q-17 | Định nghĩa điểm danh, chuỗi ngày (ngày nghỉ, ngày không có lịch); có thưởng thêm theo chuỗi? (nguồn cũ đã xóa) | Điểm danh = hoàn thành ≥1 phiên/ngày; ngày không có lịch nhóm không ngắt chuỗi; chuỗi chỉ cho huy hiệu, không cộng Coins | EP-05, EP-06 | Chờ |
| Q-18 | Phiên theo lịch: vào muộn / vắng mặt thì sao? (thay câu “Host thoát lobby” — nguồn cũ đã xóa) | Vào muộn ≤5 phút được tham gia phần còn lại, Coins theo tỉ lệ; vắng không tính thoát, không báo | EP-03, EP-08 | Chờ |
| Q-19 | Chủ nhóm có tham gia phiên và bị ghi dữ liệu như thành viên? | Tùy chọn tham gia; nếu tham gia thì ghi như thành viên, không ai nhận thông báo về chủ nhóm | EP-01, EP-03 | Đã chốt → xem D-25 |
| Q-20 | Không đồng ý điều khoản minh bạch / rời nhóm thì dữ liệu xử lý thế nào? (GĐ1 §6) | Không đồng ý = không vào nhóm; rút đồng ý = rời nhóm ngay, phiên đang chạy dừng không tính thoát; rời nhóm: giữ số liệu tổng hợp đến ngày rời, ngừng ghi mới; không cho xóa riêng sự kiện thoát (thay bằng giải trình) | EP-01, EP-02, EP-08 | Đã chốt → xem D- |
| Q-21 | Thành viên có xem được ai đã xem/xuất dữ liệu của mình? (T-BA-05) | Có, qua nhật ký truy cập | EP-01, NFR riêng tư | Chờ |
| Q-22 | Quản trị được xem sự kiện thoát chi tiết khi nào? (T-BA-05) | Chỉ khi xử lý khiếu nại/lỗi, có ghi nhật ký truy cập | EP-09 | Chờ |
| Q-23 | Chủ nhóm có thấy Coins của thành viên? (T-BA-05) | Không — báo cáo chỉ cần phiên/phút | EP-06, EP-08 | Chờ |
| Q-24 | Thành viên có xem báo cáo tổng nhóm? (T-BA-05) | Có, chỉ khi nhóm ≥5 người (tránh suy ngược cá nhân) | EP-08 | Chờ |
| Q-25 | Thời hạn lưu dữ liệu? (T-BA-05) | Sự kiện & báo cáo 13 tháng; sao lưu ≤35 ngày; xóa tài khoản xong trong 30 ngày | NFR riêng tư | Chờ |
| Q-26 | Hết hạn tạm dừng khi người dùng không ở trong app? (T-BA-06) | Cho khoan hồng 3s, không trừ lượt | EP-03 | Chờ |
| Q-27 | Trạng thái mất kết nối (LOST) có ngắt chuỗi? (T-BA-06) | Chốt ở T-BA-12 §Thưởng | EP-05 | Chờ |
| Q-28 | Ngưỡng nhận diện sự cố server? (T-BA-06) | ≥80% thành viên mất kết nối trong 10s; cần tách khỏi mất mạng cục bộ văn phòng | EP-03, NFR | Đã chốt → xem D- |
| Q-29 | Chủ nhóm có được dừng/hủy phiên đã bắt đầu? (T-BA-06) | Không | EP-03 | Chờ |
| Q-30 | Mất mạng khi đang khoan hồng? (T-BA-06) | Hạn 3s vẫn chạy trên server, không chuyển DISCONNECTED (chống lách bằng chế độ máy bay) | EP-03 | Chờ |
| Q-31 | Đang mất kết nối khi hết giờ phiên? (T-BA-06) | Nối lại trong ends_at + 10s thì tính hoàn thành | EP-03, EP-05 | Chờ |
| Q-32 | Tạm dừng có lý do có push cho chủ nhóm? (T-BA-06) | Không; chỉ hiện trong bản gộp và báo cáo | EP-04 | Đã chốt → xem D- |
| Q-33 | Chế độ gộp báo cuối phiên là Must hay Should? (T-BA-04) | Should | EP-04 | Đã chốt → xem D- |
| Q-34 | Chủ nhóm rời nhóm: chuyển giao hay giải tán? (T-BA-04) | MVP chỉ giải tán, giữ dữ liệu theo thời hạn lưu | EP-02 | Chờ |
| Q-35 | Ai gán vai trò Chủ nhóm? (T-BA-04) | Quản trị gán | EP-01, EP-09 | Đã chốt → xem D- |
| Q-36 | Báo cáo tháng MVP xuất PDF hay Excel? (T-BA-04) | MVP chỉ PDF; cả hai là Could | EP-08 | Đã chốt → xem D- |
| Q-37 | Khiếu nại/miễn trừ (NFR-P14) có ở MVP? Khôi phục Coins/chuỗi khi miễn trừ? (T-BA-04) | Should; thống nhất với Q-16 | EP-04, EP-09 | Chờ |
| Q-38 | Huy hiệu là thành tích hay hàng trong Shop? (GĐ1 §4.4 vs §4.6) | Huy hiệu thành tích Must; huy hiệu bán trong Shop Could | EP-05, EP-06 | Chờ |
| Q-39 | Hoàn thành phiên bị mất thưởng tập thể (D-05) có tính điểm danh? (T-BA-12) | Có (đã có mặt và tập trung đủ); chỉ mất Coins + ngắt chuỗi | EP-05, EP-08 | Đã chốt → xem D-11 |
| Q-40 | Bị ngắt chuỗi rồi hoàn thành phiên hợp lệ khác cùng ngày: chuỗi = 0 hay 1? (T-BA-12) | Chuỗi = 1 (bắt đầu lại) | EP-05 | Chờ |
| Q-41 | (D-05) Vào muộn sau khi phiên đã mất thưởng tập thể: có bị áp dụng D-05? (T-BA-06) | Có, nhưng cảnh báo trước khi vào; không vào thì ghi vắng | EP-03, EP-05 | Chờ |
| Q-42 | “Số lần gây mất thưởng tập thể” chỉ tính người thoát đầu tiên hay mọi người thoát? (T-BA-15) | Chỉ người khởi phát; người thoát sau vẫn vào “số lần thoát” | EP-08 | Chờ |
| Q-43 | Số ngày điểm danh trong báo cáo nhóm tính theo nhóm đó hay mọi nhóm của người dùng? (T-BA-15) | Chỉ phiên của nhóm đó (tránh lộ hoạt động nhóm khác) | EP-08, riêng tư | Chờ |
| Q-44 | Nhóm giải tán giữa tháng có báo cáo tháng đó không? (T-BA-15) | Có, phần tháng đến ngày giải tán, gửi người từng là chủ nhóm | EP-02, EP-08 | Chờ |
| Q-45 | Coins khi vào muộn làm tròn thế nào; tạm dừng có trừ Coins? (T-BA-12) | Làm tròn xuống theo tỉ lệ phút có mặt; tạm dừng hợp lệ không trừ | EP-06 | Chờ |
| Q-50 | (D-05) Khi phiên mất thưởng tập thể, các thành viên khác có được biết **ai** đã thoát không? (T-BA-04) | Không nêu tên; chỉ báo “phiên đã mất thưởng tập thể”, chỉ chủ nhóm thấy tên (tránh mâu thuẫn đồng nghiệp, NFR-P06) | EP-03, EP-04, NFR riêng tư | Đã chốt → xem D- |
| Q-51 | (D-05 × Q-14) Mất kết nối quá 10s có gây mất thưởng tập thể cho cả phiên không? (T-BA-04) | Không; chỉ người mất kết nối không nhận Coins phiên, người khác giữ thưởng | EP-03, EP-05, EP-06 | Đã chốt → xem D- |
| Q-60 | (D-05) Thành viên rút đồng ý / rời nhóm giữa phiên có làm cả phiên mất thưởng tập thể không? (T-BA-05) | Không; phiên người đó kết thúc, không tính thoát, người khác giữ thưởng (tránh "phạt" quyền rút đồng ý) | EP-01, EP-03, NFR riêng tư | Đã chốt → xem D- |
| Q-61 | (D-08 × D-07) Khi màn hình khóa, iOS/Android có thể treo socket/heartbeat — server xử lý thế nào để không tính mất kết nối/thoát? Nhóm có đủ iPhone + Mac + tài khoản Apple Developer để kiểm thử iOS không? (T-BA-18) | Client báo "khóa màn hình" trước khi bị treo; server chờ đến khi mở khóa hoặc hết giờ phiên; cần spike trên máy thật; tối thiểu 2 Android + 1 iPhone | EP-03, NFR-04, NFR-08, NFR-19 | Đã chốt → xem D- |
| Q-62 | Chọn region AWS nào (không có region tại VN)? Có yêu cầu lưu dữ liệu trong nước không? (T-BA-18) | ap-southeast-1 (Singapore) cho đồ án; hỏi chuyên gia pháp lý trước khi dùng thật | NFR riêng tư, hạ tầng | Chờ |
| Q-63 | (D-10) Ai cũng tạo được nhóm — có cần cơ chế báo cáo lạm dụng nhóm (giám sát không mong muốn) cho quản trị không? (T-BA-05) | Should: nút "báo cáo nhóm" + quản trị giải tán nhóm | EP-02, EP-09 | Chờ |
| Q-64 | Email báo cáo tháng (SES) là Must hay Should ở MVP? (T-BA-18; GĐ1 §11) | Must cho demo (SES sandbox, địa chỉ đã xác minh); nếu thiếu thời gian thì tải PDF trong app | EP-08, ánh xạ AWS | Đã chốt → xem D- |
| Q-65 | Phương thức đăng nhập MVP: chỉ email + mật khẩu (Cognito) hay thêm Google/Apple (iOS bắt buộc Sign in with Apple nếu có đăng nhập mạng xã hội)? (EP-01) | Chỉ email + mật khẩu | EP-01, D-07 | Chờ |
| Q-66 | Đăng xuất hoặc đăng nhập máy khác khi đang trong phiên? (EP-01) | Chặn đăng xuất trong phiên; máy thứ hai không chiếm phiên đang chạy; socket chỉ nhận 1 thiết bị/phiên | EP-01, EP-03, BR phiên | Chờ |
| Q-67 | (Q-19) Chủ nhóm tham gia phiên nhóm mình có cần màn đồng ý riêng (D-05 áp cho chính mình)? (EP-01) | Xác nhận ngắn lần đầu bật "tham gia phiên" | EP-01, EP-03 | Hủy — D-25 |
| Q-68 | (D-02) Sĩ số 4–10 có tính chủ nhóm không? Nhóm < 4 người (lúc tạo hoặc do rời/rút đồng ý/xóa tài khoản) có được đặt lịch, chạy phiên? (EP-01, EP-02) | Chủ nhóm tính vào sĩ số; trần 10 chặn cứng; sàn 4 chỉ cảnh báo chủ nhóm mời thêm, vẫn đặt lịch và chạy phiên (không chặn quyền rút đồng ý) | EP-01, EP-02, EP-03 | Chờ |
| Q-69 | Xóa tài khoản có thời gian chờ để hủy (vd. 7 ngày)? (EP-01) | Không ở MVP; xóa ngay sau xác nhận mật khẩu | EP-01, NFR riêng tư | Chờ |
| Q-70 | Sổ cái Coins bất biến (BR-44) khi xóa tài khoản: xóa dòng hay ẩn danh `user_id`? (EP-01) | Ẩn danh để giữ toàn vẹn sổ cái | EP-01, EP-06 | Chờ |
| Q-71 | Một người tạo tối đa bao nhiêu nhóm? (EP-02) | Cấu hình được, mặc định 10 | EP-02 | Chờ |
| Q-72 | Đổi `notify_mode`/mục đích báo cáo khi phiên đang chạy có hiệu lực lúc nào? (EP-02, EP-04) | Từ phiên kế tiếp | EP-02, EP-04 | Chờ |
| Q-73 | Mã mời và lời mời email: hạn dùng, độ dài, ngưỡng thử sai? (EP-02) | Mã 8 ký tự, hiệu lực đến khi chủ nhóm đổi; lời mời email hết hạn 7 ngày; sai 5 lần/15 phút thì khóa 15 phút | EP-02 | Chờ |
| Q-74 | Giới hạn số lời mời đang chờ? (EP-02) | Không giới hạn; kiểm tra trần 10 lúc đồng ý | EP-02 | Chờ |
| Q-75 | Người đã rời/bị xóa có tham gia lại được? (EP-02) | Được, phải mời lại và đồng ý lại | EP-01, EP-02 | Chờ |
| Q-76 | Chủ nhóm xóa thành viên đang trong phiên ACTIVE? (EP-02) | Hiệu lực sau `ends_at`; không đổi kết quả phiên | EP-02, EP-03 | Chờ |
| Q-77 | Giải tán nhóm (do chủ nhóm hoặc quản trị xử lý báo cáo lạm dụng) khi đang có phiên COUNTDOWN/ACTIVE? Gộp báo cáo lạm dụng trùng? Ẩn danh người báo cáo? (EP-02, EP-09) | Hiệu lực sau phiên hiện tại (chủ nhóm không giải tán được giữa phiên); gộp báo cáo trùng trong 24 giờ; luôn ẩn danh với chủ nhóm | EP-02, EP-09 | Chờ |
| Q-78 | Lịch lặp lại có ở MVP? Sửa/hủy chuỗi lặp thế nào? (EP-02) | Có (theo ngày trong tuần); sửa/hủy "lần này" hoặc "lần này và sau" | EP-02, EP-03 | Chờ |
| Q-79 | Khoảng tối thiểu giữa lúc đặt/sửa lịch và giờ bắt đầu? (EP-02) | Đặt mới ≥ 1 phút; sửa/hủy được đến trước COUNTDOWN | EP-02 | Chờ |
| Q-80 | Thành viên có được nhắc (push) trước giờ phiên? (EP-02) | Có, 5 phút trước, cấu hình theo nhóm | EP-02, EP-04 | Chờ |
| Q-81 | Cảnh báo trùng lịch cho chủ nhóm lộ đến mức nào? (EP-02) | Chỉ số người trùng + tên thành viên nhóm mình; không lộ tên/giờ nhóm khác | EP-02, NFR riêng tư | Hủy — D-21 |
| Q-82 | Thành viên có được "báo vắng trước" một phiên? (EP-02) | Should; ghi ABSENT kèm ghi chú, không push | EP-02, EP-03, EP-08 | Chờ |
| Q-83 | Phòng chờ mở trước giờ bắt đầu bao lâu? (EP-03) | 10 phút, cấu hình được | EP-02, EP-03 | Chờ |
| Q-84 | Rời app trong COUNTDOWN (chưa ghi) thì khi sang ACTIVE xử lý thế nào? (EP-03) | Nếu khi ACTIVE không ở app → GRACE tính từ `started_at`, có trừ lượt khoan hồng | EP-03 | Chờ |
| Q-85 | Có đếm ngược 3 giây / thông báo cục bộ "Quay lại ngay" khi đang GRACE? (EP-03) | Có; thông báo cục bộ, không gửi server | EP-03 | Chờ |
| Q-86 | Mất bao nhiêu nhịp heartbeat thì DISCONNECTED? (EP-03) | Không nhận heartbeat trong 2 × `heartbeat_s` (10 giây) hoặc socket đóng; phối hợp Q-61 | EP-03, NFR | Chờ |
| Q-87 | Thành viên đang úp máy/khóa màn hình/PAUSED được báo phiên `forfeited` bằng kênh nào để không bị dụ rời app? (EP-03, EP-04) | Không push hệ thống trong phiên; banner khi quay lại/mở khóa và ở màn kết quả | EP-03, EP-04 | Chờ |
| Q-88 | Phiên không ai vào: thành viên ghi ABSENT hay phiên VOID? (EP-03) | ABSENT, không ngắt chuỗi | EP-03, EP-05, EP-08 | Chờ |
| Q-89 | Push không tới (tắt quyền, lỗi SNS): có hộp thông báo trong app và thử lại? (EP-04) | Có hộp thông báo trong app; SNS thử lại 1 lần, ghi log | EP-04 | Chờ |
| Q-90 | Giải trình: độ dài tối đa, hạn gửi, hạn sửa, có gửi ngay khi phiên còn chạy? (EP-04) | 500 ký tự; gửi trong 7 ngày; sửa trong 24 giờ; cho gửi ngay sau EXITED | EP-04, EP-08 | Chờ |
| Q-91 | Hạn khiếu nại; khi nào khiếu nại chuyển lên quản trị (chủ nhóm tự khiếu nại, chủ nhóm không phản hồi, nghi lỗi hệ thống); có mở lại ca đã đóng? (EP-04, EP-09) | Hạn 24 giờ sau `ends_at`; chuyển quản trị khi người khiếu nại là chủ nhóm, quá 72 giờ không phản hồi, hoặc nghi lỗi hệ thống; mở lại cần lý do + nhật ký truy cập | EP-04, EP-09 | Chờ |
| Q-92 | Miễn trừ một người khi còn người EXITED khác: phiên vẫn `forfeited`? người khởi phát đổi thế nào? (EP-04) | Vẫn `forfeited`; người khởi phát chuyển sang người EXITED kế tiếp chưa được miễn trừ | EP-04, EP-05, EP-06, EP-08 | Chờ |
| Q-93 | Thông báo ngắt chuỗi do D-05: push riêng hay gộp vào push "phiên mất thưởng"? (EP-05) | Gộp một push tại `ends_at`; chi tiết ở màn kết quả | EP-04, EP-05 | Chờ |
| Q-94 | Huy hiệu/chuỗi mặc định hiện trên hồ sơ cho người cùng nhóm hay ẩn? (EP-05, EP-07) | Mặc định ẩn, người dùng tự bật | EP-05, EP-07, NFR riêng tư | Chờ |
| Q-95 | Nhận huy hiệu có push không? (EP-05) | Chỉ thông báo trong app | EP-05 | Chờ |
| Q-96 | Chuỗi là cấp người dùng (mọi nhóm): chủ nhóm A thấy chuỗi bị ngắt do phiên nhóm B có làm lộ hoạt động nhóm khác? (EP-05) | Chủ nhóm chỉ thấy giá trị chuỗi, không thấy lịch sử/lý do ngắt từ nhóm khác; hoặc chỉ thấy điểm danh theo nhóm (như Q-43) | EP-05, EP-08, NFR riêng tư | Đã chốt → xem D- |
| Q-97 | Thuật ngữ "Hoàn thành phiên = không ai thoát" (01 §8) mâu thuẫn BR-23 (COMPLETED vẫn ghi khi `forfeited`) và định nghĩa điểm danh (EP-05) | Sửa thuật ngữ theo BR-23/BR-46: "hoàn thành" = hết giờ mà bản thân không thoát; thêm "hoàn thành có thưởng" | EP-05, EP-06, EP-08 | Đã chốt → xem D- |
| Q-98 | Giá đồ Shop bao nhiêu? (EP-06) | Khung 60–150, hình nền 100–250 Coins; danh hiệu 50 | EP-06 | Chờ |
| Q-99 | Có cho hoàn/trả đồ đã mua? (EP-06) | Không hoàn; xác nhận trước khi mua | EP-06 | Chờ |
| Q-100 | Danh hiệu bán trong Shop có được trùng/giống huy hiệu thành tích? (EP-06) | Không; chỉ trang trí, không gợi ý thành tích/xếp hạng | EP-05, EP-06 | Chờ |
| Q-101 | Lịch sử Coins có hiện dòng "0 Coins — mất thưởng tập thể / đạt trần"? (EP-06) | Không ghi sổ cái (BR-41); hiện ở kết quả phiên và lịch sử phiên | EP-06 | Chờ |
| Q-102 | Quản trị đổi `coins_25`/`coins_50`/`coins_daily_cap` giữa ngày thì áp từ khi nào? (EP-06) | Áp cho phiên có `ends_at` sau thời điểm đổi; trần theo giá trị hiện hành | EP-06, EP-09 | Chờ |
| Q-103 | Có đồ mặc định miễn phí cho tài khoản mới? (EP-06) | Có 1 khung + 1 hình nền mặc định, không hiện trong Shop | EP-06, EP-07 | Chờ |
| Q-104 | Phần công khai của hồ sơ gồm những trường nào? (EP-07) | Tên, avatar, khung, hình nền, huy hiệu/chuỗi tự chọn; không Coins, không số lần thoát | EP-07, NFR riêng tư | Chờ |
| Q-105 | Có kiểm duyệt tên/avatar không phù hợp? (EP-07) | MVP không lọc tự động; người cùng nhóm báo cáo, quản trị đặt lại mặc định (cùng luồng Q-63) | EP-07, EP-09 | Chờ |
| Q-106 | Xem hồ sơ công khai có ghi nhật ký truy cập (NFR-P07)? (EP-07) | Không; chỉ ghi khi xem dữ liệu phiên/báo cáo | EP-01, EP-07 | Chờ |
| Q-107 | Nhật ký 1 mục/ngày hay nhiều mục/ngày? (EP-07) | 1 mục/ngày | EP-07 | Chờ |
| Q-108 | Xóa nhật ký: xóa thẳng hay thùng rác 30 ngày? (EP-07) | Xóa thẳng ở MVP | EP-07, NFR riêng tư | Chờ |
| Q-109 | Mã hóa nhật ký phía server (KMS) hay đầu-cuối? (EP-07) | MVP phía server; E2E làm sau | EP-07, NFR-12, kiến trúc | Chờ |
| Q-110 | Ngưỡng "nhóm ≥5 người" (Q-24) đếm lúc nào, có tính chủ nhóm? (EP-08) | Đếm thành viên (không gồm chủ nhóm) tại lúc tạo báo cáo | EP-08 | Chờ |
| Q-111 | Link tải PDF báo cáo (presigned S3) hết hạn sau bao lâu? (EP-08) | 15 phút trong app; link email 7 ngày (NFR-P12) | EP-08 | Chờ |
| Q-112 | Giải trình thêm sau khi báo cáo đã tạo có hiện trong báo cáo? (EP-08) | Số liệu giữ nguyên; giải trình mới hiện khi xem trong app; PDF đã tạo không đổi | EP-04, EP-08 | Chờ |
| Q-113 | Thành viên đã rời nhóm có còn xem dòng của mình ở báo cáo kỳ cũ? (EP-08) | Có, trong thời hạn lưu 13 tháng | EP-01, EP-08 | Chờ |
| Q-114 | Kỳ không có dữ liệu có gửi email? Chủ nhóm tắt được email báo cáo? (EP-08) | Có gửi email ngắn; không cho tắt ở MVP | EP-08 | Chờ |
| Q-115 | Tạo báo cáo lỗi: chạy lại bao nhiêu lần, ai được báo? (EP-08) | Thử lại tối đa 3 lần đến 06:00; lỗi thì báo quản trị | EP-08, EP-09 | Chờ |
| Q-116 | Tạo/thu hồi tài khoản quản trị thế nào? Bắt buộc MFA? (EP-09) | Nhóm phát triển tạo trên Cognito; bật MFA cho nhóm "admin" | EP-01, EP-09 | Chờ |
| Q-117 | Người bị khóa tài khoản giữa phiên: tính EXITED (kích hoạt D-05) hay không? (EP-09) | Không; coi như WITHDRAWN, người khác giữ thưởng (thống nhất Q-60) | EP-03, EP-09 | Chờ |
| Q-118 | Khóa tài khoản chủ nhóm thì nhóm xử lý thế nào? (EP-09) | Tạm dừng lịch; báo thành viên; giải tán nếu khóa > 30 ngày | EP-02, EP-09 | Chờ |
| Q-119 | Đổi giá vật phẩm khi người dùng đang mua? Mỗi vật phẩm mua 1 hay nhiều lần? (EP-09) | Dùng giá server, xác nhận lại nếu khác; vật phẩm trang trí mua 1 lần | EP-06, EP-09 | Chờ |
| Q-120 | Điều chỉnh Coins của quản trị (ADMIN_ADJUST) có tính vào trần ngày? Ngưỡng tối đa mỗi lần? (EP-09) | Không tính trần; > 500 Coins cần xác nhận lần hai | EP-06, EP-09 | Chờ |
| Q-121 | Thời hạn lưu nhật ký truy cập? (EP-09) | 12 tháng, sau đó xóa | EP-09, NFR riêng tư | Chờ |
| Q-122 | Miền giá trị hợp lệ của từng thông số Admin? (EP-09) | `ba-rules` định nghĩa min/max cho mỗi thông số (đã đề xuất tại BR-112) | EP-09 | Chờ |
| Q-123 | (Q-14 × D-05) Người đã EXITED **trước** khi phiên bị hủy do sự cố: có giữ ngắt chuỗi cá nhân không? (EP-03, BR-68) | Giữ ngắt chuỗi của chính người đó (đã rời app thật); không Coins vì phiên hủy; không vào báo cáo; khiếu nại được thì khôi phục | EP-03, EP-05, EP-08 | Chờ |
| Q-124 | (Q-37) Người có EXITED được miễn trừ nhận gì: Coins đủ mức, điểm danh, chuỗi như COMPLETED? Phút tập trung tính đến đâu? (EP-04, BR-87) | Như COMPLETED về Coins/điểm danh/chuỗi; phút tập trung chỉ đến lúc EXITED (không bịa dữ liệu sau thời điểm đó) | EP-04, EP-05, EP-06, EP-08 | Chờ |
| Q-125 | Quản trị đổi `badge_milestones`: cấp hồi tố cho người đã vượt mốc mới hay chỉ áp từ sau? (EP-05, BR-90) | Cấp hồi tố ở lần tính kế tiếp; mốc bị bỏ không thu hồi | EP-05, EP-09 | Chờ |
| Q-126 | Giới hạn tên hiển thị/avatar khác nhau giữa EP-01 (tên 1–40, ảnh JPG/PNG ≤ 2 MB) và EP-07 (tên 2–30, ảnh JPG/PNG/WebP ≤ 5 MB) — chọn bộ nào? (BR-97, BR-98) | Theo EP-07: tên 2–30, JPG/PNG/WebP ≤ 5 MB, server thu về 512×512 | EP-01, EP-07 | Chờ |
| Q-127 | "Tổng giờ tập trung" của huy hiệu có tính phiên `forfeited` và phần trước EXITED/LOST không? (khác chỉ số báo cáo tháng) (EP-05, BR-89) | Tính phiên COMPLETED kể cả `forfeited`; không tính phần trước EXITED/LOST; đặt tên khác chỉ số báo cáo | EP-05, EP-08 | Chờ |
| Q-128 | Hạ 16 story Must xuống Should (01.06, 02.02, 02.04, 02.09, 03.06, 03.12, 04.09, 05.02, 05.06–05.09, 07.03, 07.06, 08.06, 08.09) và xếp 03.11, 03.13 là Should? Năng lực giả định 80 điểm cho 4 sprint (T-BA-20) | Chấp nhận để Must = 80 điểm | Backlog, toàn bộ | Đã chốt → xem D- |
| Q-129 | Gộp 4 cặp story trùng: 02.05→01.05, 02.07→01.07, 07.02→01.03, 04.02→03.09? (T-BA-20) | Gộp | EP-01..07 | Đã chốt → xem D- |
| Q-130 | Nhật ký riêng tư (07.07–07.10) có bắt buộc ở MVP không? GĐ1 §7 ghi có (T-BA-20) | Chủ dự án quyết | EP-07 | Đã chốt → xem D- |
| Q-131 | Người rút đồng ý/rời nhóm sau `forfeited_at` có bị ngắt chuỗi? (BR-37, BR-48) | Có (chặn lách giữ chuỗi); riêng bị khóa tài khoản thì không | EP-01, EP-05 | Đã chốt → xem D- |
| Q-132 | Xác nhận số đề xuất: mốc huy hiệu (BR-52), giờ chạy báo cáo 02:00 (BR-56), tên món Shop 1–40 ký tự (BR-93) | Theo đề xuất | EP-05, EP-06, EP-08 | Chờ |
| Q-133 | Must còn 83/80 điểm: hạ US-01.03, US-06.02, US-07.04 xuống Should, hay chấp nhận Sprint 4 = 15 điểm? Xác nhận US-02.10 ước lại L→M | Hạ 3 story | Backlog | Đã chốt → xem D- |
| Q-134 | Ngưỡng khả năng tiếp cận MVP là WCAG 2.1 AA (NFR-20)? Câu chữ về quyền truy cập của người vận hành hạ tầng cần chuyên gia pháp lý duyệt? (gộp Q-109) | WCAG 2.1 AA; có duyệt | NFR | Chờ |
| Q-135 | Chủ nhóm sở hữu nhiều nhóm tham gia phiên của nhóm nào, đổi thế nào? Thành viên nhóm A có được tạo nhóm mới làm chủ? (BR-114, D-21) | Chọn 1 "nhóm tham gia"; thành viên nhóm A được tạo nhóm nhưng không tham gia phiên nhóm đó | EP-02, EP-03 | Đã chốt → xem D-25 |
| Q-136 | Có hiện tên người mất mạng (LOST) / vắng (ABSENT) cho cả nhóm? (D-22) | Không | EP-03, NFR | Chờ |
| Q-137 | Thành viên khác có thấy số lần thoát tích lũy và giờ quay lại của người khác? (D-22) | Không | EP-03, EP-08 | Chờ |
| Q-138 | Khiếu nại được miễn trừ: gửi đính chính cho đúng những người đã nhận tin thoát? (D-22) | Có | EP-04 | Chờ |
| Q-139 | Chủ nhóm tham gia phiên mà thoát có bị nêu tên như thành viên? (D-22, Q-19) | Có | EP-03 | Đã chốt → xem D-25 |
| Q-140 | Must 86 > 83 (D-17) sau khi thêm T-06, US-03.09 lên M, US-08.10: (A) hạ US-07.04, US-06.02 xuống Should + dời US-01.02 sang S4 + gộp US-04.06 vào US-08.10; (A2) như A cũ + dời US-02.08 sang S4 + hạ US-01.03; (B) sửa D-17 giữ 86; (C) gộp US-03.09/US-04.01 (T-BA-69) + gộp như A | A | Backlog | Chờ |
| Q-141 | Sĩ số 4–10 có gồm chủ nhóm không (chủ nhóm không tham gia phiên, D-25)? | Không gồm: 4–10 thành viên | EP-02, BR-74 | Chờ |
| Q-142 | Nhóm có ít nhất 1 iPhone thật để thử phát hiện thoát app trên iOS (spike T-01)? | Cần có; nếu không, spike iOS chỉ chạy trên máy mượn/thiết bị thuê (rủi ro) | EP-03, T-01 | Chờ |
| Q-143 | Danh sách người (báo cáo, thành viên, chi tiết/kết quả phiên) sắp theo gì để tránh xếp hạng ngầm? | Theo tên hiển thị A→Z, không cho sắp theo chỉ số, không hiện hạng | EP-02, EP-03, EP-08, BR-115 | Chờ |
| Q-144 | Chủ nhóm có được xem trạng thái từng người theo thời gian thực trong phiên, hay can thiệp phiên? | Không: chỉ dữ liệu sau sự kiện server xác nhận, màn chỉ-xem | EP-03, EP-04, EP-08, BR-116 | Chờ |
| Q-145 | Màn danh sách nhóm của chủ nhóm có cộng gộp chỉ số nhiều nhóm không? | Không gộp, không so sánh nhóm; mỗi nhóm số riêng, sắp theo tên | EP-02, BR-117 | Chờ |
| Q-146 | US-05.09 (chủ nhóm xem điểm danh thành viên) là Should nhưng 04 §3 gọi màn "Thành viên nhóm" là lối vào duy nhất cho dữ liệu phiên — giữ Should và sửa 04 §3? | Giữ Should; lối vào chính là US-08.10 | EP-05, EP-08, NFR | Chờ |
| Q-147 | Email báo cáo có dùng ảnh theo dõi mở thư (tracking pixel) không? (V-50) | Không | EP-08, NFR riêng tư | Đã chốt → D-27 |
| Q-148 | Màn chi tiết phiên của chủ nhóm (V-46) có tự làm mới không, hay chỉ kéo xuống để làm mới? | Chỉ kéo để làm mới, không tự cập nhật thời gian thực | EP-08, BR-116 | Đã chốt → D-28 |
| Q-149 | (T-BA-123) Thành viên bấm "Rời phiên" và xác nhận khi đang ở phòng chờ V-06 (WAITING, trước `started_at`; màn đếm ngược V-07 không có nút — T-BA-132): ghi ABSENT (không thông báo, không kích hoạt D-05) hay EXITED như trong phiên? | ABSENT, không vào lại được phiên đó; ưu tiên hơn BR-64 (rời app trong COUNTDOWN → GRACE) | EP-03, BR-118, BR-64, §2.2 | Chờ |
| Q-150 | (T-BA-129) Người đang là thành viên nhóm A có được tạo nhóm B và làm chủ nhóm B không (vẫn tham gia phiên nhóm A như thành viên)? | Có; nhóm làm chủ không tính vào giới hạn 1 nhóm thành viên (D-21) | EP-01, EP-02, BR-75 (c), AC-02.01.4 | Chờ |
| Q-151 | Tín hiệu khóa màn hình đến muộn khi đang khoan hồng: cho phân loại lại thành LOCK (về FOCUSING, trả lại lượt khoan hồng)? Spike T-01 bật mặc định (`LOCK_RECLASSIFY`) | Có, nhưng chỉ khi tín hiệu khóa đến trong ≤600 ms sau khi rời; cần đo bằng spike, có thể bị lợi dụng | EP-03, BR-11…15 | Chờ |
| Q-152 | Vuốt tắt app (swipe-kill) mà socket đóng trước khi kịp gửi sự kiện rời → hiện ra LOST (không phạt tập thể) thay vì EXITED — lối lách luật. Xử lý thế nào? | Chờ kết quả spike S-05; nếu xảy ra thì tính LOST xảy ra trong ≤3s sau lần cuối app ở foreground là EXITED | EP-03, BR-19, BR-118 | Chờ |
| Q-153 | (T-BA-140) Thành viên đang ở phòng chờ (WAITING) mất mạng thì sao? | Giữ WAITING; nối lại trước `started_at` thì vào phiên được; không nối lại kịp đến `started_at` thì ABSENT | EP-03, BR-19, BR-63, BR-64, §2.2, V-06 | Chờ |
## Nhóm câu ưu tiên cho người dùng

> Cập nhật 2026-10-07: Q-96, Q-97, Q-03, Q-04, Q-14, Q-50, Q-51, Q-64, Q-131, Q-133 đã chốt (D-11…D-24). Ưu tiên còn lại: Q-136, Q-137, Q-87, Q-27, Q-78.


Tiêu chí: chặn story Must hoặc ảnh hưởng nhiều story/epic nhất. Đây là đề xuất thứ tự hỏi, **chưa chốt**.

| # | Mã | Vì sao ưu tiên |
| --- | --- | --- |
| 1 | Q-97 | Định nghĩa "hoàn thành phiên" là nền cho điểm danh, Coins, báo cáo (EP-05, EP-06, EP-08) |
| 2 | Q-68 | Sĩ số nhóm chặn tạo nhóm, tham gia, rời, đặt lịch, chạy phiên (EP-01, EP-02, EP-03) |
| 3 | Q-84 | Luật COUNTDOWN → ACTIVE nằm trên đường chính của phiên (EP-03, Must) |
| 4 | Q-86 | Ngưỡng DISCONNECTED quyết định thoát/mất kết nối; cần spike cùng Q-61 (EP-03, EP-04) |
| 5 | Q-87 | Kênh báo `forfeited` khi úp máy (D-08); sai sẽ tự dụ người dùng rời app (EP-03, EP-04) |
| 6 | Q-66 | Đăng xuất/đa thiết bị giữa phiên là kẽ hở lách phát hiện thoát (EP-01, EP-03) |
| 7 | Q-117 | Khóa tài khoản giữa phiên có kích hoạt D-05 cho cả nhóm không (EP-03, EP-09) |
| 8 | Q-91 | Luồng khiếu nại và người xử lý, nối EP-04 với EP-09 |
| 9 | Q-96 | Ràng buộc riêng tư cứng: chuỗi cấp người dùng có thể lộ hoạt động nhóm khác (EP-05, EP-08) |
| 10 | Q-78 | Lịch lặp có ở MVP hay không thay đổi phạm vi US-02.10/02.11 (EP-02) |

## Quyết định đã chốt

| Mã | Quyết định | Lý do | Ngày | Người chốt |
| --- | --- | --- | --- | --- |
| D-01 | Bỏ cơ chế cược điểm | Không phù hợp văn phòng (GĐ1 §0, §9) | — | Nhóm |
| D-02 | Nhóm 4–10 người, chủ nhóm tạo nhiều nhóm | GĐ1 §0 | — | Nhóm |
| D-03 | Không theo dõi nội dung/app đang dùng, không xếp hạng cá nhân công khai, không nạp tiền thật | GĐ1 §7 Ngoài phạm vi | — | Nhóm |
| D-04 | CSDL lõi PostgreSQL (RDS); log/nội dung xã hội DynamoDB | Khuyến nghị đặc tả 1.0 (nguồn cũ đã xóa; xem `05-tham-chieu-ky-thuat.md` §3), GĐ1 §8 | — | Nhóm |
| D-05 | (Q-01) Khi 1 người thoát, phiên **vẫn tiếp tục** đến hết giờ cho mọi người, nhưng **tất cả thành viên** trong phiên mất Coins của phiên và bị ngắt chuỗi. Chủ nhóm vẫn được báo người thoát. | Giữ áp lực đồng đội, không dừng phiên | 2026-10-06 | Người dùng |
| D-06 | (Q-02) Phiên theo **lịch do chủ nhóm (chủ room) đặt** | Đúng tinh thần khung giờ chung | 2026-10-06 | Người dùng |
| D-07 | (Q-07) Dùng **Flutter**, chạy cả iOS và Android. Hạn nộp vẫn cần hỏi giảng viên | Một mã nguồn cho 2 nền tảng | 2026-10-06 | Người dùng |
| D-08 | (Q-09) **Cho tắt màn hình**; khóa màn hình không tính là thoát | Tiết kiệm pin, tự nhiên khi úp máy | 2026-10-06 | Người dùng |
| D-09 | (Q-13) Coins: 25 phút = 10, 50 phút = 25, trần 100 Coins/ngày/người; các số cấu hình được | BA chốt theo ủy quyền của người dùng | 2026-10-06 | BA (ủy quyền) |
| D-10 | (Q-35) **Không có vai trò hệ thống "Trưởng phòng"**. Bất kỳ người dùng nào tạo nhóm thì là **chủ nhóm** của nhóm đó; ai tham gia nhóm là **thành viên** của nhóm đó. Vai trò tính theo từng nhóm (một người có thể là chủ nhóm này, thành viên nhóm khác). Chỉ còn vai trò hệ thống "Quản trị". | Đơn giản, không cần ai gán quyền | 2026-10-06 | Người dùng |
| D-11 | (Q-97) "Hoàn thành phiên" = hết giờ mà **bản thân** không thoát (COMPLETED, kể cả khi phiên bị mất thưởng tập thể). Thêm thuật ngữ "hoàn thành có thưởng" = COMPLETED và phiên không `forfeited`. | Khớp BR-23/BR-46, tách rõ điểm danh với Coins | 2026-10-06 | BA (người dùng cho triển khai theo đề xuất) |
| D-12 | (Q-96) Chủ nhóm **không thấy chuỗi** (chỉ số cấp người dùng); chỉ thấy điểm danh và kết quả phiên **trong nhóm mình**. Chuỗi chỉ hiện cho chính người dùng (và hồ sơ nếu họ tự bật). | Chặn suy luận chéo nhóm | 2026-10-06 | BA (người dùng cho triển khai) |
| D-13 | (Q-128) Hạ 16 story Must xuống Should như đề xuất T-BA-20; US-03.11, US-03.13 là Should. Năng lực giả định 80 điểm/4 sprint. | Vừa năng lực 5 người | 2026-10-06 | BA (người dùng cho triển khai) |
| D-14 | (Q-129) Gộp 4 cặp story trùng: 02.05→01.05, 02.07→01.07, 07.02→01.03, 04.02→03.09 (story bị gộp ghi "(Hủy — gộp vào …)"). | Bớt trùng lặp | 2026-10-06 | BA (người dùng cho triển khai) |
| D-15 | (Q-130) Nhật ký giữ ở MVP bản đơn giản theo GĐ1 §7: US-07.07 (viết) và US-07.10 (riêng tư) là Must; US-07.08, US-07.09 là Should. | GĐ1 §7 ghi nhật ký trong MVP; giữ tối thiểu | 2026-10-06 | BA (người dùng cho triển khai) |
| D-16 | Gộp US-07.05 (chọn thành tích hiển thị) vào US-05.06 (bộ sưu tập huy hiệu); cả hai Should. US-07.05 ghi "(Hủy — gộp vào US-05.06)". | Trùng chức năng (review lan-1 #8) | 2026-10-06 | BA (người dùng cho triển khai) |
| D-17 | (Q-133) Giữ nguyên 83 điểm Must; Sprint 4 = 15 điểm (vượt năng lực ước tính 3 điểm, nhóm chấp nhận). | Không hạ thêm story | 2026-10-07 | Người dùng |
| D-18 | (Q-61) Nhóm có tài khoản Apple Developer. Thiết bị iPhone/Mac để build & thử: (giả định) có — cần xác nhận. | Đủ điều kiện thử iOS | 2026-10-07 | Người dùng |
| D-19 | (Q-14, Q-51, Q-28) Mất mạng quá hạn → LOST, **không** làm cả phiên mất thưởng (chỉ người đó không nhận Coins); sự cố server → hủy phiên, không phạt (trừ ngoại lệ BR-68). | Tránh phạt oan do mạng | 2026-10-07 | Người dùng |
| D-20 | (Q-03, Q-32, Q-33) Khi có người thoát: báo **ngay** cho **cả nhóm (group)** và **mọi người trong phiên (room)**, không chỉ chủ nhóm. Không có chế độ gộp cuối phiên ở MVP (US-04.03, US-04.04 → Won't hoặc sau MVP). | Minh bạch, áp lực đồng đội | 2026-10-07 | Người dùng |
| D-21 | (Q-04) **Một người chỉ là thành viên của tối đa 1 nhóm** tại một thời điểm. (giả định) Chủ nhóm vẫn được tạo/quản lý nhiều nhóm (để đạt tiêu chí demo GĐ1 §11: 1 người quản lý ≥2 nhóm) nhưng chỉ tham gia phiên của 1 nhóm — cần xác nhận. | Đơn giản, bỏ xung đột lịch chéo nhóm | 2026-10-07 | Người dùng |
| D-22 | (Q-50) Mọi người trong nhóm/phiên **biết tên người thoát**. Thay thế NFR-P16 và BR-38 (không nêu tên). | Minh bạch theo nhóm | 2026-10-07 | Người dùng |
| D-23 | (Q-131, Q-20, Q-60) Rút đồng ý/rời nhóm sau `forfeited_at` vẫn bị ngắt chuỗi; rút trước đó không kích hoạt D-05. | Chặn lách giữ chuỗi | 2026-10-07 | Người dùng |
| D-24 | (Q-64, Q-36) Email báo cáo tháng gửi **nội dung tóm tắt**, không kèm PDF. PDF là tùy chọn tải trong app (Should). | Email đơn giản | 2026-10-07 | Người dùng |
| D-25 | (Q-19, Q-135, Q-139) **Chủ nhóm không tham gia phiên** — chỉ quản lý (tạo nhóm, đặt lịch, nhận thông báo, xem báo cáo). Vì vậy chủ nhóm được tạo/quản lý **nhiều nhóm** không xung đột. US-03.13 Hủy; BR-25, BR-69, BR-114 viết lại. (đề xuất, Q-141) Sĩ số 4–10 tính **thành viên, không gồm chủ nhóm**. | Vai trò quản lý thuần; đạt tiêu chí demo GĐ1 §11 | 2026-10-19 | Người dùng |
| D-26 | (D-18) Nhóm có tài khoản Apple Developer nhưng **không có máy Mac**. Build/ký IPA và đẩy TestFlight qua **GitHub Actions (runner macOS)**. Có iPhone để thử hay không: (giả định) có — Q-142. | Không cần Mac vật lý | 2026-10-19 | Người dùng |
| D-27 | (Q-147) Email báo cáo **không** dùng ảnh theo dõi mở thư (tracking pixel) hay link theo dõi. | Riêng tư | 2026-10-19 | Người dùng |
| D-28 | (Q-148) Màn chi tiết phiên của chủ nhóm (V-46) **không tự làm mới**; chỉ cập nhật khi kéo xuống để làm mới. | Không giám sát thời gian thực (BR-116) | 2026-10-19 | Người dùng |
| D-29 | (T-BA-123) Màn phiên có nút **"Rời phiên"**; bấm → hộp xác nhận nêu hệ quả (cả phiên mất thưởng, ngắt chuỗi, cả nhóm thấy tên) → xác nhận thì EXITED ngay (BR-118), không qua khoan hồng. Hủy hộp thì tiếp tục phiên. | Minh bạch, tránh lỡ tay | 2026-10-19 | Người dùng |

## Chi tiết câu hỏi

Ghi chú: “Đề xuất” là ý kiến BA, **chưa chốt**. “Chặn” = việc trong `ba/01-viec-ba.md` cần câu trả lời mới làm trọn được.

### Q-01 — Một người thoát, phiên người khác ra sao? (GĐ1 §4.3, §9, §13.1)
> **Đã chốt bởi D-05** (khác đề xuất A): phiên tiếp tục nhưng tất cả thành viên mất Coins và ngắt chuỗi.
- **A. Phiên người khác tiếp tục**, chỉ người thoát mất Coins phiên + ngắt chuỗi. Ưu: không gây mâu thuẫn đồng nghiệp, đúng tinh thần GĐ1. Nhược: giảm yếu tố “đồng đội”.
- **B. Cả nhóm thất bại** (kiểu “nổ phòng”). Ưu: áp lực nhóm mạnh. Nhược: phạt oan nhiều người; GĐ1 §9 không dùng làm mặc định.
- **C. Tiếp tục + thưởng nhóm** khi 100% hoàn thành (vd. huy hiệu nhóm). Ưu: giữ tinh thần đồng đội mà không phạt. Nhược: thêm quy tắc, thêm việc.
- Epic: EP-03, EP-04, EP-05.
- **Đề xuất: A** (C để giai đoạn sau). Lý do: rủi ro thấp nhất; là điều kiện cổng G2 (GĐ1 §12).
- Chặn: **T-BA-06**, kéo theo T-BA-09, T-BA-10, T-BA-12; T-BA-04.

### Q-02 — Ai bắt đầu phiên? (GĐ1 §4.1, §13.2)
- **A. Chỉ lịch chủ nhóm.** Ưu: đơn giản, đúng “khung giờ chung”. Nhược: cứng, không phục vụ người muốn tự tập trung.
- **B. Lịch chủ nhóm + phiên tự do cá nhân** (tính Coins, không báo chủ nhóm). Ưu: linh hoạt, tăng mức dùng. Nhược: hai loại phiên, báo cáo phải tách.
- **C. Thành viên tự mở phiên nhóm.** Nhược: lu mờ vai trò chủ nhóm, khó báo cáo.
- Epic: EP-02, EP-03, EP-08.
- **Đề xuất: A cho MVP, B là Should.** Lý do: giảm phạm vi. Nếu chọn B cần chốt thêm: phiên tự do có báo chủ nhóm/có vào báo cáo không.
- Chặn: **T-BA-06**, T-BA-04, T-BA-08, T-BA-15.

### Q-03 — Báo chủ nhóm ngay hay gộp? (GĐ1 §4.3, §13.3)
- **A. Ngay lập tức.** Ưu: đạt tiêu chí demo GĐ1 §11 (“vài giây”). Nhược: cảm giác bị giám sát, làm phiền chủ nhóm.
- **B. Gộp cuối phiên.** Ưu: nhẹ nhàng, ít push. Nhược: không đạt tiêu chí demo.
- **C. Mặc định ngay, chủ nhóm chọn gộp theo nhóm.** Nhược: thêm một cài đặt.
- Epic: EP-04, NFR độ trễ.
- **Đề xuất: C.** Lý do: khớp GĐ1, giữ tiêu chí demo.
- Chặn: T-BA-10, T-BA-18.

### Q-04 — Nhiều nhóm, nhiều chủ nhóm, nhiều văn phòng? (GĐ1 §7, §13.4)
- **A. 1 người = 1 nhóm.** Ưu: dữ liệu đơn giản. Nhược: không thực tế.
- **B. Nhiều nhóm, 1 phiên tại 1 thời điểm; 1 văn phòng.** Ưu: thực tế, vừa sức. Nhược: phải xử lý trùng lịch.
- **C. Nhiều văn phòng / nhiều chủ nhóm mỗi nhóm.** Nhược: GĐ1 §7 xếp giai đoạn sau.
- Epic: EP-01, EP-02, EP-08, mô hình dữ liệu.
- **Đề xuất: B**, mỗi nhóm đúng 1 chủ nhóm. Cần chốt thêm: hai nhóm trùng giờ (đề xuất: cảnh báo khi xếp lịch, người dùng chọn 1).
- Chặn: **T-BA-04**, T-BA-07, T-BA-08.

### Q-05 — Bài viết (GĐ1 §6, §7, §13.5)
- **A. Hoãn ngoài MVP.** Ưu: tránh phình phạm vi (GĐ1 §10 #4) và việc kiểm duyệt. Nhược: phần xã hội mỏng.
- **B. Bài viết trong nhóm, có nút báo cáo + admin kiểm duyệt.** Nhược: thêm việc ở EP-09.
- Epic: EP-10, EP-09.
- **Đề xuất: A** (Won't ở MVP). Lý do: GĐ1 §7 đã xếp giai đoạn sau.
- Chặn: T-BA-04 (MoSCoW), một phần T-BA-17.

### Q-06 — Nhật ký riêng tư hay chia sẻ? (GĐ1 §4.7, §6, §13.6)
- **A. Chỉ riêng tư.** Ưu: đơn giản, an toàn. Nhược: không có tính xã hội.
- **B. Riêng tư mặc định, tự chọn chia sẻ với bạn bè.** Nhược: phụ thuộc kết bạn (giai đoạn sau).
- Epic: EP-07.
- **Đề xuất: A cho MVP**, B khi có kết bạn. Bất biến: chủ nhóm không đọc được nhật ký.
- Chặn: T-BA-05, T-BA-14.

### Q-07 — Nền tảng & hạn nộp (GĐ1 §8, §13.7)
- **A. Android trước.** Ưu: dễ spike phát hiện nền/màn hình, thiết bị dễ có. Nhược: bỏ người dùng iOS.
- **B. Cả hai (React Native/Flutter).** Ưu: phủ rộng. Nhược: gấp đôi thử máy thật, rủi ro #1 tăng.
- **C. iOS trước.** Nhược: hạn chế hệ điều hành chặt hơn, cần máy Mac.
- Epic: toàn dự án, nhất là EP-03 và NFR.
- **Đề xuất: A** (giả định nhóm có máy Android). Hạn nộp chỉ giảng viên trả lời được.
- Chặn: T-BA-18, T-BA-20 (xếp sprint), cổng G2.

### Q-08 — Đồng nghiệp có sẵn sàng dùng thử? (GĐ1 §12, §13.8)
- Không phải lựa chọn thiết kế mà là việc **kiểm chứng**.
- **A. Phỏng vấn ≥3 người (1 chủ nhóm + 2 nhân viên).** Ưu: hiểu sâu cảm nhận bị giám sát. Nhược: tốn thời gian.
- **B. Khảo sát ngắn online.** Ưu: nhanh, nhiều người. Nhược: nông.
- **Đề xuất: A trước, B bổ sung.** Kết quả là đầu vào cho Q-03, Q-11, Q-12.
- Chặn: không chặn trực tiếp; liên quan T-BA-02, T-BA-03.

### Q-09 — Màn hình sáng hay cho tắt? (nguồn cũ đã xóa; xem `05-tham-chieu-ky-thuat.md` §1.5)
- **A. Giữ màn hình sáng.** Ưu: phát hiện thoát đơn giản. Nhược: tốn pin.
- **B. Cho tắt; khóa màn hình không tính thoát; mở khóa và rời app mới tính.** Ưu: tiết kiệm pin, tự nhiên khi úp máy. Nhược: phải phân biệt “khóa màn hình” với “rời app” — cần spike.
- Epic: EP-03, NFR pin.
- **Đề xuất: B**, phụ thuộc kết quả spike (GĐ1 §10 #1).
- Chặn: **T-BA-06**, T-BA-09, T-BA-18.

### Q-10 — Số lần khoan hồng 3 giây (nguồn cũ đã xóa; xem `05-tham-chieu-ky-thuat.md` §1)
- **A. 1 lần/người/phiên.** Ưu: chống lạm dụng, đơn giản. Nhược: dễ phạt oan lần 2.
- **B. Không giới hạn.** Nhược: lách được bằng cách mở app khác liên tục dưới 3 giây.
- **C. Theo thời lượng** (25’ = 1 lần, 50’ = 2 lần). Ưu: công bằng hơn cho phiên dài. Nhược: thêm quy tắc.
- Epic: EP-03.
- **Đề xuất: A** cho MVP (C nếu phỏng vấn cho thấy phạt oan nhiều).
- Chặn: T-BA-06, T-BA-09.

### Q-11 — “Tạm dừng có lý do” (GĐ1 §6)
- **A. Tối đa 1 lần, ≤5 phút, lý do chọn sẵn, chủ nhóm thấy lý do, không mất Coins.** Ưu: giảm phạt oan. Nhược: có thể bị lạm dụng.
- **B. Không có tạm dừng, chỉ khoan hồng.** Nhược: rủi ro #3 (phạt oan) cao.
- **C. Chủ nhóm duyệt từng lần.** Nhược: làm phiền, chậm.
- Epic: EP-03, EP-04, EP-08.
- **Đề xuất: A**; thời gian tạm dừng không cộng vào phút tập trung.
- Chặn: **T-BA-06**, T-BA-10, T-BA-15.

### Q-12 — Báo cáo tháng có dùng để đánh giá/kỷ luật? (GĐ1 §6)
- **A. App tuyên bố “chỉ để khích lệ”.** Nhược: app không kiểm soát được công ty.
- **B. Chủ nhóm khai mục đích sử dụng; nhân viên thấy trước khi đồng ý vào nhóm.** Ưu: minh bạch, đúng GĐ1 §6.
- Epic: EP-08, EP-01 (đồng ý), NFR riêng tư.
- **Đề xuất: B.** Là vấn đề chính sách; nên hỏi chủ nhóm thật (T-BA-02).
- Chặn: T-BA-05, T-BA-16.

### Q-13 — Thông số Coins (GĐ1 §4.5)
- **A. 25’ = 10, 50’ = 25, trần 100/ngày.** Ưu: khuyến khích phiên dài. Nhược: khó tính khi vào muộn (Q-18).
- **B. Tuyến tính (vd. 0,4 Coin/phút), trần 100/ngày.** Ưu: đơn giản, hợp Coins theo tỉ lệ. Nhược: không thưởng phiên dài.
- **C. Không trần.** Nhược: lạm phát Shop, khuyến khích “cày”.
- Epic: EP-06, BR thưởng.
- **Đề xuất: A**, mọi số do admin cấu hình. Ngày tính theo giờ Việt Nam (giả định).
- Chặn: T-BA-12, T-BA-13.

### Q-14 — Mất mạng giữa phiên (mới; `05-tham-chieu-ky-thuat.md` §5)
- **A. Giữ 10 giây, quá hạn = thoát.** Nhược: mạng văn phòng chập chờn sẽ báo oan.
- **B. Giữ 10 giây, quá hạn ghi “mất kết nối” (sự kiện riêng), không báo như thoát; sự cố server = hủy phiên, không ngắt chuỗi.** Nhược: có thể bị lách bằng chế độ máy bay.
- Epic: EP-03, EP-04, EP-08.
- **Đề xuất: B.** Lý do: giảm phạt oan (GĐ1 §10 #3); cách chống lách cần spike (giả định).
- Chặn: T-BA-06, T-BA-10.

### Q-15 — Miễn trừ cuộc gọi (mới; GĐ1 §6)
- **A. Tự miễn trừ khi có cuộc gọi đến.** Nhược: phụ thuộc OS, chạm ranh giới “không đọc nội dung điện thoại”.
- **B. Không tự miễn trừ; dùng tạm dừng (Q-11) + giải trình (Q-16).**
- Epic: EP-03.
- **Đề xuất: B** cho MVP. Lý do: tôn trọng ràng buộc riêng tư cứng.
- Chặn: T-BA-06.

### Q-16 — Giải trình sau khi bị báo (mới; GĐ1 §10 #3)
- **A. Có ghi chú giải trình, hiện kèm sự kiện trong thông báo/báo cáo.** Ưu: giảm cảm giác bị phạt oan. Nhược: thêm luồng.
- **B. Không có.** Nhược: rủi ro phản đối cao.
- Epic: EP-04, EP-08.
- **Đề xuất: A**, không hoàn Coins (tránh phải duyệt).
- Chặn: T-BA-10, T-BA-16.

### Q-17 — Điểm danh, chuỗi, thưởng chuỗi (mới; GĐ1 §4.4; nguồn cũ đã xóa)
- **A. Chuỗi theo ngày lịch** (cuối tuần cũng ngắt). Nhược: bất công với ngày nghỉ.
- **B. Chuỗi theo ngày có lịch nhóm.** Ưu: công bằng. Nhược: phụ thuộc lịch (Q-02).
- Thưởng: chỉ huy hiệu mốc hay cộng Coins theo chuỗi?
- **Đề xuất: B + chỉ huy hiệu.** Cần chốt: thoát 1 phiên nhưng hoàn thành phiên khác cùng ngày có ngắt chuỗi không (GĐ1 §4.3 ghi “ngắt chuỗi ngày”).
- Epic: EP-05, EP-06. Chặn: T-BA-12, T-BA-15.

### Q-18 — Vào muộn / vắng mặt phiên theo lịch (mới; thay câu “Host thoát lobby” — nguồn cũ đã xóa)
- **A. Không cho vào muộn.** Ưu: đơn giản. Nhược: mất phiên vì trễ vài phút.
- **B. Cho vào muộn ≤5 phút, Coins theo tỉ lệ.** Nhược: tính Coins phức tạp hơn.
- Vắng mặt: không tính thoát, không báo, báo cáo ghi “vắng” tách khỏi “thoát”.
- **Đề xuất: B.**
- Epic: EP-03, EP-08. Chặn: T-BA-06, T-BA-15.

### Q-19 — Chủ nhóm có tham gia phiên? (mới; GĐ1 §5 “minh bạch hai chiều”)
- **A. Không tham gia.** Ưu: đơn giản. **B. Tùy chọn; nếu tham gia thì ghi dữ liệu như thành viên.** Ưu: làm gương, tăng chấp nhận.
- **Đề xuất: B.**
- Epic: EP-01, EP-03. Chặn: T-BA-04 (vai trò & quyền).

### Q-20 — Không đồng ý / rời nhóm (mới; GĐ1 §6)
- **A. Không đồng ý thì không vào nhóm; rời nhóm giữ số liệu tổng hợp đến ngày rời, ngừng ghi mới.**
- **B. Rời nhóm xóa toàn bộ dữ liệu nhóm.** Nhược: báo cáo tháng bị lệch.
- **Đề xuất: A**, kèm quyền yêu cầu xóa theo quy định dữ liệu cá nhân (cần tham vấn chuyên môn).
- Epic: EP-01, EP-02, EP-08. Chặn: T-BA-05, T-BA-07.
