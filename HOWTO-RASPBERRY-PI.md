# HOWTO: Run on Raspberry Pi (Simple Desktop + Chromium)

This guide shows the minimal steps to run the scoreboard on a Raspberry Pi using the desktop and Chromium in fullscreen.

## 1) Prepare your Pi
- Use Raspberry Pi OS (Desktop)
- Ensure you have network access
- Optional: set auto-login to desktop in `raspi-config`

## 2) Install dependencies
```bash
sudo apt update
sudo apt install -y chromium-browser || sudo apt install -y chromium
# Install Node.js 20+ (choose one):
# Option A: Via NodeSource
# curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
# sudo apt install -y nodejs
# Option B: Via nvm
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# source ~/.nvm/nvm.sh
# nvm install 20
```

## 3) Deploy the app to the Pi
```bash
# From your computer
scp -r table-tennis-scoreboard-main pi@your-pi-ip:/home/pi/table-tennis-scoreboard
```

## 4) Install and start the app
```bash
ssh pi@your-pi-ip
cd ~/table-tennis-scoreboard
npm ci
npm run preview
```
The app listens at `http://localhost:4321`.

## 5) Open Chromium in fullscreen
```bash
chromium-browser --start-fullscreen --no-first-run \
  --disable-session-crashed-bubble --disable-infobars --noerrdialogs \
  http://localhost:4321
```
If your OS uses `chromium` instead of `chromium-browser`, swap the command name.

## Optional: One-click start
Use the included `start-scoreboard-chromium.sh`:
```bash
bash ~/start-scoreboard-chromium.sh
```

## Optional: Auto-start on desktop login
```bash
mkdir -p ~/.config/autostart
cp ~/autostart-scoreboard.desktop ~/.config/autostart/
```
Ensure the Pi is set to boot to Desktop with auto-login.

## Notes
- Exit fullscreen: press `F11`.
- For best results, use a Raspberry Pi 4 (4GB).
- This repo no longer includes kiosk or recovery scripts to keep things simple.