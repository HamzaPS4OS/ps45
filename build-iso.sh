#!/bin/bash
# Builds a bootable PS4 OS ISO (Debian Linux + kiosk -> boots straight into the PS4 OS interface).
set -e
[ "$(id -u)" = 0 ] || { echo "Run with: sudo ./build-iso.sh"; exit 1; }
command -v lb >/dev/null || apt-get install -y live-build debootstrap debian-archive-keyring
HERE="$(cd "$(dirname "$0")" && pwd)"
W=/tmp/ps4os-build; rm -rf "$W"; mkdir -p "$W"; cd "$W"
lb config --distribution bookworm --architectures amd64 \
  --binary-images iso-hybrid --debian-installer none --memtest none \
  --archive-areas "main contrib non-free non-free-firmware" \
  --iso-application "PS4 OS" --iso-volume "PS4OS" \
  --bootappend-live "boot=live components quiet splash live-config.user-default-groups=audio,video,input,render,plugdev,netdev"
cat > config/package-lists/ps4os.list.chroot <<'L'
cage
chromium
xwayland
alsa-utils
pipewire-pulse
wireplumber
fonts-noto-color-emoji
fonts-dejavu
udisks2
network-manager
firmware-linux-free
firmware-misc-nonfree
firmware-realtek
firmware-iwlwifi
L
mkdir -p config/includes.chroot/opt/ps4os config/includes.chroot/etc/systemd/system config/hooks/normal
cp "$HERE/index.html" config/includes.chroot/opt/ps4os/index.html
cp "$HERE/ps4os.service" config/includes.chroot/etc/systemd/system/ps4os.service
cat > config/hooks/normal/0100-ps4os.hook.chroot <<'H'
#!/bin/sh
systemctl enable ps4os.service
systemctl enable NetworkManager.service
systemctl set-default graphical.target
H
chmod +x config/hooks/normal/0100-ps4os.hook.chroot
lb build
cp -v ./*.iso "$HERE/PS4-OS.iso"
echo "Done: $HERE/PS4-OS.iso"
