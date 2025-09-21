# 🏓 Complete How-To Guide: Table Tennis Scoreboard on Raspberry Pi Zero 2W

This comprehensive guide will walk you through setting up a portable table tennis scoreboard using a Raspberry Pi Zero 2W with a 5-inch Waveshare touchscreen display.

## 📋 What You'll Need

### Hardware Requirements
- **Raspberry Pi Zero 2W** (1GHz quad-core, 512MB RAM)
- **Waveshare 5-inch Resistive Touchscreen** (800×480 HDMI, Low Power)
- **MicroSD Card** (32GB Class 10 or better)
- **20,000mAh Power Bank** (with USB-C output)
- **15.6-inch LCD Monitor** (optional, for spectators)
- **HDMI Splitter** (if using secondary display)
- **USB-C to USB-A Cable**
- **Mini HDMI to HDMI Cable**

### Software Requirements
- **Raspberry Pi Imager** (for flashing OS)
- **SSH Client** (PuTTY on Windows, built-in on Mac/Linux)
- **This scoreboard application**

## 🚀 Step-by-Step Setup

### Step 1: Prepare the Raspberry Pi

1. **Download Raspberry Pi OS Lite:**
   - Go to [rpi.org/software](https://www.raspberrypi.org/software/)
   - Download Raspberry Pi Imager
   - Flash **Raspberry Pi OS Lite (64-bit)** to your SD card

2. **Enable SSH and WiFi:**
   - Before ejecting the SD card, add these files to the boot partition:
   
   **Create `ssh` file (empty file, no extension):**
   ```bash
   # Just create an empty file named 'ssh'
   ```
   
   **Create `wpa_supplicant.conf`:**
   ```
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   
   network={
       ssid="YourWiFiName"
       psk="YourWiFiPassword"
   }
   ```

3. **Insert SD card and boot the Pi**

### Step 2: Initial Pi Configuration

1. **Find your Pi's IP address:**
   ```bash
   # Check your router's admin panel or use:
   nmap -sn 192.168.1.0/24
   ```

2. **SSH into your Pi:**
   ```bash
   ssh pi@192.168.1.XXX
   # Default password: raspberry
   ```

3. **Update the system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

4. **Change default password:**
   ```bash
   passwd
   ```

### Step 3: Run the Automated Setup

1. **Download the deployment script:**
   ```bash
   wget https://raw.githubusercontent.com/yourusername/table-tennis-scoreboard/main/deploy-pi.sh
   chmod +x deploy-pi.sh
   ```

2. **Run the deployment script:**
   ```bash
   sudo ./deploy-pi.sh
   ```

   This script will:
   - Install Node.js and dependencies
   - Download Waveshare display drivers
   - Create system services
   - Configure auto-start
   - Set up power management
   - Configure display settings

### Step 4: Configure the Display

1. **Install Waveshare 5-inch display drivers:**
   ```bash
   cd LCD-show
   sudo ./LCD5-show
   ```
   
   **⚠️ Important:** This will reboot your Pi automatically.

2. **After reboot, verify display is working:**
   - You should see the desktop on your 5-inch screen
   - Touch should be responsive

### Step 5: Deploy the Scoreboard App

1. **Build the application on your computer:**
   ```bash
   npm run build
   ```

2. **Copy the built app to your Pi:**
   ```bash
   # From your computer, copy the dist folder
   scp -r dist/* pi@192.168.1.XXX:/home/pi/table-tennis-scoreboard/dist/
   ```

3. **Start the scoreboard service:**
   ```bash
   sudo systemctl start scoreboard.service
   sudo systemctl enable scoreboard.service
   ```

### Step 6: Configure Kiosk Mode

The deployment script automatically configures a complete kiosk mode setup:

1. **Kiosk Features Configured:**
   - **True fullscreen mode** - No toolbars, address bar, or UI elements
   - **Auto-login** - Pi boots directly to the scoreboard
   - **Auto-restart** - Browser restarts if it crashes
   - **Touch optimized** - Perfect for resistive touchscreen
   - **Hidden cursor** - Cursor disappears after 1 second

2. **Verify kiosk script:**
   ```bash
   cat /home/pi/start-kiosk.sh
   ```

3. **Check kiosk service status:**
   ```bash
   sudo systemctl status kiosk.service
   ```

4. **Manual kiosk start (for testing):**
   ```bash
   sudo systemctl start kiosk.service
   ```

5. **Kiosk service is auto-enabled** - Will start automatically on boot

## 🔧 Advanced Configuration

### Dual Display Setup (Optional)

If you want to use a secondary 15.6-inch monitor for spectators:

1. **Connect HDMI splitter:**
   - Pi → HDMI Splitter → 5-inch display + 15.6-inch monitor

2. **Configure displays in `/boot/config.txt`:**
   ```bash
   sudo nano /boot/config.txt
   ```
   
   Add these lines:
   ```
   # 5-inch primary display (800x480)
   hdmi_force_hotplug:0=1
   hdmi_group:0=2
   hdmi_mode:0=87
   hdmi_cvt:0=800 480 60 6 0 0 0
   hdmi_drive:0=2
   
   # 15.6-inch secondary display
   hdmi_force_hotplug:1=1
   hdmi_group:1=2
   hdmi_mode:1=82
   hdmi_drive:1=2
   ```

3. **Reboot to apply changes:**
   ```bash
   sudo reboot
   ```

### Touch Calibration

If touch accuracy needs adjustment:

1. **Install calibration tool:**
   ```bash
   sudo apt install xinput-calibrator
   ```

2. **Run calibration:**
   ```bash
   xinput_calibrator
   ```

3. **Follow on-screen instructions and save the configuration**

### Power Optimization

For maximum battery life:

1. **Disable unnecessary services:**
   ```bash
   sudo systemctl disable bluetooth
   sudo systemctl disable wifi-powersave
   ```

2. **Adjust CPU frequency:**
   ```bash
   sudo nano /boot/config.txt
   ```
   
   Add:
   ```
   # Power optimization
   arm_freq=1000
   over_voltage=0
   gpu_mem=64
   ```

## 🔍 Troubleshooting

### Display Issues

**Problem:** Display not working after driver installation
```bash
# Solution: Check if drivers installed correctly
ls /usr/share/X11/xorg.conf.d/
# Should see waveshare config files

# Reinstall if needed
cd LCD-show
sudo ./LCD5-show
```

**Problem:** Touch not responding
```bash
# Solution: Check input devices
xinput list
# Should see touchscreen device

# Recalibrate if needed
xinput_calibrator
```

### Network Issues

**Problem:** Can't connect to WiFi
```bash
# Solution: Check WiFi configuration
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

# Restart WiFi
sudo systemctl restart wpa_supplicant
```

### Service Issues

**Problem:** Scoreboard not starting automatically
```bash
# Check service status
sudo systemctl status scoreboard.service
sudo systemctl status kiosk.service

# Check logs
sudo journalctl -u scoreboard.service -f
sudo journalctl -u kiosk.service -f

# Restart services
sudo systemctl restart scoreboard.service
sudo systemctl restart kiosk.service
```

### Kiosk Mode Issues

**Problem:** Browser shows toolbars or address bar
```bash
# Check if kiosk script has correct flags
cat /home/pi/start-kiosk.sh
# Should include --kiosk --start-fullscreen flags

# Restart kiosk service
sudo systemctl restart kiosk.service
```

**Problem:** Kiosk mode not starting on boot
```bash
# Check auto-login configuration
sudo systemctl status getty@tty1.service

# Check if X11 auto-starts
cat /home/pi/.bashrc | grep startx

# Verify kiosk service is enabled
sudo systemctl is-enabled kiosk.service
```

**Problem:** Browser crashes or shows error pages
```bash
# Check kiosk service logs
sudo journalctl -u kiosk.service -f

# Clear browser cache and restart
sudo rm -rf /tmp/chromium-kiosk
sudo systemctl restart kiosk.service
```

### Performance Issues

**Problem:** App running slowly
```bash
# Check system resources
htop

# Increase GPU memory
sudo nano /boot/config.txt
# Change: gpu_mem=128

# Disable unnecessary processes
sudo systemctl disable bluetooth
sudo systemctl disable cups
```

## 📊 Battery Life Optimization

### Expected Runtime
- **5-inch display + Pi Zero 2W**: ~4W total consumption
- **20,000mAh power bank**: 14-18 hours runtime
- **With 15.6-inch monitor**: 8-12 hours runtime

### Power Saving Tips

1. **Lower screen brightness:**
   ```bash
   # Add to /boot/config.txt
   hdmi_drive=1  # Reduces power slightly
   ```

2. **Use power-efficient settings:**
   ```bash
   # CPU underclocking for battery life
   arm_freq=800
   core_freq=250
   ```

3. **Monitor power usage:**
   ```bash
   # Install power monitoring
   sudo apt install powertop
   sudo powertop
   ```

## 🎯 Usage Tips

### Operating the Scoreboard

1. **Starting a match:**
   - Touch "New Match" on the 5-inch screen
   - Set player names and match format
   - Begin scoring

2. **Scoring:**
   - Large touch targets optimized for 5-inch display
   - Clear, readable fonts at 800×480 resolution
   - Responsive touch interface

3. **Match management:**
   - Pause/resume functionality
   - Score corrections
   - Match history

### Maintenance

1. **Weekly updates:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Check disk space:**
   ```bash
   df -h
   ```

3. **Clean logs:**
   ```bash
   sudo journalctl --vacuum-time=7d
   ```

## 🆘 Support

### Log Files
- **Scoreboard service**: `sudo journalctl -u scoreboard.service`
- **Kiosk service**: `sudo journalctl -u kiosk.service`
- **System logs**: `sudo journalctl -f`

### Common Commands
```bash
# Restart scoreboard
sudo systemctl restart scoreboard.service

# Check service status
sudo systemctl status scoreboard.service

# View real-time logs
sudo journalctl -u scoreboard.service -f

# Reboot system
sudo reboot

# Shutdown system
sudo shutdown -h now
```

### File Locations
- **App files**: `/home/pi/table-tennis-scoreboard/`
- **Service files**: `/etc/systemd/system/`
- **Kiosk script**: `/home/pi/start-kiosk.sh`
- **Boot config**: `/boot/config.txt`

## 🎉 Enjoy Your Portable Scoreboard!

You now have a fully functional, portable table tennis scoreboard that:
- ✅ Runs for 14-18 hours on battery
- ✅ Features a responsive 5-inch touchscreen
- ✅ Automatically starts in kiosk mode
- ✅ Supports dual displays for spectators
- ✅ Optimized for tournament use

Happy playing! 🏓

---

**Need help?** Check the troubleshooting section above or create an issue in the repository.