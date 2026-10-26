# Đợt 05B — chi tiết vật phẩm và xác nhận mua

Ngày 24/10/2026. Phạm vi: `ShopItemScreen`, `_TryOn` và helper riêng cho hai phần này trong `shop_screen.dart`; test tương ứng. Không sửa danh sách Shop, inventory, helper dùng chung, backend hoặc API contract. Agent triển khai và verifier là hai người khác nhau. **ĐÃ PHÂN XỬ NGUỒN / CHƯA XÁC MINH HÌNH ẢNH**. Không dùng browser khác để né hạn chế truy cập UI.

## Nguồn và ngoại lệ

Đã đọc README, DECISIONS, BACKLOG, hai prompt arbiter/verifier, source và phản hồi reference reviewer. Nguồn chính `mockup/s_02_chi_ti_t_v_t_ph_m_v_x_c_nh_n_mua/code.html`; token theo HTML design system và D02–D04. Giữ phân cấp hero, thử vật phẩm, thông tin sở hữu, biên nhận và footer; bỏ chữ giải thích trạng thái mẫu, số dư/giá demo và artwork cũ thay thế AI đã chấp nhận.

Mockup mâu thuẫn ở hai điểm: lỗi mạng hứa Coins không bị trừ, trong khi request có thể đã hoàn tất; “kích hoạt ngay” mâu thuẫn toast yêu cầu trang bị riêng. Theo giao dịch thật: kết quả chưa rõ phải kiểm tra/retry đúng ý định; mua lưu vào kho, trang bị là hành động riêng. Các rủi ro từ 05A nay thuộc phạm vi sửa của 05B.

## Quyết định và tiêu chí

