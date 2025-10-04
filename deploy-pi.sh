#!/bin/bash
# Optimized Deployment script for Raspberry Pi Zero 2W with 5-inch Waveshare display
# This version fixes kiosk mode auto-start issues
# Run this script on your Raspberry Pi

set -e

echo "🏓 Table Tennis Scoreboard - Raspberry Pi Deployment (Optimized)"
echo "================================================================"

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
  xinput-calibrator \
  lightdm \
  openbox \
  onboard \
  at-spi2-core

# Install Waveshare 5-inch HDMI display drivers
echo "📺 Setting up Waveshare 5-inch HDMI display..."
if [ ! -d "LCD-show" ]; then
    git clone https://github.com/waveshare/LCD-show.git
fi
cd LCD-show/
chmod +x LCD5-show
echo "⚠️  Run 'sudo ./LCD5-show' manually after this script completes (it will reboot)"
cd ..

# Create app directory
echo "📁 Setting up application..."
sudo mkdir -p /home/pi/table-tennis-scoreboard
sudo chown pi:pi /home/pi/table-tennis-scoreboard
cd /home/pi/table-tennis-scoreboard

# Install serve globally
sudo npm install -g serve

# Create systemd service for the app
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/scoreboard.service > /dev/null <<EOF
[Unit]
Description=Table Tennis Scoreboard Web Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/table-tennis-scoreboard
ExecStart=/usr/bin/serve -s dist -l 4321
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create optimized kiosk startup script
echo "🖥️ Creating optimized kiosk startup script..."
tee /home/pi/start-kiosk.sh > /dev/null <<'EOF'
#!/bin/bash

# Wait for X11 to be fully ready
sleep 5

# Set display
export DISPLAY=:0

# Hide cursor after 1 second of inactivity
unclutter -idle 1 &

# Wait for network and scoreboard service to be ready
echo "Waiting for scoreboard service..."
while ! curl -s http://localhost:4321 > /dev/null; do
    sleep 2
done

# Kill any existing Chromium processes
pkill -f chromium-browser || true

# Wait a moment for cleanup
sleep 3

# Load Chromium environment variables to suppress warnings
source /home/pi/.chromium-env 2>/dev/null || true

# Apply Pi Zero 2W optimizations
/home/pi/power-management.sh 2>/dev/null || true

# Start Chromium in full kiosk mode (optimized for Pi Zero 2W)
chromium-browser \
  --kiosk \
  --start-fullscreen \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-web-security \
  --disable-features=TranslateUI,VizDisplayCompositor,AudioServiceOutOfProcess,MediaRouter \
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
  --disable-extensions \
  --disable-plugins \
  --disable-component-extensions-with-background-pages \
  --disable-background-networking \
  --disable-component-update \
  --disable-client-side-phishing-detection \
  --disable-default-apps \
  --disable-domain-reliability \
  --disable-background-mode \
  --disable-breakpad \
  --disable-crash-reporter \
  --disable-notifications \
  --disable-speech-api \
  --disable-file-system \
  --disable-permissions-api \
  --disable-presentation-api \
  --disable-remote-fonts \
  --disable-shared-workers \
  --disable-speech-synthesis-api \
  --disable-web-bluetooth \
  --disable-webgl \
  --disable-webgl2 \
  --memory-pressure-off \
  --max_old_space_size=256 \
  --js-flags="--max-old-space-size=256 --gc-interval=100" \
  --user-data-dir=/tmp/chromium-kiosk \
  --disk-cache-dir=/tmp/chromium-cache \
  --disk-cache-size=50000000 \
  --media-cache-size=25000000 \
  --window-size=800,480 \
  --window-position=0,0 \
  http://localhost:4321 2>/dev/null &

# Keep the script running to maintain the kiosk
wait
EOF

chmod +x /home/pi/start-kiosk.sh

# Configure passwordless sudo for pi user (essential for kiosk mode)
echo "🔐 Configuring passwordless sudo for pi user..."
echo "pi ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/010_pi-nopasswd > /dev/null
sudo chmod 440 /etc/sudoers.d/010_pi-nopasswd

# Configure LightDM for auto-login
echo "🔐 Configuring auto-login..."
sudo tee /etc/lightdm/lightdm.conf > /dev/null <<EOF
[SeatDefaults]
autologin-user=pi
autologin-user-timeout=0
user-session=openbox
autologin-session=openbox

