#!/bin/bash
# Minimal Raspberry Pi setup for running the scoreboard with Chromium fullscreen
# - Installs Chromium (browser)
# - Installs Node.js 20 (via NodeSource) if missing/too old
# - Installs app dependencies and starts server on chosen port
# - Optionally sets up desktop autostart (no kiosk mode)
#
# Usage:
#   bash setup-pi-chromium.sh [--app-dir /home/pi/table-tennis-scoreboard] [--port 4321] [--autostart]
#
# Notes:
# - Run this ON the Raspberry Pi.
# - Default app dir: /home/pi/table-tennis-scoreboard
# - Default port: 4321

set -euo pipefail

APP_DIR=${APP_DIR:-"/home/pi/table-tennis-scoreboard"}
PORT=${PORT:-"4321"}
CREATE_AUTOSTART=false

# Parse simple flags
while [ $# -gt 0 ]; do
  case "$1" in
    --app-dir)
      APP_DIR="$2"; shift 2;;
    --port)
      PORT="$2"; shift 2;;
    --autostart)
      CREATE_AUTOSTART=true; shift 1;;
    *)
      echo "Unknown option: $1"; echo "Use: --app-dir PATH --port PORT --autostart"; exit 1;;
  esac
done

log() { echo "[setup] $*"; }

log "App dir: $APP_DIR"
log "Port: $PORT"

# Ensure apt indexes are fresh
log "Updating apt packages..."
sudo apt update -y

# Ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
  log "Installing curl..."
  sudo apt install -y curl
fi

# Install Chromium (browser)
if command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
  log "Chromium already installed."
else
  log "Installing Chromium..."
  sudo apt install -y chromium || sudo apt install -y chromium-browser || {
    log "ERROR: Chromium installation failed. Try: sudo apt install chromium"; exit 1;
  }
fi

# Install Node.js 20 if missing or too old
NEED_NODE=true
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -v | sed -E 's/v([0-9]+).*/\1/')
  if [ "$NODE_MAJOR" -ge 18 ]; then
    NEED_NODE=false
    log "Node.js v$(node -v) present."
  else
    log "Node.js too old (v$(node -v)). Will install v20."
  fi
else
  log "Node.js not found. Will install v20."
fi

if [ "$NEED_NODE" = true ]; then
  log "Installing Node.js 20 via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
  log "Node.js installed: $(node -v)"
fi

# Verify app directory
if [ ! -d "$APP_DIR" ]; then
  log "ERROR: App directory not found: $APP_DIR"
  log "Copy the repo to $APP_DIR (e.g. scp -r ... /home/pi/table-tennis-scoreboard)"
  exit 1
fi

# Install dependencies
log "Installing app dependencies (npm ci)..."
(cd "$APP_DIR" && npm ci)

# Start server on chosen port (bind to all interfaces for LAN access)
log "Starting Astro preview on port $PORT (host 0.0.0.0)..."
# Use nohup so it stays up if terminal closes
nohup bash -lc "cd '$APP_DIR' && npm run preview -- --host --port '$PORT'" > "$HOME/scoreboard-preview.log" 2>&1 &
PREVIEW_PID=$!
log "Preview started (PID: $PREVIEW_PID). Logs: $HOME/scoreboard-preview.log"

# Wait for server readiness
log "Waiting for server to be ready at http://localhost:$PORT ..."
for i in $(seq 1 60); do
  if curl -sSf "http://localhost:$PORT" >/dev/null 2>&1; then
    log "Server is up."
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    log "WARNING: Server did not respond after 60s; continuing anyway."
  fi
done

# Determine Chromium command
CHROMIUM_CMD=""
if command -v chromium >/dev/null 2>&1; then
  CHROMIUM_CMD="chromium"
elif command -v chromium-browser >/dev/null 2>&1; then
  CHROMIUM_CMD="chromium-browser"
else
  log "ERROR: Chromium not found after install."
  exit 1
fi

# Launch Chromium in fullscreen (non-kiosk)
URL="http://localhost:$PORT"
log "Launching Chromium fullscreen: $URL"
"$CHROMIUM_CMD" \
  --start-fullscreen \
  --no-first-run \
  --disable-session-crashed-bubble \
  --disable-infobars \
  --noerrdialogs \
  "$URL" &

# Optional: configure desktop autostart
if [ "$CREATE_AUTOSTART" = true ]; then
  log "Configuring desktop autostart..."
  mkdir -p "$HOME/.config/autostart"
  # Prefer existing autostart-scoreboard.desktop from repo if present
  if [ -f "$APP_DIR/autostart-scoreboard.desktop" ]; then
    cp "$APP_DIR/autostart-scoreboard.desktop" "$HOME/.config/autostart/"
    log "Copied autostart-scoreboard.desktop to ~/.config/autostart/"
  else
    # Create a minimal autostart file that calls the one-click start script
    # Ensure start-scoreboard-chromium.sh is available in $HOME
    if [ -f "$APP_DIR/start-scoreboard-chromium.sh" ]; then
      cp "$APP_DIR/start-scoreboard-chromium.sh" "$HOME/"
      chmod +x "$HOME/start-scoreboard-chromium.sh"
    fi
    cat > "$HOME/.config/autostart/scoreboard-chromium.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Scoreboard (Chromium Fullscreen)
Comment=Start the scoreboard server and open Chromium in fullscreen
Exec=/bin/bash -lc 'bash "$HOME/start-scoreboard-chromium.sh"'
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF
    log "Created ~/.config/autostart/scoreboard-chromium.desktop"
  fi
  log "Ensure Desktop auto-login is enabled (raspi-config)."
fi

log "Done. If Chromium didn’t open, run:"
log "  $CHROMIUM_CMD --start-fullscreen $URL"
log "Server logs: $HOME/scoreboard-preview.log"