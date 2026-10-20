# SRS 04 — Phi chức năng & Riêng tư

Việc: T-BA-05, T-BA-18; sửa theo review lần 1: T-BA-28, T-BA-29, T-BA-35, T-BA-39, T-BA-40, T-BA-41, T-BA-46, T-BA-47, T-BA-52, T-BA-54; sửa theo review lần 2: T-BA-62 (NFR-20 → Q-134), T-BA-68; cập nhật theo D-18…D-24; sửa theo review lần 3: T-BA-71, T-BA-74, T-BA-75, T-BA-78; cập nhật theo D-25, D-26. Nguồn: GĐ1 §4, §6, §8, §10, §11; D-03, D-04, D-05, D-07, D-08, D-10, D-11, D-12, D-15, D-18…D-26; `05-tham-chieu-ky-thuat.md` §1, §4 (tham khảo kỹ thuật).
Câu hỏi liên quan đã ghi vào sổ quyết định: Q-21…Q-25, Q-60…Q-63, Q-109, Q-123, Q-134, Q-141, Q-142. Đã chốt: Q-50 (D-22), Q-03 (D-20), Q-04 (D-21), Q-20/Q-60 (D-23), Q-64 (D-24), Q-61 (D-18), Q-14/Q-28 (D-19), Q-19/Q-135/Q-139 (D-25).

**Vai trò (theo D-10, D-21, D-25):** không có vai trò hệ thống "Trưởng phòng". Vai trò tính **theo từng nhóm**: người tạo nhóm là **chủ nhóm**, người tham gia là **thành viên**. (D-21) Một người là **thành viên của tối đa 1 nhóm** tại một thời điểm. (D-25) **Chủ nhóm không tham gia phiên** — chỉ quản lý (tạo nhóm, đặt lịch, nhận thông báo, xem báo cáo); vì vậy chủ nhóm tạo/quản lý được nhiều nhóm và **không bao giờ có dữ liệu phiên** (thoát, LOST, tạm dừng, điểm danh) trong nhóm mình quản lý. Vai trò hệ thống duy nhất: **Quản trị**. Mọi quyền "chủ nhóm" trong tài liệu này chỉ áp dụng cho nhóm người đó sở hữu.

## §Riêng tư & minh bạch

### 1. Nguyên tắc riêng tư (yêu cầu kiểm tra được)

| Mã | Yêu cầu | Cách kiểm tra | Nguồn |
| --- | --- | --- | --- |
| NFR-P01 | App chỉ ghi sự kiện vòng đời app (rời app / quay lại / khóa–mở khóa màn hình) và thời điểm. Không đọc tên app khác, nội dung màn hình, thông báo, danh bạ, vị trí. Không dùng `UsageStatsManager`/quyền Usage Access. | Rà manifest/Info.plist: chỉ quyền mạng + thông báo (+ foreground service nếu spike cần). Rà schema bảng sự kiện: không có cột tên app/nội dung. | GĐ1 §6, D-03 |
| NFR-P02 | Chỉ ghi khi phiên đang chạy (từ lúc hết đếm ngược đến khi phiên kết thúc). Ngoài phiên không gửi sự kiện nào lên server. | Test: rời app ngoài phiên → 0 bản ghi; log mạng không có request sự kiện. | GĐ1 §6 |
| NFR-P03 | Thành viên xem được **toàn bộ** dữ liệu về mình mà chủ nhóm xem (cùng trường, cùng độ chi tiết). | So màn "Dữ liệu của tôi" với màn chủ nhóm cho cùng người: trường khớp 100%. | GĐ1 §5, §6 |
| NFR-P04 | Không vào nhóm nếu chưa đồng ý rõ (§2). Không có ô đánh dấu sẵn. | Bỏ qua màn đồng ý → không vào được nhóm; DB có bản ghi đồng ý (người, nhóm, phiên bản nội dung, thời điểm). | GĐ1 §6 |
| NFR-P05 | Nhật ký mặc định riêng tư; chủ nhóm và quản trị **không** đọc được nội dung qua app hay API. MVP mã hóa **phía server** (không phải mã hóa đầu-cuối), nên mọi câu chữ hướng tới người dùng phải trung thực: dùng "Chủ nhóm và quản trị không đọc được nhật ký của bạn trong app"; **không** dùng "Chỉ mình bạn đọc được" / "Không ai khác đọc được". Màn đồng ý (§2 mục 3) và chính sách riêng tư nói rõ: dữ liệu được mã hóa khi lưu, người vận hành hạ tầng về kỹ thuật có thể truy cập nhưng bị hạn chế bằng phân quyền và nhật ký **(đề xuất, Q-109)**. | Gọi API nhật ký bằng token chủ nhóm/quản trị → 403. Nội dung nhật ký mã hóa khi lưu. Rà chuỗi giao diện: không có cụm "chỉ mình bạn" / "không ai khác" gắn với nhật ký. | GĐ1 §6, Q-06, Q-109, D-15 |
| NFR-P06 | Không xếp hạng cá nhân công khai; thành viên không thấy **số lần thoát tích lũy** (theo tháng/tổng) của người khác. Thông báo tên người thoát theo từng sự kiện (NFR-P18) không bị cấm **(giả định — D-22 chỉ nói về tên, chưa nói về số đếm)**. | Rà mọi màn thành viên: không có bảng xếp hạng/cột số lần thoát của người khác. | D-03, D-22, GĐ1 §9 |
| NFR-P07 | Mỗi lần chủ nhóm/quản trị xem hoặc xuất dữ liệu cá nhân của thành viên được ghi nhật ký truy cập; thành viên xem được ai đã xem **(đề xuất, Q-21)**. | Chủ nhóm mở báo cáo → có bản ghi truy cập hiển thị cho thành viên. | GĐ1 §5 |
| NFR-P08 | Suốt phiên, thành viên thấy chỉ báo rõ "Phiên đang được ghi". | Chỉ báo hiển thị khi và chỉ khi đang ghi. | GĐ1 §6 |
| NFR-P09 | Màn đồng ý hiển thị mục đích dùng báo cáo, do chủ nhóm điền khi tạo nhóm **(giả định, Q-12)**. | Không tạo được nhóm khi trường mục đích trống. | GĐ1 §6, Q-12 |
| NFR-P10 | Thành viên có thể giải trình cho mỗi sự kiện thoát; giải trình hiện kèm sự kiện ở mọi nơi sự kiện xuất hiện **trong app**. Ngoại lệ (BR-102): PDF báo cáo đã tạo không đổi; giải trình gửi/sửa sau lúc tạo báo cáo chỉ hiện khi xem báo cáo trong app, gắn nhãn "thêm sau khi tạo báo cáo". | Thêm giải trình trước lúc tạo → PDF và báo cáo trong app hiển thị kèm. Thêm sau lúc tạo → báo cáo trong app hiện kèm nhãn; PDF giữ nguyên. | GĐ1 §10 #3, BR-102, Q-112 |
| NFR-P15 | (D-08) Khóa màn hình / tắt màn hình trong phiên **không** tạo sự kiện thoát, không báo chủ nhóm, không làm mất thưởng. Chỉ "mở khóa rồi rời app" mới tính. | 20 lần khóa–mở khóa mỗi nền tảng (iOS, Android) → 0 sự kiện thoát. | D-08 |
| NFR-P16 | (Hủy — bản cũ "không hiện tên người thoát" bị thay bởi D-22; nội dung mới cấp mã NFR-P18, T-BA-75.) | — | D-22 |
| NFR-P17 | (D-12, T-BA-68) Màn bật "hiện chuỗi trên hồ sơ" phải hiện câu "Mọi người cùng nhóm, kể cả chủ nhóm, sẽ thấy chuỗi này"; mặc định = tắt. | Không bật được khi chưa hiển thị câu cảnh báo; tài khoản mới → trạng thái tắt. | D-12 |
| NFR-P18 | (D-22, D-20, D-25) Khi có thành viên thoát (EXITED), **chủ nhóm**, **mọi thành viên của nhóm** và **mọi người trong phiên** thấy **tên** người thoát và việc phiên mất thưởng tập thể (D-05). Chỉ hiện: tên, "đã rời app", thời điểm sự kiện. **Không** hiện cho người khác: lý do tạm dừng, giải trình/khiếu nại, số lần thoát tích lũy (NFR-P06) **(giả định)**. LOST (mất mạng) **không** gây mất thưởng tập thể (D-19) và **không** được thông báo tên cho cả nhóm như một lần thoát **(giả định)**. | Thành viên C cùng phiên và thành viên D cùng nhóm không trong phiên: nhận thông báo có tên X khi X thoát; payload không chứa giải trình/tạm dừng/số đếm. X mất mạng quá hạn → C, D không nhận thông báo "X đã rời app", phiên không mất thưởng. Chủ nhóm không có trong danh sách người tham gia phiên nên không bao giờ là người bị nêu tên (D-25). | D-22, D-20, D-19, D-05, D-25 |
| NFR-P19 | (T-BA-128; thay mã tạm "NFR-P04a") Màn đồng ý §2 mục 2 và 2b liệt kê **đủ 100%** trường dữ liệu cá nhân hiện cho chủ nhóm (push, màn "Thành viên nhóm", chi tiết phiên US-08.10, báo cáo tháng) và cho thành viên khác (thông báo thoát D-22). Thêm trường mà không cập nhật màn đồng ý = lỗi chặn phát hành. | Lập danh sách trường từ payload thông báo thoát + `03-quy-tac.md` §Báo cáo §2 + API chủ nhóm/thành viên; so với mục 2/2b → khớp 100%. Đổi mục 2 → phiên bản nội dung tăng, người cũ phải đồng ý lại. | GĐ1 §6, D-22, NFR-P04 |

