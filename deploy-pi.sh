#!/bin/bash
# Deployment script for Raspberry Pi Zero 2W with 4-inch Waveshare display
# Run this script on your Raspberry Pi

set -e

echo "🏓 Table Tennis Scoreboard - Raspberry Pi Deployment"
echo "=================================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 18 (LTS)
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install display and browser packages
echo "📦 Installing display and browser packages..."
sudo apt install -y \
  chromium-browser \
  unclutter \
  xorg \
  xinit \
  x11-xserver-utils \
  xinput-calibrator

# Install Waveshare 5-inch HDMI display drivers
echo "📺 Setting up Waveshare 5-inch HDMI display..."
git clone https://github.com/waveshare/LCD-show.git
cd LCD-show/
chmod +x LCD5-show
# Note: This will reboot the Pi, so run manually: sudo ./LCD5-show

# Create app directory
echo "📁 Setting up application..."
mkdir -p /home/pi/table-tennis-scoreboard
cd /home/pi/table-tennis-scoreboard

# Install serve globally
sudo npm install -g serve

# Create systemd service for the app
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/scoreboard.service > /dev/null <<EOF
[Unit]
Description=Table Tennis Scoreboard
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/table-tennis-scoreboard
ExecStart=/usr/bin/serve -s dist -l 4321
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create kiosk startup script
echo "🖥️ Creating kiosk startup script..."
tee /home/pi/start-kiosk.sh > /dev/null <<'EOF'
#!/bin/bash
export DISPLAY=:0

# Hide cursor after 1 second of inactivity
unclutter -idle 1 &

# Wait for network and scoreboard service to be ready
sleep 15

# Kill any existing Chromium processes
pkill -f chromium-browser

# Wait a moment for cleanup
sleep 2

# Start Chromium in full kiosk mode (no toolbars, no UI elements)
chromium-browser \
  --kiosk \
  --start-fullscreen \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-web-security \
  --disable-features=TranslateUI,VizDisplayCompositor \
  --disable-ipc-flooding-protection \
  --no-first-run \
  --fast \
  --fast-start \
  --disable-default-apps \
  --disable-pinch \
  --disable-zoom \
  --disable-scroll-bounce \
  --disable-pull-to-refresh \
  --overscroll-history-navigation=0 \
  --touch-events=enabled \
  --enable-features=TouchpadAndWheelScrollLatching \
  --disable-dev-shm-usage \
  --no-sandbox \
  --disable-gpu-sandbox \
  --disable-software-rasterizer \
  --disable-background-timer-throttling \
  --disable-backgrounding-occluded-windows \
  --disable-renderer-backgrounding \
  --disable-field-trial-config \
  --disable-back-forward-cache \
  --disable-hang-monitor \
  --disable-prompt-on-repost \
  --disable-sync \
  --disable-translate \
  --hide-scrollbars \
  --disable-logging \
  --silent \
  --user-data-dir=/tmp/chromium-kiosk \
  http://localhost:4321
EOF

chmod +x /home/pi/start-kiosk.sh

# Create autostart directory and file
echo "🚀 Setting up autostart..."
mkdir -p /home/pi/.config/lxsession/LXDE-pi
tee /home/pi/.config/lxsession/LXDE-pi/autostart > /dev/null <<EOF
# Disable desktop components for kiosk mode
# @lxpanel --profile LXDE-pi
# @pcmanfm --desktop --profile LXDE-pi
@xscreensaver -no-splash

# Start kiosk mode via systemd service (more reliable)
# The kiosk.service will handle starting the browser
EOF

# Also create a desktop autostart entry as backup
mkdir -p /home/pi/.config/autostart
tee /home/pi/.config/autostart/scoreboard-kiosk.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Table Tennis Scoreboard Kiosk
Exec=/home/pi/start-kiosk.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Configure boot config for displays
echo "📺 Configuring display settings..."
sudo tee -a /boot/config.txt > /dev/null <<EOF

# Table Tennis Scoreboard Display Configuration
# 5-inch Waveshare HDMI primary display (800x480)
hdmi_force_hotplug:0=1
hdmi_group:0=2
hdmi_mode:0=87
hdmi_cvt:0=800 480 60 6 0 0 0
hdmi_drive:0=2

