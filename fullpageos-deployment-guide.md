# FullPageOS Deployment Guide for Table Tennis Scoreboard

## Overview
FullPageOS provides the simplest possible kiosk setup for your table tennis scoreboard. It boots directly into a full-screen browser with minimal configuration required. This is ideal for users who want a "set it and forget it" solution.

## Prerequisites
- Raspberry Pi Zero 2W (or newer)
- MicroSD card (8GB minimum)
- Waveshare 5" LCD display (if using touch display)
- Network connection (WiFi or Ethernet)
- Pre-built scoreboard application hosted on a web server

## Step 1: Download and Flash FullPageOS

1. Download FullPageOS from: https://github.com/guysoft/FullPageOS/releases
2. Use Raspberry Pi Imager or balenaEtcher to flash the image
3. Configure the image before first boot

## Step 2: Pre-Boot Configuration

Before ejecting the SD card, modify these files in the boot partition:

### WiFi Configuration
Edit `fullpageos-wpa-supplicant.txt`:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourWiFiName"
    psk="YourWiFiPassword"
}
```

### Scoreboard URL Configuration
Edit `fullpageos.txt`:
```
# Table Tennis Scoreboard Configuration
fullpageos_url=http://YOUR_SERVER_IP:3000

# Display settings for Waveshare 5" LCD
fullpageos_hide_cursor=true
fullpageos_chromium_flags=--kiosk --no-sandbox --disable-infobars --disable-session-crashed-bubble --disable-translate --no-first-run --disable-features=TranslateUI --window-size=800,480 --window-position=0,0 --force-device-scale-factor=1

# Pi Zero 2W optimizations
fullpageos_chromium_flags=--kiosk --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-extensions --disable-plugins --disable-java --disable-translate --disable-infobars --disable-features=TranslateUI --disable-session-crashed-bubble --disable-notifications --disable-sync-preferences --disable-background-mode --disable-popup-blocking --no-first-run --disable-logging --disable-default-apps --disable-crash-reporter --disable-pdf-extension --disable-new-tab-first-run --start-maximized --mute-audio --hide-scrollbars --memory-pressure-off --window-size=800,480 --window-position=0,0 --force-device-scale-factor=1 --disk-cache-dir=/dev/null
```

### Display Configuration
Edit `config.txt` to add Waveshare 5" LCD support:
```
# Add these lines to the existing config.txt

# Waveshare 5" LCD Configuration
max_usb_current=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0

# Pi Zero 2W Optimizations
gpu_mem=64
force_turbo=0
cma=64
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0
```

## Step 3: Host Your Scoreboard Application

Since FullPageOS only displays web content, you need to host your built scoreboard application. You have several options:

### Option A: Use Another Raspberry Pi as Server
1. Set up a separate Pi with your current deployment script
2. Configure it to serve the built application
3. Point FullPageOS to this server's IP

### Option B: Use a Cloud Service
1. Deploy your built application to a cloud service (Netlify, Vercel, etc.)
2. Point FullPageOS to the cloud URL

### Option C: Local Network Server
1. Set up a local web server on your network
2. Copy the built application files to the server
3. Point FullPageOS to the local server IP

## Step 4: First Boot and Setup

1. Insert the configured SD card into your Pi Zero 2W
2. Connect the Waveshare display
3. Power on the Pi
4. FullPageOS will automatically:
   - Connect to WiFi
   - Start the browser in kiosk mode
   - Display your scoreboard application

## Step 5: Advanced Configuration (Optional)

If you need to make changes after initial setup, you can SSH into FullPageOS:

### Enable SSH
Create an empty file named `ssh` in the boot partition before first boot.

### SSH Access
```bash
ssh pi@[PI_IP_ADDRESS]
# Default password: raspberry
```

### Update URL
```bash
sudo nano /boot/fullpageos.txt
# Change fullpageos_url to new URL
sudo reboot
```

### Update Chromium Flags
```bash
sudo nano /boot/fullpageos.txt
# Modify fullpageos_chromium_flags
sudo reboot
```

## Step 6: Creating a Simple Setup Script

For easier deployment, create this setup script on your host computer:

```bash
#!/bin/bash
# FullPageOS Scoreboard Setup Script

echo "=== FullPageOS Table Tennis Scoreboard Setup ==="

# Variables - EDIT THESE
WIFI_SSID="YourWiFiName"
WIFI_PASSWORD="YourWiFiPassword"
SCOREBOARD_URL="http://192.168.1.100:3000"  # Change to your server IP
SD_MOUNT_POINT="/media/boot"  # Adjust for your system

