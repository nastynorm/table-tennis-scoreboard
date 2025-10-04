# Table Tennis Scoreboard - DietPi Deployment

This directory contains the DietPi-specific deployment configuration for the Table Tennis Scoreboard application, optimized for Raspberry Pi Zero 2W with Waveshare 5" LCD display.

## Why DietPi?

DietPi offers significant advantages over standard Raspberry Pi OS for kiosk applications:

- **Faster Boot Time**: ~30 seconds vs 90 seconds
- **Lower Memory Usage**: ~150MB vs 300MB
- **Simplified Setup**: Automated software installation
- **Better Performance**: Optimized for single-board computers
- **Minimal Footprint**: Only essential components installed

## Prerequisites

- Raspberry Pi Zero 2W (or compatible)
- Waveshare 5" LCD display
- MicroSD card (8GB minimum, Class 10 recommended)
- Stable internet connection for initial setup

## Quick Start

### 1. Download and Flash DietPi

1. Download DietPi image from [dietpi.com](https://dietpi.com/)
2. Flash to SD card using Raspberry Pi Imager or Balena Etcher
3. Insert SD card into Pi Zero 2W

### 2. Initial DietPi Setup

1. Boot the Pi and complete initial DietPi setup
2. Enable SSH if needed: `dietpi-config` → Advanced Options → SSH
3. Update system: `dietpi-update`

### 3. Deploy Scoreboard

```bash
# Copy deployment script to Pi
scp deploy-dietpi.sh dietpi@your-pi-ip:/home/dietpi/

# SSH into Pi and run deployment
ssh dietpi@your-pi-ip
chmod +x deploy-dietpi.sh
sudo ./deploy-dietpi.sh
```

### 4. Automatic Deployment (Alternative)

If you have the source code locally:

```bash
# Copy entire source to Pi
scp -r ../table-tennis-scoreboard-main dietpi@your-pi-ip:/tmp/scoreboard-source

# Run deployment script
ssh dietpi@your-pi-ip
sudo /tmp/scoreboard-source/table-tennis-scoreboard-dietpi/deploy-dietpi.sh
```

## What the Deployment Script Does

1. **System Updates**: Updates DietPi to latest version
2. **Software Installation**: Installs Node.js, Chromium, Git via DietPi-Software
3. **Display Configuration**: Configures Waveshare 5" LCD (800x480)
4. **Application Setup**: Clones, builds, and configures the scoreboard
5. **Kiosk Mode**: Sets up Chromium in full-screen kiosk mode
6. **Auto-Start**: Configures automatic startup on boot
7. **System Service**: Creates systemd service for reliability
8. **Optimizations**: Applies Pi Zero 2W specific optimizations
9. **Troubleshooting**: Creates helper scripts for common issues

## File Structure

```
table-tennis-scoreboard-dietpi/
├── deploy-dietpi.sh           # Main deployment script
├── README.md                  # This file
├── config/
│   ├── config.txt.template    # Boot configuration template
│   └── autostart.conf         # DietPi autostart configuration
├── scripts/
│   ├── wifi-setup/            # WiFi configuration scripts
│   ├── network-diagnostics/   # Network troubleshooting tools
│   ├── scoreboard-management/ # Scoreboard service management
│   └── README.md              # Scripts documentation
└── systemd/
    └── scoreboard-kiosk.service # Systemd service file
```

## Configuration

### Display Settings

The deployment automatically configures the Waveshare 5" LCD:

```
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1
gpu_mem=64
```

### Kiosk Mode Features

- Full-screen Chromium browser
- Automatic crash recovery
- Memory optimizations for Pi Zero 2W
- Disabled unnecessary browser features
- Touch-friendly interface

### Performance Optimizations

- Disabled Bluetooth and unnecessary services
- Memory management tuning
- GPU memory allocation optimization
- Swap file disabled for SD card longevity

## Management Commands

After deployment, use these commands to manage the scoreboard:

```bash
# Service management
./scripts/scoreboard-management/manage-scoreboard.sh start     # Start the service
./scripts/scoreboard-management/manage-scoreboard.sh stop      # Stop the service
./scripts/scoreboard-management/manage-scoreboard.sh restart   # Restart the service
./scripts/scoreboard-management/manage-scoreboard.sh status    # Check service status
./scripts/scoreboard-management/manage-scoreboard.sh logs      # View live logs

# System commands
systemctl status scoreboard-kiosk    # Check service status
journalctl -u scoreboard-kiosk -f    # View logs
sudo reboot                          # Restart system
```

## Troubleshooting

### White Lines Moving Across Screen (Waveshare 5" LCD)

This is a common issue with the Waveshare 5" LCD. Try these solutions in order:

**Solution 1: Use Updated Config (Recommended)**
```bash
# Copy the updated config.txt template
sudo cp config/config.txt.template /boot/config.txt
sudo reboot
```

**Solution 2: Force Legacy Framebuffer**
```bash
# Edit /boot/config.txt and change:
# dtoverlay=vc4-kms-v3d,noaudio
# to:
# dtoverlay=vc4-fkms-v3d,noaudio
# framebuffer_width=800
# framebuffer_height=480
sudo nano /boot/config.txt
sudo reboot
```

**Solution 3: Disable Hardware Acceleration**
```bash
# Edit /boot/config.txt and comment out all dtoverlay lines:
# #dtoverlay=vc4-kms-v3d,noaudio
# Add:
# framebuffer_width=800
# framebuffer_height=480
# gpu_mem=64
sudo nano /boot/config.txt
sudo reboot
```

### White Screen or Display Issues

```bash
# Fix display configuration
sudo ./fix-display.sh
```

### Service Not Starting

```bash
# Check service status
systemctl status scoreboard-kiosk

# View detailed logs
journalctl -u scoreboard-kiosk -n 50

# Restart service
sudo systemctl restart scoreboard-kiosk
```

### Network Issues

```bash
# Check network connectivity
ping google.com

# Restart networking
sudo systemctl restart networking

# Check WiFi configuration
dietpi-config
```

### Static IP Configuration

Setting up a static IP address ensures your Pi always has the same IP address on your network, making it easier to access consistently.

#### Method 1: Using DietPi-Config (Recommended)

1. **Access DietPi-Config**:
   ```bash
   sudo dietpi-config
   ```

2. **Navigate to Network Options**:
   - Select `Network Options: Adapters`
   - Choose `WiFi` or `Ethernet` depending on your connection
   - Select `Change Mode`
   - Choose `Static`

3. **Configure Static IP Settings**:
   - **IP Address**: Enter your desired static IP (e.g., `192.168.1.100`)
   - **Subnet Mask**: Usually `255.255.255.0` or `24`
   - **Gateway**: Your router's IP address (e.g., `192.168.1.1`)
   - **DNS**: Primary DNS server (e.g., `8.8.8.8` or your router's IP)

4. **Apply and Restart**:
   - Select `Apply` to save changes
   - Restart networking: `sudo systemctl restart networking`
   - Or reboot: `sudo reboot`

#### Method 2: Manual Configuration via dhcpcd.conf

1. **Edit the dhcpcd configuration file**:
   ```bash
   sudo nano /etc/dhcpcd.conf
   ```

2. **Add static IP configuration** (add to the end of the file):
   ```bash
   # Static IP configuration for wlan0 (WiFi)
   interface wlan0
   static ip_address=192.168.88.100/24
   static routers=192.168.88.1
   static domain_name_servers=8.8.8.8 8.8.4.4
   
   # For other common networks:
   # 192.168.1.x network:
   # static ip_address=192.168.1.100/24
   # static routers=192.168.1.1
   
   # For Ethernet (eth0), use this instead:
   # interface eth0
   # static ip_address=192.168.88.100/24
   # static routers=192.168.88.1
   # static domain_name_servers=8.8.8.8 8.8.4.4
   ```

3. **Save and restart networking**:
   ```bash
   # Save file (Ctrl+X, then Y, then Enter)
   sudo systemctl restart dhcpcd
   sudo systemctl restart networking
   ```

#### Method 3: Using NetworkManager (Alternative)

If your DietPi uses NetworkManager:

```bash
# List available connections
sudo nmcli connection show

# Modify WiFi connection for static IP
sudo nmcli connection modify "YourWiFiName" ipv4.addresses 192.168.1.100/24
sudo nmcli connection modify "YourWiFiName" ipv4.gateway 192.168.1.1
sudo nmcli connection modify "YourWiFiName" ipv4.dns "8.8.8.8,8.8.4.4"
sudo nmcli connection modify "YourWiFiName" ipv4.method manual

# Restart the connection
sudo nmcli connection down "YourWiFiName"
sudo nmcli connection up "YourWiFiName"
```

#### Important Notes

- **Choose an IP outside DHCP range**: Check your router's DHCP range and pick an IP outside it
- **Common IP ranges**:
  - `192.168.1.x` (gateway usually `192.168.1.1`)
  - `192.168.0.x` (gateway usually `192.168.0.1`)
  - `192.168.88.x` (gateway usually `192.168.88.1`)
  - `10.0.0.x` (gateway usually `10.0.0.1`)
- **Find your network info**:
  ```bash
  # Current IP and gateway
  ip route show default
  
  # Current network configuration
  ip addr show
  
  # Router/gateway IP
  route -n | grep '^0.0.0.0'
  ```

#### Troubleshooting Static IP Issues

```bash
# Check current IP configuration
ip addr show wlan0

# Check routing table
ip route show

# Test connectivity to gateway
ping 192.168.1.1

# Test DNS resolution
nslookup google.com

# Restart network services
sudo systemctl restart dhcpcd
sudo systemctl restart networking

# Check dhcpcd status
sudo systemctl status dhcpcd

# View network logs
sudo journalctl -u dhcpcd -f
```

#### Reverting to DHCP

If you need to go back to automatic IP assignment:

**Via DietPi-Config**:
- Run `sudo dietpi-config`
- Network Options → WiFi → Change Mode → DHCP

**Via dhcpcd.conf**:
```bash
sudo nano /etc/dhcpcd.conf
# Comment out or remove the static IP lines
sudo systemctl restart dhcpcd
```

### Performance Issues

```bash
# Check memory usage
free -h

# Check CPU usage
htop

# Check disk space
df -h
```

## Accessing the Scoreboard

- **Local Access**: The scoreboard runs on `http://localhost:3000`
- **Network Access**: `http://[pi-ip-address]:3000`
- **Kiosk Mode**: Automatically displays on connected screen

## Customization

### Changing the URL

Edit `/home/dietpi/scripts/scoreboard-management/start-scoreboard.sh` and modify the Chromium startup line:

```bash
chromium-browser --kiosk ... http://your-custom-url
```

### Display Rotation

Add to `/boot/config.txt`:

```
display_rotate=1  # 90 degrees
display_rotate=2  # 180 degrees
display_rotate=3  # 270 degrees
```

### Auto-Update

To enable automatic updates, add to crontab:

```bash
# Update every night at 2 AM
0 2 * * * cd /home/dietpi/scoreboard && git pull && npm run build && systemctl restart scoreboard-kiosk
```

## Backup and Recovery

### Create Backup

```bash
# Backup application
tar -czf scoreboard-backup.tar.gz /home/dietpi/scoreboard

# Backup configuration
tar -czf config-backup.tar.gz /boot/config.txt /etc/systemd/system/scoreboard-kiosk.service
```

### Restore from Backup

```bash
# Restore application
tar -xzf scoreboard-backup.tar.gz -C /

# Restore configuration
tar -xzf config-backup.tar.gz -C /
sudo systemctl daemon-reload
```

## Performance Comparison

| Metric | DietPi | Raspberry Pi OS |
|--------|--------|-----------------|
| Boot Time | ~30 seconds | ~90 seconds |
| Memory Usage | ~150MB | ~300MB |
| Disk Usage | ~1.2GB | ~4GB |
| Setup Time | ~10 minutes | ~30 minutes |
| Maintenance | Minimal | Regular updates needed |

## Support

For issues specific to this DietPi deployment:

1. Check the troubleshooting section above
2. Review logs: `journalctl -u scoreboard-kiosk -f`
3. Verify display configuration: `cat /boot/config.txt`
4. Test network connectivity: `ping google.com`

For general scoreboard issues, refer to the main project documentation.

## Contributing

To improve this DietPi deployment:

1. Test changes on actual Pi Zero 2W hardware
2. Update documentation for any configuration changes
3. Ensure compatibility with latest DietPi versions
4. Submit pull requests to the main repository

## License

This deployment configuration follows the same license as the main Table Tennis Scoreboard project.