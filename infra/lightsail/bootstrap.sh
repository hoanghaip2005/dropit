#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y ca-certificates curl gnupg postgresql postgresql-contrib nginx python3-venv unzip
systemctl stop nginx
systemctl disable nginx
# Bind databases locally; backend stays behind SSH until HTTPS is configured.
systemctl enable --now postgresql
install -d -m 750 -o ubuntu -g ubuntu /opt/dropit/releases /opt/dropit/shared/uploads /opt/dropit/shared/outbox /opt/dropit/shared/backups
install -d -m 700 -o root -g root /etc/dropit
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
printf 'deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main\n' > /etc/apt/sources.list.d/nodesource.list
apt-get update -qq
apt-get install -y nodejs
# A small swap file reduces installation OOM risk; it is not capacity validation.
if ! swapon --show | grep -q /swapfile; then
 fallocate -l 1G /swapfile
 chmod 600 /swapfile
 mkswap /swapfile >/dev/null
 swapon /swapfile
 printf '/swapfile none swap sw 0 0\n' >> /etc/fstab
fi
printf 'ready\n' >/opt/dropit/bootstrap-ready
