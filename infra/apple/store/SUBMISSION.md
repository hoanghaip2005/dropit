# App Store submission — 26/10/2026

## Verified in App Store Connect

- App: DropIt! (`6826930419`), Vietnamese primary locale.
- Version: 0.1.0; build 131 processed VALID, attached to store version.
- Release: MANUAL. No App Store review submitted.
- Copyright: `2026 Thanh Tung Trinh`, explicitly confirmed by owner; saved and verified by Apple API.
- Vietnamese name, subtitle, description, keywords and promotional text saved; source `vi.json`.
- Categories: Productivity / Education. Age questionnaire saved.
- App Review and Beta Review contacts saved and API requests succeeded: Phạm Hoàng Hải, +84387803007, hoanghaip2005@tuttylab.vn. Details supplied by owner.

## Still required

### Subsequent progress

- Published `/support.html` and `/privacy.html` at production origin; HTTPS HTTP 200 and HTML content type verified. App Store localization URLs saved successfully.
- Created free price schedule with Vietnam base territory (Apple API HTTP 201).
- Independent source review of legal pages found missing device identifier, consent records and public avatar URL disclosure; corrected and redeployed. CHƯA XÁC MINH HÌNH ẢNH.
- Reviewer password generated outside repository, never printed. Cognito creation failed because `dropit-admin` AWS login expired; no reviewer account/login verified. AWS reauthentication pending; do not treat credential file as proof account exists.

### Apple submission validation attempted

Created review submission draft `7afb1206-eb67-41e4-90d7-2a4ea0bb73ae`. Adding version failed with HTTP 409; no version submitted, no review queued. Reuse this draft next time instead of creating duplicates.

Apple explicitly requires: demoAccountName/demoAccountPassword, contentRightsDeclaration, privacyPolicyUrl, supportUrl, iPad 13-inch screenshot, qualifying large iPhone screenshot, published app data usage declarations, and app pricing. This is Apple's validation response, not an automatic approval-review rejection.

- Publish accurate support and privacy pages; assign public URLs.
- Provision dedicated reviewer account; verify production login. Keep password outside repository and enter only in Apple review credentials.
- Capture genuine screenshots from current native iOS build. Existing web screenshots are not release evidence. CHƯA XÁC MINH HÌNH ẢNH.
- Complete privacy declarations, pricing/availability and content rights using actual behavior.
- Resolve release gaps: account deletion, authenticated profile synchronization, user-generated content safeguards; verify native push delivery.
- Validate all submission requirements before submitting. Preserve manual public release.

Private signing keys, tokens and reviewer passwords must never be stored here.
