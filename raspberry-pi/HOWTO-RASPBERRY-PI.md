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
Use the included `start-scoreboard-chromium.sh` in your app directory:
```bash
bash ~/table-tennis-scoreboard/start-scoreboard-chromium.sh
```

## Optional: Auto-start on desktop login
```bash
mkdir -p ~/.config/autostart
cp ~/table-tennis-scoreboard/autostart-scoreboard.desktop ~/.config/autostart/
```
Ensure the Pi is set to boot to Desktop with auto-login.

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

Security tip (change default password):
```bash
ssh pi@<PI_IP> 'passwd'
```

## Notes
- Exit fullscreen: press `F11`.
- For best results, use a Raspberry Pi 4 (4GB).
- This repo no longer includes kiosk or recovery scripts to keep things simple.