Ghi chú D-05/D-22: cả phiên mất Coins và ngắt chuỗi, và mọi người biết tên người gây ra. Đây là thay đổi lớn về riêng tư so với GĐ1 §9 ("không bêu tên") — xem R-P12 và màn đồng ý §2 mục 4.

### 2. Luồng đồng ý khi vào nhóm

**Hiển thị trước khi vào nhóm** (một màn, ngôn ngữ đơn giản):
1. Tên nhóm, chủ nhóm, khung giờ phiên (lịch do chủ nhóm đặt — D-06). Chủ nhóm chỉ quản lý, không tham gia phiên cùng bạn (D-25).
2. **Chủ nhóm sẽ thấy về bạn (chỉ trong phiên của nhóm này)** — liệt kê đủ mọi trường xuất hiện ở thông báo "ngay" (D-20), báo cáo tháng (`03-quy-tac.md` §Báo cáo §2) và màn "Thành viên nhóm":
   - Có mặt hay **vắng** (không vào phiên — ABSENT); **vào muộn** và giờ vào.
   - **Rời app** (thoát — EXITED): có/không, giờ rời và giờ quay lại (giờ server), số lần thoát trong tháng.
   - **Mất kết nối** (LOST) trong phiên.
   - **Tạm dừng**: lý do bạn chọn, thời lượng.
   - **Giải trình** và khiếu nại bạn gửi, kết quả xử lý (miễn trừ / bác).
   - Kết quả phiên của bạn (hoàn thành theo D-11) và phiên có bị **mất thưởng tập thể** không; **bạn có phải người khiến phiên mất thưởng không** (tên bạn hiện trong thông báo) và **số lần bạn gây mất thưởng tập thể** trong tháng.
   - **Điểm danh trong nhóm này** (số ngày có phiên hoàn thành), số phiên và số phút tập trung trong nhóm này.
   - Phần hồ sơ công khai (tên, avatar, đồ đang trang bị).
   
   Chủ nhóm **không** thấy: chuỗi ngày (D-12, trừ khi bạn tự bật hiện trên hồ sơ), Coins, nhật ký.
2b. **Mọi người trong nhóm sẽ thấy khi bạn rời app trong phiên** (D-22): tên bạn, "đã rời app", thời điểm — gửi ngay cho cả nhóm và mọi người trong phiên (D-20). Câu này hiển thị nổi bật, không gộp vào chữ nhỏ. Mất mạng không tính là rời app (D-19).
3. Không ghi gì: app bạn mở, nội dung máy, dữ liệu ngoài phiên; khóa màn hình không tính là thoát (D-08). Nhật ký: "Chủ nhóm và quản trị không đọc được nhật ký của bạn trong app" (NFR-P05 — không hứa "chỉ mình bạn đọc được").
4. **Luật tập thể (D-05):** nếu bất kỳ ai trong phiên rời app, **cả phiên** mất Coins và chuỗi, và mọi người trong nhóm biết tên người thoát (D-22). Mất mạng quá hạn chỉ làm người đó không nhận Coins, không ảnh hưởng cả phiên (D-19).
5. Ai thấy: tóm tắt ma trận §3.
6. Khi nào báo: **ngay** khi hết khoan hồng, cho chủ nhóm, cả nhóm và người trong phiên; MVP không có chế độ gộp cuối phiên (D-20).
7. Mục đích báo cáo (NFR-P09) và thời hạn lưu (§4); báo cáo tháng gửi chủ nhóm qua email dạng tóm tắt (D-24).
8. Quyền của bạn: xem/xuất/xóa (§5), rút lại đồng ý bất cứ lúc nào.