# HDMI for secondary 15.6" display
hdmi_force_hotplug:1=1
hdmi_group:1=2
hdmi_mode:1=82
hdmi_drive:1=2

# GPU memory for smooth graphics
gpu_mem=128

# Optimize for battery life
arm_freq=1000
over_voltage=0

# Disable rainbow splash
disable_splash=1

# Boot optimization for kiosk mode
boot_delay=0
disable_overscan=1

# Auto-login to desktop for kiosk mode
EOF

# Configure auto-login for kiosk mode
echo "🔐 Configuring auto-login for kiosk mode..."
sudo systemctl set-default graphical.target
sudo systemctl enable getty@tty1.service

# Configure auto-login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Configure auto-start X11 for pi user
echo "🖥️ Configuring auto-start X11..."
tee -a /home/pi/.bashrc > /dev/null <<EOF

# Auto-start X11 on login for kiosk mode
if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" = 1 ]; then
    exec startx
fi
EOF

# Create kiosk systemd service for reliable startup
echo "🖥️ Creating kiosk systemd service..."
sudo tee /etc/systemd/system/kiosk.service > /dev/null <<EOF
[Unit]
Description=Table Tennis Scoreboard Kiosk
After=graphical-session.target
Wants=graphical-session.target
Requires=scoreboard.service

[Service]
Type=simple
User=pi
Group=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
ExecStartPre=/bin/sleep 20
ExecStart=/home/pi/start-kiosk.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical-session.target
EOF

# Enable services
echo "⚙️ Enabling services..."
sudo systemctl enable scoreboard.service
sudo systemctl enable kiosk.service

# Create power management script
echo "🔋 Creating power management script..."
tee /home/pi/power-management.sh > /dev/null <<'EOF'
#!/bin/bash
# Power management for battery operation

# Reduce CPU frequency when on battery
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable hciuart

# Reduce HDMI power when not needed
# /opt/vc/bin/tvservice -o  # Uncomment to turn off HDMI

echo "Power management applied"
EOF

chmod +x /home/pi/power-management.sh

# Create deployment instructions
echo "📋 Creating deployment instructions..."
tee /home/pi/DEPLOYMENT_INSTRUCTIONS.md > /dev/null <<'EOF'
# Table Tennis Scoreboard - Raspberry Pi Deployment

## Hardware Setup
- Raspberry Pi Zero 2W
- Waveshare 4-inch resistive touchscreen
- 15.6-inch LCD via HDMI
- 20Ah power bank

## Next Steps

1. **Install Waveshare Display Driver:**
   ```bash
   cd LCD-show
   sudo ./LCD4-show
   ```
   (This will reboot the Pi)

2. **Deploy Your App:**
   - Copy your built app to `/home/pi/table-tennis-scoreboard/dist/`
   - Or clone and build:
   ```bash
   cd /home/pi/table-tennis-scoreboard
   git clone [your-repo] .
   npm install
   npm run build
   ```

3. **Start Services:**
   ```bash
   sudo systemctl start scoreboard.service
   sudo systemctl status scoreboard.service
   ```

4. **Test Kiosk Mode:**
   ```bash
   startx
   ```

5. **Calibrate Touch (if needed):**
   ```bash
   xinput_calibrator
   ```

## Power Management
- Run `./power-management.sh` to optimize for battery use
- Expected runtime: 12-16 hours with 20Ah power bank

## Troubleshooting
- Check service status: `sudo systemctl status scoreboard.service`
- View logs: `sudo journalctl -u scoreboard.service -f`
- Test display: `DISPLAY=:0 chromium-browser http://localhost:4321`

## File Locations
- App: `/home/pi/table-tennis-scoreboard/`
- Service: `/etc/systemd/system/scoreboard.service`
- Autostart: `/home/pi/.config/lxsession/LXDE-pi/autostart`
- Kiosk script: `/home/pi/start-kiosk.sh`
EOF

echo ""
echo "✅ Deployment script completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run: cd LCD-show && sudo ./LCD5-show (will reboot)"
echo "2. Copy your app to /home/pi/table-tennis-scoreboard/dist/"
echo "3. Start services: sudo systemctl start scoreboard.service"
echo "4. Reboot to test autostart: sudo reboot"
echo ""
echo "📖 See /home/pi/DEPLOYMENT_INSTRUCTIONS.md for detailed instructions"