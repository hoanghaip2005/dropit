# Đợt 05B — audit chi tiết vật phẩm

Ngày 24/10/2026. Auditor: `/root/design_reference`. Phạm vi duy nhất: `ShopItemScreen`, `_TryOn` trong `shop_screen.dart`; không mở rộng danh mục, kho đồ hoặc helper chung. Tái sử dụng audit 05A cho ngôn ngữ Shop và các phụ thuộc đã nhận diện.

**CHƯA XÁC MINH HÌNH ẢNH.** Chỉ đối chiếu nguồn. Không có ảnh app đúng build/trạng thái; nguy cơ responsive chưa phải lỗi đã tái hiện. Không dùng công cụ khác để vượt hạn chế browser.

## Nguồn

| Nguồn | SHA256 | Vai trò |
| --- | --- | --- |
| `mockup/s_02_chi_ti_t_v_t_ph_m_v_x_c_nh_n_mua/code.html` | `2B3C77BFAB6DD2341F682C0992E5C2C9A99030423EF4B31CDA188D03374A72FD` | Thứ bậc hero, thử trước, thông tin sở hữu, biên nhận, CTA cố định |
| `app/lib/features/shop/shop_screen.dart` | `CB42C22E5343351097EFFBF6B9C0D9DCFFEADDF226FABEAFADF9875EB163616D` | Baseline mã trước triển khai 05B; hash toàn file, không nhận diện build phục vụ |
| `app/design/design-system.html` | `11AD6BB9D68A6C7ABD34AEE9E7533FFD02A68F5E19B974E13A492751460D8C05` | Token/component; kết hợp D02 và quyết định Shop 05A |

Đã đọc README, DECISIONS, BACKLOG, prompts reference-reviewer/app-auditor và hồ sơ 05A. Không đọc hoặc lưu khóa truy cập; không tải ảnh từ xa trong mockup.

## Chọn lọc mockup

- Giữ canvas `#F4F5F7`, card trắng không outline mặc định, khoảng cách 16px, inset trung tính, CTA chính đen theo Shop. Mockup card radius32 là tham chiếu; không thay radius toàn app.
- Giữ thứ bậc preview rõ, tên/loại, sở hữu vĩnh viễn, giá/số dư/dự kiến còn lại, một CTA phù hợp trạng thái. Có thể gộp thông tin để giảm lặp.
- Bỏ số dư480, giá250, ảnh 3D, rarity/glow trang trí, profile mẫu, section hướng dẫn các trạng thái lỗi; giữ catalog thật và artwork AI đã duyệt, nhất là Sakura.
- Copy nguồn mâu thuẫn: “kích hoạt ngay” nhưng JS toast “Vào Hồ sơ để Trang bị”. Theo luồng thật: mua lưu kho, trang bị riêng.
- Copy nguồn khẳng định lỗi mạng không trừ Coins không chứng minh được kết quả giao dịch. Không sao chép; timeout có thể xảy ra sau commit.
- Nút xem toàn màn hình chỉ là đề xuất nguồn; không thêm control giả khi chưa có hành vi hoàn chỉnh. Không cần mô phỏng profile đầy đủ để đạt hierarchy thử trước.

## Findings và điều kiện xử lý

