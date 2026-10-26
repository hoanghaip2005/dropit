# Đợt 04 — audit nguồn phòng chờ và phiên đang chạy

Ngày23/10/2026. Auditor `/root/design_reference`. **CHƯA XÁC MINH HÌNH ẢNH.** Chỉ đọc source; không chạy Flutter, không truy cập browser, không thay controller/domain. Đây là danh sách bằng chứng và tiêu chí cần kiểm; arbiter ghi quyết định triển khai riêng.

## Baseline và nguồn

- `app/lib/features/session/session_screen.dart` SHA256 `5E4D6EB53639C43D9759BC0319362901B74B301D1657320AB1DB633447C20360`.
- `app/lib/features/session/session_controller.dart` SHA256 `69BF07CF751431ABF5652811ED22ACA2FD08B97D41F7A53C510851FBBDC2E920`.
- Mockup: `session_lobby_1/code.html`, `session_lobby_2/code.html`, `lockdown_mode/code.html`, `lockdown_mode_active_focus_1/code.html`, `n_07_c_nh_b_o_khoan_h_ng_3_gi_y/code.html` dưới `mockup/`.
- Token/bề mặt: `app/design/design-system.html`, `STITCH_DESIGN_SYSTEM.md`, D02/D06–D12. Màn sáng ưu tiên canvas xám/card trắng không outline; màn focus tối có chủ đích, không tự đổi sáng vì màn khác dùng sáng.
- Domain đối chiếu: `backend/src/modules/sessions/engine.ts`, `summary.ts`, `backend/src/config.ts`; lifecycle `app/packages/focus_lifecycle/lib/focus_lifecycle.dart`. Source/mockup không chứng minh native/web detection thực tế.

## Mâu thuẫn nguồn và giới hạn contract

- Lobby mockup đếm4/7, tên người chưa vào, nút “Sẵn sàng”. API hiện có `participantCount`, `lobbyMembers` tên đã vào; không có tổng danh sách đăng ký hoặc readiness command. Không thêm số7/người vắng/avatar giả/nút không có hành vi chỉ để giống.
- Lobby mockup hiển thị25:00/50:00 nhưng app hiện đếm đến giờ bắt đầu. Cần nhãn phân biệt thời gian chờ và thời lượng phiên, không coi25:00 là yêu cầu timer countdown.
- Hai mockup focus mâu thuẫn: cùng25phút nhưng một bản+10Coins, bản khác+25Coins. Thưởng phải lấy cấu hình/server; không chọn số theo hình.
- Source focus có card thưởng; test hiện ghi “Lockdown không hiện Coins”. Đây là ngoại lệ cần arbiter quyết định, không tự thêm thưởng vì mockup có.
- Summary hiện chỉ lịch/giờ/trạng thái/forfeited, chưa có mode, reward cấu hình hoặc grace/countdown policy. Unknown không được biến thành SOLO,25phút,10Coins hoặc3giây mặc định trong UI.

## Findings source