**Hành động:** "Đồng ý và vào nhóm" / "Không đồng ý". Lưu: người dùng, nhóm, phiên bản nội dung, thời điểm.

**Kiểm tra đầy đủ (NFR-P19, trước đây ghi tạm "NFR-P04a" — T-BA-128):** mọi trường dữ liệu cá nhân hiện cho chủ nhóm ở push "ngay", màn "Thành viên nhóm", báo cáo tháng (email tóm tắt, trong app, PDF tùy chọn) đều có trong mục 2; mọi trường hiện cho thành viên khác (thông báo thoát D-22) đều có trong mục 2b. Cách kiểm tra: lập danh sách trường từ thông báo thoát + `03-quy-tac.md` §Báo cáo §2 + API chủ nhóm/thành viên, so với mục 2/2b → khớp 100%. Thêm trường mới cho chủ nhóm mà không cập nhật mục 2 = lỗi chặn phát hành; cập nhật mục 2 → tăng phiên bản, áp "đồng ý lại" bên dưới.

**Khi nội dung đồng ý thay đổi** (ví dụ thêm trường dữ liệu chủ nhóm thấy): thành viên phải đồng ý lại trước phiên kế tiếp **(đề xuất)**.

**Rút lại đồng ý:**
- Có ở cài đặt nhóm, 2 bước xác nhận.
- Hiệu lực ngay: dừng ghi; nếu đang trong phiên thì phiên của người đó kết thúc, **không** tính là "thoát", không gửi thông báo tên (NFR-P18).
- (D-23) Rút **trước** `forfeited_at` của phiên: **không** kích hoạt mất thưởng tập thể (D-05). Rút **sau** `forfeited_at` (phiên đã mất thưởng): chuỗi của người đó **vẫn bị ngắt** — rút đồng ý không dùng để giữ chuỗi. Kiểm tra: 2 kịch bản trước/sau `forfeited_at` → kết quả chuỗi đúng như trên.
- Hệ quả: thành viên rời nhóm **(giả định, Q-20)**; sau đó có thể vào nhóm khác (D-21). Chủ nhóm chỉ nhận "X đã rời nhóm", không kèm lý do.
- Coins, đồ Shop, chuỗi, hồ sơ, nhật ký vẫn thuộc tài khoản.
- Dữ liệu phiên cũ của nhóm (sự kiện thoát, tạm dừng, giải trình, điểm danh): giữ theo thời hạn §4; **không** xóa riêng theo yêu cầu khi rời nhóm — chỉ xóa khi xóa tài khoản (NFR-P13) **(giả định, Q-20)**. Sau khi rời, chủ nhóm cũ chỉ còn thấy dữ liệu đó trong báo cáo đã/sẽ tạo cho các tháng người đó còn là thành viên.
- Chủ nhóm không "rút đồng ý" được với nhóm của mình; muốn rời thì giải tán nhóm (Q-34).

### 3. Ma trận "ai thấy gì"

Ký hiệu: ✔ thấy · ✖ không · ~ thấy một phần (ghi rõ). Cột "Chủ nhóm" chỉ áp dụng cho nhóm người đó tạo.

| Dữ liệu | Thành viên (của mình) | Chủ nhóm (nhóm mình tạo) | Quản trị | Thành viên khác (cùng nhóm) |
| --- | --- | --- | --- | --- |
| Sự kiện thoát app (ai, khi nào) | ✔ | ✔ (phiên nhóm mình) | ~ chỉ khi xử lý khiếu nại/lỗi, có ghi nhật ký truy cập **(giả định, Q-22)** | ✔ tên + thời điểm rời, gửi ngay (D-22, D-20) — cả người trong phiên và thành viên nhóm không trong phiên |
| Kết quả phiên (hoàn thành theo D-11 / mất thưởng tập thể) | ✔ | ✔ (phiên nhóm mình, từng người) | ~ tổng hợp | ~ **chỉ cấp phiên** (T-BA-71): phiên có mất thưởng tập thể không và tên người khởi phát (D-05, D-22); **không** thấy kết quả từng người (ai COMPLETED/LOST/ABSENT, số phút). Kiểm tra: API kết quả phiên gọi bằng token thành viên khác chỉ trả `forfeited`, `forfeited_by` (tên), thời điểm; không có trường trạng thái/phút của người khác |
| Vắng (ABSENT), vào muộn, mất kết nối (LOST) | ✔ | ✔ (phiên nhóm mình) | ~ như dòng sự kiện thoát | ✖ **(giả định)** — LOST không gây mất thưởng tập thể (D-19) |
| Người khởi phát mất thưởng tập thể | ✔ | ✔ (phiên nhóm mình) | ~ như dòng sự kiện thoát | ✔ (D-22) |
| Số lần gây mất thưởng / số lần thoát trong tháng | ✔ | ✔ (phiên nhóm mình) | ~ như dòng sự kiện thoát | ✖ **(giả định, NFR-P06)** |
| Thời điểm quay lại app | ✔ | ✔ (phiên nhóm mình) | ~ như trên | ✖ **(giả định)** |
| Lý do tạm dừng, thời lượng | ✔ | ✔ (Q-11) | ~ như trên | ✖ |
| Giải trình, khiếu nại và kết quả | ✔ (sửa trong 24h **(đề xuất)**) | ✔ | ~ như trên | ✖ |
| Điểm danh **trong nhóm** (số ngày, số phiên, số phút — chỉ tính phiên của nhóm đó) | ✔ | ✔ chỉ nhóm mình (D-12) | ~ số liệu tổng hợp | ✖ |
| Chuỗi ngày (`current_streak`, `longest_streak` — cấp người dùng, mọi nhóm) | ✔ | ✖ **(D-12)** — kể cả qua hồ sơ, báo cáo, API | ~ chỉ khi xử lý khiếu nại/lỗi, có nhật ký truy cập | ~ chỉ khi chính người đó tự bật hiện trên hồ sơ (D-12) — khi đó chủ nhóm cũng thấy như "thành viên khác" (cảnh báo khi bật: NFR-P17, §1) |
| Coins (số dư, lịch sử) | ✔ | ✖ **(đề xuất, Q-23)** | ~ khi xử lý lỗi | ✖ |
| Đồ Shop đã mua | ✔ | ~ đồ đang trang bị | ✔ lịch sử giao dịch | ~ đồ đang trang bị |
| Hồ sơ (tên, avatar, khung, thành tích) | ✔ | ✔ phần công khai (giống thành viên khác; dữ liệu phiên **không** xem qua hồ sơ) | ✔ phần công khai + email | ✔ phần công khai |
| Nhật ký | ✔ | ✖ | ✖ | ✖ (Q-06) |
| Báo cáo tháng (cá nhân) | ✔ phần của mình | ✔ | ✖ **(đề xuất)** | ✖ |
| Báo cáo tháng (tổng nhóm) | ✔ **(đề xuất, Q-24)** | ✔ | ✖ | ✔ **(đề xuất, Q-24)** |
| Nhật ký truy cập (ai xem dữ liệu mình) | ✔ (NFR-P07) | ✖ | ✔ | ✖ |