echo "Configuring FullPageOS for table tennis scoreboard..."

# Configure WiFi
cat > "${SD_MOUNT_POINT}/fullpageos-wpa-supplicant.txt" << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PASSWORD}"
}
EOF

# Configure scoreboard URL and optimizations
cat > "${SD_MOUNT_POINT}/fullpageos.txt" << EOF
# Table Tennis Scoreboard Configuration
fullpageos_url=${SCOREBOARD_URL}

# Display settings for Waveshare 5" LCD
fullpageos_hide_cursor=true

# Pi Zero 2W optimized Chromium flags
fullpageos_chromium_flags=--kiosk --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-extensions --disable-plugins --disable-java --disable-translate --disable-infobars --disable-features=TranslateUI --disable-session-crashed-bubble --disable-notifications --disable-sync-preferences --disable-background-mode --disable-popup-blocking --no-first-run --disable-logging --disable-default-apps --disable-crash-reporter --disable-pdf-extension --disable-new-tab-first-run --start-maximized --mute-audio --hide-scrollbars --memory-pressure-off --window-size=800,480 --window-position=0,0 --force-device-scale-factor=1 --disk-cache-dir=/dev/null
EOF

# Add Waveshare LCD configuration to config.txt
cat >> "${SD_MOUNT_POINT}/config.txt" << EOF

# Waveshare 5" LCD Configuration
max_usb_current=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0

# Pi Zero 2W Optimizations
gpu_mem=64
force_turbo=0
cma=64
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0
EOF

# Enable SSH
touch "${SD_MOUNT_POINT}/ssh"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "FullPageOS has been configured for your table tennis scoreboard."
echo ""
echo "Configuration:"
echo "- WiFi SSID: ${WIFI_SSID}"
echo "- Scoreboard URL: ${SCOREBOARD_URL}"
echo "- Display: Waveshare 5\" LCD (800x480)"
echo "- SSH: Enabled"
echo ""
echo "Next steps:"
echo "1. Safely eject the SD card"
echo "2. Insert into Pi Zero 2W"
echo "3. Connect Waveshare display"
echo "4. Power on the Pi"
echo "5. The scoreboard will automatically start in ~20 seconds"
echo ""
echo "Troubleshooting:"
echo "- SSH access: ssh pi@[PI_IP] (password: raspberry)"
echo "- Change URL: Edit /boot/fullpageos.txt and reboot"
echo "- Display issues: Check /boot/config.txt settings"
echo ""
```

## Troubleshooting

### Common Issues

**White Screen or No Display:**
1. SSH into the Pi: `ssh pi@[PI_IP]`
2. Check config.txt: `sudo nano /boot/config.txt`
3. Verify Waveshare LCD settings are present
4. Reboot: `sudo reboot`

**Wrong URL Displayed:**
1. SSH into the Pi
2. Edit configuration: `sudo nano /boot/fullpageos.txt`
3. Update `fullpageos_url` line
4. Reboot: `sudo reboot`

**WiFi Connection Issues:**
1. Check WiFi configuration: `sudo nano /boot/fullpageos-wpa-supplicant.txt`
2. Verify SSID and password are correct
3. Check WiFi signal strength
4. Reboot: `sudo reboot`

**Performance Issues:**
1. Verify Pi Zero 2W optimizations in config.txt
2. Check Chromium flags in fullpageos.txt
3. Ensure scoreboard server is responsive
4. Consider reducing display resolution if needed

## Advantages of FullPageOS

1. **Simplest Setup:** Minimal configuration required
2. **Fastest Boot:** ~20 seconds to display
3. **Lowest Memory Usage:** ~100MB RAM usage
4. **Most Stable:** Purpose-built for single web page display
5. **Minimal Maintenance:** No complex services to manage
6. **Automatic Recovery:** Restarts browser if it crashes

## Limitations

1. **Requires External Server:** Cannot host the application locally
2. **Limited Customization:** Fewer configuration options
3. **No Local Development:** Must deploy changes to external server
4. **Network Dependent:** Requires stable internet/network connection
5. **Basic Troubleshooting:** Limited diagnostic tools

## When to Use FullPageOS

Choose FullPageOS when:
- You want the simplest possible setup
- You have a reliable network connection
- You can host the application externally
- You prioritize stability over customization
- You want minimal maintenance overhead

FullPageOS is perfect for permanent installations where you want a "set it and forget it" solution that just works reliably with minimal configuration.