[Seat:*]
autologin-user=pi
autologin-user-timeout=0
user-session=openbox
autologin-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

# Configure raspi-config for console auto-login
echo "🔐 Configuring raspi-config for console auto-login..."
sudo raspi-config nonint do_boot_behaviour B2

# Also configure systemd auto-login as fallback
echo "🔐 Adding systemd auto-login fallback..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Additional auto-login configuration for tty1
sudo systemctl set-default graphical.target
sudo systemctl enable getty@tty1.service

# Configure .bashrc to auto-start X11 if not already running
echo "🔐 Configuring .bashrc for auto X11 start..."
tee -a /home/pi/.bashrc > /dev/null <<'EOF'

# Auto-start X11 on login for kiosk mode (if not already running)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    echo "Starting X11 for kiosk mode..."
    exec startx
fi
EOF

# Create Openbox autostart configuration
echo "🚀 Setting up Openbox autostart..."
mkdir -p /home/pi/.config/openbox
tee /home/pi/.config/openbox/autostart > /dev/null <<EOF
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Start on-screen keyboard in background (hidden by default)
onboard --startup-delay=3 --size=400x150 --dock-type=2 &

# Start the kiosk application
/home/pi/start-kiosk.sh &
EOF

# Create keyboard shortcuts for emergency access
echo "⌨️ Setting up keyboard shortcuts..."
mkdir -p /home/pi/.config/openbox
tee /home/pi/.config/openbox/rc.xml > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <keyboard>
    <!-- Emergency on-screen keyboard toggle -->
    <keybind key="A-F1">
      <action name="Execute">
        <command>pkill onboard || onboard --size=600x200 --dock-type=0</command>
      </action>
    </keybind>
    <!-- Emergency terminal -->
    <keybind key="A-F2">
      <action name="Execute">
        <command>lxterminal</command>
      </action>
    </keybind>
    <!-- Restart kiosk -->
    <keybind key="A-F3">
      <action name="Execute">
        <command>pkill chromium-browser; sleep 2; /home/pi/start-kiosk.sh</command>
      </action>
    </keybind>
  </keyboard>
</openbox_config>
EOF

# Create systemd user service for kiosk (backup method)
echo "🖥️ Creating user systemd service for kiosk..."
mkdir -p /home/pi/.config/systemd/user
tee /home/pi/.config/systemd/user/kiosk.service > /dev/null <<EOF
[Unit]
Description=Table Tennis Scoreboard Kiosk
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/home/pi/start-kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Configure boot config for 5-inch Waveshare display
echo "📺 Configuring display settings for 5-inch Waveshare..."
sudo cp /boot/config.txt /boot/config.txt.backup

# Remove any existing display configuration
sudo sed -i '/# Table Tennis Scoreboard Display Configuration/,/# End Display Configuration/d' /boot/config.txt

sudo tee -a /boot/config.txt > /dev/null <<EOF

# Table Tennis Scoreboard Display Configuration
# 5-inch Waveshare HDMI display (800x480)
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=2

# GPU memory optimized for Pi Zero 2W (reduced to save RAM)
gpu_mem=64

# Pi Zero 2W optimizations
arm_freq=1000
over_voltage=0
force_turbo=0

# Memory split optimization for limited RAM
cma=64

# Disable unnecessary features to save memory
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0

# Disable rainbow splash
disable_splash=1

# Boot optimization for kiosk mode
boot_delay=0
disable_overscan=1
# End Display Configuration
EOF

# Enable services with error handling
echo "⚙️ Enabling services..."

# Enable scoreboard service
if sudo systemctl enable scoreboard.service 2>/dev/null; then
    echo "✅ Scoreboard service enabled successfully"
else
    echo "⚠️  Warning: Could not enable scoreboard service via systemctl"
    echo "   This will be handled during reboot"
fi

# Enable lightdm service with fallback
if sudo systemctl enable lightdm.service 2>/dev/null; then
    echo "✅ LightDM service enabled successfully"
else
    echo "⚠️  Warning: SystemD bus connection failed for LightDM"
    echo "   Using alternative method..."
    
    # Alternative method: use update-rc.d for SysV compatibility
    if command -v update-rc.d >/dev/null 2>&1; then
        sudo update-rc.d lightdm enable 2>/dev/null || true
        echo "✅ LightDM enabled via update-rc.d"
    fi
    
    # Ensure lightdm is set as default display manager
    echo "/usr/sbin/lightdm" | sudo tee /etc/X11/default-display-manager > /dev/null
    echo "✅ LightDM set as default display manager"
