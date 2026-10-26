# Đợt 05A — audit nguồn Shop thành viên

Ngày: 23/10/2026. Auditor: `/root/design_reference`. Route: `/shop`, vai trò thành viên. Phạm vi triển khai đề xuất: danh mục Shop, header/số dư, bộ lọc, card vật phẩm và thao tác trang bị trên card. Chi tiết mua và kho đồ được đọc để xác định phụ thuộc; không mặc định mở rộng đợt này sang hai màn đó.

**CHƯA XÁC MINH HÌNH ẢNH.** Chỉ đọc nguồn; chưa có ảnh app đúng build, role, viewport và trạng thái. Không dùng browser hoặc công cụ khác để né hạn chế truy cập UI. Findings về mã được phân biệt với nguy cơ cần tái hiện.

## 1. Nguồn đã đọc và nhận diện

| Nguồn | SHA256 | Vai trò |
| --- | --- | --- |
| `mockup/rewards_shop/code.html` | `44C1CD418BE444F9FC50EE0AEA8575DCC067092A7BFB58C9691E27CD5716EE8A` | Bố cục Shop, card preview, giá, CTA và trạng thái đang dùng |
| `mockup/the_shop/code.html` | `2C3D560BB339643C1A9C7BEC1017CED7E1692925C0E213DCE5CD6D19C25D3C23` | Biến thể header, số dư, card compact, owned/equipped |
| `app/design/design-system.html` | `11AD6BB9D68A6C7ABD34AEE9E7533FFD02A68F5E19B974E13A492751460D8C05` | Token, bề mặt, control, focus, motion |
| `app/lib/features/shop/shop_screen.dart` | `2650D94D64DF73F50279831021C6E87FB3FE34A9672BE6DBEEFEAA431CBD503E` | Baseline app được audit; chưa phải nhận diện build đang phục vụ |

Đã đọc prompts `reference-reviewer.md`, `app-auditor.md`, README, DECISIONS, BACKLOG; đối chiếu `AppScaffold`, `AppCard`, `FilterChipPill`, `CoinChip`, `ItemPreview`, tokens và provider/models. Không tải ảnh từ xa trong HTML. Artwork chỉ được nhận diện qua tham chiếu source, chưa đánh giá chất lượng ảnh thực.

## 2. Chọn nguồn và điểm cần phân xử

Hai HTML cùng có nền `#F4F5F7`, card trắng, grid hai cột ở mobile, filter ba loại, giá bằng Coins, trạng thái mua/sở hữu/đang dùng. Dùng ngôn ngữ thị giác này cùng D02; không lấy kem/viền cũ làm chuẩn cho thành viên chỉ vì theme hiện tại đang như vậy.

| Chủ đề | Khác biệt nguồn | Đề xuất cho arbiter |
| --- | --- | --- |
| Header | Cả hai có Shop/số dư; `the_shop` lặp số dư ở thanh trên và header; app có “Bộ sưu tập” thêm một hàng | Một tiêu đề Shop, một số dư thật, đường “Đồ của tôi” rõ. Không sao chép số dư lặp hoặc icon thông báo không có mục đích ở màn này. |
| Card | `rewards_shop`: preview vuông, giá một hàng, CTA rộng bên dưới; `the_shop`: giá và Mua cùng hàng | Ưu tiên độ rõ tại 320px/chữ lớn; CTA riêng dễ đọc hơn. Arbiter chốt một biến thể, không ghép tùy tiện theo từng item. |
| Radius/type | Cả hai card `rounded-lg` =32px, padding12, preview20px; title16 đậm ở rewards,18 ở the_shop | Dùng radius theo loại card đã chọn; thử title14–16/2 dòng nếu cần để giữ tên tiếng Việt. Không tăng toàn bộ card thường trong app lên32. |
| Selected filter | Hai mockup dùng nền đen; thư viện có cam mềm kèm dấu chọn | Chốt riêng Shop. Giữ semantics selected và dấu hiệu ngoài màu. Đen không tự động là lỗi; cũng không mặc định đã được người dùng duyệt. |
| Navigation | Nguồn dùng bốn item, màu active trắng hoặc cam, nền `#1A1A1A`/`#1C1C1E` | Shell hiện hành ngoài scope; không thêm social-feed/Home giả hoặc đổi nav toàn app vì màn Shop. Kiểm clearance trên shell thực. |
| Artwork/copy | Nguồn dùng ảnh 3D, số dư420/850, giá/tên mẫu, JS mua/trang bị giả | Giữ artwork AI đã duyệt, nhất là Sakura; giữ catalog thật, không thêm rarity/ranking hoặc trang trí 3D cũ. Bỏ phụ đề “Đổi Coins lấy vật phẩm trang trí” theo D04. |

