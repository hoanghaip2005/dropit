# Đợt 05B — Chi tiết vật phẩm và xác nhận mua

Ngày: 24/10/2026. Trạng thái: **ĐÃ TRIỂN KHAI, KIỂM CHÉO SOURCE / CHƯA XÁC MINH HÌNH ẢNH**.

Tiếp tục luồng thành viên sau danh sách Shop. Phạm vi một view `/shop/item/:id`: preview, thông tin sở hữu, giá/số dư, xác nhận mua, trang bị/gỡ và các trạng thái tải/lỗi.

## Sở hữu

- `/root/implementation_audit`: chỉ `ShopItemScreen`, state và `_TryOn` trong `app/lib/features/shop/shop_screen.dart`; test mới `app/test/shop_item_design_test.dart`.
- `/root/design_reference`: audit nguồn/app theo prompt, `05B-ITEM-AUDIT.md`.
- `/root/design_arbitration`: phân xử `05B-ITEM-DECISIONS.md`, kiểm độc lập `05B-VERIFICATION.md`.
- Root điều phối, kiểm regression legacy, build và hồ sơ. Không đổi backend, dữ liệu thật, artwork, theme chung hoặc kho đồ.

## Nguồn và baseline

- `mockup/s_02_chi_ti_t_v_t_ph_m_v_x_c_nh_n_mua/code.html`, `app/design/design-system.html`; giữ AI Sakura và render artwork hiện tại.
- Tái sử dụng audit 05A về unknown/cache balance, inventory, pending/mounted và copy mua không đồng nghĩa trang bị.
- Prefix trước `/// V-31` SHA256 UTF-8: `F7835A1F21C3F62CF9CAC299C4F1D8B816E83BCCFE9F2AA487FD873FE774900C`.
- Tail từ `/// Đồ của tôi` SHA256 UTF-8: `E82A2EE606413AC572A2D0C5702B1FAA1E46DC10AE319B3DD7A869D72934CCC7`. Hai vùng ngoài phạm vi phải giữ nguyên.
- Web trước đợt: `f950dce84bc6`. Chưa có ảnh runtime hợp lệ; không thay công cụ để vượt hạn chế UI đã gặp trước đó.

## Kiểm nghiệm bắt buộc

Canvas trung tính/card trắng không outline, preview giữ tỷ lệ và artwork; 320/390/768, chữ 1.5, tên/số lớn, CTA cuộn/đọc đủ. Loading/error/missing item; số dư unknown/cache không thành 0; inventory unknown không suy trang bị. Mua giữ expected price và idempotency; retry lỗi chưa rõ phải giữ cùng item, giá và key. Giá đổi cần xác nhận lại. Mua thành công và refresh lỗi phải phân biệt. Không hứa Coins chưa bị trừ khi mất phản hồi. Busy và dispose an toàn cho mua/trang bị; không giả tự trang bị sau mua.

## Kết quả

- [Audit](05B-ITEM-AUDIT.md) và [phân xử](05B-ITEM-DECISIONS.md) đã chốt; triển khai ITEM01–11.
- Mockup có hai nội dung cần thích nghi: lỗi mất phản hồi không chứng minh Coins chưa trừ; mua không tự trang bị. Giữ cấu trúc preview/thông tin/biên nhận/footer, thay copy theo API thật.
- Đã sửa canvas trung tính/card trắng, preview thật có nhãn xem thử, tên wrap, receipt thích nghi màn hẹp và footer đen với label xuống dòng. Không đổi artwork hay theme toàn app.
- Dữ liệu số dư loading/error/cache cũ không thành 0; inventory unknown không suy đang dùng; catalog đang tải/lỗi không bật CTA stale. Có retry và trạng thái sở hữu riêng với trang bị.
- Một busy guard cho mua/equip/gỡ; mounted và version guard khi dispose/đổi itemId. Unknown retry giữ item/giá/key bất biến; PRICE_CHANGED tải lại rồi cần xác nhận mới. ALREADY_OWNED và mua thành công được giữ xác nhận cục bộ để không mời mua lại khi tải lại lỗi.
- Thông báo kết quả nằm ngoài AsyncBody, vẫn thấy khi catalog refresh lỗi. API thành công khác lỗi tải metadata; không hứa Coins chưa trừ khi mất phản hồi.
- Back tạm chặn khi request đang chờ; giao dịch chưa xác nhận có cảnh báo và quyền rời rõ. Intent chỉ giữ trong state màn, không lưu bền vững qua reload/điều hướng bên ngoài; không hứa khôi phục giao dịch sau khi rời.
- [Kiểm tra độc lập](05B-VERIFICATION.md) đóng hai findings source sau sửa: back chưa xác nhận và thông báo thành công bị che khi catalog lỗi.
- 25/25 tests mới đạt; 35/35 regression (Shop list, features, local_gaps) đạt trước hai bổ sung chỉ thay test. Analyze screen, test mới và features_test: sạch. Tests gồm GoRouter back thực, thông báo dài ở 320px, metadata/cache, immutable retry, price change, pending/dispose, equip và chữ 1.5 ở 320/390/768.
- Root chỉnh một assertion legacy sang FilledButton để vẫn kiểm nút thiếu Coins bị khóa; xóa import không còn dùng. Prefix Shop và tail Inventory khớp hash baseline. Diff check sạch, chỉ cảnh báo chuẩn hóa line ending ở test legacy.
- Source SHA256 `shop_screen.dart`: `A9C51CB87359670A6A8F6BB64812227215276B6C7B79767DCB2DA5BCCD52A852`.
- Không có ảnh app đúng build/trạng thái: **CHƯA XÁC MINH HÌNH ẢNH**. Widget tests không thay runtime browser/Android. Không đổi dữ liệu thật/backend.
- Web release build thành công (`API_BASE_URL=http://localhost:3000`); preview `ac5bc85e4e10`: http://127.0.0.1:8080/_preview/ac5bc85e4e10/#/shop . Mở một vật phẩm để xem màn chi tiết mới. Preview, JavaScript và backend health HTTP 200. Hai dịch vụ local đã được bật lại vì trước kiểm tra đều không hoạt động.
- SHA256 `build/web/main.dart.js`: `8A898014D69B0C3380AB6A086C7115B5378EEF5F37E16AB2D3047BD97D1D1729`; test mới: `8D0D4972E22277859619B1A5471051582E6316DB3807CC502B20BC44B097D235`.
- Compiler còn cảnh báo dry-run Wasm `socket_io_common` và font Cupertino; bản JavaScript release thành công. Không dùng build/test làm nghiệm thu hình ảnh.