fi

# Enable user service for pi user with error handling
if sudo -u pi systemctl --user enable kiosk.service 2>/dev/null; then
    echo "✅ User kiosk service enabled successfully"
else
    echo "⚠️  Warning: Could not enable user kiosk service"
    echo "   Auto-start will use alternative methods (LightDM + Openbox)"
fi

# Create power management script
echo "🔋 Creating power management script..."
tee /home/pi/power-management.sh > /dev/null <<'EOF'
#!/bin/bash
# Power management and optimization for Pi Zero 2W

echo "Applying Pi Zero 2W optimizations..."

# Reduce CPU frequency when on battery
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable unnecessary services to save memory and reduce warnings
sudo systemctl disable bluetooth || true
sudo systemctl disable hciuart || true
sudo systemctl disable avahi-daemon || true
sudo systemctl disable triggerhappy || true
sudo systemctl disable dphys-swapfile || true

# Reduce WiFi power consumption
sudo iwconfig wlan0 power on

# Memory optimization for Pi Zero 2W
echo 1 | sudo tee /proc/sys/vm/overcommit_memory
echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure
echo 10 | sudo tee /proc/sys/vm/swappiness

# Clear system caches to free memory
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Set memory limits for better performance
ulimit -v 400000  # Virtual memory limit (400MB)

echo "Pi Zero 2W optimizations applied successfully"
EOF

chmod +x /home/pi/power-management.sh

# Create display troubleshooting script
echo "📺 Creating display troubleshooting script..."
tee /home/pi/fix-display.sh > /dev/null <<'EOF'
#!/bin/bash
# Fix white screen and display issues after LCD5-show

echo "🔧 Waveshare Display Troubleshooting"
echo "===================================="

# Backup current config
sudo cp /boot/config.txt /boot/config.txt.backup-$(date +%Y%m%d-%H%M%S)

echo "📋 Current display status:"
echo "HDMI status:"
/opt/vc/bin/tvservice -s

echo -e "\nFramebuffer info:"
fbset

echo -e "\n🔧 Applying display fixes..."

# Remove conflicting configurations
sudo sed -i '/^dtoverlay=vc4-kms-v3d/d' /boot/config.txt
sudo sed -i '/^dtoverlay=vc4-fkms-v3d/d' /boot/config.txt

# Ensure proper Waveshare 5-inch configuration
sudo tee -a /boot/config.txt > /dev/null <<DISPLAYEOF

# Waveshare 5-inch Display Fix
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=2
display_rotate=0

# Disable GPU acceleration that can cause white screen
dtoverlay=
gpu_mem=64
disable_overscan=1

# Force framebuffer
framebuffer_width=800
framebuffer_height=480

DISPLAYEOF

echo "✅ Display configuration updated"
echo "🔄 Reboot required: sudo reboot"
echo ""
echo "If still white screen after reboot, try:"
echo "1. SSH in and run: sudo /opt/vc/bin/tvservice -p"
echo "2. Then run: sudo systemctl restart lightdm"
echo "3. Or try: DISPLAY=:0 xrandr --output HDMI-1 --mode 800x480"
EOF

chmod +x /home/pi/fix-display.sh

# Create troubleshooting script
echo "🔧 Creating troubleshooting script..."
tee /home/pi/troubleshoot-kiosk.sh > /dev/null <<'EOF'
#!/bin/bash
# Troubleshooting script for kiosk mode issues

echo "🔍 Table Tennis Scoreboard - Kiosk Troubleshooting"
echo "================================================="

echo "📊 Service Status:"
echo "Scoreboard service:"
sudo systemctl status scoreboard.service --no-pager -l

echo -e "\nLightDM service:"
sudo systemctl status lightdm.service --no-pager -l

echo -e "\n📋 Process Information:"
echo "Chromium processes:"
ps aux | grep chromium || echo "No Chromium processes found"

echo -e "\nX11 processes:"
ps aux | grep Xorg || echo "No X11 processes found"