Thứ bậc, bề mặt và trạng thái là tham chiếu; thông số demo và JS của HTML không phải hợp đồng API. Việc click card/nút “Mua” mở chi tiết để xác nhận là thích nghi hợp lệ; không chuyển thành trừ Coins ngay trên card chỉ vì mockup làm vậy.

## 3. Findings từ mã hiện tại

| ID | Mức | Bằng chứng cụ thể | Đề xuất / điều kiện kiểm |
| --- | --- | --- | --- |
| SH01 | P1 | `ShopScreen`: `meProvider.value`; `me?.coinsBalance ??0` truyền vào `itemActionOf` | Loading/error số dư bị hiểu là0 và kết luận thiếu tiền. Giữ balance unknown riêng; số0 chỉ khi API trả0. Lỗi có retry, không làm catalog biến mất nếu vẫn tải được catalog. Không cho hành động phụ thuộc số dư chưa xác minh. |
| SH02 | P1 | `inventoryProvider.value ??[]`; equipped set từ danh sách này | Loading/error kho đồ bị hiểu chưa trang bị, dễ hiện “Trang bị” sai. Gate trạng thái trang bị riêng, giữ dữ liệu stale có chỉ báo nếu dùng; không đoán từ `owned` rằng đang dùng. Retry inventory độc lập. |
| SH03 | P1 | `equipItem` dùng chung: không busy/guard; async xong gọi `ref.invalidate` trước kiểm context mounted | Có thể gửi nhiều equip/gỡ cạnh tranh và dùng ref sau dispose. Thêm trạng thái pending theo loại/vật phẩm ở scope đã giao, chặn nhấn lặp, sau lỗi giữ trạng thái thật và retry được; kiểm mounted trước truy cập ref sau await. Phải ghi tác động helper đến detail/inventory nếu sửa shared. |
| SH04 | P2 | `AppScaffold` không truyền background; default `DT.background=#FAF7F3`; preview dùng `DT.background` | Thành viên giữ nền kem, khác canvas xám/inset trung tính. Sửa scoped canvas `#F4F5F7`, preview `#F8F9FA`, ink/muted phù hợp; không bật owner role để lấy màu. Không đổi theme toàn app. |
| SH05 | P2 | `_ShopCard`: border luôn có `DT.divider` hoặc accent khi equipped; radius `DT.radiusMd=24` | Outline mặc định trái D02 và cả hai nguồn. Bỏ viền card thường; trạng thái equipped dùng nhãn/check rõ. Radius24 là khác nguồn32, cần chốt có chủ đích. Không xóa viền focus/input theo quy tắc card. |
| SH06 | P2 | Card preview cao140/100 cố định, grid `mainAxisExtent=284/244`; `ItemPreview(size:144)` | Preview không theo ô vuông như nguồn; giới hạn cao không tính tên/CTA khi chữ lớn. Có nguy cơ overflow hoặc cắt artwork/title ở màn hẹp. Chọn layout/card height theo chiều rộng và text scale; không kéo méo hoặc thay asset đã duyệt. Chưa có ảnh tái hiện. |
| SH07 | P2 | Tên item `maxLines:1/ellipsis`; `_Pill` owned/equipped cũng một dòng | Tên dài và “Đã sở hữu · Trang bị” dễ mất nội dung, nhất là320px hai cột. Cho phép tên hai dòng hoặc layout một cột khi cần; CTA phải đọc đủ và semantic label đầy đủ. |
| SH08 | P2 | `_Pill` padding dọc8 + label12, không minHeight44, không Semantics button riêng | Vùng chạm có thể thấp hơn44px; bàn phím/focus cần kiểm. Dùng button hoặc constraints/semantics hợp lệ, giữ action phụ khác tap toàn card, tránh tap mua làm card mở hai lần. |
| SH09 | P2 | Item thiếu Coins dùng màu nhạt như disabled nhưng `_Pill.onTap` vẫn mở chi tiết | Hành vi có thể hợp lệ để xem trước, nhưng affordance gây hiểu nhầm. Chốt label “Xem” hoặc nhãn thiếu Coins rõ; xác nhận mua bị khóa tại detail. Không biến balance unknown thành thiếu tiền. |
| SH10 | P2 | Header `AppHeader.large` có CoinChip trailing; dưới đó thêm hàng “Bộ sưu tập”/“Đồ của tôi” | Thứ bậc nhiều hàng hơn nguồn; header trailing và title có thể cạnh tranh khi số dư dài/chữ lớn. Giảm lặp, một balance thật, giữ đường kho đồ/Coins history. Không khôi phục phụ đề đã bị bỏ. |
| SH11 | P2 | Filter dùng shared `FilterChipPill`: nền cam mềm, viền theo member theme; nguồn selected đen | Cần quyết định riêng thay vì coi shared theme là chuẩn. Giữ selected semantics hiện có, keyboard và vùng chạm; nếu custom local không làm đổi màn khác. Scroll filter đến loại thứ ba trên320px. |
| SH12 | P2 | Empty StateMessage không có RefreshIndicator/action; `_refreshShop` chỉ await shop, invalidate me/inventory | Catalog rỗng không có thao tác tải lại trực tiếp; retry catalog không biểu đạt lỗi balance/kho. Bổ sung đường tải lại thích hợp cho rỗng/lỗi; refresh không giả tất cả nguồn đã thành công chỉ vì catalog xong. |
| SH13 | P2 | Loading/error chỉ được AsyncBody của catalog xử lý | Không có trạng thái độc lập cho balance/inventory. Ma trận cần cả catalog thành công + balance lỗi, inventory lỗi, refresh đang chạy; không trình bày dữ liệu chưa có như trạng thái cuối. |
| SH14 | P3 | `ItemAction.defaultItem` tồn tại nhưng `itemActionOf` không trả; ba kind hardcoded từ `itemKinds` | Không thêm default item vào catalog chỉ để dùng enum. Kho đồ mặc định là flow riêng. Kind lạ cần xử lý có chủ đích, không bịa tab/badge mới từ dữ liệu mẫu. |

