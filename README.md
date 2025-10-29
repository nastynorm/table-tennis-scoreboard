# Raspberry Pi Zero 2 W: Table Tennis Scoreboard Kiosk Setup

Goal

- Serve your Astro scoreboard locally on the Pi.
- Launch Chromium in full-screen kiosk mode displaying it on boot.
- Work reliably on a Pi Zero 2 W with minimal overhead.

## Step 1 — Install Raspberry Pi OS Lite (64-bit)

- Download Raspberry Pi OS Lite 64-bit:
  https://www.raspberrypi.com/software/operating-systems/
- Flash it to a microSD card using Raspberry Pi Imager.
- Enable SSH and Wi-Fi during imaging or edit `ssh` and `wpa_supplicant.conf` manually.

## Step 2 — Update system

SSH into your Pi and run:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install git curl -y
```

## Step 3 — Install Node.js

Astro requires Node 18+ (Node 20 recommended):

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Check versions:

```bash
node -v
npm -v
```

## Step 4 — Clone your Astro scoreboard and build

```bash
cd ~
git clone https://github.com/nastynorm/table-tennis-scoreboard.git
cd table-tennis-scoreboard
npm install
npm run build
```

Important: `npm run build` produces a `dist/` folder with static files.
The server will serve this folder, and Chromium will open it.

## Step 5 — Install a lightweight static server

```bash
sudo npm install -g serve
```

Test the server:

```bash
serve -s dist -l 3000
```

Open another terminal (or SSH from another machine) and check:

`http://<pi-ip>:3000`

If you see “site can’t be reached”, the server might not be running or the port is blocked.

## Step 6 — Install minimal GUI + Chromium

```bash
sudo apt install --no-install-recommends \
  xserver-xorg x11-xserver-utils xinit openbox chromium-browser unclutter -y
```

- `xserver-xorg` → basic graphical system
- `openbox` → lightweight window manager
- `chromium-browser` → browser
- `unclutter` → hides the cursor

## Step 7 — Configure Openbox autostart

Create Openbox autostart folder and file:

```bash
mkdir -p ~/.config/openbox
nano ~/.config/openbox/autostart
```

Paste:

```bash
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
```

Make executable:

```bash
chmod +x ~/.config/openbox/autostart
```

## Step 8 — Auto-start X on boot

Edit `.bash_profile`:

```bash
nano ~/.bash_profile
```

Add at the end:

```bash
# Start X automatically on tty1
[[ -z $DISPLAY && $(tty) = /dev/tty1 ]] && startx
```

This ensures Openbox + Chromium start when Pi boots and logs in.

## Step 9 — Auto-start the scoreboard server

Create a systemd service for `serve`:

```bash
sudo nano /etc/systemd/system/scoreboard.service
```

Paste:

```ini
[Unit]
Description=Table Tennis Scoreboard Server
After=network.target

[Service]
WorkingDirectory=/home/pi/table-tennis-scoreboard
ExecStart=/usr/bin/serve -s dist -l 3000
Restart=always
User=pi
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable scoreboard.service
sudo systemctl start scoreboard.service
sudo systemctl status scoreboard.service
```

Check that the service is running without errors.
If status shows active (running), the server is ready.

## Step 10 — Enable auto-login

Make sure Pi logs in automatically so `.bash_profile` can launch X:

```bash
sudo raspi-config
```

Navigate:

System Options → Boot / Auto Login → Console Autologin

## Step 11 — Reboot and test

```bash
sudo reboot
```

Pi boots → auto-login → X/Openbox → Chromium kiosk mode → `http://localhost:3000`.
Scoreboard should be visible automatically.

If Chromium shows “site can’t be reached”, it usually means the `serve` server hasn’t started in time. The `sleep 5` in autostart may need to be increased to `sleep 10`.

## Step 12 — Optional tweaks for stability

Increase delay in autostart:

```bash
sleep 10
```

Restart Chromium automatically if it crashes:

```bash
chromium-browser --noerrdialogs --disable-infobars --disable-gpu --kiosk http://localhost:3000 --incognito
```

Disable unused services to save memory on Pi Zero 2 W:

```bash
sudo systemctl disable bluetooth
sudo systemctl disable hciuart
```

## ✅ Result

Pi Zero 2 W boots directly into your table tennis scoreboard in full-screen Chromium, running locally with `serve`. No manual commands needed after boot.

I can also provide a single ready-to-copy autostart + systemd + sleep timing config that’s guaranteed to work on Pi Zero 2 W — so you just flash, clone, and reboot.

## Add On-Screen Keyboard

```bash
sudo apt update
sudo apt install matchbox-keyboard -y
```

Edit your Openbox autostart file:

```bash
nano ~/.config/openbox/autostart
```

Example with Chromium + matchbox keyboard:

```bash
# Disable screen blanking
xset -dpms
xset s off
xset s noblank

# Hide mouse cursor
unclutter &

# Launch Chromium in kiosk mode
chromium-browser --noerrdialogs --disable-infobars --disable-gpu --kiosk http://localhost:3000 &

# Launch on-screen keyboard
matchbox-keyboard &
```

The `&` ensures both programs run in parallel.

Optional tweaks for usability:

Resize keyboard: You can set size via `-x` and `-y` flags:

```bash
matchbox-keyboard -x 800 -y 200 &
```

Hide keyboard at startup and show on focus: `matchbox-keyboard` doesn’t do this automatically; you can use shortcuts or a toggle button in Chromium (JS-based virtual keyboard) if you want more control.