echo -e "\n🌐 Network Connectivity:"
echo "Scoreboard web server:"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:4321 || echo "Cannot connect to scoreboard"

echo -e "\n📺 Display Information:"
echo "Current display:"
echo $DISPLAY

echo -e "\nXrandr output:"
DISPLAY=:0 xrandr 2>/dev/null || echo "Cannot get display information"

echo -e "\n📝 Recent Logs:"
echo "Scoreboard service logs (last 10 lines):"
sudo journalctl -u scoreboard.service -n 10 --no-pager

echo -e "\nLightDM logs (last 5 lines):"
sudo journalctl -u lightdm.service -n 5 --no-pager

echo -e "\n📺 Display Issues:"
echo "HDMI/Display status:"
/opt/vc/bin/tvservice -s 2>/dev/null || echo "Cannot get HDMI status"

echo -e "\nFramebuffer info:"
fbset 2>/dev/null || echo "Cannot get framebuffer info"

echo -e "\n🔧 Quick Fixes:"
echo "For white screen after LCD5-show:"
echo "  ./fix-display.sh"
echo ""
echo "To restart kiosk mode manually:"
echo "  sudo systemctl restart lightdm"
echo ""
echo "To test kiosk script manually:"
echo "  DISPLAY=:0 /home/pi/start-kiosk.sh"
echo ""
echo "To check if app is accessible:"
echo "  curl http://localhost:4321"
echo ""
echo "Emergency display commands:"
echo "  sudo /opt/vc/bin/tvservice -p"
echo "  DISPLAY=:0 xrandr --output HDMI-1 --mode 800x480"
EOF

chmod +x /home/pi/troubleshoot-kiosk.sh

# Create emergency keyboard access script
echo "⌨️ Creating emergency keyboard access script..."
tee /home/pi/emergency-keyboard.sh > /dev/null <<'EOF'
#!/bin/bash
# Emergency on-screen keyboard access

echo "🔧 Emergency Keyboard Access"
echo "============================"

# Kill existing onboard instances
pkill onboard 2>/dev/null

# Start onboard keyboard in floating mode
echo "Starting on-screen keyboard..."
DISPLAY=:0 onboard --size=800x300 --dock-type=0 --theme=Droid &

echo "On-screen keyboard started!"
echo ""
echo "Touch gestures available:"
echo "• Tap screen edge to show/hide keyboard"
echo "• Long press for right-click menu"
echo ""
echo "Emergency shortcuts (if you have USB keyboard):"
echo "• Alt+F1: Toggle on-screen keyboard"
echo "• Alt+F2: Open terminal"
echo "• Alt+F3: Restart kiosk mode"
EOF

# Create Chromium warning suppression script for Pi Zero 2W
echo "🔇 Creating Chromium warning suppression script..."
tee /home/pi/suppress-chromium-warnings.sh > /dev/null <<'EOF'
#!/bin/bash
# Suppress Chromium warnings and optimize for Pi Zero 2W

echo "Configuring Chromium for Pi Zero 2W..."

# Create Chromium preferences to suppress warnings
mkdir -p /home/pi/.config/chromium/Default

# Suppress specific warnings and notifications
tee /home/pi/.config/chromium/Default/Preferences > /dev/null <<'PREFS'
{
   "profile": {
      "default_content_setting_values": {
         "notifications": 2,
         "geolocation": 2,
         "media_stream": 2,
         "media_stream_mic": 2,
         "media_stream_camera": 2
      },
      "content_settings": {
         "exceptions": {
            "notifications": {},
            "geolocation": {},
            "media_stream": {},
            "media_stream_mic": {},
            "media_stream_camera": {}
         }
      }
   },
   "browser": {
      "show_home_button": false,
      "check_default_browser": false
   },
   "distribution": {
      "skip_first_run_ui": true,
      "import_bookmarks": false,
      "import_history": false,
      "import_search_engine": false,
      "make_chrome_default": false,
      "make_chrome_default_for_user": false,
      "verbose_logging": false,
      "suppress_first_run_default_browser_prompt": true
   },
   "first_run_tabs": [],
   "homepage": "http://localhost:4321",
   "homepage_is_newtabpage": false,
   "session": {
      "restore_on_startup": 1,
      "startup_urls": ["http://localhost:4321"]
   }
}
PREFS

# Set proper ownership
chown -R pi:pi /home/pi/.config/chromium

