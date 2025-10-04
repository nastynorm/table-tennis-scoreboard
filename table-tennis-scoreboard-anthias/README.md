# Table Tennis Scoreboard - Anthias (Screenly OSE) Deployment

This directory contains the Anthias-specific deployment configuration for the Table Tennis Scoreboard application, optimized for Raspberry Pi Zero 2W with Waveshare 5" LCD display.

## About Anthias (formerly Screenly OSE)

Anthias is the open-source digital signage platform formerly known as Screenly OSE. It provides:

- **Professional Digital Signage**: Enterprise-grade display management
- **Web-based Management**: Control displays remotely via web interface
- **Scheduling**: Time-based content scheduling
- **Multi-format Support**: Web pages, images, videos
- **Asset Management**: Centralized content management
- **API Control**: Programmatic content management

## Why Choose Anthias?

- ✅ Professional digital signage features
- ✅ Remote management capabilities
- ✅ Content scheduling and rotation
- ✅ Web-based administration interface
- ✅ API for automation
- ✅ Multi-display support
- ✅ Asset versioning and updates

## Prerequisites

- Raspberry Pi Zero 2W (or compatible)
- Waveshare 5" LCD display
- MicroSD card (8GB minimum, Class 10 recommended)
- Stable internet connection
- Computer for initial setup and management

## Quick Start

### 1. Download and Flash Anthias

1. Download Anthias image from [GitHub Releases](https://github.com/Screenly/Anthias/releases)
2. Flash to SD card using Raspberry Pi Imager or Balena Etcher
3. **Do not boot yet** - configure first

### 2. Pre-Boot Configuration

#### Configure WiFi
Edit `wpa_supplicant.conf` on SD card:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourWiFiName"
    psk="YourWiFiPassword"
}
```

#### Configure Display for Waveshare 5" LCD
Edit `config.txt` on SD card:
```
# Waveshare 5" LCD Configuration
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
gpu_mem=64

# Pi Zero 2W optimizations
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0
```

#### Enable SSH (Optional)
Create empty file named `ssh` on SD card root.

### 3. First Boot and Setup

1. Insert SD card into Pi Zero 2W
2. Connect Waveshare display
3. Power on the Pi
4. Wait for boot (may take 2-3 minutes)
5. Find Pi's IP address on your network
6. Access web interface: `http://[pi-ip-address]`

### 4. Configure Scoreboard Asset

1. Open Anthias web interface
2. Go to "Assets" section
3. Add new asset:
   - **Type**: Website
   - **URL**: Your scoreboard URL (see hosting options below)
   - **Duration**: 86400 (24 hours for always-on display)
   - **Name**: Table Tennis Scoreboard
4. Activate the asset

## Hosting the Scoreboard Application

Since Anthias displays web content, you need to host the scoreboard application:

### Option 1: Cloud Hosting (Recommended)

Deploy to a cloud service:

```bash
# Build the application
npm run build

# Deploy to Netlify (example)
npm install -g netlify-cli
netlify deploy --prod --dir=dist

# Use the provided URL in Anthias
```

### Option 2: Local Server

Host on your network:

```bash
# On a separate Pi or computer
npm run build
npx serve dist -l 3000

# Use http://[server-ip]:3000 in Anthias
```

### Option 3: GitHub Pages

```bash
# Build and deploy to GitHub Pages
npm run build
# Push dist folder to gh-pages branch
# Use https://username.github.io/table-tennis-scoreboard
```

## Anthias Web Interface

### Accessing the Interface

1. Find your Pi's IP address: `hostname -I`
2. Open browser: `http://[pi-ip-address]`
3. Default credentials: No authentication required (configure security!)

### Main Sections

#### Assets
- **Add Website**: Add your scoreboard URL
- **Upload Media**: Images, videos (not needed for scoreboard)
- **Asset Settings**: Duration, start/end dates
- **Preview**: Test assets before activation

#### Playlist
- **Active Assets**: Currently displayed content
- **Scheduling**: Time-based content rotation
- **Asset Order**: Sequence for multiple assets

#### Settings
- **Display Settings**: Resolution, orientation
- **Network Settings**: WiFi, ethernet configuration
- **System Settings**: Timezone, updates
- **API Settings**: Enable/configure API access

#### System Info
- **Hardware Info**: Pi model, memory, storage
- **Network Status**: IP address, connectivity
- **System Logs**: Troubleshooting information

## Configuration Files

### Asset Configuration

Create `scoreboard-asset.json` for API deployment:

```json
{
  "name": "Table Tennis Scoreboard",
  "uri": "https://your-scoreboard-url.com",
  "duration": "86400",
  "mimetype": "webpage",
  "is_enabled": 1,
  "nocache": 0,
  "play_order": 0,
  "skip_asset_check": 0
}
```

### Display Configuration

Edit `/boot/config.txt` for Waveshare 5" LCD:

```bash
# Waveshare 5" LCD optimized settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0

# Performance settings
gpu_mem=64
force_turbo=0
dtparam=audio=off
disable_overscan=1
```

### Network Configuration

Edit `/etc/wpa_supplicant/wpa_supplicant.conf`:

```bash
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourNetwork"
    psk="YourPassword"
    priority=1
}
```

## API Management

### Enable API Access

1. Access web interface
2. Go to Settings → API
3. Enable API access
4. Note the API endpoint: `http://[pi-ip]/api/v1/`

