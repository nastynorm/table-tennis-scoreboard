#!/bin/bash
# Start the scoreboard server and open Chromium in fullscreen (non-kiosk)
# Usage:
#  - Copy this file to your Raspberry Pi home (e.g. /home/pi/)
#  - Ensure your app directory is set correctly below
#  - Run: bash ~/start-scoreboard-chromium.sh

set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/table-tennis-scoreboard}"
PORT="${PORT:-4321}"
URL="http://localhost:${PORT}"

log() { echo "[scoreboard] $*"; }

log "App dir: ${APP_DIR}"
log "Target URL: ${URL}"

# Ensure the app directory exists
if [ ! -d "$APP_DIR" ]; then
  log "ERROR: App directory not found: $APP_DIR"
  log "Copy the repo to $APP_DIR or set APP_DIR to the correct path."
  exit 1
fi

# Start the Astro preview server if the port is free
if lsof -Pi :"$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
  log "Port ${PORT} already in use; assuming server is running."
else
  log "Starting Astro preview server on port ${PORT}..."
  (cd "$APP_DIR" && npm run preview >/dev/null 2>&1 &)
fi

# Wait for the server to respond
log "Waiting for server to be ready..."
for i in $(seq 1 60); do
  if curl -sSf "$URL" >/dev/null 2>&1; then
    log "Server is up: ${URL}"
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    log "WARNING: Server did not respond after 60s; continuing anyway."
  fi
done

# Pick Chromium command name (prefer chromium over chromium-browser)
CHROMIUM_CMD=""
if command -v chromium >/dev/null 2>&1; then
  CHROMIUM_CMD="chromium"
elif command -v chromium-browser >/dev/null 2>&1; then
  CHROMIUM_CMD="chromium-browser"
fi

if [ -z "$CHROMIUM_CMD" ]; then
  log "Chromium not found. Installing..."
  sudo apt update
  sudo apt install -y chromium || sudo apt install -y chromium-browser || true
  if command -v chromium >/dev/null 2>&1; then
    CHROMIUM_CMD="chromium"
  elif command -v chromium-browser >/dev/null 2>&1; then
    CHROMIUM_CMD="chromium-browser"
  else
    log "ERROR: Could not install Chromium automatically."
    log "Install manually: sudo apt install chromium (or chromium-browser)"
    exit 1
  fi
fi

log "Launching Chromium in fullscreen (non-kiosk)"
exec "$CHROMIUM_CMD" \
  --start-fullscreen \
  --no-first-run \
  --disable-session-crashed-bubble \
  --disable-infobars \
  --noerrdialogs \
  "$URL"