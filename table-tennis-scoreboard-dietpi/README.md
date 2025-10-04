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
│   ├── start-scoreboard.sh    # Kiosk startup script
│   ├── fix-display.sh         # Display troubleshooting
│   └── manage-scoreboard.sh   # Service management
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
./manage-scoreboard.sh start     # Start the service
./manage-scoreboard.sh stop      # Stop the service
./manage-scoreboard.sh restart   # Restart the service
./manage-scoreboard.sh status    # Check service status
./manage-scoreboard.sh logs      # View live logs

# System commands
systemctl status scoreboard-kiosk    # Check service status
journalctl -u scoreboard-kiosk -f    # View logs
sudo reboot                          # Restart system
```

## Troubleshooting

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

Edit `/home/dietpi/start-scoreboard.sh` and modify the Chromium startup line:

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