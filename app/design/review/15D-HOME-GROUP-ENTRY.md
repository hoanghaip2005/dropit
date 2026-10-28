# 15D — Independent Home / Group / Entry verification

28/10/2026. Reviewer: shop_refine. Implementer: root (app), current_review (backend).

## Scope / evidence
Source audit only: home_screen.dart, group_screens.dart, report_screens.dart, session_controller.dart, session_screen.dart; engine/manager contract inspected for left_lobby:true with WAITING. Reference priority: latest explicit user requests, domain semantics, existing review decisions. No production state was mutated for screenshots.

## Findings
- Home removes redundant owner scheduling copy and streak section title. Upcoming CTA is available before scheduled start and named Check-in / Vào phòng chờ; after start it says Vào phiên ngay.
- Group member card includes entry action when nextSession exists. Xem nhóm has explicit black/white foreground/background and no arrow. Owner retains schedule action.
- Owner schedule hub provides direct edit route and explicit Sửa button; return invalidates schedules and group metadata.
- Session lobby leave explains no absence before start. Controller consumes left_lobby:true without changing WAITING to ABSENT; screen routes home. Existing active-session EXITED behavior remains distinct.
- Backend entryFor uses created_at as earliest check-in opening, consistent with arbitrary early entry. Runtime membership and start processing need backend regression validation by its owner.
- Shop badge and preserved preview were checked from source/test only; no visual pass inferred.

## Tests
`flutter test test/session_controller_test.dart test/session_screen_design_test.dart test/owner_groups_design_test.dart test/group_management_test.dart --reporter compact`: 45 tests passed.

## Decision / limits
No blocking source finding in reviewed patch. CHƯA XÁC MINH HÌNH ẢNH: no screenshot of new production build, role/state/viewport available. Need production check-in -> leave -> re-enter; owner schedule edit; member Group entry; responsive header/coin tests do not prove runtime visuals.
