# Physical-device QA and App Review capture

Status: NOT EXECUTED. Complete on the candidate TestFlight build before resubmission.

Record device model, OS version, app version/build, test date, tester, observed result and recording URL. Use an iPhone and an iPad if both remain supported. Simulator captures do not satisfy Apple's physical-device video request.

| Flow | Required observation | Result |
| --- | --- | --- |
| Launch | Start recording before app launch; no crash | Not tested |
| Registration | Real verification email, error handling, login | Not tested |
| Session restore | Relaunch retains valid session; expired credentials recover | Not tested |
| Member | Join seeded group; check in before start; leave waiting room without false absence; attend session | Not tested |
| Owner | Create group; custom-duration schedule; edit; member management | Not tested |
| Results | Completed/early exit, history and explanation reflect actual session | Not tested |
| Cosmetics | Earned Coins, purchase, equip, updated preview; no real-money payment claim | Not tested |
| UGC | Report profile/group or explanation through supported controls; verify queue | Not tested |
| Blocking | Block target; target content hidden where promised; unblock restores | Not tested |
| Deletion | Disposable account: cancel confirmation, wrong credentials fail, confirm delete; old session rejected; account cannot sign in | Not tested |
| Push | Permission denied still permits use; permitted delivery on device | Not tested |
| Accessibility | Text scaling; readable buttons; confirmation controls labeled | Not tested |

Use dedicated disposable accounts for destructive tests, never existing users. Redact passwords, verification codes, email inbox contents and real group data from shareable video. Store reviewer credentials only in App Store Connect private review fields.

Capture authenticated screenshots for required iPhone and iPad sizes: group list, session, history and shop using real candidate app. Do not use login-only screenshots or fabricate completed sessions. Label any demonstration data explicitly.

Release gate: new build uploaded and processed; production API supports client endpoints; privacy policy reflects deployed behavior; review credentials tested for both roles; recording link accessible to reviewer; Notes and Resolution Center response consistent. Do not infer App Review acceptance from a passing build.
