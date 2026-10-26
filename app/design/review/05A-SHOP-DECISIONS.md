# Đợt 05A — phân xử Shop thành viên

Ngày 23/10/2026. Phạm vi: `/shop`, header, bộ chọn loại, danh sách và card vật phẩm. Không sửa màn chi tiết mua, kho đồ, theme hoặc navigation dùng chung. Agent triển khai chỉ sở hữu phần Shop đã giao trong `shop_screen.dart` và test tương ứng. **AUDIT NGUỒN / CHƯA XÁC MINH HÌNH ẢNH**. Không truy cập browser thay thế khi công cụ trước đã bị chặn.

## Nguồn và cách chọn

- Chính: `mockup/rewards_shop/code.html` — nền xám, card trắng, preview vuông, giá và CTA tách hàng. Tham khảo `mockup/the_shop/code.html` cho trạng thái sở hữu/trang bị, không lấy bố cục giá+nút cùng hàng dễ chật.
- `app/design/design-system.html`, D02–D04 và audit `05A-SHOP-AUDIT.md` đã bàn giao. Đã đối chiếu các mâu thuẫn nguồn và rủi ro dữ liệu với reference reviewer trước khi chốt.
- Dữ liệu mockup, hành vi JavaScript giả mua và artwork 3D cũ không phải contract. Giữ AI Sakura và artwork đã chấp nhận; giữ `ItemPreview`, `previewKey` và các đường dẫn asset hiện hữu.
- Yêu cầu bỏ phụ đề “Đổi Coins lấy vật phẩm trang trí” tiếp tục có hiệu lực. Không khôi phục chỉ để khớp nguồn.

## Quyết định triển khai

| ID | Quyết định | Lý do và tiêu chí |
|---|---|---|
| SHOP01 | Canvas `#F4F5F7`, card trắng không outline; preview inset trung tính. | Theo D02. Card bo32/padding12 theo nguồn chính; preview bo20 nếu phù hợp crop asset. Không dùng viền màu cho món đang trang bị; dùng nhãn/check. Border focus vẫn được phép. |
| SHOP02 | Header Shop gọn; số Coins thật và đường tới `/coins`; “Đồ của tôi” tới `/shop/mine`. | Không thêm số dư demo420, avatar giả hoặc heading trùng lặp “Bộ sưu tập” nếu không giúp phân cấp. Số dư loading là đang tải/dấu chờ; lỗi có retry riêng, không giả0. Số lớn phải wrap/thu gọn hợp lý, giữ nghĩa và khả năng truy cập. |
| SHOP03 | Ba bộ chọn theo `itemKinds`; selected đen có check/semantics, inactive trắng. | Nguồn Shop dùng đen có chủ đích; không kết luận là control mặc định. Brand cam ở giá/Coins, không đổi toàn theme. Selected rõ ngoài màu; vùng chạm tối thiểu44px, bàn phím/focus hoạt động, cuộn ngang khi cần. |
| SHOP04 | Preview là trọng tâm; tên rõ, loại và giá thật, CTA riêng một hàng. | Giữ artwork đúng tỷ lệ, không cắt khung Sakura hay thay PNG bằng màu/text. Tên dài đọc được tối thiểu2dòng, có đầy đủ qua semantics/chi tiết. Giá không bị nút mua đè; preview linh hoạt theo cardwidth. Không rarity, giảm giá, số bán, bonus hoặc countdown giả. |
| SHOP05 | Grid thích nghi; hẹp/chữ lớn chuyển một cột nếu cần. | Không ép2cột ở320px khi nội dung hoặc text scale gây chật. Không giữ height244/284 cố định gây overflow; chiều cao theo nội dung hoặc tính đủ cho tên/giá/action lớn. Trên390/768 cân đối mật độ, không đổi asset để vừa ô. |
| SHOP06 | Dữ liệu catalog, số dư, inventory được phân biệt loading/error/data. | `me.value ??0` và `inventory.value ??[]` không phải bằng chứng thiếu Coins/chưa trang bị. Catalog vẫn có thể xem khi metadata lỗi, nhưng trạng thái/hành động chưa biết phải hiển thị đang cập nhật/khóa phù hợp, có retry. Không gọi “Thiếu Coins” khi số dư chưa tải. |
| SHOP07 | Chưa sở hữu: giá+CTA mở chi tiết, không mua ngay ở danh sách. | Dù đủ hoặc thiếu Coins vẫn được mở chi tiết. Nếu ghi “Mua” nhưng chưa đủ tiền, phải rõ đây là xem chi tiết/kiểm tra giá; ưu tiên “Xem vật phẩm” hoặc “Xem chi tiết” khi trạng thái chưa rõ. Không biến list tap thành POSTpurchase; giữ expected_price/idempotency trong luồng mua hiện tại. |
| SHOP08 | Đã sở hữu: trạng thái rõ, trang bị/gỡ thật qua API; đang dùng có check và nhãn. | Không dùng màu viền để thay status. Chờ inventory thì chưa khẳng định equipped. Tránh tap vào CTA đồng thời kích hoạt cardroute. Cho phép card mở chi tiết ngay cả khi đã sở hữu. |
| SHOP09 | Chặn gửi đôi equip trong phạm vi Shop. | Dùng busy theo loại hoặc toàn Shop để hai item cùng loại không race; disabled/loading vẫn giữ tên/status, không optimistic fake success. Chờ API, invalidate inventory/me rồi cập nhật. Lỗi giữ danh sách và cho retry, không lộ raw kỹ thuật. Nếu cần sửa helper dùng chung phải báo root; không vô tình đổi detail/inventory. |
| SHOP10 | Loading/error/empty có nghĩa và refresh được. | Phân biệt catalog rỗng với loại hiện chọn rỗng; không bỏ mất điều khiển category. Refresh tải catalog+metadata, lỗi một nguồn không giả thành công nguồn khác. Giữ lọc hiện chọn; tránh refresh làm nhảy scroll không cần thiết. |
| SHOP11 | Giữ domain/privacy và phạm vi. | Vật phẩm chỉ trang trí, không ưu thế/Coins bonus, không ranking/rarity. Shop của chính user không lộ số dư người khác. Không thêm BADGE tab khi contract chỉ AVATAR_FRAME/BACKGROUND/TITLE. Shared navigation, detailpurchase và inventory ở lô sau, ghi riêng các rủi ro hiện hữu. |

