#!/bin/bash
set -euo pipefail
id dropit >/dev/null 2>&1 || useradd --system --home /opt/dropit --shell /usr/sbin/nologin dropit
install -d -m 750 -o dropit -g dropit /opt/dropit/shared/{uploads,outbox,backups}
install -d -m 700 /etc/dropit
release=/opt/dropit/releases/beta-20261026
install -d -o dropit -g dropit "$release"
tar -xzf /tmp/dropit-backend.tar.gz -C "$release"
cd "$release"
chown -R dropit:dropit "$release"
sudo -u dropit npm ci --cache /tmp/dropit-npm-cache --omit=dev --no-audit --no-fund >/tmp/dropit-npm.log 2>&1
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='dropit'" | grep -q 1; then
 sudo python3 - <<'PY'
import secrets,subprocess,pathlib
password=secrets.token_hex(32)
subprocess.run(['sudo','-u','postgres','psql','-v','ON_ERROR_STOP=1'],input="CREATE ROLE dropit LOGIN PASSWORD '"+password+"';",text=True,check=True,stdout=subprocess.DEVNULL)
subprocess.run(['sudo','-u','postgres','createdb','-O','dropit','dropit'],check=True)
env='NODE_ENV=production\nDEV_AUTH=0\nPORT=3000\nDATABASE_URL=postgres://dropit:'+password+'@127.0.0.1:5432/dropit\nCOGNITO_REGION=ap-southeast-1\nCOGNITO_USER_POOL_ID=ap-southeast-1_iCogdmW0v\nCOGNITO_CLIENT_ID=6vkgari2smj7qp1114lheihom0\nPUBLIC_BASE_URL=https://dropit.tutty-lab-demo.com\nUPLOADS_DIR=/opt/dropit/shared/uploads\nOUTBOX_DIR=/opt/dropit/shared/outbox\nAWS_REGION=ap-southeast-1\nJOURNAL_MASTER_KEY='+secrets.token_hex(32)+'\n'
p=pathlib.Path('/etc/dropit/backend.env');p.write_text(env);p.chmod(0o600)
PY
fi
# Only create schema on an empty database. Never run development user/group seeds.
if ! sudo -u postgres psql -d dropit -tAc "SELECT to_regclass('public.users') IS NOT NULL" | grep -q t; then
 sudo -u postgres psql -v ON_ERROR_STOP=1 -d dropit < "$release/schema.sql" >/tmp/dropit-schema.log
 sudo -u postgres psql -d dropit -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dropit; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dropit; ALTER SCHEMA public OWNER TO dropit;" >/dev/null
 # Migrations ALTER tables: assign initial schema ownership to application role.
 sudo -u postgres psql -d dropit -Atc "SELECT 'ALTER TABLE ' || quote_ident(schemaname) || '.' || quote_ident(tablename) || ' OWNER TO dropit;' FROM pg_tables WHERE schemaname='public'" | sudo -u postgres psql -d dropit >/dev/null
 sudo -u postgres psql -d dropit -Atc "SELECT 'ALTER VIEW ' || quote_ident(schemaname) || '.' || quote_ident(viewname) || ' OWNER TO dropit;' FROM pg_views WHERE schemaname='public'" | sudo -u postgres psql -d dropit >/dev/null
fi
ln -sfn "$release" /opt/dropit/current
cat >/etc/systemd/system/dropit-backend.service <<'UNIT'
[Unit]
Description=DropIt backend beta
After=network-online.target postgresql.service
Wants=network-online.target
[Service]
User=dropit
Group=dropit
WorkingDirectory=/opt/dropit/current
EnvironmentFile=/etc/dropit/backend.env
ExecStart=/usr/bin/node --max-old-space-size=256 dist/src/server.js
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/opt/dropit/shared
UMask=0027
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now dropit-backend
sleep 3
curl --fail --silent http://127.0.0.1:3000/health
