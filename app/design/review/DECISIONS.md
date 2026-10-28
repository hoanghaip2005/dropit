# Phân xử khác biệt thiết kế

28/10/2026 — [Đăng ký](10-REGISTRATION.md): yêu cầu mới thay giới hạn chỉ tài khoản được cấp. Tái sử dụng login hiện tại vì mockup không có signup riêng. Chọn tạo/tham gia nhóm là ý định onboarding; quyền vẫn theo quan hệ backend. Cognito xác minh email, không bypass. Giữ shop artwork hiện có; bổ sung catalog production riêng, không chạy demo seed.

Ngày: 22/10/2026. Trạng thái: **SOURCE_AUDIT — chưa nghiệm thu thị giác**.

Tài liệu ghi yêu cầu, ngoại lệ và điểm cần đối chiếu. “Chấp nhận” bên dưới là chấp nhận yêu cầu hoặc quy tắc; không xác nhận màn hiện tại đã đạt. Build, analyze và test không thay thế ảnh đối chiếu.

## Thứ tự nguồn

1. Yêu cầu hiện tại của người dùng và ngoại lệ đã được duyệt rõ ràng.
2. Quy tắc nghiệp vụ, quyền riêng tư, quyền truy cập, dữ liệu thật và khả năng API hiện tại.
3. Quyết định riêng của màn đã có bằng chứng và người duyệt.
4. Thư viện HTML cùng màn Stitch phù hợp đúng vai trò, trạng thái.
5. Biến thể Stitch cũ và tài liệu lịch sử.

Không lấy metadata dark của project làm chuẩn cho màn sáng. Không mặc định mọi khác biệt đều là lỗi. Stitch là tham chiếu bố cục và ngôn ngữ thị giác; nội dung mẫu cũ không phải yêu cầu sản phẩm.

## Sổ quyết định

| ID | Trạng thái | Quyết định | Nguồn và lý do | Tác động / bằng chứng còn thiếu |
|---|---|---|---|---|
| D01 | CHẤP NHẬN | Đối chiếu từng màn; không sao chép Stitch 100%. | Yêu cầu mới nhất: cần agent đánh giá rồi kiểm tra lại các điều chỉnh. | Mỗi sai khác phải được phân loại và ghi lý do trước khi sửa. |
| D02 | CHẤP NHẬN YÊU CẦU / TOKEN THAM CHIẾU | Nền trung tính được làm kỹ; card không có outline mặc định. Token triển khai tham chiếu: canvas `#F4F5F7`, card trắng. | Người dùng phản hồi nền và outline; mã màu lấy từ `STITCH_DESIGN_SYSTEM.md`, không phải lời duyệt riêng từng mã màu của người dùng. Spec mới thay quyết định nền kem cũ. | Cần ảnh màn thực để kiểm tra cả vùng cuộn, inset, modal; không xóa viền input/nút phụ theo quy tắc card. |
| D03 | CHẤP NHẬN | Giữ khung Sakura AI và artwork đã được duyệt. | Người dùng nêu khung hoa đào đúng ý. | Không thay artwork chỉ để khớp mockup cũ. Không suy rộng thành duyệt mọi item. |
| D04 | CHẤP NHẬN | Bỏ mô tả shop “Đổi Coins lấy vật phẩm trang trí”, giải thích nhóm “Bạn chỉ thuộc 1 nhóm thành viên tại một thời điểm.”, email trong hero hồ sơ. | Các đánh dấu “bỏ” của người dùng; lịch sử yêu cầu. | Kiểm tra bản hiện tại đã bỏ đúng vị trí, không xóa dữ liệu tài khoản hoặc quy tắc nhóm. |
| D05 | CHẤP NHẬN | Không hiển thị mục đích sử dụng trên báo cáo; giảm nội dung giải thích dài. | Người dùng yêu cầu trực tiếp ở màn báo cáo. | Giữ trường backend và luồng đồng ý cần thiết; không tự bỏ consent. |
| D06 | CẦN BẰNG CHỨNG | Phân xử primary đen hoặc cam theo màn và ngữ cảnh. | Từng có phản hồi control đen mặc định; HTML mới có biến thể đen Stitch/cam thương hiệu. | Không kết luận mọi nút đen đều sai hoặc mọi nút đen đều đã duyệt. Chụp cả phương án liên quan nếu cần quyết định. |
| D07 | CẦN BẰNG CHỨNG | Theme khác nhau giữa chủ nhóm và thành viên chưa phải quyết định thiết kế đã duyệt. | Spec mới mô tả `ownerOnlyProvider`; tài khoản hai vai trò dùng theme thành viên. | Đây là trạng thái triển khai. Cần so cùng vai trò; đánh giá tác động token dùng chung trước khi sửa. |
| D08 | CHẤP NHẬN | Ưu tiên audit lịch sử phiên thành viên và kết quả rời sớm. | Phản hồi gần nhất trước yêu cầu quy trình: session history chưa giống, hỏi left early result. | Không tiếp tục máy móc hàng đợi owner cũ; lập baseline hai màn này trước. |
| D09 | CHẤP NHẬN | Giữ khác biệt `EXITED`, `LOST`, `ABSENT`, `VOID`, hoàn thành mất thưởng. | `ResultCopy` và nghiệp vụ hiện tại. | Có thể rút gọn trình bày; không gom thành một trạng thái “thất bại”. Hành động khiếu nại phải theo dữ liệu thật. |
| D10 | TỪ CHỐI | Thêm tính năng/số liệu mẫu cũ chỉ vì có trên Stitch. | Domain/API hiện tại có ưu tiên cao hơn mockup. | Không tự thêm export/PDF/social, avatar giả, tỷ lệ tổng hợp không có dữ liệu; không lộ Coins/streak thành viên cho chủ nhóm. |
| D11 | TỪ CHỐI | Nghiệm thu thị giác bằng source/test/build hoặc ảnh bản cũ. | Quy trình kiểm chứng thị giác; yêu cầu kiểm tra độc lập. | Phải có ảnh đúng build, route, vai trò và trạng thái. |
| D12 | CẦN BẰNG CHỨNG | Font, icon, radius, spacing và hiệu ứng của từng màn. | Source chỉ cho biết ý định triển khai. | Không tuyên bố khớp khi chưa có ảnh cặp và kiểm tra tương tác. |

