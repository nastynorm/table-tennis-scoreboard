#!/bin/bash
# Raspberry Pi Zero 2 W: Auto Install and Kiosk Setup
# Implements the exact process from README for a minimal, reliable kiosk.
# - Installs Node 20, serve, minimal X + Openbox + Chromium + unclutter
# - Builds the Astro app to dist/ and serves it via systemd at :3000
# - Configures Openbox autostart to launch Chromium in kiosk mode
# - Configures .bash_profile to auto-start X on tty1
#
# Usage:
#   bash raspberry-pi/deploy.sh
#
# Assumes you run this ON the Pi as user 'pi'.

set -euo pipefail

REPO_URL="https://github.com/nastynorm/table-tennis-scoreboard.git"
APP_DIR="/home/pi/table-tennis-scoreboard"
PORT="3000"
SERVE_BIN=""

log() { echo "[deploy] $*"; }
run() { log "$*"; eval "$*"; }

# Step 2 — Update system
log "Updating apt and installing git + curl..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y git curl

# Step 3 — Install Node.js 20
if command -v node >/dev/null 2>&1; then
  log "Node present: $(node -v)"
else
  log "Installing Node.js 20 via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
fi
log "Node: $(node -v) | npm: $(npm -v)"

# Step 4 — Clone your Astro scoreboard and build
if [ -d "$APP_DIR/.git" ]; then
  log "Repo exists at $APP_DIR; pulling latest..."
  run "bash -lc 'cd "$APP_DIR" && git pull --rebase --autostash'"
else
  log "Cloning repo to $APP_DIR..."
  run "bash -lc 'git clone "$REPO_URL" "$APP_DIR"'"
fi

log "Installing app dependencies (npm install) and building to dist/..."
run "bash -lc 'cd "$APP_DIR" && npm install'"
run "bash -lc 'cd "$APP_DIR" && npm run build'"

# Step 5 — Install a lightweight static server (serve)
log "Installing serve globally..."
sudo npm install -g serve
SERVE_BIN=$(command -v serve || true)
if [ -z "$SERVE_BIN" ]; then
  log "ERROR: Global 'serve' not found in PATH after install."; exit 1
fi
log "serve binary: $SERVE_BIN"

# Step 6 — Install minimal GUI + Chromium
log "Installing minimal X + Openbox + Chromium + unclutter..."
sudo apt install --no-install-recommends -y \
  xserver-xorg x11-xserver-utils xinit openbox chromium-browser unclutter

# Step 7 — Configure Openbox autostart
log "Configuring Openbox autostart..."
mkdir -p "$HOME/.config/openbox"
cat > "$HOME/.config/openbox/autostart" <<'EOF'
# Disable screen blanking
xset -dpms
xset s off
xset s noblank

# Hide mouse cursor
unclutter &

# Give server a few seconds to start
sleep 5

# Launch Chromium in kiosk mode pointing to local scoreboard
chromium-browser --noerrdialogs --disable-infobars --disable-gpu --kiosk http://localhost:3000
EOF
chmod +x "$HOME/.config/openbox/autostart"

# Step 9 — Auto-start the scoreboard server (systemd service)
log "Creating systemd service for serve (scoreboard.service)..."
SERVICE_FILE="/etc/systemd/system/scoreboard.service"
sudo bash -lc "cat > '$SERVICE_FILE'" <<EOF
[Unit]
Description=Table Tennis Scoreboard Server
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=$SERVE_BIN -s dist -l $PORT
Restart=always
User=pi
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

log "Enabling and starting scoreboard.service..."
sudo systemctl daemon-reload
sudo systemctl enable scoreboard.service
sudo systemctl start scoreboard.service
sleep 2
sudo systemctl status scoreboard.service --no-pager || true

# Step 8 — Auto-start X on boot (.bash_profile)
log "Ensuring .bash_profile auto-starts X on tty1..."
BASH_PROFILE="$HOME/.bash_profile"
if [ ! -f "$BASH_PROFILE" ]; then
  touch "$BASH_PROFILE"
fi
if ! grep -q "startx" "$BASH_PROFILE"; then
  cat >> "$BASH_PROFILE" <<'EOF'
# Start X automatically on tty1
[[ -z $DISPLAY && $(tty) = /dev/tty1 ]] && startx
EOF
fi

# Step 8.1 — Ensure X starts Openbox (via ~/.xinitrc)
log "Ensuring X starts Openbox (creating ~/.xinitrc)..."
XINITRC="$HOME/.xinitrc"
if [ ! -f "$XINITRC" ] || ! grep -q "openbox-session" "$XINITRC"; then
  cat > "$XINITRC" <<'EOF'
exec openbox-session
EOF
fi

# Step 10 — Configure dual HDMI displays (Pi 4 optimization)
log "Configuring dual HDMI displays for Pi 4..."
BOOT_CONFIG="/boot/config.txt"
FIRMWARE_CONFIG="/boot/firmware/config.txt"

# Determine correct config file location
CONFIG_FILE=""
if [ -f "$BOOT_CONFIG" ]; then
  CONFIG_FILE="$BOOT_CONFIG"
elif [ -f "$FIRMWARE_CONFIG" ]; then
  CONFIG_FILE="$FIRMWARE_CONFIG"
else
  log "WARNING: Could not find boot config file. Skipping display configuration."
fi

if [ -n "$CONFIG_FILE" ]; then
  log "Backing up existing config: ${CONFIG_FILE}.backup"
  sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
  
  # Remove any existing dual HDMI configuration
  sudo sed -i '/# Dual HDMI Configuration/,/# End Dual HDMI Configuration/d' "$CONFIG_FILE"
  
  # Add dual HDMI configuration
  sudo bash -c "cat >> '$CONFIG_FILE'" <<'EOF'

# Dual HDMI Configuration for Table Tennis Scoreboard
# HDMI 0: 800x480 (Primary scoreboard display)
# HDMI 1: 1280x768 (Secondary/control display)
max_framebuffers=2
hdmi_group:0=2
hdmi_mode:0=87
hdmi_cvt:0=800 480 60 6 0 0 0
hdmi_drive:0=2
hdmi_group:1=2
hdmi_mode:1=87
hdmi_cvt:1=1280 768 60 6 0 0 0
hdmi_drive:1=2
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
gpu_mem=128
disable_overscan=1
dtoverlay=vc4-kms-v3d
max_framebuffer_width=1280
max_framebuffer_height=768
arm_freq=1500
gpu_freq=500
over_voltage=2
arm_64bit=1
# End Dual HDMI Configuration
EOF
  log "Dual HDMI configuration added to $CONFIG_FILE"
fi

# Step 11 — Configure console autologin (non-interactive)
log "Configuring console autologin for user 'pi' on tty1..."
AGETTY_BIN=$(command -v agetty || echo /sbin/agetty)
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo bash -lc "cat > /etc/systemd/system/getty@tty1.service.d/override.conf" <<EOF
[Service]
ExecStart=
ExecStart=-$AGETTY_BIN --autologin pi --noclear %I 38400 linux
EOF
sudo systemctl daemon-reload
sudo systemctl restart getty@tty1.service || true

log "All steps completed. You can test now or reboot:"
log "  Chromium: will launch in kiosk via Openbox when X starts"
log "  Server:   http://localhost:$PORT (served from $APP_DIR/dist)"
log "  Reboot:   sudo reboot"