# TestFlight via GitHub Actions

Manual workflow `.github/workflows/ios-testflight.yml`, repository hoanghaip2005/dropit. Flutter3.44.2, macos-15 runner, explicitly selected Xcode26.3/iOS26SDK, distribution profile with production push. Quality job on Ubuntu runs analyze, app tests and focus_lifecycle package tests before macOS. Workflow timeout20/45minutes; concurrency serializes signing/upload. No push/PR trigger. `upload=false` builds artifact only; defaulttrue uploads to TestFlight, never submits App Store review or adds external testers automatically.

Signing certificates and private keys are GitHub repository Secrets, never committed. Dedicated certificate/profile created for DropIt; other apps untouched. Temporary keychain/profile/API key cleaned with always() step. Signed IPA artifacts retained3days; repo is public, so artifact access follows GitHub permissions. Signing private keys excluded from artifact paths. App code includes public Firebase config only.

Run: `gh workflow run ios-testflight.yml --ref main -f upload=true`. Build number derived from GitHub run number/attempt; increment formula if any future external uploads use a higher build. Workflow assumes no competing manual App Store uploads.

Required Secrets: ASC_API_KEY_P8, ASC_KEY_ID, ASC_ISSUER_ID, IOS_DISTRIBUTION_P12_BASE64, IOS_P12_PASSWORD, IOS_PROFILE_BASE64. These were configured securely from local files. Recovery private signing material outside repository under user-only credential directory. Certificate expires26/10/2027; regenerate profile/rotate secrets before expiry.

A successful upload is not Apple processing completion or device testing. Check App Store Connect build processing/export compliance and internal tester access. Apple agreements, membership, privacy metadata and delivery on real iOS devices remain operational dependencies. Public standard hosted runners are generally free; GitHub account policies and nonstandard runner choices may change costs.

## Verified first upload

26/10/2026: run https://github.com/hoanghaip2005/dropit/actions/runs/40268267873 completed SUCCESS. Quality job passed. Xcode26.3 archive/export succeeded, signed IPA31.1MB. Version0.1.0 build131 (workflow run3 attempt1). altool explicitly returned UPLOAD SUCCEEDED with no errors. Temporary signing secrets cleanup succeeded. Apple builds API immediately after upload returned no indexed builds yet; processing/readiness/device install not verified at this checkpoint. No App Store review submission or tester invitation performed.

Initial upload with default Xcode16.4 was rejected for outdatedSDK; workflow now pins Xcode26.3 and checks iOSSDK>=26 before build. iOS deployment minimum15.0 aligns Firebase4/16, photo-library purpose declared for avatar selection.

## Apple processing and internal testing

Build131 resource fe1ae94d-e3a2-45b2-b5c9-6277bade075d processed VALID. usesNonExemptEncryption=false set after inspecting mobile source (standard platform/network encryption; no custom crypto feature found). Created internal group DropIt Internal (cb8f963f-ba30-46f6-85bc-4fc89dd3db75), associated build, added Vietnamese what-to-test notes. Readback internalBuildState READY_FOR_BETA_TESTING; externalBuildState READY_FOR_BETA_SUBMISSION. No testers invited/added yet; need intended Apple ID and internal App Store Connect access. No public link or external/App Store review submitted.
