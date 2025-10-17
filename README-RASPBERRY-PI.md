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
Use the provided `start-scoreboard-chromium.sh` in your app directory:
```bash
bash ~/table-tennis-scoreboard/start-scoreboard-chromium.sh
```
- Starts the server (if not already running)
- Waits for it to be ready
- Launches Chromium in fullscreen

## Optional: Auto-start on login
Create desktop autostart:
```bash
mkdir -p ~/.config/autostart
cp ~/table-tennis-scoreboard/autostart-scoreboard.desktop ~/.config/autostart/
```
Ensure Raspberry Pi is set to boot to Desktop with auto-login (use `raspi-config`).

## Remote setup from Windows (SSH)

### Set up passwordless SSH
Use Windows PowerShell (replace `<PI_IP>` with your Pi’s IP):
```powershell
# Generate a key if missing
if (!(Test-Path $env:USERPROFILE\.ssh\id_ed25519.pub)) { ssh-keygen -t ed25519 -C "Windows-key" }

# Add your key to the Pi (enter your Pi password once)
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh pi@<PI_IP> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Test key-based login
ssh -o PreferredAuthentications=publickey pi@<PI_IP> "echo OK && uname -a"
```

### One-command remote update
Installs `git`/`curl`, pulls the latest repo into `~/table-tennis-scoreboard`, installs Chromium and Node, enables autostart, and runs on port `4321`:
```bash
ssh pi@<PI_IP> 'set -e; sudo apt update && sudo apt install -y git curl; if [ -d ~/table-tennis-scoreboard ]; then cd ~/table-tennis-scoreboard && git pull; else git clone https://github.com/nastynorm/table-tennis-scoreboard.git ~/table-tennis-scoreboard && cd ~/table-tennis-scoreboard; fi; chmod +x setup-pi-chromium.sh; ./setup-pi-chromium.sh --port 4321 --autostart'
```
Reboot to validate autostart:
```bash
ssh pi@<PI_IP> 'sudo reboot'
```

### Remote manual start (no autostart)
```bash
ssh pi@<PI_IP> 'cd ~/table-tennis-scoreboard && npm run preview'
ssh pi@<PI_IP> 'command -v chromium-browser >/dev/null && chromium-browser --start-fullscreen --app=http://localhost:4321 || chromium --start-fullscreen --app=http://localhost:4321'
```

### Push your local folder to the Pi (alternative)
PowerShell (Windows):
```powershell
scp -r "C:\\Users\\<you>\\Downloads\\table-tennis-scoreboard-main\\table-tennis-scoreboard-main" pi@<PI_IP>:~/apps/
```
macOS/Linux:
```bash
scp -r table-tennis-scoreboard-main pi@<PI_IP>:~/apps/
```
Then on the Pi:
```bash
ssh pi@<PI_IP> 'cd ~/apps/table-tennis-scoreboard-main && npm ci && npm run preview'
ssh pi@<PI_IP> 'command -v chromium-browser >/dev/null && chromium-browser --start-fullscreen --app=http://localhost:4321 || chromium --start-fullscreen --app=http://localhost:4321'
```

## Remote hosting (optional)
If you run the app elsewhere, replace `http://localhost:4321` with your server URL when launching Chromium.

## Notes
- You can exit fullscreen with `F11`.
- For performance, prefer the Raspberry Pi 4 (4GB).
- This repo intentionally removed kiosk and recovery scripts to keep things simple.