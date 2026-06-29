# Pi 4 WiFi Setup & Recovery Guide

## 🌐 **WiFi Configuration Methods**

### **Method 1: Direct Terminal Configuration (If you have keyboard/monitor)**

#### **Step 1: Check WiFi Status**
```bash
# Check if WiFi interface exists
ip link show

# Check current WiFi status
iwconfig

# Scan for available networks
sudo iwlist wlan0 scan | grep ESSID
```

#### **Step 2: Configure WiFi via raspi-config**
```bash
sudo raspi-config
```
- Navigate to: `1 System Options` → `S1 Wireless LAN`
- Enter your WiFi network name (SSID)
- Enter your WiFi password
- Finish and reboot

#### **Step 3: Manual WiFi Configuration**
```bash
# Edit WiFi configuration
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

Add your network:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YOUR_WIFI_NAME"
    psk="YOUR_WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
```

#### **Step 4: Restart WiFi**
```bash
# Restart WiFi service
sudo systemctl restart dhcpcd
sudo wpa_cli -i wlan0 reconfigure

# Check connection
ping -c 4 google.com
```

---

### **Method 2: SD Card Configuration (From Another Computer)**

#### **Step 1: Remove SD Card from Pi**
1. Power off Pi completely
2. Remove microSD card
3. Insert into computer

#### **Step 2: Create WiFi Configuration**
Navigate to the **boot** partition and create `wpa_supplicant.conf`:

```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YOUR_WIFI_NAME"
    psk="YOUR_WIFI_PASSWORD"
}
```

#### **Step 3: Enable SSH**
Create an empty file named `ssh` (no extension) in the boot partition.

#### **Step 4: Insert SD Card Back**
Put the SD card back in Pi and boot.

---

### **Method 3: Ethernet Connection (Recommended for Setup)**

#### **Use Ethernet Cable**
1. Connect Pi directly to router via Ethernet
2. Find Pi's IP address from router admin panel
3. SSH in: `ssh pi@[PI_IP_ADDRESS]`
4. Configure WiFi from SSH session

---

## 🔧 **WiFi Troubleshooting**

### **Common WiFi Issues & Fixes**

#### **WiFi Not Detected**
```bash
# Check if WiFi is blocked
sudo rfkill list all

# Unblock WiFi if needed
sudo rfkill unblock wifi

# Restart WiFi interface
sudo ip link set wlan0 down
sudo ip link set wlan0 up
```

#### **Wrong Country Code**
```bash
# Set correct country code
sudo raspi-config
# Navigate to: 5 Localisation Options → L4 WLAN Country
```

#### **5GHz vs 2.4GHz Issues**
- Pi 4 supports both, but 2.4GHz is more reliable
- Try connecting to 2.4GHz network first
- Some routers broadcast same name for both bands

#### **Password Issues**
```bash
# Test WiFi credentials
sudo wpa_passphrase "YOUR_WIFI_NAME" "YOUR_PASSWORD"
```

### **Advanced WiFi Diagnostics**
```bash
# Check WiFi driver
lsmod | grep brcm

# Check WiFi power management
iwconfig wlan0

# Disable power management if needed
sudo iwconfig wlan0 power off

# Check system logs for WiFi errors
sudo journalctl | grep wlan0
sudo dmesg | grep wlan0
```

---

## 📱 **Mobile Hotspot Method**

If your main WiFi isn't working:

1. **Create mobile hotspot** on your phone
2. **Use simple password** (no special characters)
3. **Connect Pi to hotspot**:
   ```bash
   sudo raspi-config
   # Add hotspot credentials
   ```
4. **SSH from phone or computer** connected to same hotspot
5. **Fix main WiFi** remotely

---

## 🔄 **WiFi Configuration Templates**

### **For WPA2 Networks**
```
network={
    ssid="YOUR_NETWORK"
    psk="YOUR_PASSWORD"
    key_mgmt=WPA-PSK
}
```

### **For Open Networks**
```
network={
    ssid="YOUR_NETWORK"
    key_mgmt=NONE
}
```

### **For Hidden Networks**
```
network={
    ssid="YOUR_NETWORK"
    psk="YOUR_PASSWORD"
    key_mgmt=WPA-PSK
    scan_ssid=1
}
```

### **For Enterprise Networks**
```
network={
    ssid="YOUR_NETWORK"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="username"
    password="password"
    phase2="auth=MSCHAPV2"
}
```

---

## ✅ **Quick WiFi Test Commands**

```bash
# Check if connected
iwconfig wlan0

# Get IP address
hostname -I

# Test internet
ping -c 4 8.8.8.8

# Test DNS
nslookup google.com

# Check WiFi signal strength
iwconfig wlan0 | grep Signal
```

---

## 🚨 **Emergency Recovery**

If WiFi completely fails:

1. **Use Ethernet cable** for internet
2. **Update system**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. **Reinstall WiFi packages**:
   ```bash
   sudo apt install --reinstall wpasupplicant
   sudo apt install --reinstall dhcpcd5
   ```
4. **Reset network configuration**:
   ```bash
   sudo systemctl restart networking
   sudo systemctl restart dhcpcd
   ```

---

## 📋 **WiFi Setup Checklist**

- [ ] Correct WiFi name (SSID)
- [ ] Correct password (case-sensitive)
- [ ] Correct country code set
- [ ] WiFi not blocked by rfkill
- [ ] 2.4GHz network (more compatible)
- [ ] Simple password (avoid special characters initially)
- [ ] SSH enabled for remote access
- [ ] Ethernet backup connection available

**💡 Pro Tip:** Always test WiFi with a simple setup first, then add complexity (special characters, 5GHz, etc.) once basic connection works.