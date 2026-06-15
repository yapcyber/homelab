#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get -y upgrade
apt-get -y install --no-install-recommends qemu-guest-agent cloud-init sudo python3 curl ca-certificates gnupg unattended-upgrades

# Docker — codename dérivé de l'OS (trixie sur Debian 13, bookworm sur 12)
CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $CODENAME stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
usermod -aG docker debian

printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' > /etc/apt/apt.conf.d/20auto-upgrades
printf 'datasource_list: [ ConfigDrive, NoCloud ]\n' > /etc/cloud/cloud.cfg.d/99-pve.cfg

# --- SEAL ---
cloud-init clean --logs || true
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id && ln -sf /etc/machine-id /var/lib/dbus/machine-id
rm -f /etc/ssh/ssh_host_*
apt-get clean && rm -rf /var/lib/apt/lists/*
find /var/log -type f -exec truncate -s 0 {} \;
rm -f /root/.bash_history /home/debian/.bash_history
sync
