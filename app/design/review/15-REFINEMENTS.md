# Đợt 15 — Tinh chỉnh Shop, lịch chủ nhóm và check-in phiên

Ngày: 28/10/2026
Trạng thái: `AUDIT MÃ NGUỒN` / **CHƯA XÁC MINH HÌNH ẢNH**

## Phạm vi

- Thành viên: `/shop`, `/shop/mine`, `/home`, `/groups/:gid`.
- Chủ nhóm: `/owner/schedule`, `/groups/:gid`, `/owner/sessions/:sid/edit`.
- Phiên: `/session/:sid` và trạng thái WAITING/ABSENT khi rời trước giờ bắt đầu.
- Build/runtime screenshot trước-sau: **CHƯA XÁC MINH HÌNH ẢNH**.

## Nguồn và tiêu chí

Ưu tiên yêu cầu mới nhất, nghiệp vụ hiện tại, sau đó dùng quyết định D02/D04/D06/D09 và hồ sơ 05A/05B/11. Không có ảnh Stitch/runtime cùng build trong đợt này nên chỉ audit source.

## Findings + phân xử

| ID | Finding nguồn | Mức | Quyết định | Tiêu chí nghiệm thu |
|---|---|---:|---|---|
| SHOP-15-01 | `shop_screen.dart` header còn `DropIt!`; tiêu đề shop và coin nằm khác hàng; các copy “Đã trang bị vật phẩm”, “Sở hữu vĩnh viễn · Chỉ dùng để trang trí”, “Mua để lưu vào Đồ của tôi…” và nhãn “Đồ của tôi” xuất hiện trong UI. | P1 | **SỬA** theo yêu cầu người dùng; giữ trạng thái ngắn gọn cho accessibility, bỏ marketing/copy lặp. | Header chỉ còn title Shop + coin cùng row; bỏ brand thừa; không render các subtitle bị yêu cầu bỏ; inventory vẫn truy cập được bằng icon/label gọn. |
| SHOP-15-02 | `_Pill` “Xem vật phẩm” dùng `minimumSize: 44` và padding dọc 10; card 2 cột khiến CTA chiếm nhiều chiều cao. | P2 | **SỬA**: compact CTA, giảm padding nhưng giữ vùng chạm tối thiểu theo accessibility. | Text/padding giảm; hit target vẫn ≥44 logical px hoặc có parent semantics. |
| OWNER-15-01 | `OwnerScheduleHubScreen` chỉ render dòng lịch và nút “Lên lịch phiên”; không có action sửa trên từng phiên. Chi tiết nhóm có action `Sửa / hủy lịch`, gây đường đi vòng. | P1 | **SỬA**: thêm sửa trực tiếp tại row lịch ở tab Lịch; dùng route edit hiện tại, không nhân bản logic. | Mỗi phiên SCHEDULED đủ điều kiện có nút Sửa; disabled/đã bắt đầu giải thích rõ. |
| OWNER-15-02 | `group_screens.dart` nút “Xem nhóm” có `trailingIcon: Icons.arrow_forward_rounded`; yêu cầu bỏ arrow và chữ trắng. | P2 | **SỬA** trong owner/member group card; giữ primary background, foreground trắng. | Không còn arrow; tương phản chữ trắng trên nền primary. |
| MEMBER-15-01 | Home `_UpcomingCard` hiện copy “Lịch do chủ nhóm đặt…” và “Chủ nhóm không tham gia phiên…”; `_MySummary` có title “Chuỗi của bạn: …”. | P2 | **SỬA**: bỏ các title/copy thừa theo yêu cầu; giữ dữ liệu Coins/chuỗi nhưng dùng heading ngắn hoặc không heading. | Không còn 3 copy nêu trên; không xóa dữ liệu hoặc privacy boundary. |
| MEMBER-15-02 | Home có nút vào phiên; group card chủ yếu `Xem nhóm`, chưa có action vào phiên kế tiếp cho member. | P1 | **SỬA**: trong group card member, khi có session kế tiếp, thêm CTA vào phòng chờ/phiên theo cùng `canEnter` policy; owner card không có CTA tham gia. | Member thấy CTA ở tab Nhóm; trạng thái trước mở check-in hiển thị thời điểm mở, không cho join sớm hơn policy. |
| SESSION-15-01 | `session_screen.dart` dialog khi rời WAITING ghi “Bạn sẽ bị ghi vắng”; controller/engine hiện `WAITING -> ABSENT` ngay khi `session:leave` (`engine.ts:276`). | P0/P1 | **SỬA nghiệp vụ**: rời trước giờ bắt đầu/check-in không ghi ABSENT. Giữ trạng thái chưa tham gia/withdrawn theo hợp đồng; chỉ ghi ABSENT khi đến mốc bắt đầu/admission deadline mà thành viên đã đăng ký nhưng không vào. Copy dialog phải nói “Rời phòng chờ trước giờ bắt đầu; bạn có thể vào lại” nếu còn cửa sổ. | Leave WAITING trước start không tạo ABSENT/NO_SHOW; re-open session cho phép join lại trong check-in window; test engine + API regression. |
| SESSION-15-02 | Copy home hiện “Phòng chờ mở lúc …” và nút disabled trước `lobbyOpensAt`; yêu cầu mới gọi đây là “giờ check-in” để tránh hiểu lầm. | P1 | **THÍCH NGHI**: đổi label thành “Check-in mở lúc …”/“Vào check-in”; giải thích check-in có thể mở sớm, phiên chỉ bắt đầu đúng giờ. Giữ server policy và timestamp. | Trước giờ check-in: hiển thị giờ mở; trong cửa sổ: “Check-in ngay”; sau start: “Vào phiên”/late policy. Không gọi là phòng chờ nếu gây hiểu lầm. |

## Tác động shared component

- Shop `_Pill` chỉ áp dụng Shop; không đổi `PrimaryButton` toàn app.
- CTA member trong group card dùng cùng route/session controller; owner không được lộ nút tham gia.
- Session leave policy cần backend engine + manager, API ack, controller copy và tests; không chỉ sửa text.

## Kiểm tra yêu cầu

- Source audit: đã đọc các file liên quan.
- Test/build/runtime screenshot: **CHƯA XÁC MINH HÌNH ẢNH**; implementer/verifier phải chụp đúng role, route, populated state ở 390×844 và kiểm hẹp 320×740.
- Dữ liệu thật: không seed/đổi dữ liệu để làm ảnh đẹp.