## Mâu thuẫn tài liệu cần phân xử

| Chủ đề | `DESIGN_SYSTEM.md` cũ | `STITCH_DESIGN_SYSTEM.md` mới | Xử lý |
|---|---|---|---|
| Nền/card | Kem, viền sand | Xám `#F4F5F7`, card trắng không viền | Theo D02; tài liệu cũ không còn làm chuẩn phần này. |
| Primary | Terracotta | Đen; HTML có biến thể cam | Theo D06, không đổi hàng loạt thiếu đối chiếu. |
| Navigation | Trắng cho cả hai vai trò | Tối cho owner, thành viên giữ hiện trạng | Theo D07; cần quyết định rõ theo màn/vai trò. |
| Bo góc nhóm | 24 | Hero 32, card thường 16 | Chọn theo loại component và ảnh tham chiếu cụ thể; chưa có visual pass. |
| Tiến độ | Dễ bị trình bày như số mặc định | Không có dữ liệu phải là null, không phải 0 | Giữ ý nghĩa dữ liệu; kiểm tra riêng, không bịa tỷ lệ. |
| Thứ tự triển khai | `OWNER_VIEW_PLAN.md` tập trung owner | Phản hồi mới tập trung thành viên | D08 ưu tiên; các ghi chú “đã triển khai” trong plan không đồng nghĩa đã nghiệm thu. |

## Cách phân xử một khác biệt

1. Ghi mã màn, vai trò, route, viewport, seed/trạng thái, build và nguồn mockup chính xác. Chụp app và tham chiếu tương ứng.
2. Phân loại: lỗi triển khai; thích nghi nghiệp vụ có chủ đích; tham chiếu lỗi thời; hoặc chưa đủ bằng chứng.
3. Ghi đề xuất kèm nguồn, lý do, tác động tới component dùng chung, quyền riêng tư và hành vi. Không tự ghi “người dùng đã duyệt”.
4. Chỉ sửa phạm vi đã xác định. Giữ các ngoại lệ D03–D05 và ngữ nghĩa D09. Không đổi token toàn app để giải quyết một màn mà chưa rà tác động.
5. Người kiểm tra độc lập đối chiếu lại ảnh và tương tác sau sửa. Kết quả: đạt, cần sửa, hoặc chưa đủ bằng chứng; ghi người kiểm tra và đường dẫn bằng chứng.
6. Chưa đủ bằng chứng thì giữ mở. Không dùng phần trăm “giống mockup” thay cho danh sách sai khác cụ thể.

Mỗi bản ghi riêng của màn cần: ID sai khác, nguồn, ảnh trước/sau, quyết định, lý do, file tác động, người sửa, người kiểm tra, kết quả và điểm còn mở.

## Bộ trạng thái cần kiểm tra trước

### Yêu cầu bổ sung lịch sử — 22/10/2026

Yêu cầu người dùng mới ưu tiên hơn giới hạn N-10 cũ. Đợt sửa đầu chưa bao phủ đủ màn; đóng findings source trước đó không đồng nghĩa đủ chức năng.