Ràng buộc chung:
- Chủ nhóm chỉ thấy dữ liệu **trong nhóm mình tạo và trong phiên của nhóm đó**. (D-21) Thành viên chỉ thuộc 1 nhóm nên không còn ca "một người ở nhiều nhóm"; ràng buộc chéo nhóm cũ (Q-04) (Hủy — D-21 loại bỏ trường hợp). Kiểm tra: thêm X vào nhóm thứ hai khi đang là thành viên nhóm A → bị từ chối.
- **(D-12) Chủ nhóm không thấy chuỗi, Coins** của thành viên dù chỉ có 1 nhóm. Dữ liệu cũ của X ở nhóm trước (trước khi rời và vào nhóm mới) không hiện cho chủ nhóm mới. Kiểm tra: X rời A, vào B → API chủ nhóm B không trả dữ liệu phiên của X ở A.
- **Lối vào cho dữ liệu phiên của thành viên** (sửa 2026-10-19, Q-146): lối vào **chính** là màn "Chi tiết phiên" của chủ nhóm (US-08.10, Must; mở từ thông báo thoát, danh sách phiên, báo cáo tháng) và báo cáo tháng (US-08.02); màn "Thành viên nhóm" (US-05.09, Should) là lối vào phụ khi có làm **(đề xuất, Q-146)**. Ngoài các màn này, không API/màn nào trả dữ liệu phiên của thành viên cho chủ nhóm; mỗi lần mở ghi nhật ký truy cập (NFR-P07). Mọi màn trên chỉ đọc, chỉ hiện dữ liệu sau khi phiên kết thúc / sự kiện đã được server xác nhận, không trạng thái thời gian thực, không thao tác can thiệp (BR-116, Q-144). Mở hồ sơ thành viên chỉ hiện phần công khai.
- **(S11) Ràng buộc ghi sẵn cho EP-10 Xã hội (ngoài MVP, Q-05):** khi làm EP-10, bài viết/kết bạn không tự đính kèm dữ liệu phiên, Coins, số lần thoát, chuỗi, huy hiệu; chỉ chia sẻ thành tích bằng thao tác chủ động từng lần của người viết; chủ nhóm không đọc được bài ngoài phạm vi người viết chọn; không đọc/đồng bộ danh bạ, thư mục công ty, Google Workspace, Slack để gợi ý bạn (01 §6); nhật ký vẫn riêng tư (NFR-P05). Áp BR-120. Kiểm tra: tạo bài mới → payload không chứa trường phiên/Coins/chuỗi/huy hiệu trừ khi người viết chọn đính kèm.
- Quyền tính theo cặp (người dùng, nhóm) ở server, không theo vai trò toàn cục (D-10). Kiểm tra: người là chủ nhóm A gọi API báo cáo nhóm B (nơi họ chỉ là thành viên) → 403.
- (D-25) Chủ nhóm **không tham gia phiên**: server không ghi sự kiện phiên nào cho chủ nhóm trong nhóm mình quản lý; chủ nhóm không thể là người khởi phát mất thưởng. Ràng buộc cũ "chủ nhóm tham gia phiên thì ghi như thành viên" (Hủy — D-25). Kiểm tra: chủ nhóm gọi API vào phiên của nhóm mình → bị từ chối; bảng sự kiện phiên không có bản ghi nào của chủ nhóm. Sĩ số 4–10 không gồm chủ nhóm **(đề xuất, Q-141)**.

### 4. Thời hạn lưu và xóa **(đề xuất, Q-25)**

| Dữ liệu | Lưu | Sau hạn |
| --- | --- | --- |
| Sự kiện thoát, thời điểm, lý do tạm dừng, giải trình | 13 tháng | Xóa chi tiết, giữ số đếm ẩn danh trong tổng nhóm (DynamoDB TTL) |
| Báo cáo tháng (tệp PDF tùy chọn trên S3 — D-24, Should) | 13 tháng | Xóa tệp (S3 Lifecycle) |
| Email báo cáo tóm tắt (D-24) | Không lưu bản sao phía app ngoài log gửi SES | Hộp thư người nhận do họ quản lý — app không xóa được **(giả định)** |
| Bản ghi đồng ý, nhật ký truy cập | Đến khi xóa tài khoản + 12 tháng | Xóa |
| Điểm danh/chuỗi, Coins, đồ Shop, hồ sơ | Đến khi xóa tài khoản | Xóa |
| Nhật ký | Đến khi người viết xóa hoặc xóa tài khoản | Xóa ngay, không thùng rác quá 30 ngày |
| Bản sao lưu | ≤ 35 ngày (giới hạn tối đa của RDS automated backup) | Hết vòng sao lưu thì dữ liệu đã xóa biến mất hẳn |

Xóa tài khoản: hoàn tất ≤ 30 ngày; dữ liệu trong báo cáo tổng nhóm đã phát hành giữ dạng ẩn danh **(giả định)**. Chủ nhóm xóa tài khoản → nhóm giải tán (Q-34).

### 5. Quyền của thành viên với dữ liệu của mình

| Mã | Quyền | Yêu cầu kiểm tra được |
| --- | --- | --- |
| NFR-P11 | Xem | Màn "Dữ liệu của tôi" liệt kê mọi loại dữ liệu ở cột 1 ma trận §3. |
| NFR-P12 | Xuất | Tự xuất (JSON/CSV) trong app; tệp sẵn sàng ≤ 24h, link tải hết hạn sau 7 ngày **(đề xuất)**. |
| NFR-P13 | Xóa | Xóa nhật ký từng mục ngay; xóa tài khoản theo §4. Không cho xóa riêng sự kiện thoát khi còn trong nhóm — thay bằng giải trình **(giả định, Q-20)**. |
| NFR-P14 | Sửa / khiếu nại | Gửi khiếu nại sự kiện thoát sai tới chủ nhóm; chủ nhóm đánh dấu "miễn trừ" → sự kiện không tính, Coins/chuỗi được khôi phục **cho cả phiên** (D-05) **(đề xuất, Q-37)**. |