| ID | Mức | Bằng chứng mã baseline | Điều kiện xử lý |
| --- | --- | --- | --- |
| IT01 | P1 | `meProvider.value`, `coinsBalance ?? 0`, `inventoryProvider.value ?? []` | Loading/lỗi/đang refresh không bị hiểu thành0/chưa trang bị. Hiển thị unknown và retry; gate thao tác theo metadata đã xác minh. Nếu giữ cache, chỉ rõ đang kiểm tra và không cho xác nhận từ snapshot chưa xác minh. |
| IT02 | P1 | Footer ngoài `AsyncBody`, lấy `items.value`; có thể dùng catalog cũ khi body loading/lỗi | Body/footer cùng policy catalog freshness. Không để CTA xác nhận giá cũ trong lúc kiểm tra; item biến mất hoặc `ITEM_UNAVAILABLE` phải chặn mua đến khi xác minh. |
| IT03 | P1 | Catch mặc định `_buy`: “Coins của bạn không bị trừ” | Phân biệt từ chối xác định và kết quả chưa rõ. Lỗi mạng/timeout dùng thông báo chưa xác nhận; retry cùng ý định phải giữ cùng idempotency key. Không ngụ ý giao dịch thất bại chắc chắn. |
| IT04 | P1 | `_buy` invalidate ref sau await trước mounted; catch setState không guard | Sau dispose không truy cập ref/context/setState. Chụp dependency trước await khi cần; guard sau await cho cả success/error. Xác định cách quay lại trong lúc pending/kết quả chưa rõ; không làm mất key rồi cho mua mới tùy tiện. |
| IT05 | P1 | Chỉ mua có `_busy`; equip/gỡ gọi helper chung không khóa | Busy trong scope detail cho mọi mutation; không gửi equip/gỡ lặp hoặc xen mua. Không sửa helper/list/inventory ngoài scope. Lỗi giữ trạng thái thật, cho thử lại khi thích hợp. |
| IT06 | P1 | `PRICE_CHANGED` đổi key và invalidate nhưng giá hiển thị có thể còn cache | Sau giá đổi, bắt buộc tải snapshot mới và xác nhận lại giá; không tự mua tiếp. `ALREADY_OWNED` đồng bộ catalog/kho/số dư, không khẳng định đã trang bị. |
| IT07 | P2 | Scaffold dùng nền mặc định; preview/copy còn cấu trúc cũ | Canvas/card scoped theo Shop; không đổi theme chung hoặc thay artwork. Bỏ lặp điều khoản, sửa “kích hoạt” thành mua vào kho rồi trang bị. |
| IT08 | P2 | Header preview có trailing Text không flex; `ReceiptRow` nhãn dài, footer label gồm giá | Kiểm 320/390px và chữ lớn: nhãn xuống dòng/Wrap, không che số Coins, không overflow; nội dung cuối không bị footer che. Đây là nguy cơ cần ảnh runtime. |
| IT09 | P2 | `_TryOn` chỉ render item đang xem, bỏ cosmetics đang trang bị khác; `me == null` thành tên rỗng | Gọi đúng là thử vật phẩm; không hứa profile đầy đủ. Unknown profile có trạng thái rõ, không tạo người giả. Giữ asset renderer thật cho frame/title/background, ràng buộc kích thước và tên dài. |

## Checklist chuyển giao

- [ ] Catalog/me/inventory: loading, error, stale refresh, retry, số dư thật0; footer không suy đoán.
- [ ] Buy: đủ/thiếu Coins; nhấn lặp; success; already owned; giá thay đổi; ngừng bán; timeout có thể đã commit; retry cùng key/cùng ý định.
- [ ] Pending/dispose: rời màn, quay lại, đổi itemId nếu state được tái sử dụng; không lỗi lifecycle hoặc mất ngữ nghĩa giao dịch.
- [ ] Owned/equipped: trang bị, gỡ, lỗi, nhấn lặp; cập nhật số dư/kho/catalog sau kết quả xác định.
- [ ] UI scoped: canvas trung tính, card không outline, artwork đã duyệt, preview có nhãn trung thực, receipt không hứa số dư khi unknown.
- [ ] Kiểm cuối bởi agent khác implementer; lưu diff/build/test và ảnh đúng trạng thái. Chưa có ảnh thì giữ nhãn CHƯA XÁC MINH HÌNH ẢNH.

Các tiêu chí trên là đề xuất cho arbiter; log phân xử 05B mới là quyết định triển khai cuối. Không coi danh mục hoặc kho đồ đã đạt qua thay đổi màn chi tiết.