| ID | Quyết định | Tiêu chí cụ thể |
|---|---|---|
| ITEM01 | Bề mặt đồng bộ Shop, không thay toàn theme. | Canvas `#F4F5F7`, card trắng không outline, inset trung tính; primary đen có chủ đích, Coins màu thương hiệu. Header gọn, back đúng route; không thêm avatar giả. |
| ITEM02 | Hero và preview dùng nội dung thật. | Tên dài wrap, loại đúng contract; AI Sakura và asset khác giữ nguyên. Preview lớn, đúng tỷ lệ, không crop ornament. `_TryOn` hiện chỉ áp món đang xem, không compose mọi trang bị: nhãn “Xem thử vật phẩm”, không hứa đây là hồ sơ hoàn chỉnh. Tên/avatar chỉ từ me thật; loading/error không fake tên hay ảnh người dùng. |
| ITEM03 | Mua, sở hữu và trang bị là các trạng thái riêng. | Chưa sở hữu: xác nhận mua theo giá hiện tại. Đã sở hữu: trang bị; đang dùng: gỡ. Sau mua không tự equip hoặc hứa kích hoạt ngay. Nhãn sở hữu có thể dựa catalog hoặc inventory đã xác minh; equipped chỉ từ inventory. |
| ITEM04 | Metadata chưa biết không thành số 0 hoặc trạng thái mặc định. | Balance loading/error/cache cũ hiển thị tương ứng, có retry; cachedAt không null ghi chưa cập nhật, không kết luận thiếu Coins hoặc cho xác nhận mua dựa số cũ. Inventory loading/error khóa equip/gỡ, không đoán đang dùng. Số dư thật 0 vẫn hợp lệ. Catalog loading/error/refresh không dùng item cũ để mở footer mutation. |
| ITEM05 | Biên nhận và chính sách rõ trước xác nhận. | Giá niêm yết, số dư đã xác minh và phần còn lại sau mua chỉ tính khi đủ dữ liệu; thiếu hoặc unknown dùng dấu chờ/không đủ, không số âm. Giữ “Không hoàn Coins sau khi mua” trước CTA. Vật phẩm trang trí, không ưu thế hoặc bonus. Không thêm ưu đãi, độ hiếm, hạn giả; vĩnh viễn chỉ theo chính sách hiện hữu. |
| ITEM06 | Một thao tác mutation tại một thời điểm. | Busy chung cho mua/equip/gỡ; chặn tap đôi và thay hành động khi request chưa chốt. Capture API trước await; mọi ref/setState/navigation sau await phải kiểm mounted. API trả thành công mới thông báo, cập nhật providers thật; lỗi giữ nội dung và cho kiểm tra/retry. Không sửa helper equip dùng chung để kéo thay đổi sang inventory/list. |
| ITEM07 | Ý định mua bất định phải bất biến. | Giữ trọn `{itemId, expectedPrice, idempotencyKey}` khi network/timeout/lỗi không xác định. Retry dùng cả ba giá trị cũ, kể cả catalog refresh đổi giá. Cùng key nhưng body khác vi phạm backend `IDEMPOTENCY_MISMATCH`. Không tự tạo key mới, không tự chuyển thành mua lần hai sau lỗi bất định. UI nêu “Chưa xác nhận được giao dịch. Kiểm tra lại hoặc thử lại cùng giao dịch”, không hứa chưa trừ Coins. |
| ITEM08 | Lỗi nghiệp vụ xác định xử lý theo mã, không suy từ mọi HTTP status. | PRICE_CHANGED: tải lại giá rồi cần xác nhận giá mới, cho reset intent sau kết quả xác định. ALREADY_OWNED: refresh quyền sở hữu, chuyển về trạng thái thật. INSUFFICIENT_COINS: refresh balance, không giả số thiếu. ITEM_UNAVAILABLE: ngừng mua, có back. Lỗi chung dùng copy an toàn; không hiện raw message hoặc hứa refund. Không tự retry POST bằng key mới. |
| ITEM09 | Refresh sau request không đổi ý nghĩa kết quả đã biết. | Mua/equip thành công nhưng metadata refresh lỗi phải nói đã xử lý, chưa cập nhật được trạng thái; không gọi giao dịch thất bại hoặc khuyến khích mua lần nữa. Giữ intent bất định qua pull-to-refresh; không silently xóa trạng thái chờ xác minh. Chỉ mở mutation tiếp khi đủ quyền/dữ liệu mới. |
| ITEM10 | Footer và nội dung thích nghi màn nhỏ. | Footer SafeArea, nút ít nhất44px, label wrap; không che chính sách, lỗi hoặc dòng giá. Receipt label/value stack khi hẹp/chữ lớn. Preview và text không overflow ở320×740,390×844,768×1024, text1.5. Loading skeleton, lỗi+retry, không tìm thấy có back; không giữ CTA stale phía dưới lỗi. |
| ITEM11 | Phạm vi riêng, bảo toàn luồng thật. | Giữ purchase expected_price/idempotency; equip qua API, Coins chỉ của user hiện tại. Không POST khi chỉ mở preview. Inventory/list ngoài đợt giữ nguyên; shared component nếu bắt buộc phải báo root trước. Không tuyên bố toàn bộ flow đã hoàn thiện từ một màn. |

## Kiểm tra bắt buộc

1. Ba loại preview và AI Sakura; tên dài, thiếu avatar/name, metadata loading/error/cache/0.
2. Item chưa sở hữu/đã sở hữu/đang dùng; catalog loading/error/missing/unavailable; không mutation stale.
3. Mua thành công, thiếu tiền, đã sở hữu, đổi giá cần xác nhận lại, item ngừng bán; sau mua không auto equip.
4. Timeout rồi retry giữ cả key và expectedPrice; refresh đổi catalog giá không đổi body intent; không có copy “Coins không bị trừ” ở lỗi bất định.
5. Thành công API nhưng refresh lỗi; busy tap đôi; equip/gỡ đúng trạng thái; dispose trong API pending và trong refresh không dùng ref/setState sau dispose.
6. Route/back, SafeArea, scroll/footer, text1.5 ở320/390/768; kiểm source/test riêng ảnh runtime. Chưa có ảnh đúng build thì ghi CHƯA XÁC MINH HÌNH ẢNH.
