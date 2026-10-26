# TestFlight via GitHub Actions

Manual workflow `.github/workflows/ios-testflight.yml`, repository hoanghaip2005/dropit. Flutter3.44.2, macos-15 runner, distribution profile with production push. Quality job on Ubuntu runs analyze, app tests and focus_lifecycle package tests before macOS. Workflow timeout20/45minutes; concurrency serializes signing/upload. No push/PR trigger. `upload=false` builds artifact only; defaulttrue uploads to TestFlight, never submits App Store review or adds external testers automatically.

Signing certificates and private keys are GitHub repository Secrets, never committed. Dedicated certificate/profile created for DropIt; other apps untouched. Temporary keychain/profile/API key cleaned with always() step. Signed IPA artifacts retained3days; repo is public, so artifact access follows GitHub permissions. Signing private keys excluded from artifact paths. App code includes public Firebase config only.

Run: `gh workflow run ios-testflight.yml --ref main -f upload=true`. Build number derived from GitHub run number/attempt; increment formula if any future external uploads use a higher build. Workflow assumes no competing manual App Store uploads.

Required Secrets: ASC_API_KEY_P8, ASC_KEY_ID, ASC_ISSUER_ID, IOS_DISTRIBUTION_P12_BASE64, IOS_P12_PASSWORD, IOS_PROFILE_BASE64. These were configured securely from local files. Recovery private signing material outside repository under user-only credential directory. Certificate expires26/10/2027; regenerate profile/rotate secrets before expiry.

A successful upload is not Apple processing completion or device testing. Check App Store Connect build processing/export compliance and internal tester access. Apple agreements, membership, privacy metadata and delivery on real iOS devices remain operational dependencies. Public standard hosted runners are generally free; GitHub account policies and nonstandard runner choices may change costs.