| ID | Mức | Vị trí / bằng chứng | Rủi ro và tiêu chí sửa/giữ |
| --- | --- | --- | --- |
| S01 | P1 | `SessionScreen.build`: `sessionInfoProvider(id).value` | Nuốt loading/error; lobby tự điền25phút và suy10Coins khi thiếu info. Gate metadata riêng, lỗi/retry có thể độc lập socket; giữ hành động thoát hợp lệ, không trình bày số đoán. |
| S02 | P1 | `LobbyView`: `durationMin ??25`, reward `dur>=50?25:10` | Không theo configured rewards hoặc cap; thay số thật khi contract có, nếu chưa có dùng nội dung định tính/unknown. Không hứa mọi người chắc chắn nhận đủ base. |
| S03 | P1 | Lobby/countdown/focus/grace copy cố định3giây,1lượt; countdown clamp1..5, grace clamp0..3 | Backend cho phép GRACE_MS/GRACE_MAX/COUNTDOWN_MS khác. Không cắt countdown7thành5 hoặc grace10thành3. Timer dùng deadline và server offset; policy text cần metadata thật hoặc mô tả không nêu số. |
| S04 | P1 | `CountdownView`: ceil rồi clamp1..5 | Khi deadline đã tới nhưng controller chưa đổi phase, còn hiện1giây giả. Hiện trạng thái đồng bộ tại0/chờ xác nhận phù hợp; không tự chốt/kết thúc backend từ UI. |
| S05 | P1 | Copy khóa/úp máy an toàn ở Lobby, Countdown, Lockdown | Native bridge Android có tín hiệu khóa; MissingPlugin chỉ còn lifecycle. Không có chứng cứ web phân biệt khóa màn hình; “úp máy” không có cảm biến. Bỏ hứa bảo đảm đa nền tảng; diễn đạt theo capability/giới hạn đã xác nhận. |
| S06 | P1 | `DisconnectedOverlay` chỉ Align+panel, không barrier phủ nền | Vùng ngoài panel có thể chạm controls dưới: nút rời mở confirm rồi controller từ chối vì disconnected; rút đồng ý vẫn có thể điều hướng. Cần phân xử overlay modal và hành động hợp lệ, kiểm hit-testing ngoài panel. Không sửa leave queue policy để chữa UI. |
| S07 | P2 | `LockdownView` không nhận info, chỉ số giờ+recording | Thiếu ngữ cảnh nhóm/loại phiên so focus mockup. Thêm tên/context từ nguồn thật, không suy SOLO từ số người. Không lộ metadata người khác. |
| S08 | P2 | LOST vẫn render `remaining` từ `endsAt` của nhóm | Label “Phiên của bạn đã kết thúc” nhưng số tiếp tục chạy gây hiểu nhầm member còn trong phiên. Tách trạng thái member kết thúc khỏi đồng hồ nhóm; nếu giữ giờ nhóm phải gắn nhãn rõ. |
| S09 | P2 | `RecordingPill` copy “Phiên đang được ghi” | NFR cho phép metadata lifecycle, không chứng minh ghi âm/video/màn hình. Câu chữ cần rõ phạm vi theo dõi; không thêm camera/mic asset hoặc hứa theo dõi thao tác app khác. |
| S10 | P2 | `_confirmLeave`: lobby khẳng định vắng/không ai được báo; active khẳng định mất thưởng/tên cả nhóm | Đối chiếu đúng phase/mode/domain; thông báo đã gửi không đồng nghĩa mọi người đã nhận. Giữ xác nhận hậu quả nhưng tránh chắc chắn sai khi metadata unknown hoặc futureSOLO. |
| S11 | P2 | `_confirmLeave` sau await không kiểm mounted trước ref; không guard dialog đang mở | Người dùng doubletap/back có thể mở nhiều confirm; dispose khi dialog mở có thể dùng ref sau dispose. Guard mounted và pending dialog; leaving phải chặn mọi trigger tương ứng. |
| S12 | P2 | Dark route PopScope chặn back; handler chỉ xử lý lobby | Countdown/focus/grace/disconnected/lost có hành vi khác. Ghi rõ chủ đích back; không để hardware back gây no-op khó hiểu khi có action thoát hợp lệ. Không biến back thành rời phiên không xác nhận. |
| S13 | P2 | `LobbyView` participant Row chứa Text không Expanded | Tên/nhãn dài hoặc text scale lớn có nguy cơ overflow; dùng wrap/flex phù hợp, count0 khácnull. Không suy số người từ danh sách tên khi server count unknown. |
| S14 | P2 | Countdown/Lockdown/Grace dùng Column+Spacer, ring180, chữ72, fixedgap72 | Không có cuộn;320×740/chữ1.5–2/safearea có nguy cơ tràn, banner đè timer. Cần đo thật và layout thích nghi, giữ dark tĩnh/reducedmotion. Đây là nguy cơ source, chưa có ảnh tái hiện. |
| S15 | P2 | ExitBanner positioned top56, timerẩn6giây, hàng đợi | Banner dài có thể đè context/countdown; nếu grace/disconnected che banner thì vẫn autoẩn trước khi đọc. Kiểm thứ tự và accessibility;6giây là giả định ghi trong controller, không metadata server. Không sửa forfeited khi chỉ dismiss banner. |
| S16 | P2 | Connecting/error/cancelled dùng header “Phòng chờ” chung; error chỉ vềhome/groups | Có state nhưng chưa có retry/resume chủ động và phân biệt metadata/socket. Không để retry tạo lầnjoin mới sai hoặc ghi vắng. Back directlink cần đường thoát hữu ích. |
| S17 | P2 | Cancelled copy “Kết quả của bạn không bị tính” với SERVER_OUTAGE | Cần phân biệt người đãEXITED trước sự cố và người đượcVOID; result flow hiện có cancelledOutageExited. Không hứa xóa mọi hậu quả chỉ vì cancelReason outage. |
| S18 | P2 | `_tick` rebuild mỗi giây, không observer UI riêng | Controller serverNow có offset, socket reconnect/resume; không cần animation ring giả. Kiểm clock sau background/resume, metadata update, timer cleanup; UI không tự chuyển finalphase khi timer về0. |

