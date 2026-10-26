# Đợt 05A — Shop thành viên

Ngày: 23/10/2026. Trạng thái: **ĐÃ TRIỂN KHAI, KIỂM CHÉO SOURCE / CHƯA XÁC MINH HÌNH ẢNH**.

Người dùng phản hồi chưa thấy thay đổi trong flow thành viên, đang mở `/shop`. Ưu tiên màn Shop trực tiếp thay vì mở rộng các trạng thái chỉ thấy khi đang học.

## Phạm vi và sở hữu

- Route `/shop`, vai trò thành viên. Header, số dư, lối vào Đồ của tôi, bộ lọc ba loại, danh sách/card, trạng thái sở hữu/trang bị và các cổng tải/lỗi/rỗng.
- Implementer `/root/implementation_audit`: phần ShopScreen và component riêng của danh sách trong `app/lib/features/shop/shop_screen.dart`; test mới `app/test/shop_screen_design_test.dart`.
- Audit nguồn/app `/root/design_reference`: `05A-SHOP-AUDIT.md`.
- Phân xử và verifier độc lập `/root/design_arbitration`: `05A-SHOP-DECISIONS.md`, `05A-VERIFICATION.md`.
- Không thay theme toàn app, artwork, renderer cosmetics, backend, giá/số dư hay dữ liệu mẫu. Chi tiết mua và Đồ của tôi là các đợt riêng; giữ route và nghiệp vụ hiện tại.

## Nguồn và yêu cầu

- `mockup/the_shop/code.html`, `mockup/rewards_shop/code.html`, `app/design/design-system.html`; hash và phân xử ở audit.
- Giữ artwork AI đã duyệt, đặc biệt khung Sakura. Không lấy ảnh 3D mẫu cũ thay artwork hiện tại.
- Nền trung tính `#F4F5F7`, card trắng không outline mặc định theo D02. Bỏ subtitle shop theo D04.
- Không giả số dư 0 hoặc trạng thái chưa trang bị khi provider đang tải/lỗi. Nội dung demo và hiệu ứng mua giả trong HTML không phải nghiệp vụ app.
- Kiểm 320×740, 390×844, 768×1024, text scale 1.5; tên dài, loading/error/empty, chưa biết số dư, mua/thiếu Coins/đã sở hữu/đang dùng và điều hướng.

## Bằng chứng

Baseline web trước đợt: version `e7659d2b3ba1`, route `/shop`. Chưa có ảnh app hiện tại được thu hợp lệ. Công cụ UI đã bị chặn ở phiên trước; không dùng công cụ khác để vượt giới hạn. Kiểm source và widget không thay nghiệm thu browser.

## Kết quả

- [Audit nguồn](05A-SHOP-AUDIT.md): 14 findings; [phân xử](05A-SHOP-DECISIONS.md): 11 quyết định đã giao triển khai.
- Bố cục chính từ `rewards_shop`: preview lớn, giá và CTA riêng hàng; trạng thái từ `the_shop`. Selected filter và CTA đen có chủ đích theo nguồn, Coins dùng màu thương hiệu. Không đổi theme toàn app.
- Tail từ `/// V-31` đến cuối file được bảo vệ SHA256 UTF-8 substring `562CF4492F1D912B51776FB7F076B907DF993180CFE8EDF78492E545E049E03A`.
- Đã sửa header, số dư, filter, preview, card và CTA của danh sách. Canvas xám; card trắng không viền; tên hai dòng; giá và CTA riêng hàng. 320px hoặc chữ lớn dùng một cột, 390px hai cột, 768px ba cột. Giữ artwork hiện tại.
- Balance loading/error/cache cũ không bị hiểu là 0 hoặc thiếu Coins. Retry metadata rõ; inventory chưa tải khóa equip, giữ trạng thái sở hữu có nguồn.
- Equip có busy guard toàn Shop; chờ API và nguồn inventory/me mới. Hoàn tất sau dispose không dùng ref/setState. Lỗi không báo thành công giả.
- Preview mở chi tiết bằng vùng chạm riêng. Nút equip disabled không truyền tap sang card rồi mở trang ngoài ý muốn. Danh sách không gọi purchase; route Coins, Đồ của tôi và chi tiết giữ nguyên.
- [Verifier độc lập](05A-VERIFICATION.md): đóng ba findings source sau các vòng sửa; chưa nghiệm thu hình ảnh.
- 12/12 tests Shop mới đạt ở patch cuối. 23/23 tests `features_test.dart` + `local_gaps_test.dart` đạt trước bổ sung preview InkWell; sau bổ sung đã chạy lại 12 tests Shop. Analyze `shop_screen.dart` và test mới: sạch. Diff check sạch.
- Hash tail bảo vệ khớp baseline; chi tiết mua và kho đồ không đổi trong đợt này. Không đổi backend, dữ liệu thật, artwork hoặc theme dùng chung.
- Chưa có ảnh runtime đúng build/trạng thái. **CHƯA XÁC MINH HÌNH ẢNH**; widget tests chỉ kiểm hành vi/bố cục, không chứng minh browser hay Android thực tế.
- Build web release thành công, 23/10/2026: `API_BASE_URL=http://localhost:3000`. URL: http://127.0.0.1:8080/_preview/f950dce84bc6/#/shop . Preview/JavaScript/backend health đều HTTP 200.
- SHA256 `build/web/main.dart.js`: `3AB5FA2EF0B50250ECA8667EF1A97E15B2122C5F4193DB4BB8EB5FE1CBB2DCF2`. Compiler còn cảnh báo dry-run Wasm `socket_io_common` và font Cupertino; bản JavaScript release đã build thành công.
- Đợt tiếp theo cần xử lý chi tiết mua (lỗi mạng chưa biết kết quả giao dịch, mounted, copy kích hoạt) và kho đồ. Không tuyên bố toàn bộ flow thành viên đã hoàn thiện từ danh sách Shop.
