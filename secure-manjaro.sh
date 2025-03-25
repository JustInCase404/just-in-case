#!/bin/bash

# Function to check if a package is installed
is_installed() {
    pacman -Q "$1" &>/dev/null
}

# === STEP 1: Ensure yay is Installed (for AUR Packages) ===
if ! is_installed yay; then
    echo "📥 Installing yay (AUR Helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf ~/yay
fi

# === STEP 2: Update System and Install Official Packages ===
echo "🔄 Updating system and installing official security tools..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm clamav ufw firewalld apparmor cronie fail2ban rkhunter

# === STEP 3: Install chkrootkit Manually (Avoid Running as Root) ===
if ! is_installed chkrootkit; then
    echo "❌ chkrootkit is not installed. Please install it manually by running:"
    echo "👉 yay -S chkrootkit (as a regular user, NOT root)"
fi

# === STEP 4: Setup ClamAV ===
echo "🛡️ Setting up ClamAV..."
sudo systemctl enable --now clamav-freshclam
sudo systemctl enable --now clamav-daemon
sudo freshclam
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/freshclam") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * 7 /usr/bin/clamscan -r --remove / > /var/log/clamscan.log 2>&1") | crontab -

# === STEP 5: Setup Rootkit Scanners ===
echo "🛡️ Setting up rkhunter..."
sudo rkhunter --propupd
sudo rkhunter --update
(crontab -l 2>/dev/null; echo "0 4 * * * /usr/bin/rkhunter --update && /usr/bin/rkhunter --check --sk") | crontab -

echo "🛡️ Setting up chkrootkit..."
(crontab -l 2>/dev/null; echo "0 5 * * 3 /usr/bin/chkrootkit > /var/log/chkrootkit.log 2>&1") | crontab -

# === STEP 6: Setup Firewall (UFW or Firewalld) ===
echo "🔥 Configuring firewall..."
if is_installed ufw; then
    echo "🔹 Using UFW..."
    sudo systemctl enable --now ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
else
    echo "🔹 Using Firewalld..."
    sudo systemctl enable --now firewalld
    sudo firewall-cmd --set-default-zone=public
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --reload
fi

# === STEP 7: Setup Fail2Ban ===
echo "🛡️ Configuring Fail2Ban..."
sudo systemctl enable --now fail2ban

# Ensure the Fail2Ban configuration exists before writing to it
if [ ! -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
EOF

# Restart Fail2Ban to apply changes
sudo systemctl restart fail2ban

# === STEP 8: Create Systemd Watchdog for Fail2Ban ===
echo "🔄 Creating Fail2Ban watchdog..."
cat <<EOF | sudo tee /etc/systemd/system/fail2ban-watchdog.service
[Unit]
Description=Fail2Ban Watchdog
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "systemctl is-active --quiet fail2ban || systemctl restart fail2ban"

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/fail2ban-watchdog.timer
[Unit]
Description=Check Fail2Ban Every Hour

[Timer]
OnBootSec=10min
OnUnitActiveSec=1h
Unit=fail2ban-watchdog.service

[Install]
WantedBy=timers.target
EOF

# Enable Fail2Ban watchdog
sudo systemctl enable --now fail2ban-watchdog.timer

# === STEP 9: Setup AppArmor ===
echo "🛡️ Configuring AppArmor..."
sudo systemctl enable --now apparmor

cat <<EOF | sudo tee /etc/systemd/system/apparmor-watchdog.service
[Unit]
Description=AppArmor Watchdog
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "systemctl is-active --quiet apparmor || systemctl restart apparmor"

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF | sudo tee /etc/systemd/system/apparmor-watchdog.timer
[Unit]
Description=Check AppArmor Every 6 Hours

[Timer]
OnBootSec=10min
OnUnitActiveSec=6h
Unit=apparmor-watchdog.service

[Install]
WantedBy=timers.target
EOF

# Enable AppArmor watchdog
sudo systemctl enable --now apparmor-watchdog.timer

# === STEP 10: Verify Everything is Running ===
echo "🔍 Verifying security services and timers..."
systemctl list-timers --all | grep -E "fail2ban|apparmor"
sudo crontab -l

echo "✅ Security setup is complete. Your system is now protected!"