## Domain phải giữ; điểm chưa chứng minh

- Controller `session:join` lần đầu có fallback `session:resume` khi server cho biết state trước đó; reconnect dùng resume+last eventID, khử trùng sự kiện. Không sửa thành luônjoin để làm retry UI.
- `leave()` kiểm `canLeave`, busy, socketconnected; offline báo “Chưa rời phiên”, không xếp hàng leave. UI không chuyển home/result chỉ vì đã nhấn hoặc mở confirm.
- LOST là terminal cá nhân, không tự gây forfeited nhóm; forfeited có thể đã xảy ra bởi người khác. Copy phải nói đúng nguyên nhân riêng, không phủ nhận phiên nhóm vốn mất thưởng.
- Deadlinegrace và offset lấy server; controller tự đưa countdown tới focusing/disconnected theo startedAt nhưng kết quả cuối phải do server. Bản UI không mở rộng thay lifecycle hoặc bảo mật.
- `lockReclassify` backend mặc địnhfalse; nếu leftApp đã xảy ra rồi mới nhận screenLocked trongGRACE thì không tự đảo lại. Không hứa mọi chuỗi sự kiện khóa máy đều được cứu. Native/web cần kiểm riêng.
- `SessionView.copyWith` giữgiátrị khi inputnull; forfeited trong `_applyServerState` chỉ chuyểntrue, không rõresetfalse. Đây là hành vi hiện hữu ngoài scope UI; metadata mới cófalse phải giữfalse khi root mởcontract, không dùng `??default` haytruthy để biếnfalse thànhunknown/true.
- Disconnected state chưa có `disconnectedAt/holdDeadline`; không bịa countdown reconnect10giây. Countdown reconnect/waiting và grace+offline cần ma trận rõ; `connected=false` không tự kết luận người đãLOST.

## Checklist nghiệm thu chức năng và bố cục

1. **Metadata:** loadsuccess/loading/error+retry, duration/mode/reward/policy unknown; config khác mặc định; false/0/null được phân biệt. Socket vẫn hoạt động khi HTTPinfo lỗi; không reset session vì retryinfo.
2. **Waiting:** đến trướcgiờ, cập nhật lịch từserver, startnull, countnull/0/nhiều, namesrỗng/dài, reconnect, xácnhậnleave/cancel/offline/ACKtimeout; không tạo sẵn sàng command giả.
3. **Countdown:** startnull,5/7/0giây theo deadline thật, clock lệch/resume/offline, chuyển focus chỉ controller; back policy, chưa bật ghi sớm.
4. **Focus:** group/mode knownunknown, timerpositive/0/null, forfeitedtruefalse, banners0/1/nhiều tên dài, lifecycle recording copy rõ, leave/back/doubletap/rútconsent đúng flow riêng.
5. **Grace:** deadlinenull/đãhết/cấu hình khác3giây, graceMaxkhác1, returned trước/đúng/sau biên, offline và emergency leave; fieldcount không clamp số giả. Không tự can thiệp timerengine.
6. **Disconnected:** fullhit-test overlay, auto reconnect/resume, waiting/countdown/grace/focus đều được biểu đạt; offlineleave không báo thànhcông; chưa códeadline thì không hiện số đoán.
7. **LOST/final/cancel:** ghi đã dừng, khôngleave, home hữu ích, không lẫn timer cá nhân với nhóm; cancelledoutage trước/sauEXITED, removed, absent, completed, withdrawn; directlink/route replacement đúng ngữ cảnh.
8. **Responsive/accessibility:**320×740,390×844,768×1024; text1.5/2; longVietnamese và fontfallback; safearea/keyboarddialogs, focuskeyboard, semanticlabels và thông báo không đọc lại mỗi giây quá mức. Darkmotion tĩnh, contrast icon/text.
9. **Timer/back:** dispose tick/banner safely, dialog pending/dispose, autoẩn queue; định nghĩa systemback cho từngphase và deep link. Thời gian hiển thị luônserveroffset, không tích lũy tick drift.
10. **Evidence:** fixture nhận diện rõ, hash/build, platform/browser, role, route/state, viewport, ảnh cặp trước/sau+source; widget/controller tests hỗ trợ hành vi, không thay visualpass. Android lifecycle proof khác web UI preview.

Test hiện tại `widgets_test.dart` đã có smoke countdown/lobby/grace/disconnected/lost, `session_controller_test.dart` có reconnect/state. Auditor chỉ đọc, chưa chạy và chưa coi chúng bao phủ checklist trên. Mọi hash sau baseline phải ghi recheck riêng; không đánh dấu cảđợt đạt từ audit source này.
