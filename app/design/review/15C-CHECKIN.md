# 15C — Check-in phiên

Ngày: 28/10/2026. Trạng thái: triển khai backend, chờ verifier/app đúng build.

## Quyết định

Yêu cầu mới override Q149/Q153 và giới hạn mở phòng chờ 10 phút: check-in mở từ khi lịch được tạo. Phiên vẫn bắt đầu đúng giờ. Rời check-in trước giờ không ghi vắng, không mất thưởng/chuỗi, có thể vào lại. Hạn vào trễ vẫn là started_at + 1 phút (hoặc ends_at nếu sớm hơn). Chỉ hết hạn mới ghi NO_SHOW.

## Phạm vi và thay đổi

- `backend/src/modules/sessions/engine.ts`: leave WAITING giữ WAITING nhưng bỏ socket, ack `left_lobby:true`; không ABSENT ngay start khi socket null; join/resume trong admission grace chuyển FOCUSING. Danh sách/count lobby chỉ tính người có socket. Timer xa được chia nhỏ để tránh Node timeout overflow (>24.8 ngày).
- `backend/src/modules/sessions/manager.ts`: entry tải runtime theo yêu cầu cho lịch tương lai; cron vẫn chỉ tải horizon 10 phút. Hết admission mới final WAITING không socket -> ABSENT/NO_SHOW và ghi DB trước finalization. Empty vẫn CANCELLED/NO_ATTENDEE. Leaving check-in không chặn chuyển sang check-in phiên khác. Lịch missed vì outage không khởi động lại quá trễ.
- `backend/src/modules/sessions/summary.ts`: `lobby_opens_at = sessions.created_at`, giữ contract field cho app cũ.
- Không sửa schema enum, không thêm trạng thái vắng giả khi user chỉ rời check-in.

## Kiểm thử

- Build/typecheck: đạt.
- Unit suite: 66 tests đạt trước test timeout xa; engine mới 24 tests đạt.
- Integration group-management: 7/7 đạt, gồm check-in từ lịch xa, leave/rejoin trước start, resume sau start trong grace, empty deadline.
- Integration session: 5/5 đạt, gồm leave lobby chỉ NO_SHOW khi hết hạn.
- Sau thay đổi persistence và timer xa: 31/31 (engine 24 + group 7) đạt.
- Ảnh app/native thực tế: **CHƯA XÁC MINH HÌNH ẢNH**. Root sở hữu app/controller/copy và deployment; verifier khác phải kiểm leave/check-in/CTA thực tế.
