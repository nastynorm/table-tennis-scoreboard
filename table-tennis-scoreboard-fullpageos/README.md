# Table Tennis Scoreboard - FullPageOS Deployment

This directory contains the FullPageOS-specific deployment configuration for the Table Tennis Scoreboard application, optimized for Raspberry Pi Zero 2W with Waveshare 5" LCD display.

## Why FullPageOS?

FullPageOS is the simplest kiosk solution for Raspberry Pi, offering:

- **Zero Configuration**: Boots directly into a web browser
- **Minimal Setup**: Just flash and configure URL
- **Ultra Lightweight**: Minimal resource usage
- **Stable**: Purpose-built for kiosk applications
- **Touch Optimized**: Built-in touch screen support

## Prerequisites

- Raspberry Pi Zero 2W (or compatible)
- Waveshare 5" LCD display
- MicroSD card (4GB minimum, Class 10 recommended)
- Stable internet connection or local server for hosting the scoreboard

## Important: Hosting Requirements

FullPageOS displays web content from a URL, so you need to host the scoreboard application somewhere accessible:

### Option 1: Separate Raspberry Pi Server
- Use another Pi to host the built application
- Run `npm run build && npx serve dist -l 3000` on the server Pi
- Point FullPageOS to `http://[server-pi-ip]:3000`

### Option 2: Cloud Hosting
- Deploy to Netlify, Vercel, or GitHub Pages
- Point FullPageOS to your hosted URL

### Option 3: Local Network Server
- Host on any computer on your network
- Ensure the server is always running when the kiosk is in use

## Quick Start

### 1. Download and Flash FullPageOS

1. Download FullPageOS from [github.com/guysoft/FullPageOS](https://github.com/guysoft/FullPageOS)
2. Flash to SD card using Raspberry Pi Imager or Balena Etcher
3. **Do not boot yet** - configure first

### 2. Pre-Boot Configuration

Before first boot, edit files on the SD card:

#### Configure WiFi (if using wireless)
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

#### Configure Scoreboard URL
Edit `fullpageos.txt`:
```
# Table Tennis Scoreboard Configuration
fullPageOS_url=http://your-server-ip:3000

# Waveshare 5" LCD Settings
fullPageOS_display_rotate=0
fullPageOS_hide_cursor=true
fullPageOS_cursor_timeout=2

# Performance optimizations for Pi Zero 2W
fullPageOS_gpu_mem=64
fullPageOS_disable_overscan=1
```

#### Configure Display for Waveshare 5" LCD
Edit `config.txt` on the SD card:
```
# Add these lines for Waveshare 5" LCD
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

### 3. First Boot

1. Insert SD card into Pi Zero 2W
2. Connect Waveshare display
3. Power on the Pi
4. FullPageOS will automatically:
   - Connect to WiFi
   - Configure display
   - Open the scoreboard URL in full-screen browser

## Configuration Files

### fullpageos.txt
Main configuration file for FullPageOS settings:

```bash
# Scoreboard URL (REQUIRED)
fullPageOS_url=http://192.168.1.100:3000

# Display settings
fullPageOS_display_rotate=0        # 0=normal, 1=90°, 2=180°, 3=270°
fullPageOS_hide_cursor=true        # Hide mouse cursor
fullPageOS_cursor_timeout=2        # Cursor timeout in seconds

# Browser settings
fullPageOS_chrome_flags="--disable-features=TranslateUI --disable-infobars"
fullPageOS_start_delay=10          # Delay before starting browser

# Performance settings
fullPageOS_gpu_mem=64              # GPU memory split
fullPageOS_disable_overscan=1      # Disable overscan
```

### fullpageos-wpa-supplicant.txt
WiFi configuration:

```bash
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YourWiFiNetwork"
    psk="YourWiFiPassword"
    priority=1
}

# Multiple networks (optional)
network={
    ssid="BackupNetwork"
    psk="BackupPassword"
    priority=2
}
```

### config.txt additions
Display configuration for Waveshare 5" LCD:

```bash
# Waveshare 5" LCD Configuration
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0

# Pi Zero 2W Optimizations
gpu_mem=64
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0
force_turbo=0
```

## Advanced Configuration

### SSH Access (Optional)

To enable SSH for troubleshooting:

1. Create empty file named `ssh` on SD card root
2. SSH credentials: `pi` / `raspberry` (change default password!)

### Custom Startup Script

Create `fullpageos-custom.sh` on SD card:

```bash
#!/bin/bash
# Custom startup script for scoreboard

# Wait for network
while ! ping -c 1 google.com >/dev/null 2>&1; do
    sleep 1
done

# Custom display settings
xset s off
xset -dpms
xset s noblank

