# WiFi Pre-Configuration Guide for DietPi

This guide helps you configure WiFi settings on your DietPi SD card **before** inserting it into your Raspberry Pi. This is essential when you don't have a keyboard/monitor to configure WiFi directly on the Pi.

## 🎯 Quick Solution (Recommended)

### Option 1: Use the Quick Setup Script

1. **Download and run the quick setup script:**
   ```bash
   # On Windows (Git Bash/WSL) or Linux/Mac
   cd table-tennis-scoreboard-dietpi/scripts
   chmod +x wifi-setup/quick-wifi-setup.sh
   ./wifi-setup/quick-wifi-setup.sh
   ```

2. **Enter your WiFi credentials when prompted:**
   - WiFi Network Name (SSID): `YourWiFiName`
   - WiFi Password: `YourWiFiPassword`

3. **Copy the generated files to your SD card:**
   - Copy `wpa_supplicant.conf` to the **root** of your SD card
   - Copy `ssh` file to the **root** of your SD card

4. **Insert SD card into Pi and power on**

### Option 2: Manual File Creation

If you prefer to create the files manually:

1. **Create `wpa_supplicant.conf` file:**
   ```
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   country=US

   network={
       ssid="YourWiFiName"
       psk="YourWiFiPassword"
       key_mgmt=WPA-PSK
   }
   ```

2. **Create empty `ssh` file** (no extension, no content)

3. **Copy both files to the root of your SD card**

## 🔧 For Your 192.168.88.x Network

Since you mentioned your network uses `192.168.88.x`, here's a specific example:

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="YourNetworkName"
    psk="YourNetworkPassword"
    key_mgmt=WPA-PSK
}
```

## 📋 Step-by-Step Process

### 1. Prepare SD Card
- Flash DietPi to your SD card
- **Keep the SD card connected to your computer**

### 2. Configure WiFi
Choose one of the methods above to create WiFi configuration files.

### 3. Enable SSH Access
Create an empty file named `ssh` (no extension) in the root of the SD card.

### 4. Insert and Boot
- Safely eject SD card from computer
- Insert into Raspberry Pi
- Power on the Pi
- **Wait 2-3 minutes** for first boot and WiFi connection

### 5. Find Your Pi's IP Address
- Check your router admin panel (usually `http://192.168.88.1`)
- Look for "DietPi" or "raspberrypi" in connected devices
- Use a network scanner app on your phone
- The IP will likely be in range `192.168.88.100-254`

### 6. Connect via SSH
```bash
ssh dietpi@[IP_ADDRESS]
# Default password: dietpi
```

### 7. Run Deployment Script
```bash
cd /tmp
wget https://raw.githubusercontent.com/[your-repo]/table-tennis-scoreboard-dietpi/deploy-dietpi.sh
chmod +x deploy-dietpi.sh
sudo ./deploy-dietpi.sh
```

## 🛠️ Advanced Configuration

### Static IP Configuration
If you want to set a static IP during WiFi setup, you can also create a `dhcpcd.conf` file:

```
# Static IP for 192.168.88.x network
interface wlan0
static ip_address=192.168.88.100/24
static routers=192.168.88.1
static domain_name_servers=8.8.8.8 8.8.4.4
```

Copy this file to the SD card root as `dhcpcd.conf`.

### Hidden Networks
For hidden WiFi networks, add `scan_ssid=1` to your network configuration:

```
network={
    ssid="HiddenNetworkName"
    psk="NetworkPassword"
    key_mgmt=WPA-PSK
    scan_ssid=1
}
```

### Open Networks (No Password)
For open networks without passwords:

```
network={
    ssid="OpenNetworkName"
    key_mgmt=NONE
}
```

## 🔍 Troubleshooting

### Pi Doesn't Connect to WiFi

1. **Check file placement:**
   - Files must be in the **root** of the SD card (not in folders)
   - File names are case-sensitive

2. **Verify WiFi credentials:**
   - Double-check SSID (network name) spelling
   - Ensure password is correct
   - Make sure network is 2.4GHz (Pi Zero W requirement)

3. **Check router settings:**
   - Ensure MAC address filtering is disabled
   - Check if guest network isolation is enabled

4. **Re-create configuration files:**
   - Delete existing files and create new ones
   - Ensure proper file encoding (UTF-8, Unix line endings)

### Can't Find Pi's IP Address

1. **Check router admin panel:**
   - Go to `http://192.168.88.1` (or your router's IP)
   - Look in "Connected Devices" or "DHCP Clients"

2. **Use network scanning:**
   - Download "Fing" app on your phone
   - Scan for devices on your network
   - Look for "Raspberry Pi Foundation" devices

3. **Try common IP ranges:**
   ```bash
   # Try pinging common IPs
   ping 192.168.88.100
   ping 192.168.88.101
   # etc.
   ```

### SSH Connection Issues

1. **Verify SSH is enabled:**
   - Ensure `ssh` file exists in SD card root
   - File should be empty (0 bytes)

2. **Check firewall:**
   - Temporarily disable Windows firewall
   - Ensure port 22 is not blocked

3. **Try different SSH clients:**
   - Windows: PuTTY, Windows Terminal, Git Bash
   - Mac/Linux: Terminal

## 📁 File Structure on SD Card

After configuration, your SD card root should contain:
```
/
├── wpa_supplicant.conf    # WiFi configuration
├── ssh                    # Enables SSH (empty file)
├── dhcpcd.conf           # Static IP (optional)
├── dietpi.txt            # DietPi configuration (existing)
├── config.txt            # Boot configuration (existing)
└── ... (other DietPi files)
```

## ✅ Success Indicators

You'll know it worked when:
- Pi boots without errors (green LED activity)
- Pi appears in your router's connected devices
- You can SSH into the Pi successfully
- Network connectivity test passes during deployment

## 🚀 Next Steps

Once WiFi is working and you can SSH in:
1. Run the deployment script
2. The script will detect your pre-configured WiFi
3. Optionally configure static IP during deployment
4. Complete the scoreboard setup

This approach eliminates the need for a keyboard/monitor during initial setup!