### 6. Ghi chú pháp lý (không phải kết luận pháp lý)

- Cần đối chiếu quy định bảo vệ dữ liệu cá nhân hiện hành của Việt Nam (văn bản nào áp dụng, hiệu lực, nghĩa vụ cụ thể) với **người có chuyên môn** trước khi dùng thật.
- Điểm cần hỏi chuyên gia: dữ liệu hành vi trong giờ làm có là dữ liệu cá nhân/nhạy cảm không; vai trò bên kiểm soát/xử lý (công ty, chủ nhóm là cá nhân, nhóm phát triển) — **D-10 làm việc này phức tạp hơn** vì bất kỳ ai cũng tạo nhóm được, chủ nhóm không nhất thiết đại diện công ty; hình thức đồng ý hợp lệ trong quan hệ lao động; yêu cầu lưu trữ trong nước (AWS không có region tại Việt Nam — ảnh hưởng chọn region); thông báo khi rò rỉ.
- Nội quy văn phòng/hợp đồng lao động có thể đặt thêm điều kiện — do công ty quyết (Q-12).
- Tài liệu này chỉ nêu yêu cầu kỹ thuật hỗ trợ tuân thủ, **không** khẳng định app đã tuân thủ.

### 7. Rủi ro riêng tư còn mở

| Mã | Rủi ro | Giảm thiểu | Mức |
| --- | --- | --- | --- |
| R-P01 | Đồng ý trong quan hệ lao động có thể không thật sự tự nguyện | Cho rút lại không hệ quả ngoài rời nhóm; mục đích công bố (NFR-P09) | Cao |
| R-P02 | Phát hiện nhầm → báo oan; theo D-05 còn làm **cả phiên** mất thưởng (phạt oan nhân lên) | Khoan hồng, giải trình, khiếu nại khôi phục cho cả phiên (NFR-P14); spike khóa màn hình (NFR-P15) | Cao |
| R-P03 | Báo cáo bị dùng để kỷ luật trái mục đích | Thông báo mục đích; nhật ký truy cập | Cao |
| R-P04 | Rò rỉ nhật ký/dữ liệu cá nhân | Mã hóa khi lưu/truyền, phân quyền theo nhóm, bí mật không nằm trong mã | Trung bình |
| R-P05 | Quản trị có quyền rộng | Giới hạn theo ca xử lý + nhật ký truy cập (Q-22) | Trung bình |
| R-P06 | Nhóm nhỏ → báo cáo tổng nhóm lộ cá nhân | Tổng nhóm cho thành viên chỉ khi ≥ 5 người **(đề xuất, Q-24)** | Thấp |
| R-P07 | Chưa rõ yêu cầu lưu trữ trong nước | Hỏi chuyên gia trước khi chốt region (Q-62) | Trung bình |
| R-P08 | (Hủy — D-22 chủ động hiện tên người thoát, không còn rủi ro "đoán ra"; thay bằng R-P12.) | — | — |
| R-P12 | (D-22, D-20, D-05) Tên người thoát gửi ngay cho cả nhóm kèm việc cả phiên mất thưởng → áp lực, bêu tên, mâu thuẫn hoặc bắt nạt giữa đồng nghiệp; mâu thuẫn tinh thần GĐ1 §9; báo oan (R-P02) còn bị cả nhóm thấy | Câu 2b nổi bật ở màn đồng ý; chỉ gửi tên + thời điểm, không lý do/số đếm; LOST không bị nêu tên (D-19); khiếu nại được miễn trừ → gửi thông báo đính chính cho cùng người nhận **(đề xuất)**; câu chữ trung tính, không dùng từ phán xét **(đề xuất)**; theo dõi qua phỏng vấn (Q-08) | Cao |
| R-P10 | Nhật ký mã hóa phía server: người vận hành hạ tầng về kỹ thuật có thể giải mã | Câu chữ trung thực (NFR-P05); khóa quản lý riêng, hạn chế quyền IAM, nhật ký truy cập; E2E để sau MVP (Q-109) | Trung bình |
| R-P11 | Màn đồng ý lệch khi thêm trường mới cho chủ nhóm → đồng ý không còn đầy đủ | Kiểm tra NFR-P19 là lỗi chặn phát hành; tăng phiên bản + đồng ý lại | Trung bình |
| R-P09 | (D-10) Bất kỳ ai tạo nhóm và mời người khác → có thể dùng để giám sát không chính thức ngoài ý công ty | Đồng ý rõ + mục đích bắt buộc; thành viên rời nhóm bất cứ lúc nào; quản trị xử lý báo cáo lạm dụng (Q-63) | Trung bình |

## §NFR

Mục tiêu đặt cho MVP đồ án; số liệu tham khảo đặc tả 1.0 (nguồn cũ đã xóa) nhưng hạ quy mô cho văn phòng. Mọi ngưỡng là **(đề xuất)** trừ khi ghi nguồn chốt.

