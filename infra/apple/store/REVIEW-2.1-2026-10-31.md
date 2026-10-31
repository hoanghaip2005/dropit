# Guideline 2.1 response preparation — 2026-10-31

Status: DRAFT. Do not submit this document as evidence of completed device QA.

## Release blockers

- Physical-device recording on latest supported OS: NOT PROVIDED. Must start at app launch, show registration, login, member and owner flows, account deletion, and applicable UGC report/block flows.
- Account deletion: no account deletion endpoint found in current backend route audit. Deleting an avatar or signing out does not meet this requirement.
- UGC: group names, profile names/avatars and explanations require a concrete moderation assessment. No user-report/block routes found in route audit; monthly study reports are not abuse reports.
- Store screenshots: replace login-only screenshots with actual authenticated app screens for required iPhone/iPad sizes.
- Verify both reviewer roles against production and submitted native build. Keep credentials outside repository; put them only in App Store Connect review fields/Notes.
- Old SUBMISSION.md is historical, not authoritative current Apple status. User supplied an Apple information request on 2026-10-31; current state needs live verification.

## Proposed review response / Notes (English)

1. Physical-device demonstration: [ADD ACCESSIBLE RECORDING URL, DEVICE MODEL, OS VERSION, APP VERSION/BUILD AND TEST DATE AFTER REAL TESTING].

2. Purpose and audience: DropIt! is a productivity app for people who want to maintain a regular study/focus routine. Group owners organize scheduled focus sessions. Members join a group, check in, attend sessions, and view their own attendance/results. Session history, journals and cosmetic rewards help users track progress and maintain motivation. It is not intended to make educational eligibility or grading decisions.

3. Access and main features: Sign in using the dedicated member and owner review accounts supplied privately below. Member: join a study group using its invitation code, open a scheduled session, enter the waiting room, attend the session and inspect the result/history. Owner: create/manage a group, schedule a session, manage membership and inspect group reports. Profile, journal, achievements and the cosmetic shop are accessible after sign-in. Notification permission is optional. No sample files are required. [INSERT VERIFIED ROLE CREDENTIALS AND SEEDED GROUP/SESSION INSTRUCTIONS IN APP STORE CONNECT ONLY]. [ADD ACTUAL DELETION AND UGC SAFETY INSTRUCTIONS AFTER IMPLEMENTATION].

4. External services: AWS Cognito provides authentication. The application API and database run on AWS Lightsail. Firebase Cloud Messaging and Apple Push Notification service provide mobile push notifications where configured and permitted. Cosmetics use virtual Coins earned within the app; confirm no real-money purchase path in the submitted build. No runtime AI generation service was identified in this audit. Confirm deployed configuration before sending.

5. Regions: [VERIFY AND CONFIRM REGION AVAILABILITY, FEATURE PARITY AND LANGUAGE SUPPORT BEFORE SENDING]. Do not infer worldwide consistency solely from source code.

6. Regulated services / protected material: DropIt! provides study productivity features, not a regulated financial, healthcare or other licensed service. [VERIFY RIGHTS TO ALL INCLUDED ARTWORK AND THIRD-PARTY MATERIAL BEFORE ATTESTING AUTHORIZATION].

## Physical-device capture checklist

Use TestFlight build selected for resubmission. Record launch, sign-up/verification, login, primary member flow, owner scheduling flow, results/history, shop, deletion and applicable report/block controls. Do not expose real user data, OTPs or review passwords in the public recording. Test supported iPhone and iPad platforms; record observed outcomes rather than claiming unperformed QA.

## Implementation update — 2026-10-31

Implemented locally, not deployed or uploaded in a new native build:
- Profile > Xóa tài khoản: explicit irreversible confirmation; clears personal app data, dissolves owned groups, disconnects sessions, deletes Cognito login when provider succeeds. Provider failure returns an error and permits retry; no false success. Stale application JWT cannot recreate the account. Deidentified relational session/report metric records remain; backups and previously delivered data are outside immediate purge.
- Public profile > Báo cáo người dùng / Chặn người dùng. Own profile > Người dùng đã chặn > Bỏ chặn. Reports persist for operator investigation; blocking protects profile access and masks supported group/session/report/notification content. Operator queue and takedown tools documented in backend/src/modules/moderation/OPERATIONS.md.
- No proactive content filter. Previously delivered OS notifications/cached content and historical names are not comprehensively recalled. Do not claim complete UGC compliance.
- Cognito deletion scope, production migration/runtime permissions, real-device testing, screenshots and video remain release gates. Current App Store build does not gain these features until new code is deployed and a new native build uploaded.

Do not copy draft placeholders into App Store Connect. Replace release blockers with verified evidence only after deployment/testing.

Verification: backend full suite146/146 passed (single runner); Flutter selected safety/auth/profile tests26/26 passed; backend typecheck passed; web release build passed. This is local verification, not production/native-device evidence.
