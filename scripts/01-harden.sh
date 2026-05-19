#!/usr/bin/env bash
# Run as root on a fresh Ubuntu 24.04 droplet.
# Creates the clairy user, hardens SSH, sets up firewall, swap, etc.
set -euo pipefail

USERNAME="clairy"
TIMEZONE="America/New_York"

echo ">>> Creating user: $USERNAME"
adduser --disabled-password --gecos "Clairy" "$USERNAME"
usermod -aG sudo "$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"

echo ">>> Copying SSH keys"
mkdir -p /home/"$USERNAME"/.ssh
cp /root/.ssh/authorized_keys /home/"$USERNAME"/.ssh/authorized_keys
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh
chmod 600 /home/"$USERNAME"/.ssh/authorized_keys

echo ">>> Hardening SSH"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo ">>> Installing security packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ufw fail2ban unattended-upgrades

echo ">>> Configuring UFW"
ufw allow 22/tcp
ufw --force enable
ufw default deny incoming
ufw default allow outgoing

echo ">>> Enabling fail2ban"
systemctl enable fail2ban
systemctl start fail2ban

echo ">>> Configuring unattended-upgrades (security only)"
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo ">>> Setting timezone to $TIMEZONE"
timedatectl set-timezone "$TIMEZONE"

echo ">>> Creating 1GB swap"
if [ ! -f /swapfile ]; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo ">>> Done. Now install Tailscale, then lock down SSH to tailscale0."
