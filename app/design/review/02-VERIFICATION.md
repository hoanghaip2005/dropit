# Đợt 02 — kiểm tra độc lập

Ngày audit 22/10/2026; cập nhật kết quả 23/10/2026. Verifier: `design_arbitration`, khác hai implementer. Phạm vi: source ResultScreen/ExplanationScreen, hai test design mới, core API/models, backend result/giải trình và OpenAPI. **SOURCE REVIEW — CHƯA XÁC MINH HÌNH ẢNH**. Verifier không chạy lại Flutter; kết quả thực thi bên dưới do root cung cấp, tách khỏi nhận xét đọc source.

## Đã xác nhận từ source

- Result dùng mode explicit, thời lượng focus thực có giây, timestamps riêng và lịch dự kiến có nhãn; null không giả giờ. Participants chỉ tên/trạng thái, không đọc Coins/chuỗi/giải trình của người khác.
- ResultCopy phân biệt trạng thái, thưởng0, cap không hardcode100, forfeited thực, ngoại lệ EXITED khi hủy do sự cố; không khẳng định delivery thông báo. Chuỗi hiện tại không giả snapshot sau phiên lịch sử.
- `has_explanation` giữ đường xem bản đã gửi sau hạn; navigation từ history/direct riêng. Style scoped không thay toàn theme.
- Explanation gate hai async sources, giữ draft khi lỗi, ngăn gửi đôi, trim và đếm Unicode codepoints, readOnly khi hết quyền; có deadline timer, history, added_after_report, xác nhận bỏ draft.
- Backend submit deadline dựa `ends_at` và cấu hình; edit deadline từ lần gửi đầu. Quyền đọc/ghi chính chủ vẫn theo requireOwnExit; dữ liệu giải trình không đưa vào participants.
- `Explanation.canEdit` fail-closed khi metadata thiếu; model giữ version, API gửi If-Match có quote; PUT trả full metadata qua GET thay vì object thiếu can_edit/history. Không thấy field mới làm lộ dữ liệu người khác trong source đã xem.

## Findings và vòng sửa

| ID | Mức | Phát hiện | Trạng thái |
|---|---|---|---|
| V02-01 | P2 | Result từng coi mọi HTTP409 là đang chốt kết quả, che lỗi khác. | ĐÓNG SOURCE: đã đổi chỉ `SESSION_NOT_FINISHED`, có test409 khác code. Root cung cấp kết quả chạy chung63/63 test đạt; verifier không chạy lại. |
| V02-02 | P2 | Lịch sử chỉnh sửa giải trình chỉ hiện giờ viết/thay thế, thiếu ngày/năm; các bản khác ngày có thể trùng giờ. | ĐÓNG SOURCE: đã đọc lại, cả written_at/replaced_at có hhmm và ddmm (helper có năm). |
| V02-03 | P2 | OpenAPI MySessionResult thiếu mode/timestamps/submit deadline/has_explanation/cap mới; PUT còn schema Explanation thay vì MyExplanation fullmetadata. | ĐÓNG SOURCE vòng2: đã đọc lại field đủ và indent8spaces đúng properties, PUT MyExplanation. Root báo yaml.safe_load parse53paths đạt. |
| V02-04 | P2 / thiếu bằng chứng | Test explanation ban đầu dùng390×1800, thiếu case timer vừa hết hạn, version forwarding/conflict giữ draft,320px/chữ lớn/bàn phím. | ĐÓNG SOURCE phần coverage: đã đọc test deadline transition, version8 forwarding/conflict+reload giữ draft/servercopy,320×740 text1.5. Bàn phím thật/insets/runtime chưa được chứng minh bởi test nhập text. |

Vòng source cuối: direct-link close có fallback `/history/:sid`; giữ draft và xác nhận bỏ. Các findings source V02-01–04 đã đóng trong phạm vi nêu trên; gate hình ảnh vẫn mở.

## Kết quả thực thi do root cung cấp — 23/10/2026

- Flutter chạy chung6testfiles: **63/63 đạt**; gồm result, explanation và kiểm liên quan.
- Analyze8files: sạch.
- Backend typecheck: đạt;9integration đạt, gồm history contract và appeals có case stale If-Match.
- OpenAPI `yaml.safe_load`: parse53paths đạt.
- Source result/appeals giữ SHA256 đã ghi bên dưới. Verifier không chạy lại các lệnh này. Build web đang do root thực hiện; version/hash build sẽ ghi riêng sau khi có kết quả, chưa dùng làm bằng chứng runtime trong hồ sơ này.

SHA256 snapshot đã đọc:

| File | SHA256 |
|---|---|
| result_screen.dart | `0AAF4F1BC5BD7C300A2B856C43531BCEF0D99F40C4FA720220202BF4430BEF9F` |
| appeal_screens.dart sau khôi phục formatting ngoài phạm vi | `77AF528CCC8C5524C159A96F903AA799B0CE5A713259B4149BBA40BAD48484F7` |
| explanation_design_test.dart | `3BDF3E158FAE875532C0280700AFD43A1E8D7A1CC286938317AE18AE9F809F7F` |
| session_result_design_test.dart | `6E5936039C5E0D286A8BDB9FB864B3FD220EAC565DD6155B8BB5F420D90B6167` |
| backend sessions/routes.ts | `8606837BC0004FFB744190FB225DB28749B14BC87E901378D31478C1453ED49E` |
| backend appeals/service.ts | `33738DB7A0BEDD7E52017222E529A62471F7F4B5E5B3DDAA550CE994BAAFEEB5` |
| OpenAPI trước sửa indent | `5462E7FDBE41115BE1878DB62490526EEA4D4779EE8DC2B17180D37A8A941520` |
| OpenAPI sau sửa indent đã đọc lại | `565DA2541ADA55106C5538214A08DFE1C6A1D646E9EC4583BC14384CBEA8488C` |

## Giới hạn và điều kiện đóng

- Findings source đã đọc lại và đóng; test được root cung cấp như trên. Không đóng findings thị giác chỉ từ test hoặc lời báo đã sửa.
- API concurrency: client gửi If-Match version hiện tại; root cung cấp test backend stale edit đạt. Chưa kiểm thao tác đồng thời trên browser runtime.
- Cần ảnh app đúng build/role/state ở320/390/768, chữ lớn, scroll và keyboard. Test widget không chứng minh visual giống reference hoặc browser/native hoạt động đúng.
- Toàn bộ trạng thái trong `02-DETAIL-EXPLANATION-DECISIONS.md` vẫn là checklist nghiệm thu; những trạng thái chưa xem/kiểm không được ghi đạt. Không có visual PASS trong vòng kiểm này.
