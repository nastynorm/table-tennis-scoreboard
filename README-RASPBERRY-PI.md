# Table Tennis Scoreboard - Raspberry Pi Zero 2W Setup

## Hardware Configuration
- **Raspberry Pi Zero 2W** (1GHz quad-core, 512MB RAM)
- **Waveshare 5-inch Resistive Touchscreen** (800×480 HDMI, Low Power)
- **15.6-inch LCD Monitor** (via HDMI splitter)
- **20,000mAh Power Bank** (14-18 hours runtime with 5-inch display)

## Features Optimized for Small Screen
- ✅ **Touch-optimized buttons** (44px minimum touch targets)
- ✅ **Responsive layout** for 4-inch display
- ✅ **Larger score displays** for visibility
- ✅ **Simplified navigation** for touch interface
- ✅ **Battery-optimized performance**

## Quick Start

### 1. Prepare SD Card
```bash
# Flash Raspberry Pi OS Lite (64-bit) to SD card
# Enable SSH and configure WiFi in boot partition
```

### 2. Run Deployment Script
```bash
# Copy deploy-pi.sh to your Pi and run:
chmod +x deploy-pi.sh
./deploy-pi.sh
```

### 3. Install Display Driver
```bash
cd LCD-show
sudo ./LCD5-show  # This will reboot the Pi
```

### 4. Deploy Your App
```bash
cd /home/pi/table-tennis-scoreboard
# Option A: Copy pre-built files
cp -r /path/to/your/dist/* ./dist/

# Option B: Build from source
git clone [your-repo-url] .
npm install
npm run build
```

### 5. Start Services
```bash
sudo systemctl start scoreboard.service
sudo systemctl enable scoreboard.service
```

## Display Configuration

### Dual Display Setup
The configuration supports both displays simultaneously:
- **4-inch touchscreen**: Primary interface for scoring
- **15.6-inch monitor**: Secondary display for spectators

### Touch Calibration
If touch input is inaccurate:
```bash
sudo apt install xinput-calibrator
xinput_calibrator
```

## Power Management

### Battery Optimization
```bash
# Run the power management script
./power-management.sh
```

### Expected Runtime
- **Pi Zero 2W**: ~2-3W
- **4-inch display**: ~1-2W  
- **15.6-inch LCD**: ~8-12W
- **Total consumption**: ~12-17W
- **Runtime with 20Ah bank**: **12-16 hours**

## Kiosk Mode Features

### Auto-start Configuration
The app automatically starts in full-screen kiosk mode:
- No browser UI visible
- Touch-optimized interface
- Automatic recovery from crashes
- Network reconnection handling

### Browser Optimizations
- Hardware acceleration enabled
- Touch events optimized
- Scroll behavior disabled
- Translation UI disabled
- Faster startup times

## File Structure
```
/home/pi/table-tennis-scoreboard/
├── dist/                          # Built app files
├── start-kiosk.sh                # Kiosk startup script
├── power-management.sh           # Battery optimization
└── DEPLOYMENT_INSTRUCTIONS.md    # Detailed setup guide

/etc/systemd/system/
└── scoreboard.service            # App service

/home/pi/.config/lxsession/LXDE-pi/
└── autostart                     # Desktop autostart

/boot/
└── config.txt                    # Display configuration
```

## Troubleshooting

### Service Issues
```bash
# Check service status
sudo systemctl status scoreboard.service

# View logs
sudo journalctl -u scoreboard.service -f

# Restart service
sudo systemctl restart scoreboard.service
```

### Display Issues
```bash
# Test display manually
DISPLAY=:0 chromium-browser http://localhost:4321

# Check display configuration
tvservice -s

# Restart X server
sudo systemctl restart lightdm
```

### Touch Issues
```bash
# List input devices
xinput list

# Test touch input
xinput test [device-id]

# Recalibrate
xinput_calibrator
```

### Network Issues
```bash
# Check network status
ip addr show

# Test local server
curl http://localhost:4321

# Restart networking
sudo systemctl restart networking
```

## Performance Tips

### For Better Battery Life
1. **Reduce CPU frequency**: Already configured in power-management.sh
2. **Disable unused services**: Bluetooth, etc. disabled by default
3. **Lower screen brightness**: Adjust display settings
4. **Use airplane mode**: When WiFi not needed

### For Better Performance
1. **Increase GPU memory**: Already set to 128MB
2. **Use faster SD card**: Class 10 or better
3. **Overclock carefully**: With proper cooling only
4. **Monitor temperature**: `vcgencmd measure_temp`

## Customization

### Screen Rotation
Edit `/boot/config.txt`:
```ini
# Rotate 4-inch display
display_rotate=1  # 90 degrees
display_rotate=2  # 180 degrees
display_rotate=3  # 270 degrees
```

### Touch Sensitivity
For resistive touchscreen tuning:
```bash
# Adjust touch pressure threshold
echo 150 > /sys/class/input/input0/pressure_threshold
```

### Custom Startup
Modify `/home/pi/start-kiosk.sh` to customize:
- Startup delay
- Browser flags
- Display settings
- Error handling

## Maintenance

### Regular Updates
```bash
# Update system
sudo apt update && sudo apt upgrade

# Update app
cd /home/pi/table-tennis-scoreboard
git pull
npm run build
sudo systemctl restart scoreboard.service
```

### Backup Configuration
```bash
# Backup important configs
tar -czf scoreboard-backup.tar.gz \
  /home/pi/table-tennis-scoreboard \
  /etc/systemd/system/scoreboard.service \
  /home/pi/.config/lxsession/LXDE-pi/autostart \
  /boot/config.txt
```

## Support

### Log Locations
- **App logs**: `sudo journalctl -u scoreboard.service`
- **System logs**: `/var/log/syslog`
- **X server logs**: `/var/log/Xorg.0.log`

### Common Solutions
1. **Black screen**: Check HDMI connection and config.txt
2. **No touch**: Verify display driver installation
3. **App not loading**: Check network and service status
4. **Poor performance**: Monitor CPU temperature and load

This setup provides a robust, portable table tennis scoreboard perfect for tournaments, clubs, or home use!