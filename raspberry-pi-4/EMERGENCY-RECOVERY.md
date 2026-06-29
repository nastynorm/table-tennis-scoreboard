# 🚨 Pi 4 Emergency Recovery Guide

## **Your Current Issues:**
- ✅ Pi boots (you can run commands)
- ❌ Display shows blank screen with cursor after `startx`
- ❌ WiFi not working properly

---

## 🔧 **IMMEDIATE FIXES - Do These First**

### **Fix 1: Reset Display Configuration**

**Option A: If you have keyboard access to Pi:**
```bash
# Backup current config
sudo cp /boot/config.txt /boot/config.txt.broken

# Copy minimal working config
sudo cp ~/table-tennis-scoreboard/raspberry-pi-4/boot-config-minimal.txt /boot/config.txt

# Reboot
sudo reboot
```

**Option B: Using SD card on another computer:**
1. Power off Pi, remove SD card
2. Insert SD card into computer
3. Navigate to the `boot` partition
4. Rename `config.txt` to `config.txt.broken`
5. Copy `boot-config-minimal.txt` from this repo
6. Rename it to `config.txt`
7. Put SD card back in Pi and boot

### **Fix 2: Setup WiFi First**

**Method 1: Using SD card (Easiest):**
1. With SD card in computer, go to `boot` partition
2. Create file named `wpa_supplicant.conf`:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YOUR_WIFI_NAME"
    psk="YOUR_WIFI_PASSWORD"
}
```
3. Create empty file named `ssh` (no extension)
4. Put SD card back in Pi

**Method 2: Use Ethernet cable:**
- Connect Pi to router with Ethernet
- Find Pi's IP from router admin
- SSH in and configure WiFi

---

## 🎯 **Step-by-Step Recovery Process**

### **Step 1: Get Network Access**
```bash
# If using terminal on Pi directly:
sudo raspi-config
# Go to: System Options → Wireless LAN
# Enter WiFi name and password

# Test connection:
ping -c 4 google.com
```

### **Step 2: Fix Display Issues**
```bash
# Kill any running X sessions
sudo pkill X
sudo pkill chromium

# Apply minimal boot config
sudo cp ~/table-tennis-scoreboard/raspberry-pi-4/boot-config-minimal.txt /boot/config.txt

# Reboot to apply changes
sudo reboot
```

### **Step 3: Test Basic Display**
After reboot:
```bash
# Try starting X again
startx
```
You should now see a desktop instead of blank screen.

### **Step 4: Test Scoreboard**
```bash
# Check if scoreboard service is running
sudo systemctl status table-tennis-scoreboard

# If not running, start it
sudo systemctl start table-tennis-scoreboard

# Test in browser
DISPLAY=:0 chromium --kiosk http://localhost:3000 &
```

---

## 🔍 **Diagnosis Commands**

Run these to understand what's happening:

```bash
# Check display status
tvservice -s
vcgencmd display_power

# Check if X server can start
sudo systemctl status lightdm
ps aux | grep X

# Check WiFi status
iwconfig
ip addr show wlan0

# Check system logs
sudo journalctl -xe | tail -20
dmesg | tail -10
```

---

## 🛠 **Advanced Troubleshooting**

### **If Display Still Doesn't Work:**

**Try different HDMI modes:**
```bash
# Edit boot config
sudo nano /boot/config.txt

# Try these different modes one at a time:
# For 1080p:
hdmi_group=1
hdmi_mode=16

# For 720p:
hdmi_group=1
hdmi_mode=4

# For your specific 800x480:
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
```

### **If WiFi Still Doesn't Work:**

```bash
# Reset network completely
sudo systemctl stop dhcpcd
sudo systemctl stop wpa_supplicant
sudo ip link set wlan0 down
sudo ip link set wlan0 up
sudo systemctl start wpa_supplicant
sudo systemctl start dhcpcd

# Check if WiFi is blocked
sudo rfkill list all
sudo rfkill unblock wifi
```

---

## 📱 **Mobile Hotspot Backup Plan**

If your main WiFi won't work:

1. **Create hotspot on phone** with simple name/password
2. **Connect Pi to hotspot:**
   ```bash
   sudo raspi-config
   # Add hotspot credentials
   ```
3. **SSH from phone or laptop** connected to same hotspot
4. **Fix everything remotely**

---

## 🔄 **Complete Reset Procedure**

If nothing works, nuclear option:

```bash
# Backup your scoreboard code
cp -r ~/table-tennis-scoreboard ~/table-tennis-scoreboard-backup

# Reset to defaults
sudo raspi-config
# Advanced Options → Expand Filesystem
# System Options → Boot → Desktop Autologin

# Reinstall everything
cd ~/table-tennis-scoreboard
git pull
bash raspberry-pi-4/deploy.sh
```

---

## ✅ **Success Checklist**

After fixes, you should have:
- [ ] WiFi connected (`ping google.com` works)
- [ ] Desktop appears when running `startx`
- [ ] Scoreboard service running (`systemctl status table-tennis-scoreboard`)
- [ ] Chromium opens scoreboard (`http://localhost:3000`)
- [ ] SSH access working
- [ ] Auto-boot to kiosk mode working

---

## 🆘 **If All Else Fails**

1. **Flash fresh Raspberry Pi OS**
2. **Enable SSH and WiFi during imaging**
3. **Clone scoreboard repo**
4. **Run deploy script**
5. **Use minimal boot config**

**Files you need:**
- `raspberry-pi-4/boot-config-minimal.txt` (basic display)
- `raspberry-pi-4/WIFI-SETUP-GUIDE.md` (network setup)
- `raspberry-pi-4/deploy.sh` (full setup)

**Remember:** Start simple, then add complexity once basics work!