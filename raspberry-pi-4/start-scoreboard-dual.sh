#!/bin/bash
# Auto-launch the Table Tennis Scoreboard across BOTH Pi 4 displays with zero
# clicks:
#   - 5" 800x480 touch screen (primary, HDMI-0)  -> CONTROL board (+ buttons)
#   - big HDMI monitor (secondary, HDMI-1)        -> clean SPECTATOR board
#
# Both windows run in ONE Chromium instance so they stay in sync over the app's
# BroadcastChannel (no Wi-Fi / internet needed). The control window broadcasts;
# it then opens the spectator window on the second display automatically.
#
# Usage:  bash ~/start-scoreboard-dual.sh
# Override geometry with env vars if your monitor differs, e.g.:
#   VIEWER_W=1280 VIEWER_H=1024 bash ~/start-scoreboard-dual.sh

set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/table-tennis-scoreboard}"
PORT="${PORT:-4321}"
URL="http://localhost:${PORT}"

# Primary (5") geometry and the spectator window position/size on display 2.
PRIMARY_W="${PRIMARY_W:-800}"
PRIMARY_H="${PRIMARY_H:-480}"
VIEWER_X="${VIEWER_X:-800}"   # second display starts where the 5" ends
VIEWER_Y="${VIEWER_Y:-0}"
VIEWER_W="${VIEWER_W:-1280}"
VIEWER_H="${VIEWER_H:-768}"

log() { echo "[scoreboard-dual] $*"; }

if [ ! -d "$APP_DIR" ]; then
  log "ERROR: App directory not found: $APP_DIR (set APP_DIR=...)"
  exit 1
fi

# Start the static preview server if the port is free.
if lsof -Pi :"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
  log "Port ${PORT} already in use; assuming server is running."
else
  log "Starting Astro preview server on port ${PORT}..."
  (cd "$APP_DIR" && npm run preview >/dev/null 2>&1 &)
fi

log "Waiting for server..."
for i in $(seq 1 60); do
  curl -sSf "$URL" >/dev/null 2>&1 && { log "Server up."; break; }
  sleep 1
done

# Find Chromium.
CHROMIUM_CMD=""
command -v chromium >/dev/null 2>&1 && CHROMIUM_CMD="chromium"
[ -z "$CHROMIUM_CMD" ] && command -v chromium-browser >/dev/null 2>&1 && CHROMIUM_CMD="chromium-browser"
if [ -z "$CHROMIUM_CMD" ]; then
  log "Chromium not found; installing..."
  sudo apt update && sudo apt install -y chromium || sudo apt install -y chromium-browser || true
  command -v chromium >/dev/null 2>&1 && CHROMIUM_CMD="chromium" || CHROMIUM_CMD="chromium-browser"
fi

# Stop screen blanking if X is up.
if [ -n "${DISPLAY:-}" ]; then
  xset -dpms 2>/dev/null || true
  xset s off 2>/dev/null || true
  xset s noblank 2>/dev/null || true
  command -v unclutter >/dev/null 2>&1 && (unclutter -idle 1 & ) || true
fi

CONTROL_URL="${URL}/?screen=control&spawnViewer=1&vx=${VIEWER_X}&vy=${VIEWER_Y}&vw=${VIEWER_W}&vh=${VIEWER_H}"
log "Launching control on primary (${PRIMARY_W}x${PRIMARY_H}); spectator will open at ${VIEWER_X},${VIEWER_Y} (${VIEWER_W}x${VIEWER_H})."

# One instance: control on the 5", which auto-opens the spectator popup on the
# big screen. --disable-popup-blocking is required for the auto-open.
exec "$CHROMIUM_CMD" \
  --user-data-dir="$HOME/.config/tts-kiosk" \
  --start-fullscreen \
  --window-position=0,0 \
  --window-size="${PRIMARY_W},${PRIMARY_H}" \
  --disable-popup-blocking \
  --no-first-run \
  --fast \
  --fast-start \
  --disable-session-crashed-bubble \
  --disable-infobars \
  --noerrdialogs \
  --autoplay-policy=no-user-gesture-required \
  "$CONTROL_URL"