Không phát hiện source catalog đang hiển thị Coins/chuỗi người khác. Balance đi `/coins`, item đi `/shop/item/:id`, kho đi `/shop/mine`; phải kiểm routing thực, không tự thêm đường từ mockup HTML.

## 4. Phụ thuộc mua/trang bị cần giữ, backlog ngoài list

- Mua ở màn chi tiết có expectedPrice và Idempotency-Key theo ý định; busy guard; thành công invalidate catalog/inventory/me/ledger. Đợt05A không bỏ xác nhận hoặc tạo transaction tại card.
- `ShopItemScreen._buy` catch gọi setState không kiểm mounted; sau request success còn ref.invalidate trước mounted. Ghi backlog05B hoặc mở rộng scope rõ nếu sửa; không âm thầm sửa vì cùng file.
- Lỗi mạng ở detail đang nói “Coins của bạn không bị trừ”; request có thể đã commit nhưng response mất. Cần câu chưa xác nhận giao dịch, retry cùng key/reconcile. Không hứa số dư chưa đổi khi chưa có bằng chứng server.
- Hint “Vật phẩm kích hoạt ngay sau khi mua” mâu thuẫn flow mua xong chuyển sang “Trang bị”. Giữ mua/sở hữu/trang bị là các trạng thái riêng; chốt copy ở05B.
- Kho hiện dùng previewKey từ catalog đang bán; owned item đã ẩn khỏi shop có thể không còn ánh xạ asset, fallback itemId. Bảo toàn artwork với item đã sở hữu là vấn đề05C/kho, không thay asset sang placeholder trong05A.
- Trang bị/gỡ hiện dùng chung helper nên mọi sửa helper phải kiểm detail/kho tối thiểu; không đổi semantics gỡ về mặc định, không làm owned thành mất sở hữu.

