# HOWTO: Run on Raspberry Pi 4B 4GB (Desktop Version)

This guide shows how to set up and run the table tennis scoreboard on a Raspberry Pi 4B 4GB using Raspberry Pi OS Desktop with a convenient desktop shortcut.

## Prerequisites
- Raspberry Pi 4B with 4GB RAM (recommended for optimal performance)
- Raspberry Pi OS Desktop (latest version)
- MicroSD card (32GB or larger recommended)
- Network connection (WiFi or Ethernet)
- Monitor, keyboard, and mouse for initial setup

## 1) Prepare your Raspberry Pi 4B

### Initial Setup
1. Flash Raspberry Pi OS Desktop to your microSD card using Raspberry Pi Imager
2. Insert the SD card and boot your Pi
3. Complete the initial setup wizard:
   - Set country, language, and timezone
   - Create user account (default: `pi`)
   - Connect to WiFi network
   - Update system when prompted

### Configure Auto-login (Optional but Recommended)
```bash
sudo raspi-config
```
- Navigate to: `System Options` → `Boot / Auto Login` → `Desktop Autologin`
- This ensures the desktop loads automatically on boot

## 2) Install Dependencies

Open Terminal and run:
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Chromium browser (if not already installed)
sudo apt install -y chromium-browser

# Install Node.js 20+ (recommended method for Pi 4B)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installations
node --version
npm --version
chromium-browser --version
```

## 3) Deploy the Scoreboard App

### Option A: Download from GitHub (Recommended)
```bash
# Clone the repository
git clone https://github.com/nastynorm/table-tennis-scoreboard.git ~/table-tennis-scoreboard
cd ~/table-tennis-scoreboard
```

### Option B: Transfer from Another Computer
From your computer (Windows PowerShell):
```powershell
scp -r "table-tennis-scoreboard" pi@<PI_IP>:~/table-tennis-scoreboard
```

## 4) Install and Build the App
```bash
cd ~/table-tennis-scoreboard
npm ci
npm run build
```

## 5) Create Desktop Shortcut

### Create the Desktop Link Script
```bash
# Create a launcher script
cat > ~/start-scoreboard.sh << 'EOF'
#!/bin/bash
cd ~/table-tennis-scoreboard
npm run preview &
sleep 3
chromium-browser --start-fullscreen --no-first-run \
  --disable-session-crashed-bubble --disable-infobars --noerrdialogs \
  --app=http://localhost:4321
EOF

# Make it executable
chmod +x ~/start-scoreboard.sh
```

### Create Desktop Shortcut
```bash
# Create desktop shortcut file
cat > ~/Desktop/Table-Tennis-Scoreboard.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Table Tennis Scoreboard
Comment=Launch Table Tennis Scoreboard App
Exec=/home/pi/start-scoreboard.sh
Icon=/home/pi/table-tennis-scoreboard/public/android-chrome-192x192.png
Terminal=false
Categories=Game;Sports;
StartupNotify=true
EOF

# Make desktop file executable
chmod +x ~/Desktop/Table-Tennis-Scoreboard.desktop

# Trust the desktop file (required for newer Pi OS versions)
gio set ~/Desktop/Table-Tennis-Scoreboard.desktop metadata::trusted true
```

## 6) Test the Setup

### Manual Test
1. Double-click the "Table Tennis Scoreboard" icon on your desktop
2. The app should start automatically in fullscreen mode
3. Press `F11` to exit fullscreen if needed

### Command Line Test
```bash
# Start the app manually
cd ~/table-tennis-scoreboard
npm run preview
```
Then open Chromium and navigate to `http://localhost:4321`

## 7) Auto-start on Boot (Optional)

To automatically start the scoreboard when the Pi boots:
```bash
# Copy the autostart file
mkdir -p ~/.config/autostart
cp ~/table-tennis-scoreboard/raspberry-pi-4/autostart-scoreboard.desktop ~/.config/autostart/

# Edit the autostart file to use our script
sed -i 's|Exec=.*|Exec=/home/pi/start-scoreboard.sh|' ~/.config/autostart/autostart-scoreboard.desktop
```

## Performance Optimization for Pi 4B

### GPU Memory Split
Allocate more memory to GPU for better performance:
```bash
sudo raspi-config
```
- Navigate to: `Advanced Options` → `Memory Split`
- Set to `128` or `256` MB

### Disable Unnecessary Services
```bash
# Disable Bluetooth if not needed
sudo systemctl disable bluetooth
sudo systemctl disable hciuart

# Disable WiFi if using Ethernet
# sudo systemctl disable wpa_supplicant
```

## Troubleshooting

### App Won't Start
- Check Node.js version: `node --version` (should be 18+)
- Verify app installation: `cd ~/table-tennis-scoreboard && npm list`
- Check for port conflicts: `sudo netstat -tlnp | grep 4321`

### Desktop Shortcut Issues
- Ensure the desktop file is executable: `chmod +x ~/Desktop/Table-Tennis-Scoreboard.desktop`
- Check file permissions: `ls -la ~/Desktop/Table-Tennis-Scoreboard.desktop`
- Verify the script path in the desktop file

### Performance Issues
- Monitor system resources: `htop`
- Check temperature: `vcgencmd measure_temp`
- Ensure adequate power supply (official Pi 4B power adapter recommended)

## Remote Management

### SSH Access
Enable SSH for remote management:
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### Remote Start/Stop
```bash
# Start remotely
ssh pi@<PI_IP> '~/start-scoreboard.sh'

# Stop remotely
ssh pi@<PI_IP> 'pkill -f "npm run preview" && pkill chromium-browser'
```

## Notes
- The Pi 4B 4GB provides excellent performance for this application
- Use a high-quality microSD card (Class 10 or better) for optimal performance
- Consider using an SSD via USB 3.0 for even better performance
- The desktop shortcut makes it easy for non-technical users to start the app
- Exit fullscreen mode by pressing `F11`
- For best results, use a monitor with 1920x1080 resolution or higher