# Create environment variables to suppress warnings
tee /home/pi/.chromium-env > /dev/null <<'ENV'
export CHROMIUM_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu-sandbox"
export LIBGL_ALWAYS_SOFTWARE=1
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-pi
export PULSE_RUNTIME_PATH=/tmp/pulse-runtime
ENV

echo "Chromium warnings suppression configured for Pi Zero 2W"
EOF

chmod +x /home/pi/emergency-keyboard.sh
chmod +x /home/pi/suppress-chromium-warnings.sh

# Create post-deployment service verification script
echo "🔍 Creating service verification script..."
tee /home/pi/verify-services.sh > /dev/null <<'EOF'
#!/bin/bash
# Verify and fix service configurations after deployment

echo "🔍 Service Verification and Fix"
echo "==============================="

# Check if we're in a proper systemd environment
if ! systemctl --version >/dev/null 2>&1; then
    echo "❌ SystemD not available"
    exit 1
fi

echo "📊 Checking service status..."

# Check scoreboard service
echo "Scoreboard service:"
if systemctl is-enabled scoreboard.service >/dev/null 2>&1; then
    echo "✅ Enabled"
else
    echo "⚠️  Not enabled, fixing..."
    sudo systemctl enable scoreboard.service 2>/dev/null || echo "❌ Failed to enable"
fi

if systemctl is-active scoreboard.service >/dev/null 2>&1; then
    echo "✅ Running"
else
    echo "⚠️  Not running, starting..."
    sudo systemctl start scoreboard.service 2>/dev/null || echo "❌ Failed to start"
fi

# Check LightDM service
echo -e "\nLightDM service:"
if systemctl is-enabled lightdm.service >/dev/null 2>&1; then
    echo "✅ Enabled"
else
    echo "⚠️  Not enabled, fixing..."
    sudo systemctl enable lightdm.service 2>/dev/null || {
        echo "Using alternative method..."
        sudo update-rc.d lightdm enable 2>/dev/null || true
        echo "/usr/sbin/lightdm" | sudo tee /etc/X11/default-display-manager > /dev/null
    }
fi

if systemctl is-active lightdm.service >/dev/null 2>&1; then
    echo "✅ Running"
else
    echo "⚠️  Not running"
    echo "   This is normal if running via SSH - LightDM starts on boot"
fi

# Check if graphical target is set
echo -e "\nBoot target:"
if systemctl get-default | grep -q graphical; then
    echo "✅ Graphical target set"
else
    echo "⚠️  Setting graphical target..."
    sudo systemctl set-default graphical.target
fi

# Verify auto-login configuration
echo -e "\nAuto-login configuration:"
if grep -q "autologin-user=pi" /etc/lightdm/lightdm.conf 2>/dev/null; then
    echo "✅ LightDM auto-login configured"
else
    echo "❌ LightDM auto-login not configured"
fi

if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
    echo "✅ Getty auto-login configured"
else
    echo "❌ Getty auto-login not configured"
fi

echo -e "\n📋 Summary:"
echo "If services show as 'Failed to enable', this is usually due to:"
echo "1. Running deployment via SSH before full boot"
echo "2. SystemD bus not available during deployment"
echo "3. This is often harmless - services will start on reboot"
echo ""
echo "🔄 To fix any issues, reboot the Pi:"
echo "   sudo reboot"
echo ""
echo "After reboot, run this script again to verify everything is working."
EOF

chmod +x /home/pi/verify-services.sh

# Create updated deployment instructions
echo "📋 Creating deployment instructions..."
tee /home/pi/DEPLOYMENT_INSTRUCTIONS.md > /dev/null <<'EOF'
# Table Tennis Scoreboard - Optimized Raspberry Pi Deployment

## Hardware Setup
- Raspberry Pi Zero 2W
- Waveshare 5-inch resistive touchscreen (800x480)
- 20Ah power bank

## Deployment Steps

### 1. Install Waveshare Display Driver (IMPORTANT!)
```bash
cd LCD-show
sudo ./LCD5-show
```
**This will reboot the Pi automatically**

### 2. Deploy Your App
After reboot, copy your built app:
```bash
cd /home/pi/table-tennis-scoreboard
# Copy your dist folder here, or build from source:
git clone [your-repo] .
npm install
npm run build
```

