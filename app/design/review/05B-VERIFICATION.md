# Đợt 05B — kiểm tra độc lập chi tiết vật phẩm

Ngày 24/10/2026. Verifier `design_arbitration`, khác agent triển khai. Đã đọc patch ban đầu của `ShopItemScreen`, `_TryOn` và helper riêng theo 05B-ITEM-DECISIONS/AUDIT. Không sửa app, không chạy Flutter hoặc browser. **CHƯA XÁC MINH HÌNH ẢNH**.

## Phát hiện chuyển sửa

| ID | Mức | Phát hiện | Trạng thái |
|---|---|---|---|
| V05B-01 | P1 | Chưa có chính sách Back khi request mua đang chờ hoặc giao dịch chưa xác nhận. Intent chỉ nằm trong state, rời màn có thể mất bộ key/giá dùng retry. | ĐÓNG SOURCE vòng 2: PopScope chặn busy; dialog unknown cho ở lại hoặc chủ động rời. Đã đọc test GoRouter thực: rời một lần về Shop root, không thêm request mua hoặc lặp dialog. Test đạt theo kết quả implementer. Không yêu cầu lưu intent bền vững. |
| V05B-02 | P2 | API mua/trang bị thành công nhưng refresh catalog lỗi khiến AsyncBody error che thông báo trạng thái bền vững; chỉ còn snackbar ngắn, khó biết giao dịch đã thành công. | ĐÓNG SOURCE vòng 2: thông báo và retry nằm ngoài AsyncBody; catalog lỗi không che trạng thái. Đã đọc test mua thành công + metadata refresh lỗi và test 320×740, text scale 1.5: thông báo bền vững, footer hiện, không có exception. Test đạt theo kết quả implementer. |

## Đã xác nhận từ source ban đầu

- Intent giữ cả itemId, expectedPrice và key, retry không tự dùng giá catalog mới. Lỗi xác định được phân loại theo mã; unknown không hứa chưa trừ Coins. Giá đổi cần xác nhận lại sau refresh.
- `_version` tăng khi itemId đổi; callback cũ kiểm mounted/version trước khi đổi trạng thái. Busy chung mua/equip, không gửi đôi. Không sửa helper equip dùng chung hoặc domain backend.
- Mua thành công đặt `_purchased`, không tự trang bị. Refresh lỗi có nội dung đúng ý nghĩa trong state, cần sửa vị trí hiển thị V05B-02. Equip cũng phân biệt API thành công với refresh lỗi.
- Balance loading/error/cache không suy thành 0 hoặc thiếu Coins, có retry; inventory unknown khóa equip. Catalog loading/error không dùng item cũ để bật footer mutation.
- Preview giữ artwork hiện hữu, tên/avatar thật; nhãn xem thử vật phẩm không giả hồ sơ đầy đủ. Card trắng/canvas trung tính, receipt thích nghi hẹp và footer nút wrap theo phạm vi màn.

## Ngoại lệ giới hạn navigation

Theo phân xử root, không xây cơ chế lưu giao dịch bền vững trong lô UI này. Sau khi người dùng chủ động rời màn qua cảnh báo, route bị thay từ bên ngoài hoặc browser reload, intent local có thể mất. Không hứa phục hồi request khi chưa có cơ chế đó. Backend ràng buộc mỗi user chỉ sở hữu/mua một item giúp ngăn tính tiền trùng cho cùng vật phẩm; không dùng điều này để khẳng định kết quả request hiện tại khi chưa xác minh.

## Cổng chốt

- V05B-01/02 đã đọc lại và đóng trong phạm vi source. Bổ sung local confirmed ownership khi ALREADY_OWNED để tránh bật lại nút mua dù catalog chưa cập nhật. Chưa phát hiện lỗi mới trong phạm vi sửa.
- Đã đọc source test cho back busy/unknown và rời chủ động, header dài ở màn hẹp/chữ lớn, expectedPrice/key bất biến qua refresh, route reuse, pending/dispose, metadata unknown, success-refresh-fail, stale CTA và busy equip.
- Implementer/root cung cấp: **25/25 tests mới đạt**; **35/35 regression đạt** trước hai bổ sung chỉ sửa test cuối; analyze 3 file sạch. Verifier không tự chạy Flutter. Root xác nhận hash phần Shop list trước scope và Inventory sau scope giữ nguyên.
- Root cung cấp: build web `ac5bc85e4e10`, HTTP preview/JS/health 200; JS SHA256 `8A898014D69B0C3380AB6A086C7115B5378EEF5F37E16AB2D3047BD97D1D1729`. Đây là bằng chứng build/phục vụ, không phải bằng chứng giao diện.
- **CHƯA XÁC MINH HÌNH ẢNH**: chưa có ảnh runtime đúng build/role/state; chưa nghiệm thu thị giác.

## Dấu vết bản kiểm cuối

Hash SHA256 được verifier đọc trực tiếp từ file sau patch cuối:

| File | SHA256 |
|---|---|
| `app/lib/features/shop/shop_screen.dart` | `A9C51CB87359670A6A8F6BB64812227215276B6C7B79767DCB2DA5BCCD52A852` |
| `app/test/shop_item_design_test.dart` | `8D0D4972E22277859619B1A5471051582E6316DB3807CC502B20BC44B097D235` |