- Badge loại phiên: hiển thị Cá nhân với mode `SOLO`, Squad với `SQUAD`; không suy mode từ tên nhóm trống hoặc số người tham gia. Backend hiện chỉ có phiên nhóm, trả `SQUAD`; chưa triển khai engine học cá nhân trong đợt UI này.
- Badge thời gian: dùng `focus_seconds` thực tế; trạng thái hoàn thành/rời sớm/mất kết nối riêng. Giờ rời/kết thúc lấy `exited_at`/`ended_at`, null phải hiện thiếu thời điểm hoặc bỏ nhãn, không tính từ giờ lịch. Thay quyết định H06 giữ giờ dự kiến ở đợt đầu.
- Có tab Ngày/Tuần/Tháng và chọn ngày. Phạm vi truy vấn backend theo ngày VN `[from,to)`; tải mọi trang trong kỳ trước khi đưa tổng, tránh chọn ngày cũ nhưng chỉ tìm trong 50 phiên mới nhất.
- Banner Thưởng hôm nay độc lập với ngày đang xem, tổng `SESSION_REWARD` theo ngày thưởng VN và cap cấu hình thật. Không dùng balance hoặc cộng trang đầu; loading/lỗi không giả số 0.
- Kiểm lại checklist này độc lập, không chỉ kiểm màu và font. Duyệt source không thay bằng chứng hình ảnh/runtime.

- Lịch sử thành viên: có dữ liệu, rỗng, tải, lỗi; tên dài; tuần/tháng; `COMPLETED` có thưởng/mất thưởng, `EXITED`, `LOST`, `ABSENT`, `VOID`. Kiểm tra phạm vi bộ lọc danh sách so với số tổng; hiện chỉ là điểm cần audit source, chưa xác nhận lỗi.
- Kết quả rời sớm: mở sau phiên và từ lịch sử; phân biệt chủ động rời với mất kết nối quá hạn; thưởng/ảnh hưởng nhóm đúng dữ liệu; hành động quay lại, về trang chủ và khiếu nại đúng trạng thái.
- Sau hai màn trên: hồ sơ, nhóm rồi các màn thành viên còn lại theo danh sách sai khác có bằng chứng. Không coi thứ tự này là nghiệm thu các màn owner trước đó.

### Shop thành viên — 23/10/2026

Người dùng phản hồi chưa thấy thay đổi trong flow thành viên, đang mở Shop. Ưu tiên đợt [05A — Shop](05A-SHOP.md), theo [phân xử riêng](05A-SHOP-DECISIONS.md). Canvas trung tính, card trắng không viền; bố cục preview lớn từ `rewards_shop`, trạng thái từ `the_shop`. Selected filter và CTA đen có nguồn thiết kế cụ thể; Coins màu thương hiệu. Quyết định chỉ áp dụng Shop, không tự đổi control toàn app.

Giữ artwork AI và ngoại lệ bỏ subtitle. Balance/kho đang tải, lỗi hoặc cache cũ không được biến thành số 0 hay trạng thái chưa trang bị. Mua vẫn mở chi tiết xác nhận; trang bị trên danh sách phải chống request lặp. Chi tiết mua, kho đồ, hồ sơ và thành tích được triển khai theo đợt riêng; không coi Shop list là toàn bộ flow thành viên đã hoàn thiện.

### Chi tiết vật phẩm — 24/10/2026

[Đợt 05B](05B-ITEM.md) sửa riêng chi tiết và xác nhận mua theo [phân xử ITEM01–11](05B-ITEM-DECISIONS.md). Giữ cấu trúc preview/thông tin/biên nhận/footer của s_02, artwork AI và bề mặt đồng bộ Shop. Thay hai copy mẫu sai nghiệp vụ: mất phản hồi chỉ là chưa xác nhận được giao dịch; mua lưu quyền sở hữu, trang bị là thao tác riêng. Retry giao dịch bất định giữ nguyên item, expected price và idempotency key, không gửi body mới cùng key. Không đổi backend, kho đồ hoặc theme chung.

### Đăng nhập production — 24/10/2026

Ưu tiên mới: bỏ đăng nhập mock, theo [phân xử LOGIN01–10](08-LOGIN-DECISIONS.md). Giữ canvas trung tính, nhận diện DropIt!, form thật và trạng thái lỗi/loading/accessibility. Không seed list, dev token fallback, control đăng ký/reset/ghi nhớ giả. Auth Cognito do root chốt theo architecture; nếu dùng Hosted UI, thích nghi thành CTA chuyển trang thay vì form mật khẩu giả. UI scope chỉ LoginScreen/helper riêng; verifier độc lập kiểm source auth/security sau triển khai, không coi test đạt là nghiệm thu hình ảnh.

### Control theo vai trò và mất quyền nhóm — 28/10/2026

Đợt [11](11-GROUP-CONTROLS-SESSION.md): giữ owner đen/chữ trắng, member cam/chữ đen; ghép foreground theo theme thay màu cố định. Mất quyền nhóm trả thông báo trung tính và lối về nhóm, giữ phân biệt lỗi mạng. Không mở rộng kết luận sang toàn bộ giao diện.
