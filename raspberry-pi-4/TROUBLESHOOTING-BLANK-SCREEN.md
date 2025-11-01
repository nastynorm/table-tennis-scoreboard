# Pi 4 Blank Screen Troubleshooting Guide

## 🚨 **Blank Screen with Cursor - Common Causes & Solutions**

### **Quick Diagnosis Steps**

#### **1. Check SSH Access (Recommended First Step)**
If you can SSH into your Pi, the system is running but the display/GUI isn't starting:

```bash
# From your computer, try to SSH into the Pi
ssh pi@[PI_IP_ADDRESS]
```

If SSH works, proceed to **Software Troubleshooting** below.
If SSH doesn't work, proceed to **Hardware Troubleshooting**.

---

## **🔧 Software Troubleshooting (SSH Accessible)**

### **Check System Status**
```bash
# Check if X server is running
ps aux | grep X

# Check if Chromium is running
ps aux | grep chromium

# Check system logs for errors
sudo journalctl -xe | tail -50

# Check boot messages
dmesg | tail -20
```

### **Check Display Configuration**
```bash
# Verify boot config
cat /boot/config.txt | grep hdmi

# Check current display status
tvservice -s

# List available display modes
tvservice -m CEA
tvservice -m DMT
```

### **Manual X Server Test**
```bash
# Stop any running X sessions
sudo pkill X
sudo pkill chromium

# Start X server manually (from SSH)
sudo systemctl stop lightdm 2>/dev/null || true
export DISPLAY=:0
startx &

# If X starts, try launching Chromium
DISPLAY=:0 chromium-browser --kiosk http://localhost:3000 &
```

### **Check Autostart Configuration**
```bash
# Verify autostart file exists and is correct
cat ~/.config/openbox/autostart

# Check if .bash_profile is configured for auto-X
cat ~/.bash_profile
```

### **Service Status Check**
```bash
# Check if scoreboard service is running
sudo systemctl status table-tennis-scoreboard

# Check if it's enabled
sudo systemctl is-enabled table-tennis-scoreboard

# Restart the service
sudo systemctl restart table-tennis-scoreboard
```

---

## **⚡ Quick Fixes to Try**

### **Fix 1: Force HDMI Output**
```bash
# Edit boot config to force HDMI
sudo nano /boot/config.txt

# Add these lines if missing:
hdmi_force_hotplug=1
hdmi_drive=2
config_hdmi_boost=4
```

### **Fix 2: Reset Display Configuration**
```bash
# Backup current config
sudo cp /boot/config.txt /boot/config.txt.backup

# Apply our dual HDMI config
sudo cp ~/table-tennis-scoreboard/raspberry-pi-4/boot-config-dual-hdmi.txt /boot/config.txt

# Reboot
sudo reboot
```

### **Fix 3: Recreate Autostart**
```bash
# Ensure directory exists
mkdir -p ~/.config/openbox

# Recreate autostart file
cat > ~/.config/openbox/autostart << 'EOF'
# Disable screen blanking
xset -dpms
xset s off
xset s noblank

# Hide mouse cursor
unclutter &

# Wait for network and services
sleep 10

# Launch Chromium in kiosk mode
chromium-browser --noerrdialogs --disable-infobars --disable-gpu --kiosk http://localhost:3000 --incognito &
EOF
```

### **Fix 4: Recreate .bash_profile**
```bash
cat > ~/.bash_profile << 'EOF'
# Auto-start X on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec startx
fi
EOF
```

---

## **🔌 Hardware Troubleshooting**

### **HDMI Connection Issues**
1. **Try Different HDMI Port**: Use HDMI0 (closest to power) instead of HDMI1
2. **Check Cable**: Try a different HDMI cable
3. **Monitor Compatibility**: Test with a different monitor/TV
4. **Power Supply**: Ensure you're using official Pi 4 power supply (5V 3A)

### **SD Card Issues**
1. **Reseat SD Card**: Remove and reinsert the microSD card
2. **Check SD Card**: Try the SD card in another device
3. **Flash Fresh Image**: Re-flash Raspberry Pi OS if corruption suspected

### **Boot Sequence Check**
1. **Rainbow Screen**: Should appear briefly during boot
2. **Boot Messages**: Text should scroll during startup
3. **Login Prompt**: Should appear if GUI fails

---

## **🚀 Emergency Recovery**

### **Method 1: Safe Mode Boot**
1. Power off Pi
2. Hold SHIFT while powering on
3. This should boot to recovery mode

### **Method 2: Edit Files from Another Computer**
1. Remove SD card from Pi
2. Insert into computer
3. Edit `/boot/config.txt` directly
4. Remove dual display settings temporarily:
   ```
   # Comment out these lines:
   # hdmi_group:0=2
   # hdmi_mode:0=87
   # hdmi_cvt:0=800 480 60 6 0 0 0
   ```

### **Method 3: Fresh Deploy**
If all else fails, re-run the deployment:
```bash
# SSH into Pi and re-run setup
cd ~/table-tennis-scoreboard
git pull
bash raspberry-pi-4/deploy.sh
```

---

## **📋 Common Solutions Summary**

| **Symptom** | **Likely Cause** | **Solution** |
|-------------|------------------|--------------|
| Cursor only, no GUI | X server not starting | Check autostart, restart X |
| Black screen, no cursor | HDMI/display issue | Force HDMI, check cables |
| Boot text then blank | Service failure | Check systemctl status |
| Works sometimes | Timing issue | Add delays to autostart |
| Wrong resolution | Boot config issue | Apply correct HDMI settings |

---

## **🔍 Debug Commands Reference**

```bash
# System info
uname -a
cat /proc/version

# Display info
vcgencmd display_power
vcgencmd get_config hdmi_group
vcgencmd get_config hdmi_mode

# Memory info
free -h
vcgencmd get_mem arm
vcgencmd get_mem gpu

# Temperature check
vcgencmd measure_temp

# Service logs
sudo journalctl -u table-tennis-scoreboard -f
```

---

**💡 Need Help?** If these steps don't resolve the issue, please share:
1. What you see on screen (cursor, black, boot text, etc.)
2. Output of `ssh pi@[PI_IP]` attempt
3. Any error messages from the debug commands above