| Mã | Hạng mục | Yêu cầu đo được | Cách đo | Nguồn |
| --- | --- | --- | --- | --- |
| NFR-01 | Độ trễ thông báo thoát (push) | Người nhận push = người **không** có trạng thái chưa kết thúc trong phiên đó (BR-27): chủ nhóm, thành viên nhóm không vào phiên (vắng/không được mời), thành viên trong phiên đã kết thúc (COMPLETED/EXITED/LOST/…). Họ nhận push "X đã rời app" ≤ 5 giây (p95) sau khi server ghi EXITED (hết khoan hồng hoặc bấm "Rời phiên", D-29). Người **đang trong phiên** (FOCUSING khóa màn hình, GRACE, PAUSED) **không** nhận push hệ thống; thấy banner khi quay lại app (BR-82, D-08) — đo theo NFR-02 khi ở tiền cảnh | ≥ 3 máy thật, 30 lần, Wi-Fi văn phòng: máy 1 chủ nhóm (app nền/khóa), máy 2 thành viên ngoài phiên (app nền/khóa), máy 3 thành viên trong phiên khóa màn hình. Đo chênh thời điểm server ghi sự kiện và lúc máy 1, 2 nhận push → p95 ≤ 5 s. Máy 3: **0** push trong suốt phiên; mở khóa → banner hiện ≤ 2 s | GĐ1 §11, D-20, BR-27, BR-82 |
| NFR-02 | Độ trễ cập nhật trong app | Mọi người nhận đang mở app (chủ nhóm, thành viên trong phiên, thành viên nhóm): tên người thoát + trạng thái "mất thưởng" cập nhật qua socket ≤ 2 giây (p95) | Như NFR-01 | GĐ1 §11, D-05, D-20, D-22 |
| NFR-03 | Độ trễ phát hiện | Client gửi sự kiện rời app ≤ 1 giây sau sự kiện vòng đời (khi có mạng); server kết luận "thoát" ≤ 0,5 giây sau hết khoan hồng 3 giây | Log có dấu thời gian client/server, 30 lần mỗi nền tảng | `05-tham-chieu-ky-thuat.md` §1 |
| NFR-04 | Độ chính xác phát hiện | Rời app thật: ≥ 95% được phát hiện; khóa màn hình: 0 lần bị tính thoát (NFR-P15) | Kịch bản kiểm thử 20 lần × mỗi tình huống × mỗi nền tảng | GĐ1 §10 #1, D-08 |
| NFR-05 | Tải đồng thời | MVP chịu **100 nhóm / 1.000 kết nối socket** đồng thời trên 1 máy chủ, CPU < 70% | Thử tải (vd. k6/Artillery) mô phỏng client | đặc tả 1.0 (hạ từ 500 phòng; nguồn cũ đã xóa), GĐ1 §10 #5 |
| NFR-06 | Tải dồn đầu giờ | 100 nhóm bắt đầu trong cùng 1 phút: vào phiên ≤ 3 giây (p95), không lỗi kết nối > 1% | Thử tải kịch bản 8:00 | GĐ1 §10 #5 |
| NFR-07 | Demo tối thiểu | 1 người là chủ ≥ 2 nhóm (D-25: chủ nhóm chỉ quản lý, không tham gia phiên); 1 nhóm 4–10 thành viên, không gồm chủ nhóm **(đề xuất, Q-141)** (máy thật + mô phỏng) chạy trọn phiên 25 phút | Kịch bản demo | GĐ1 §11, D-02, D-10 |
| NFR-08 | Pin | Phiên 50 phút màn hình tắt (D-08): app tiêu ≤ 5% pin trên máy kiểm thử; không polling liên tục. Nhịp heartbeat và ngưỡng mất kết nối lấy theo `03-quy-tac.md` (BR-66, BR-19 — `heartbeat_s`, `heartbeat_timeout_s`), tài liệu này **không** đặt số riêng. Ràng buộc: khi client đang gửi heartbeat thì chu kỳ gửi phải nhỏ hơn `heartbeat_timeout_s` (không bao giờ tự chạm ngưỡng DISCONNECTED); khi client đã báo "khóa màn hình" thì server không áp ngưỡng heartbeat (BR-66) nên client được giảm/ngừng heartbeat để tiết kiệm pin **(giả định, phụ thuộc spike — Q-61, Q-86)** | Đo pin hệ thống trước/sau, 3 lần mỗi nền tảng; log server: 0 lần DISCONNECTED giả trong phiên khóa màn hình có mạng ổn định | `05-tham-chieu-ky-thuat.md` §1.5, D-08, BR-66 |
| NFR-09 | Bảo mật truyền | Mọi kết nối HTTPS/WSS TLS ≥ 1.2; không có endpoint HTTP thuần | Quét cổng + thử gọi http:// → từ chối/chuyển hướng | `05-tham-chieu-ky-thuat.md` §2, §4 |
| NFR-10 | Xác thực | Token truy cập (Cognito JWT) hết hạn ≤ 60 phút; socket kiểm tra token khi kết nối và khi làm mới | Dùng token hết hạn → bị ngắt/401 | `05-tham-chieu-ky-thuat.md` §2, §4 |
| NFR-11 | Phân quyền theo nhóm | Mọi API/sự kiện socket kiểm tra quyền theo (người dùng, nhóm) ở server; 0 lỗ hổng truy cập chéo nhóm | Bộ test IDOR: token thành viên/chủ nhóm khác gọi tài nguyên nhóm khác → 403 | D-10, §3 |
| NFR-12 | Mã hóa khi lưu | RDS, DynamoDB, S3 bật mã hóa; nội dung nhật ký mã hóa | Rà cấu hình tài nguyên | GĐ1 §10 #7 |
| NFR-13 | Bí mật | Không có mật khẩu/khóa trong mã nguồn hay ảnh build; DB/Redis chỉ nhận kết nối từ máy chủ ứng dụng (private subnet, Security Group) | Quét repo (vd. gitleaks); thử kết nối DB từ ngoài → thất bại | `05-tham-chieu-ky-thuat.md` §4 |
| NFR-14 | Sẵn sàng | 99% trong giờ hành chính (8:00–18:00, T2–T6, giờ VN); không Multi-AZ ở MVP | CloudWatch uptime check theo tháng | `05-tham-chieu-ky-thuat.md` §2, §4 |
| NFR-15a | (Hủy — mã lệch quy ước, thay bằng NFR-23, T-BA-74.) | — | — | — |
| NFR-15 | Sự cố server (D-19) | Server khởi động lại giữa phiên → phiên hủy (CANCELLED, BR-22); không ai bị ghi thoát hay mất chuỗi **do sự cố**; client báo rõ trong ≤ 15 giây. **Ngoại lệ BR-68:** người đã EXITED **trước** sự cố vẫn giữ sự kiện EXITED và bị ngắt chuỗi của **chính mình** (không ảnh hưởng người khác); người đó nhận thông báo riêng (khác thông báo hủy chung) nói rõ chuỗi bị ngắt vì đã rời app trước sự cố và có thể khiếu nại **(đề xuất, Q-123)** | Tắt tiến trình khi đang phiên, 2 kịch bản: (a) không ai thoát trước → mọi người VOID, chuỗi giữ nguyên; (b) 1 người EXITED trước → chỉ người đó mất chuỗi, nhận thông báo riêng | Q-14, Q-28, BR-22, BR-68, Q-123 |
| NFR-16 | Sao lưu / khôi phục | RPO ≤ 24 giờ, RTO ≤ 4 giờ | Diễn tập khôi phục 1 lần trước demo | (đề xuất) |
| NFR-17 | Báo cáo tháng | Tạo tự động trước 06:00 ngày 1 hàng tháng; email **nội dung tóm tắt, không đính kèm PDF** gửi tới chủ nhóm ≤ 1 giờ sau khi tạo. PDF chỉ là tùy chọn tải trong app (Should) | Chạy thủ công lịch trên dữ liệu mẫu; email nhận được không có tệp đính kèm | GĐ1 §11, D-24 |
| NFR-18 | Nền tảng | Một mã nguồn **Flutter** chạy cả iOS và Android; phiên bản tối thiểu Android 8.0 (API 26), iOS 15 **(giả định)** | Build và chạy trên cả hai | D-07 |
| NFR-19 | Thiết bị kiểm thử tối thiểu | ≥ 2 máy Android thật (2 hãng khác nhau, vì tối ưu pin mỗi hãng khác) + ≥ 1 iPhone thật; build iOS ký bằng **tài khoản Apple Developer sẵn có của nhóm** (D-18). (D-26) **Không có Mac**: build/ký IPA trên runner macOS của GitHub Actions (NFR-24), cài lên iPhone qua **TestFlight**. Có ≥ 1 iPhone thật **(giả định, Q-142)** — nếu không có, spike iOS T-01 chỉ chạy trên máy mượn/thuê (R-K01). Tính năng phát hiện thoát chỉ được coi là "xong" khi qua trên máy thật cả hai nền tảng | Danh sách thiết bị trong kế hoạch test ghi rõ model/OS iPhone; bản TestFlight cài được trên iPhone đó | GĐ1 §8, §10 #1, D-18, D-26, Q-142 |
| NFR-20 | Khả năng tiếp cận | Chữ phóng to theo hệ thống đến 200% không vỡ bố cục màn phiên/kết quả; tương phản chữ ≥ 4.5:1; mọi nút chính có nhãn đọc màn hình (TalkBack/VoiceOver); trạng thái không chỉ dựa vào màu | Kiểm tra thủ công + Accessibility Scanner/Xcode Accessibility Inspector | **(đề xuất, Q-134** — suy luận từ WCAG 2.1 AA, chưa có nguồn GĐ1) |
| NFR-21 | Ngôn ngữ, giờ | Giao diện tiếng Việt; mọi mốc ngày (chuỗi, trần Coins D-09, báo cáo) theo giờ Việt Nam (UTC+7) | Test qua nửa đêm | D-09 |
| NFR-22 | Chi phí | Có AWS Budgets cảnh báo ở 50% / 80% / 100% hạn mức nhóm đặt từ ngày đầu | Ảnh chụp cấu hình Budgets | GĐ1 §8, §10 #8 |
| NFR-23 | Mất mạng (D-19; thay NFR-15a) | Người mất mạng quá hạn → LOST; chỉ người đó không nhận Coins; phiên **không** mất thưởng tập thể, người khác giữ Coins/chuỗi | Ngắt Wi-Fi 1 máy **≥ `heartbeat_timeout_s + disconnect_hold_s`** (= 20 giây theo BR-19 mục 5) và kết thúc trước `ends_at` → server ghi LOST (không chỉ DISCONNECTED) cho máy đó; máy khác nhận đủ Coins, không có thông báo "đã rời app" | D-19, BR-19, T-BA-74 |
| NFR-24 | Build iOS không cần Mac (D-26) | (a) Build/ký IPA và đẩy TestFlight chạy trên **GitHub Actions runner macOS**; không bước nào cần Mac vật lý. (b) Chứng chỉ ký, provisioning profile, App Store Connect API key lưu ở **GitHub Secrets** (hoặc Environment secrets), **không** có trong repo hay log build. (c) Workflow iOS chạy khi **merge vào nhánh chính** và khi **kích hoạt thủ công** (`workflow_dispatch`); không chạy mỗi commit nhánh phụ để tiết kiệm phút. (d) Một lần build iOS ≤ 30 phút **(đề xuất)**; tổng phút runner macOS/tháng nằm trong hạn mức nhóm đặt. Lưu ý: với repo private, phút runner macOS bị tính theo **hệ số nhân cao** so với Linux — mức hệ số và hạn mức miễn phí **cần kiểm trên trang billing GitHub, chưa xác minh** | (a) Chạy workflow thủ công → bản mới xuất hiện trên TestFlight. (b) gitleaks + rà repo không thấy `.p12`, `.mobileprovision`, `.p8`; log build che bí mật. (c) Rà trigger trong tệp workflow. (d) Thống kê thời gian job và trang usage GitHub mỗi sprint | D-26, D-18, NFR-13 |

