# 15A — Shop refinements

28/10/2026. Scope: member Shop list/detail header and copy.

## User decisions
- Remove standalone DropIt header; show Shop title with coin badge on same row and compact inventory icon.
- Remove decorative policy copy and verbose status snack text. Keep transactional states and accessibility labels.
- Compact “Xem” CTA; keep black/white contrast.
- Preserve catalog/inventory data during refresh; hide mutation footer while catalog is loading to prevent stale actions.

## Source audit
Source: app/lib/features/shop/shop_screen.dart, existing 05A/05B decisions. Runtime image: CHƯA XÁC MINH HÌNH ẢNH.

## Changes
- Header now title + balance + inventory icon.
- Detail policy copy removed.
- Shop card kind subtitle removed; detail CTA shortened.
- Compact button padding/minimum size.
- Refresh no longer presents stale mutation footer while catalog loading.

## Validation
`flutter test test/shop_screen_design_test.dart test/shop_item_design_test.dart test/profile_shop_personalization_test.dart` 37 tests đạt (shop list/detail); profile/shop personalization trước đó 7 tests đạt. Runtime visual remains CHƯA XÁC MINH HÌNH ẢNH.
