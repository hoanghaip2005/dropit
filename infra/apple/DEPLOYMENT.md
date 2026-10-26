# Apple setup — 26/10/2026

App Store Connect API authenticated successfully; existing four apps untouched. Private API key remains outside repository; no token or private key stored here.

- Team ID: `5MNN7PQYBD`.
- Bundle identifier: `com.bakhi.dropit.dropit` (matches Android/iOS source).
- Apple bundle resource ID: `2N9YLFX9NM`, registered through API, HTTP201.
- Push Notifications capability enabled, HTTP201.
- Xcode Runner and RunnerTests configurations now specify this development team. No signing certificate or provisioning profile issued. Native build not verified on Windows.

## Next required steps

1. App Store Connect web: Apps > + > New App. iOS, name `DropIt!`, primary language Vietnamese, bundle `com.bakhi.dropit.dropit`, SKU `dropit-ios-001`. API explicitly rejects apps CREATE. User created app via web; verified GET HTTP200: app ID `6826930419`, name `Dropit!`, bundle and SKU match, primary locale vi.
2. Apple Developer > Certificates, Identifiers & Profiles > Keys: create APNs key for push, save private .p8 outside repository. App Store Connect API key is NOT an APNs key. User supplied APNs key ID `44DY6P9FQH`; local file located outside repository. Parsed successfully as EC P-256 private key. This checks file format only, not Apple key scope/revocation/environment or device delivery. Not uploaded to Firebase yet.
3. Register Firebase iOS/Android apps and configure APNs credential, then SNS FCM v1 application and least-privilege server credential. Firebase project dropit-89d28 accessed via authenticated Firebase CLI. Android app 1:136773953250:android:4f0449840ef9a9164520bb and iOS app 1:136773953250:ios:a29004805bc9cccc4520bb registered. Native SDK configs downloaded. Public client/build defines saved app/config/firebase-android.json and firebase-ios.json, usable via --dart-define-from-file. These enable client push initialization; delivery still blocked on APNs upload and SNS/server configuration. No billing upgrade or Cloud Run deployment performed.
4. macOS/Xcode signing/archive, real-device push tests, TestFlight upload and privacy/review metadata remain required. No app published or submitted.

## Push backend provisioned

Google Cloud account OAuth renewed. Dedicated service account dropit-sns-fcm@dropit-89d28.iam.gserviceaccount.com created, granted roles/firebasecloudmessaging.admin. Service-account private JSON saved outside repository under user-only ACL; supplied to SNS, not copied to Flutter/server.

SNS GCM application DropIt-FCM created in ap-southeast-1, Enabled=true, AuthenticationMethod=Token (FCM v1). Public ARN in infra/aws-public-config.json. Dedicated IAM user DropItPushRuntime has inline policy limited to CreatePlatformEndpoint on this application and SetEndpointAttributes/Publish on its endpoints. Runtime access key stored outside repository and root600 backend.env; no administrator credentials on server. Rotate/revoke these credentials operationally.

Backend service restarted active; local and public HTTPS health200 production. No device registered, no test notification sent. APNs upload/scope not independently verified; Google FCM API enable request still awaiting CLI completion. No native build/delivery verification. Spark billing not upgraded by this work; SNS delivery can incur AWS usage fees.

FCM follow-up: service-account OAuth token exchange HTTP200. FCM validate_only request with deliberately invalid, non-device token reached API and returned400 INVALID_ARGUMENT invalid registration token (not permission denied/API disabled); no notification sent. This verifies API/credential access only. SNS IAM policy readback matches intended scoped application/endpoints; IAM simulator did not support these mobile ARN resources reliably, so no simulator-based permission proof claimed. Actual device flow remains untested.

## Android build work

Windows JDK loopback failure traced to Unix-domain socket temporary path; short jdk.net.unixdomain.tmpdir resolves Gradle startup. Reusable build script app/scripts/build_android_test.ps1 sets process-local JAVA_TOOL_OPTIONS and restores it. Added explicit AndroidX core and lifecycle-livedata dependencies for firebase_messaging16 in root Android build config; compileReleaseJavaWithJavac verified successful. Release APK packaging underway. Current release signing remains debug/internal-test only. No Android device connected via adb, no actual delivery/UI verified.

Android packaging completed: app/build/app/outputs/flutter-apk/app-release.apk, approximately66MB. apksigner verification successful, Android Debug certificate (internal testing only). SHA256 5F2EBB4A9710E86676833313A1258B8228DF621F08816E82B386987FAEBF007B. Build includes AWS origin/Cognito and Firebase push defines. Lint emitted path warning for exclamation mark in workspace; assembleRelease exited0. Device delivery/login not tested (adb device list empty).

## iOS TestFlight update

Distribution certificate/profile now created for DropIt, stored securely in GitHub Secrets; see TESTFLIGHT.md. GitHub macOS workflow successfully built and uploaded iOS version0.1.0 build131 using Xcode26.3. altool UPLOAD SUCCEEDED verified; Apple indexing/processing still pending at immediate API check. No review submission or device push verification. Earlier statements that no native iOS build/certificate/profile existed are superseded.