## 5. Checklist nghiệm thu theo phần

| Phần | Trạng thái / tiêu chí cần kiểm |
| --- | --- |
| Nền/card | Canvas xám toàn màn/cuộn; card trắng không outline mặc định; inset trung tính; equipped/focus không lẫn nhau; bóng nhẹ đúng token và artifact AI giữ nguyên. |
| Header/balance | Shop + một balance thật, số0/số lớn/unknown/loading/error khác nhau; retry độc lập; Coins history và Đồ của tôi mở đúng route; không phụ đề đã bỏ. |
| Filter | Khung avatar/Hình nền/Danh hiệu; selected đủ semantics, dấu chọn/weight ngoài màu; keyboard focus, touch44; horizontal scroll320px; đổi tab không mất balance hoặc coi inventory đang tải là chưa equip. |
| Item/preview | Cả ba loại, title dài tiếng Việt, asset known/missing/transparent, tên người dùng dài/rỗng; preview đúng tỉ lệ, không crop mất hoa/khung, artwork không bị màu fallback thay thế khi vẫn có asset. |
| Giá/trạng thái | Giá thật và balance0/thiếu/bằng/đủ; owned chưa dùng/equipped/default; không có giá demo/rarity/ranking. Cần xem trước khi thiếu tiền vẫn truy cập được nhưng label rõ. |
| Equip/gỡ | Một request khi tap lặp; pending không nhận equip khác cùng loại gây race; success cập nhật nguồn thật, error không báo thành công, retry được; dispose trong pending không dùng ref/context đã hủy. Gỡ về mặc định, không xóa ownership. |
| Purchase | Card mở detail, không trừ ngay; no-refund và expectedPrice/idempotency giữ; buy khi thiếu/unknown bị gate đúng; lỗi mạng không hứa transaction chưa xảy ra. Full audit detail ở05B. |
| Empty/error/loading | Catalog loading/error/retry/empty từng loại; balance và kho loading/error độc lập; refresh giữ filter, không giả0/[]; dữ liệu stale phải có nghĩa rõ. |
| Responsive/navigation | 320×740,390×844,768×1024; text1.5/2; tên dài, owned CTA dài, balance lớn; một/hai/nhiều cột có chủ đích, không overflow; hàng cuối không bị nav shell che; active Shop đúng route. |
| Motion/accessibility | Focus ring, Enter/Space, semantics giá/tên/owned/equipped, contrast chữ disabled; touch44; animation artwork/motion hiện có không gây xung đột reduced-motion. Không thêm hover scale chỉ vì mockup có. |

## 6. Các bước triển khai đề xuất

1. Arbiter chốt nguồn chính, card layout/radius, primary/filter và ma trận balance/inventory unknown; ghi ngoại lệ so HTML.
2. Sửa riêng `/shop`: palette scoped, header gọn, card không viền, preview/layout thích nghi, CTA đọc đủ. Giữ asset và route detail/kho.
3. Sửa gating dữ liệu và pending equip trong scope đã giao; test có ý nghĩa cho unknown/error, owned/equipped, tap lặp, narrow/chữ lớn và routing. Không thêm test chỉ lặp lại màu khai báo.
4. Verifier khác implementer kiểm code/test rồi ảnh thực cùng build/state. Thiếu ảnh giữ **CHƯA XÁC MINH HÌNH ẢNH**. Findings05B/05C được giữ backlog, không coi05A hoàn tất toàn bộ Shop.

Test có sẵn trong `app/test/features_test.dart` bao phủ detail mua/idempotency/thiếu Coins và các flow liên quan; không chứng minh catalog layout, metadata errors hoặc responsive đã đạt. Auditor không chạy test trong đợt đọc nguồn này.