## Ánh xạ dịch vụ AWS

Nguyên tắc: mỗi dịch vụ làm một việc thật, truy được về tính năng. **Must cho MVP: 8 dịch vụ** (EC2, RDS, DynamoDB, Cognito, SNS, S3, CloudWatch, SES) — vượt yêu cầu ≥ 3 kể cả khi phải cắt bớt. Phương án tối thiểu an toàn nếu thiếu thời gian: **EC2 + RDS + Cognito** (3 dịch vụ, đều là lõi).

**Quy tắc Must ↔ dịch vụ (T-BA-78):** story/hạng mục Must chỉ được **phụ thuộc** dịch vụ Must. Dịch vụ Should/Could chỉ là phương án thay thế, không là điều kiện "xong":
- T-02 (hạ tầng): chỉ EC2, RDS, DynamoDB, Cognito, SNS, S3, CloudWatch, SES. TLS bằng Nginx + Let's Encrypt trên EC2; ALB/ElastiCache để sau MVP.
- US-06.03 (ảnh Shop): phụ thuộc **S3** (presigned URL/đọc công khai có kiểm soát); CloudFront là tối ưu Could.
- US-08.01 (báo cáo tháng tự động): "lịch tự động — **cron trên EC2** (Must) hoặc EventBridge Scheduler + Lambda (Should)". Đạt NFR-17 với cron EC2 là đủ.
Kiểm tra: rà backlog — không story Must nào ghi dịch vụ Should/Could là phụ thuộc bắt buộc.

