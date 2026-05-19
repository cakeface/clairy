#!/usr/bin/env bash
# Run as root. Installs XFCE desktop and xrdp.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

USERNAME="clairy"

echo ">>> Installing XFCE4 and xrdp"
apt-get install -y xfce4 xfce4-goodies xrdp dbus-x11

echo ">>> Configuring xrdp for XFCE"
echo "startxfce4" > /home/"$USERNAME"/.xsession
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.xsession

cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
startxfce4
EOF
chmod +x /etc/xrdp/startwm.sh

echo ">>> Setting password for RDP login"
echo "$USERNAME:$USERNAME" | chpasswd

echo ">>> Installing browsers and VS Code"
apt-get install -y firefox chromium-browser

# VS Code
apt-get install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt-get update -qq
apt-get install -y code

echo ">>> Enabling xrdp"
systemctl enable xrdp
systemctl restart xrdp

echo ">>> Done. Connect via RDP to the Tailscale IP, user: $USERNAME, password: $USERNAME"
echo ">>> Change password after first login!"
