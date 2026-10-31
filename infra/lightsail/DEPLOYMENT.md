# AWS beta deployment — 26/10/2026

Region ap-southeast-1; profile dropit-admin (MFA, không root). User authorized deploying AWS before Apple configuration. Single instance architecture, not HA or full ECS/RDS topology.

## Đã tạo / kiểm

- CloudFormation `dropit-cognito` CREATE_COMPLETE. Cognito Lite pool `ap-southeast-1_iCogdmW0v`, public client `6vkgari2smj7qp1114lheihom0`, no client secret, admin-only users. Chưa tạo user/mật khẩu thật.
- Lightsail `dropit-beta-sg`, Ubuntu24.04, micro_3_0,1GB,40GB,$7/month listed Singapore; static IP `54.254.61.215` attached, không thêm unattached IP. Inbound80/443 public, SSH22 current management IPv4/32; no3000/5432 public. Host key pinned TOFU on first SSH because AWS accessDetails hostKeys empty; subsequent connections strict verify.
- PostgreSQL16 local, schema34tables and migrations; no dev/demo users/groups imported. Runtime system user dropit; systemd enabled, restart-on-failure, protected system/home, writes only shared directory. Local health200 production, no mock auth. Random DB/journal keys generated server-side, root600 `/etc/dropit/backend.env`, no keys in repo/output.
- Caddy serves Flutter and proxies /v1/, /socket.io/, /health. Web built with Cognito IDs and HTTPS origin `https://dropit.tutty-lab-demo.com`. Trusted HTTPS certificate issued and verified; HTTP redirects to HTTPS. Same-origin web avoids production CORS changes.
- Bucket `dropit-backups-303278700480-sg`, small_1_0,$1/month; private, allowPublicOverrides=false. Resource access granted to instance; no bucket access keys created. This is instance-level access, not per-process IAM isolation.
- Encrypted daily backup uploaded; downloaded encrypted object, decrypted and restored temporary DB successfully34tables, then removed temporary DB. Timer19:15UTC =02:15VN next day with jitter<=5min, keep7daily+2weekly; backups include DB/uploads and backend env for recovery, encrypted before leaving server.
- Backup encryption key stored root600 `/etc/dropit/backup.key`, recovery copy outside repo `%USERPROFILE%/.aws/dropit-recovery/backup.key` user-only ACL. Keep recovery key separate from backup bucket; no key contents in dossier.
- Journald cap100MB disk/30MB runtime.1GB swap; swap is not load-test proof. Measured idle after install roughly479MB used/909MB available hardware; no10concurrent benchmark yet.
- SES identity `notify.dropit.tutty-lab-demo.com` created, DKIM pending. SES account sandbox200recipients/day,1/sec;0sent. No production access request or mail sending performed. Backend email remains local outbox until SES sender implemented/configured.
- Budgets and anomaly alerts as `infra/guardrails/DEPLOYMENT.md` unchanged.

## Chờ người dùng / giới hạn

1. User confirmed Tino A record. Cloudflare resolver returns54.254.61.215 TTL3600; local OS resolver still cached NXDOMAIN. Trusted HTTPS verified using curl --resolve (certificate validation enabled): /health200 production, /200, /v1/me401 without JWT, unauthenticated Socket.IO polling400. Successful authenticated socket/session flow not tested. No Route53 zone created.
2. Firebase project not identified yet. Firebase Cloud Messaging is not Cloud Run; backend stays AWS. Need Firebase project/app registration/FCM v1 service account supplied via safe file/console, not chat. SNS mobile application cannot be legitimately created without provider credential; no fake SNS ARN/platform application provisioned. SNS runtime policy/credentials pending exact app ARN and constrained delivery identity; no admin creds on server. iOS APNs configuration follows Apple setup.
3. SES DKIM CNAME records inDNS-RECORDS.md optional for future email; not necessary for realtime/app login. Sending code still local outbox; don't claim SES email functional.
4. Cognito access JWT usually lacks profile email/name; trusted sync remains pre-release blocker from login dossier. Admin-created account must have permanent password or unsupported challenge handled before use. No MFA/recovery UI in app yet.
5. No account/signup/upload hard caps, no RAM capacity benchmark, no off-host uptime alarms yet. Budget notifications not hard stop. HTTPS reachable at public IP with correct hostname; local DNS caches may take time to refresh. Backend no production user data currently.

## Billing / rollback

Instance and bucket now accrue charges according to region/plan, nominal$8/month before tax/transfer/etc; not free. No ALB/RDS/NAT/CloudFront, snapshot, additional server or autoscaling created. Do not delete instance/bucket/key to roll back app; keep release artifact/current symlink and DB backup, migrate compatibly. Stopping instance may still accrue Lightsail bundle cost. Bucket retention and billing need periodic checking.

## Files

bootstrap.sh (run explicitly bash; initial Lightsail wrapper used sh, rerun successful), deploy-backend.sh, Caddyfile, backup.py. Current release `/opt/dropit/releases/beta-20261026`, runtime `/opt/dropit/current`, web `/opt/dropit/web`. npm dependencies installed omitdev, backend compiled locally. No git secrets, no demo seeds copied into production DB.

## Push update

SNS FCM v1 application and scoped runtime IAM user provisioned; see infra/apple/DEPLOYMENT.md for current status. Earlier missing-Firebase/SNS statements are superseded. Native delivery/APNs and FCM API enable completion still unverified. Backend active, HTTPS health200 after configuration.

## Web cache retirement — 28/10/2026

Production index points to bootstrap-canonical-20261028.js, main-session-retry-final-20261028.js. Root and query-string URL return identical index with no-store. Bootstrap removes only legacy `v` query parameter, preserving route and other parameters.

Every future web deployment MUST copy `infra/lightsail/flutter_service_worker.js` to web root after Flutter build; --pwa-strategy=none generates an empty file that does not retire a previously installed offline worker. Retirement worker skipWaiting/activate deletes flutter-* caches only, unregisters, navigates same-origin open windows to their existing URLs. It does not clear auth/sessionStorage. Keep worker URL available with no-store until legacy clients have migrated.

Verified HTTP root/query same bootstrap, worker617bytes no-store; browser visiting ?v=auth-20261028#/login ends at /#/login. Legacy cached root may need one browser reload to trigger worker update; no claim all existing clients migrated immediately.

## Safety release — 31/10/2026

Source9a73a53. Backend `/opt/dropit/releases/safety-20261031`, previous `/opt/dropit/releases/management-20261028`; DB dump before migration under `/opt/dropit/shared/backups/pre-safety-20261031/database.dump` (server-private). Migrations001–005 applied. Corrected ownership of `trg_require_active_group()` to application schema owner before migration003; first attempt rolled back003 and left old runtime active. New runtime health200 production. No active/countdown sessions at deployment preflight.

Web root uses bootstrap-safety-20261031.js/main-safety-20261031.js; root and retirement worker no-store verified. Prior web copy `/opt/dropit/web-before-safety-20261031`. Policy/support pages updated for actual new behavior. No auth storage cleared. Owner/member Cognito authentication and GET /v1/me + /v1/me/blocks200; invalid deletion confirmation400, no real account deleted. Access token scope includes aws.cognito.signin.user.admin; actual Cognito deletion still requires disposable-account physical/device QA. No claim native testing or Apple approval.

Rollback code: restore previous current symlink then restart service; restore web backup. New migrations additive/compatible except new duration/active-group rules already intended by prior changes; do not restore database over live user data as routine rollback.
