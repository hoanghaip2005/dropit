# Đợt 05A — kiểm tra độc lập Shop

Ngày 23/10/2026. Verifier `design_arbitration`, khác agent triển khai. Đã đọc phần Shop trong `shop_screen.dart`, test `shop_screen_design_test.dart`, audit và quyết định 05A. **KIỂM TRA MÃ NGUỒN / CHƯA XÁC MINH HÌNH ẢNH**. Đã kiểm bản mã nguồn cuối; không chạy Flutter hoặc browser trong vòng này.

## Phát hiện

| ID | Mức | Nội dung | Trạng thái |
|---|---|---|---|
| V05A-01 | P2 | `MeProfile.cachedAt != null` là dữ liệu lưu offline, không phải số dư đã xác minh. Patch đã ghi “Chưa cập nhật”, không tính thiếu Coins từ số cũ, nhưng retry metadata chỉ xuất hiện khi provider lỗi; dữ liệu cache trả success nên thiếu retry gần thông báo. | ĐÓNG SOURCE vòng 2: retry gồm cả cache cũ; đã đọc test cache số dư 0 không hiện thiếu Coins, nhấn retry gọi tải lần 2. Kết quả thực thi cuối được ghi bên dưới. |
| V05A-02 | P2 / kiểm thử còn thiếu | `_equip` có kiểm mounted sau API và finally, nhưng test chưa chứng minh dispose khi request đang chờ không dùng ref/setState sau dispose. | ĐÓNG SOURCE vòng 2: đã đọc test pending equip, dispose Shop, hoàn tất request và kiểm không có exception. Kết quả thực thi cuối được ghi bên dưới. |
| V05A-03 | P2 | Nút equip disabled có thể để thao tác rơi vào `AppCard.onTap`, vô tình mở chi tiết. | ĐÓNG SOURCE vòng 3: `AppCard` không có onTap; `InkWell` chỉ bao preview, key `shopPreview-id`, CTA equip/detail ở ngoài. Đã đọc test route qua preview và metadata pending giữ nút equip disabled. Kết quả thực thi cuối được ghi bên dưới. |

## Đã xác nhận từ source vòng đầu

- Canvas trung tính, card trắng không outline, preview lớn theo tỷ lệ vuông, tên tối đa hai dòng có semantics đầy đủ; giá và CTA riêng hàng. Không khôi phục subtitle đã bỏ hoặc heading dư “Bộ sưu tập”.
- Filter selected đen có check và semantics; CTA có chiều cao tối thiểu 44 px. Grid chuyển một cột ở màn hẹp hoặc chữ lớn; không dùng chiều cao card cố định cũ.
- Số dư loading/error không biến thành 0. Số dư cache có nhãn chưa cập nhật, không dùng để kết luận thiếu Coins. Inventory chưa tải không kết luận đang trang bị; món đã sở hữu vẫn giữ nhãn và khóa equip cho đến khi xác minh.
- Equip dùng busy toàn Shop, chờ API và tải lại inventory/me trước khi mở thao tác tiếp. Lỗi dùng copy trung tính, không lộ raw detail. Card/CTA chỉ mở chi tiết; không gọi purchase trực tiếp từ danh sách.
- Giữ `ItemPreview`, `previewKey` và AI artwork; không thêm rarity, ưu đãi hoặc số liệu giả. Các helper dùng chung và luồng chi tiết mua/kho đồ nằm ngoài phạm vi sửa 05A.
- Đã đọc test bố cục 320/390/768, metadata loading/error, equip success/remove/error/duplicate và navigation. Đây là kiểm tra nội dung test, chưa xác nhận thực thi hoặc chất lượng hình ảnh.

## Điều kiện chốt

Snapshot cuối đã kiểm hash trực tiếp: `shop_screen.dart` SHA256 `CB42C22E5343351097EFFBF6B9C0D9DCFFEADDF226FABEAFADF9875EB163616D`; `shop_screen_design_test.dart` SHA256 `D7081D8491BE042E875340E795CDE3119847678114F1ED1CF3C18E745F475B7A`.

Kết quả do agent triển khai và root cung cấp: **12/12 test Shop đạt sau preview tap**; **23/23 test features và local_gaps đạt trước thay đổi preview**; analyze 2 file sạch. Verifier đã đọc mã nguồn và test, không chạy lại Flutter. Cả ba phát hiện đóng trong phạm vi kiểm tra mã nguồn. Root đang build web; thông tin build sẽ ghi riêng. Chưa có ảnh runtime của bản cuối, chưa nghiệm thu thị giác.

- Đọc lại fixes V05A-01/02 và ghi hash cuối, kết quả test do agent triển khai/root cung cấp. Root kiểm phạm vi diff phần đuôi chi tiết/kho đồ để tránh thay đổi ngoài lô.
- `SHOP06` được hiểu gồm cả dữ liệu cache: success từ provider không đồng nghĩa số dư mới. Không dùng số dư cũ để kết luận thiếu Coins; phải có nhãn chưa cập nhật và retry.
- Nếu có ảnh widget render sẽ kiểm riêng và ghi rõ giới hạn; ảnh đó không chứng minh browser runtime. Không đổi công cụ để né hạn chế truy cập UI. Chưa có visual pass.

## Bàn giao build — root bổ sung

Web release thành công 23/10/2026; preview `f950dce84bc6`, `/shop`. Preview và file JavaScript trả HTTP 200; backend health HTTP 200. SHA256 `main.dart.js`: `3AB5FA2EF0B50250ECA8667EF1A97E15B2122C5F4193DB4BB8EB5FE1CBB2DCF2`. Tail chi tiết/kho từ `/// V-31` giữ hash `562CF4492F1D912B51776FB7F076B907DF993180CFE8EDF78492E545E049E03A`. Build không thay kết luận chưa xác minh hình ảnh.

