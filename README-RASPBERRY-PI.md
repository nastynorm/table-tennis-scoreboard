# Raspberry Pi Setup (Chromium Fullscreen)

This project now uses a simple approach: run the app locally and open it in Chromium fullscreen. No kiosk mode, no display managers, no special OS tweaks.

## Requirements
- Raspberry Pi (preferably 4GB RAM, Desktop mode)
- Node.js 20+ (via `nvm` or Raspberry Pi OS repo)
- Chromium browser installed (`sudo apt install -y chromium-browser` or `chromium`)

## Deploy the app to Pi
```bash
# On your computer
scp -r table-tennis-scoreboard-main pi@your-pi-ip:/home/pi/table-tennis-scoreboard
```

## Start the app
```bash
ssh pi@your-pi-ip
cd ~/table-tennis-scoreboard
npm ci
npm run preview
```
The app will serve at `http://localhost:4321`.

## Open Chromium in fullscreen
```bash
chromium-browser --start-fullscreen --no-first-run \
  --disable-session-crashed-bubble --disable-infobars --noerrdialogs \
  http://localhost:4321
```
If your OS uses `chromium` instead of `chromium-browser`, swap the command name accordingly.

## Optional: One-click start script
Use the provided `start-scoreboard-chromium.sh`.
```bash
bash ~/start-scoreboard-chromium.sh
```
- Starts the server (if not already running)
- Waits for it to be ready
- Launches Chromium in fullscreen

## Optional: Auto-start on login
Create desktop autostart:
```bash
mkdir -p ~/.config/autostart
cp ~/autostart-scoreboard.desktop ~/.config/autostart/
```
Ensure Raspberry Pi is set to boot to Desktop with auto-login (use `raspi-config`).

## Remote hosting (optional)
If you run the app elsewhere, replace `http://localhost:4321` with your server URL when launching Chromium.

## Notes
- You can exit fullscreen with `F11`.
- For performance, prefer the Raspberry Pi 4 (4GB).
- This repo intentionally removed kiosk and recovery scripts to keep things simple.