| Dịch vụ | Tính năng dùng | Lý do (vì sao không dùng thứ khác) | Must cho MVP? |
| --- | --- | --- | --- |
| EC2 | Chạy server Node.js + Socket.io: phiên thời gian thực, khoan hồng 3s, heartbeat, API REST | Cần kết nối giữ lâu (WebSocket) và bộ đếm phía server; Lambda không hợp với socket giữ trạng thái | **Must** |
| RDS PostgreSQL | Người dùng, nhóm, **thành viên nhóm + vai trò theo nhóm (D-10)**, lịch, phiên, Coins, Shop, bản ghi đồng ý | Dữ liệu quan hệ, cần giao dịch (trừ Coins cả phiên theo D-05); D-04 đã chốt | **Must** |
| DynamoDB | Log sự kiện phiên (thoát/quay lại/tạm dừng), nhật ký cá nhân, nhật ký truy cập; TTL tự xóa theo §4 | D-04 đã chốt; ghi nhiều, đọc theo khóa; TTL miễn phí thay job xóa | **Must** |
| Cognito (User Pool) | Đăng ký/đăng nhập, JWT; **chỉ một nhóm Cognito "admin"**. Không tạo nhóm "trưởng phòng" — quyền chủ nhóm/thành viên kiểm tra ở server dựa trên bảng thành viên nhóm trong RDS (D-10) | Không tự viết lưu mật khẩu; vai trò theo nhóm là dữ liệu động nên không đặt trong Cognito groups | **Must** |
| SNS (Mobile Push) | (D-20, D-22) Push **ngay** "X đã rời app — phiên mất thưởng" chỉ tới người **không** có trạng thái chưa kết thúc trong phiên: chủ nhóm, thành viên nhóm không trong phiên, người trong phiên đã kết thúc (BR-27, NFR-01). Người đang trong phiên (khóa màn hình, GRACE, PAUSED) **không** nhận push — thấy banner khi quay lại app (BR-82); người đang mở app nhận qua socket (NFR-02). Không có bản gộp cuối phiên ở MVP (D-20). Danh sách endpoint tính tại lúc gửi theo trạng thái phiên **(đề xuất)**, không dùng topic cố định của nhóm | Một API cho cả APNs (iOS) và FCM (Android), hợp D-07. Vẫn cần cấu hình FCM + chứng chỉ/khóa APNs | **Must** |
| S3 | Tệp PDF báo cáo tháng tải tùy chọn trong app (D-24, Should), ảnh avatar/khung/hình nền Shop, tệp xuất dữ liệu (NFR-P12, link ký hạn 7 ngày) | Lưu tệp rẻ, Lifecycle xóa theo §4, presigned URL | **Must** |
| CloudWatch | Log ứng dụng, chỉ số kết nối/độ trễ (NFR-01…06), cảnh báo, uptime (NFR-14) | Đo được NFR; có sẵn với EC2 | **Must** |
| EventBridge Scheduler + Lambda | Tạo báo cáo tháng (ngày 1), mở phiên theo lịch chủ nhóm, chốt chuỗi cuối ngày | Việc định kỳ, không cần chạy server liên tục | Should — MVP dùng cron trên EC2 (Must) cho cùng việc; không story Must nào phụ thuộc bắt buộc |
| SES | Gửi email báo cáo tháng **dạng tóm tắt, không đính kèm PDF** cho chủ nhóm (D-24) | Tiêu chí GĐ1 §11; ở sandbox chỉ gửi tới địa chỉ đã xác minh — đủ cho demo; không đính kèm nên không cần API raw email | **Must** (D-24) |
| ElastiCache (Redis) | Trạng thái phiên đang chạy, TTL khoan hồng, pub/sub chéo instance | Chỉ cần khi > 1 instance EC2; MVP 1 instance giữ trạng thái trong bộ nhớ | Should |
| GitHub Actions (không phải AWS) | Runner macOS build/ký IPA, đẩy TestFlight (D-26, NFR-24) | Không có Mac vật lý | Must (vận hành, không tính vào ≥ 3) |
| ALB + ACM | Kết thúc TLS (wss), sticky session, mở rộng EC2 | Cần khi nhiều instance; chi phí cố định theo giờ | Should |
| Secrets Manager | Mật khẩu DB, khóa APNs/FCM | Xoay vòng bí mật; dev dùng SSM Parameter Store SecureString (miễn phí) thay thế | Could |
| CloudFront | CDN ảnh Shop | Lượng người dùng nhỏ, S3 trực tiếp là đủ | Could |
| Route 53 | Tên miền API | Có thể dùng DNS của nhà đăng ký tên miền | Could |
| AWS Budgets | Cảnh báo chi phí (NFR-22) | Bắt buộc theo GĐ1 §8; không tính là dịch vụ chức năng | Must (vận hành, không tính vào ≥ 3) |

### Lưu ý chi phí / Free Tier

- **Chính sách Free Tier đã đổi từ 15/07/2025**: tài khoản mới nhận tín dụng (gói Free có hạn) thay cho "12 tháng miễn phí" kiểu cũ. Nhóm cần kiểm tra loại tài khoản đang dùng và hạn tín dụng trên trang Billing **(giả định — cần xác minh)**; không dựa vào con số trong tài liệu này.
- Thường gần như miễn phí ở quy mô đồ án: Cognito (dưới ngưỡng MAU miễn phí), DynamoDB (on-demand, dung lượng nhỏ), SNS push, S3 vài GB, CloudWatch cơ bản, Lambda, EventBridge, SES sandbox.
- Tốn tiền theo giờ dù không dùng: **RDS, ElastiCache, ALB, NAT Gateway, Elastic IP không gắn, Secrets Manager (theo bí mật/tháng)**.
- **Phương án rẻ cho dev:**
  - 1 EC2 loại nhỏ (t3/t4g micro–small), tắt ngoài giờ làm (EventBridge/Instance Scheduler).
  - RDS single-AZ loại micro, không Multi-AZ; hoặc dev chạy PostgreSQL bằng Docker trên máy, chỉ bật RDS khi tích hợp/demo.
  - Không dùng ElastiCache/ALB ở dev; TLS bằng Nginx + Let's Encrypt trên EC2.
  - **Tránh NAT Gateway** (đắt nhất với nhóm nhỏ): RDS ở private subnet không cần NAT; dùng VPC endpoint cho S3/DynamoDB nếu cần.
  - DynamoDB Local / LocalStack để test không tốn phí.
  - Một region duy nhất (đề xuất ap-southeast-1 Singapore, gần VN) — chờ Q-62.
  - Budgets cảnh báo ở mức thấp (vd. 10–20 USD/tháng, nhóm tự chọn) ngay ngày đầu.
- **GitHub Actions macOS (D-26):** repo private → phút macOS tính hệ số cao, có thể hết hạn mức miễn phí nhanh **(chưa xác minh — kiểm trang billing GitHub)**. Giảm: chỉ build iOS khi merge nhánh chính/thủ công (NFR-24), cache pub/CocoaPods, đặt spending limit = 0 hoặc mức nhỏ; repo public thì runner chuẩn miễn phí **(giả định — cần xác minh)**.

### Rủi ro kỹ thuật

| Mã | Rủi ro | Giảm thiểu | Mức |
| --- | --- | --- | --- |
| R-K01 | (D-26) Không có Mac/Xcode → khó debug vòng đời app iOS (phát hiện thoát, khóa màn hình D-08): không xem log thiết bị trực tiếp, mỗi lần sửa phải chờ build CI + TestFlight | Log từ xa: app gửi sự kiện vòng đời kèm dấu thời gian lên CloudWatch (chỉ bản TestFlight nội bộ, chỉ trong phiên — NFR-P02); thử trên **iPhone thật** qua TestFlight (Q-142); làm spike iOS sớm ở Sprint 1 (T-01); build thủ công `workflow_dispatch` khi debug | Cao |