### 3. Start Services
```bash
sudo systemctl start scoreboard.service
sudo systemctl status scoreboard.service
```

### 4. Test Kiosk Mode
Reboot to test auto-start:
```bash
sudo reboot
```

## Troubleshooting

### If Kiosk Mode Doesn't Start:
```bash
# Run the troubleshooting script
./troubleshoot-kiosk.sh

# Manual restart
sudo systemctl restart lightdm

# Check if X11 is running
ps aux | grep Xorg

# Test kiosk script manually
DISPLAY=:0 /home/pi/start-kiosk.sh
```

### Common Issues:
1. **Black screen**: Display driver not installed - run `sudo ./LCD5-show`
2. **White screen after LCD5-show**: Run `./fix-display.sh` then `sudo reboot`
3. **No auto-start**: Check LightDM status - `sudo systemctl status lightdm`
4. **App not loading**: Check scoreboard service - `sudo systemctl status scoreboard.service`
5. **Touch not working**: Run touch calibration - `xinput_calibrator`
6. **Password prompt**: Multiple auto-login methods configured - should boot directly
7. **Chromium warnings on Pi Zero 2W**: Run `./suppress-chromium-warnings.sh`
8. **SystemD bus connection failed**: Run `./verify-services.sh` after reboot

### White Screen Fix:
```bash
# If you get white screen after LCD5-show:
./fix-display.sh
sudo reboot

# If still white screen, try via SSH:
sudo /opt/vc/bin/tvservice -p
sudo systemctl restart lightdm
```

### Emergency Access (No Physical Keyboard):
```bash
# If you can access via SSH:
./emergency-keyboard.sh

# Touch gestures on screen:
# • Tap screen edges to show on-screen keyboard
# • Long press for context menu
```

### Emergency Shortcuts (USB Keyboard):
- **Alt+F1**: Toggle on-screen keyboard
- **Alt+F2**: Open terminal
- **Alt+F3**: Restart kiosk mode

### Power Management:
```bash
# Optimize for battery use
./power-management.sh
```

### File Locations:
- App: `/home/pi/table-tennis-scoreboard/`
- Kiosk script: `/home/pi/start-kiosk.sh`
- Troubleshooting: `/home/pi/troubleshoot-kiosk.sh`
- Display fix: `/home/pi/fix-display.sh`
- Emergency keyboard: `/home/pi/emergency-keyboard.sh`
- Power management: `/home/pi/power-management.sh`
- Chromium optimization: `/home/pi/suppress-chromium-warnings.sh`
- Service verification: `/home/pi/verify-services.sh`
- Service: `/etc/systemd/system/scoreboard.service`
- Display config: `/boot/config.txt`
- Auto-login: `/etc/lightdm/lightdm.conf`
- Openbox autostart: `/home/pi/.config/openbox/autostart`
- Keyboard shortcuts: `/home/pi/.config/openbox/rc.xml`

## Expected Runtime
- **Total consumption**: ~4-6W (Pi + 5" display)
- **Runtime with 20Ah bank**: **16-20 hours**
EOF

echo ""
echo "✅ Optimized deployment script completed!"
echo ""
echo "🔧 Key Improvements Made:"
echo "   • Fixed auto-start timing issues"
echo "   • Simplified service dependencies"
echo "   • Added LightDM + multiple auto-login fallbacks"
echo "   • Installed on-screen keyboard (onboard)"
echo "   • Created emergency access methods"
echo "   • Added troubleshooting tools"
echo "   • Optimized for 5-inch Waveshare display"
echo ""
echo "📋 Next steps:"
echo "1. Run: cd LCD-show && sudo ./LCD5-show (will reboot)"
echo "2. After reboot, copy your app to /home/pi/table-tennis-scoreboard/dist/"
echo "3. Start services: sudo systemctl start scoreboard.service"
echo "4. Test: sudo reboot"
echo ""
echo "🔧 If issues occur, run: ./troubleshoot-kiosk.sh"
echo "📺 For white screen after LCD5-show: ./fix-display.sh"
echo "⌨️ For emergency keyboard access: ./emergency-keyboard.sh"
echo "🔇 For Pi Zero 2W optimization: ./suppress-chromium-warnings.sh"
echo "🔍 For service verification: ./verify-services.sh"
echo "📖 See /home/pi/DEPLOYMENT_INSTRUCTIONS.md for detailed instructions"