## Kiểm nghiệm chấp nhận

1. Catalog loading/lỗi/retry/rỗng; đổi đủ3loại; một loại rỗng nhưng loại khác có đồ.
2. Balance loading/error/0/đủ/thiếu/rất lớn; inventory loading/error/equipped/default; không fake0 hay trạng thái sở hữu.
3. Preview AI Sakura, khung khác, background, title; asset giữ nguyên, không thay artwork đã duyệt.
4. Card tên dài/giá lớn;320×740,390×844,768×1024 và text1.5; không overflow, CTA tối thiểu44px, vùng cuộn không bị navigation che.
5. Cardroute, Coinsroute, inventoryroute đúng; trang bị/gỡ thành công/lỗi/busy; hai tap nhanh hoặc hai item cùng loại không gửi đôi. Danh sách không gọi purchase trực tiếp.
6. Kiểm độc lập bằng source và test trước; ảnh runtime đúng build/role/state mới nghiệm thu thị giác. Không ép PASS khi thiếu ảnh. Không thay browser để né hạn chế công cụ.

## Rủi ro ngoài phạm vi cần giữ hồ sơ

`ShopItemScreen._buy` hiện có lỗi mạng mà copy cam kết “Coins không bị trừ”, dù kết quả giao dịch có thể chưa xác định; catch cũng cần kiểm mounted nếu điều hướng khỏi màn trong request. Đây là lô chi tiết mua, không tự sửa chung trong05A. `InventoryScreen` và helper equip dùng chung chưa có cùng cơ chế busy; ghi riêng nếu root mở rộng phạm vi, không tuyên bố toàn bộ Shop flow đã được sửa từ lô danh sách.