### API Examples

#### Add Scoreboard Asset
```bash
curl -X POST http://[pi-ip]/api/v1/assets \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Table Tennis Scoreboard",
    "uri": "https://your-scoreboard-url.com",
    "duration": "86400",
    "mimetype": "webpage"
  }'
```

#### Update Asset URL
```bash
curl -X PUT http://[pi-ip]/api/v1/assets/[asset-id] \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "https://new-scoreboard-url.com"
  }'
```

#### Get System Info
```bash
curl http://[pi-ip]/api/v1/info
```

## Advanced Features

### Content Scheduling

Schedule different content for different times:

1. Add multiple assets
2. Set start/end dates and times
3. Configure playlist order
4. Enable scheduling in Settings

### Remote Updates

Update scoreboard content remotely:

1. Deploy new version to hosting service
2. Asset will automatically refresh
3. Or use API to update asset URL
4. Monitor via web interface

### Multi-Display Management

Manage multiple kiosks:

1. Deploy Anthias to multiple Pis
2. Use API to update all displays
3. Create management scripts
4. Monitor all displays from central location

## Troubleshooting

### Display Issues

**Problem**: Black screen or wrong resolution
**Solution**:
1. Check `config.txt` Waveshare settings
2. Verify HDMI connections
3. Try different `hdmi_mode` values
4. Check System Info in web interface

**Problem**: Display rotated incorrectly
**Solution**:
1. Edit `config.txt`: `display_rotate=1` (90°)
2. Or use web interface Display Settings
3. Reboot after changes

### Network Issues

**Problem**: Can't access web interface
**Solution**:
1. Check Pi's IP address: `hostname -I`
2. Verify network connectivity
3. Check firewall settings
4. Try ethernet connection

**Problem**: Asset not loading
**Solution**:
1. Verify asset URL is accessible
2. Check internet connectivity
3. Review asset settings (duration, dates)
4. Check system logs in web interface

### Performance Issues

**Problem**: Slow loading or crashes
**Solution**:
1. Increase GPU memory in `config.txt`
2. Optimize scoreboard application
3. Use local hosting instead of cloud
4. Check system resources in web interface

### API Issues

**Problem**: API calls failing
**Solution**:
1. Verify API is enabled in Settings
2. Check API endpoint URL
3. Validate JSON syntax
4. Review API documentation

## File Locations

Important files on Anthias system:

- Configuration: `/boot/config.txt`
- WiFi: `/etc/wpa_supplicant/wpa_supplicant.conf`
- Assets: `/home/pi/screenly_assets/`
- Logs: `/var/log/screenly/`
- Database: `/home/pi/.screenly/screenly.db`
- Web interface: `/home/pi/screenly/`

## Security Considerations

### Basic Security

1. **Change Default Passwords**: Set strong passwords
2. **Enable Firewall**: Configure UFW or iptables
3. **Disable SSH**: If not needed for management
4. **Network Isolation**: Use separate VLAN if possible

### Advanced Security

1. **HTTPS**: Use SSL certificates for web interface
2. **VPN Access**: Restrict management to VPN
3. **API Authentication**: Implement API keys
4. **Regular Updates**: Keep system updated

## Backup and Recovery

### Create Backup

```bash
# Backup entire SD card
sudo dd if=/dev/sdX of=anthias-backup.img bs=4M status=progress

# Backup configuration only
tar -czf anthias-config-backup.tar.gz /boot/config.txt /etc/wpa_supplicant/ /home/pi/.screenly/
```

### Restore Configuration

```bash
# Restore from backup
tar -xzf anthias-config-backup.tar.gz -C /

# Restart services
sudo systemctl restart screenly-web
sudo systemctl restart screenly-viewer
```

## Performance Comparison

| Feature | Anthias | DietPi | FullPageOS |
|---------|---------|---------|------------|
| Setup Complexity | Medium | Medium | Simple |
| Management | Web Interface | SSH/Scripts | File Config |
| Remote Control | ✅ API + Web | ❌ SSH only | ❌ Limited |
| Scheduling | ✅ Advanced | ❌ None | ❌ None |
| Multi-Display | ✅ Yes | ❌ Manual | ❌ Manual |
| Resource Usage | Medium | Low | Lowest |
| Boot Time | ~60 seconds | ~30 seconds | ~45 seconds |
| Memory Usage | ~200MB | ~150MB | ~100MB |

## When to Use Anthias

Choose Anthias when you need:
- Professional digital signage features
- Remote management capabilities
- Content scheduling and rotation
- Multiple display management
- API-based automation
- Web-based administration

Consider alternatives if:
- You want simplest setup (use FullPageOS)
- You need lowest resource usage (use DietPi)
- You don't need remote management features
- You prefer command-line management

## Support and Resources

- **Official Documentation**: [Anthias Documentation](https://github.com/Screenly/Anthias)
- **Community Forum**: [Screenly Community](https://community.screenly.io/)
- **API Documentation**: Available in web interface
- **GitHub Issues**: [Report bugs and feature requests](https://github.com/Screenly/Anthias/issues)

## Contributing

To improve this Anthias deployment:
1. Test on Pi Zero 2W with Waveshare display
2. Optimize configuration for performance
3. Create automation scripts
4. Update documentation
5. Submit improvements to main repository

## License

This deployment configuration follows the same license as the main Table Tennis Scoreboard project.