# Start your custom services here
```

### Browser Customization

Edit browser flags in `fullpageos.txt`:

```bash
# Optimized flags for Pi Zero 2W
fullPageOS_chrome_flags="--disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --memory-pressure-off --disable-features=TranslateUI"
```

## Hosting the Scoreboard Application

### Method 1: Raspberry Pi Server

On a separate Raspberry Pi (or the same network):

```bash
# Clone and build the scoreboard
git clone https://github.com/yourusername/table-tennis-scoreboard.git
cd table-tennis-scoreboard
npm install
npm run build

# Serve the built application
npx serve dist -l 3000 -s

# Make it permanent with PM2
npm install -g pm2
pm2 start "npx serve dist -l 3000 -s" --name scoreboard
pm2 startup
pm2 save
```

### Method 2: Static File Server

Simple Python server:

```bash
cd table-tennis-scoreboard/dist
python3 -m http.server 3000
```

### Method 3: Nginx (Advanced)

Install and configure Nginx:

```bash
sudo apt install nginx
sudo cp -r dist/* /var/www/html/
sudo systemctl enable nginx
```

## Troubleshooting

### Display Issues

**Problem**: Black screen or wrong resolution
**Solution**: 
1. Check `config.txt` has correct Waveshare settings
2. Verify `hdmi_cvt=800 480 60 6 0 0 0` line
3. Try different `hdmi_mode` values (1-86)

**Problem**: Display rotated incorrectly
**Solution**: 
- Edit `fullpageos.txt`: `fullPageOS_display_rotate=1` (for 90° rotation)
- Or edit `config.txt`: `display_rotate=1`

### Network Issues

**Problem**: WiFi not connecting
**Solution**:
1. Check `fullpageos-wpa-supplicant.txt` syntax
2. Verify WiFi credentials
3. Check country code matches your location
4. Try ethernet cable for testing

**Problem**: Can't reach scoreboard URL
**Solution**:
1. Verify server is running: `curl http://server-ip:3000`
2. Check firewall settings on server
3. Ensure both devices on same network
4. Try IP address instead of hostname

### Browser Issues

**Problem**: Page not loading or white screen
**Solution**:
1. Check URL is accessible from another device
2. Verify server is serving correct content
3. Try different browser flags in `fullpageos.txt`
4. Check for JavaScript errors (enable SSH and check logs)

**Problem**: Touch not working
**Solution**:
1. Verify Waveshare touch drivers
2. Check USB connections
3. Add touch calibration to `config.txt`

### Performance Issues

**Problem**: Slow loading or laggy interface
**Solution**:
1. Reduce browser features in `fullpageos.txt`
2. Increase GPU memory: `fullPageOS_gpu_mem=128`
3. Optimize scoreboard application for mobile
4. Use wired ethernet instead of WiFi

## File Locations on FullPageOS

After boot, important files are located at:

- Configuration: `/boot/fullpageos.txt`
- WiFi: `/boot/fullpageos-wpa-supplicant.txt`
- Boot config: `/boot/config.txt`
- Logs: `/var/log/fullpageos.log`
- Browser cache: `/home/pi/.config/chromium/`

## Advantages and Limitations

### Advantages
- ✅ Extremely simple setup
- ✅ Minimal resource usage
- ✅ Stable and reliable
- ✅ Automatic recovery from crashes
- ✅ No Linux knowledge required
- ✅ Perfect for dedicated kiosks

### Limitations
- ❌ Requires external hosting
- ❌ Limited customization options
- ❌ No local application hosting
- ❌ Dependent on network connectivity
- ❌ Less control over system

## When to Use FullPageOS

Choose FullPageOS when:
- You want the simplest possible setup
- You have reliable network connectivity
- You can host the application elsewhere
- You need a dedicated, stable kiosk
- You don't need local customization

Consider DietPi instead if:
- You want to host the application locally
- You need more system control
- You want advanced customization
- Network connectivity is unreliable

## Backup and Recovery

### Create Backup
```bash
# Backup SD card (Linux/macOS)
sudo dd if=/dev/sdX of=fullpageos-backup.img bs=4M status=progress

# Backup configuration only
cp /boot/fullpageos.txt fullpageos-config-backup.txt
cp /boot/config.txt config-backup.txt
```

### Restore Configuration
```bash
# Copy configuration files to new SD card
cp fullpageos-config-backup.txt /boot/fullpageos.txt
cp config-backup.txt /boot/config.txt
```

## Support

For FullPageOS-specific issues:
1. Check [FullPageOS GitHub Issues](https://github.com/guysoft/FullPageOS/issues)
2. Verify configuration file syntax
3. Test URL accessibility from another device
4. Check network connectivity

For scoreboard application issues, refer to the main project documentation.

## Contributing

To improve this FullPageOS deployment:
1. Test on actual Pi Zero 2W hardware
2. Verify Waveshare 5" LCD compatibility
3. Update configuration templates
4. Submit improvements to main repository