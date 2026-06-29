# Raspberry Pi 4 Dual Display Setup

This guide provides optimized configuration for running the Table Tennis Scoreboard on a Raspberry Pi 4 with dual HDMI outputs.

## Display Configuration

- **HDMI 0**: 800x480 (Primary scoreboard display)
- **HDMI 1**: 1280x768 (Secondary/control display)

## Quick Setup

### Option 1: Automated Setup (Recommended)

Run the enhanced deploy script that includes dual display configuration:

```bash
bash raspberry-pi-4/deploy.sh
```

This will automatically:
- Configure both HDMI outputs with optimal resolutions
- Set up performance optimizations for Pi 4
- Install and configure the scoreboard application
- Enable auto-start on boot

### Option 2: Manual Display Setup

If you only want to configure the displays:

```bash
bash raspberry-pi-4/setup-dual-displays.sh --apply
```

## Files Included

- `boot-config-dual-hdmi.txt` - Complete boot configuration for dual HDMI
- `setup-dual-displays.sh` - Standalone dual display configuration script
- `deploy.sh` - Enhanced deployment script with dual display support

## Configuration Details

### Boot Configuration (`/boot/config.txt`)

The setup automatically adds these optimizations:

```ini
# Dual HDMI Configuration
max_framebuffers=2
hdmi_group:0=2
hdmi_mode:0=87
hdmi_cvt:0=800 480 60 6 0 0 0
hdmi_drive:0=2
hdmi_group:1=2
hdmi_mode:1=87
hdmi_cvt:1=1280 768 60 6 0 0 0
hdmi_drive:1=2
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
gpu_mem=128
disable_overscan=1
dtoverlay=vc4-kms-v3d
max_framebuffer_width=1280
max_framebuffer_height=768
arm_freq=1500
gpu_freq=500
over_voltage=2
arm_64bit=1
```

### Performance Optimizations

- **GPU Memory**: 128MB allocated for dual display support
- **CPU Frequency**: Overclocked to 1.5GHz for better performance
- **GPU Frequency**: Optimized to 500MHz
- **Hardware Acceleration**: VC4 KMS driver enabled

## Testing Your Setup

### Test Display Configuration

```bash
bash raspberry-pi-4/setup-dual-displays.sh --test
```

This will check:
- Boot configuration presence
- Connected displays status
- Framebuffer devices
- Current resolutions

### Manual Display Check

```bash
# Check HDMI status
tvservice -s -v 2  # HDMI 0
tvservice -s -v 7  # HDMI 1

# Check framebuffer devices
ls -la /dev/fb*

# Check X11 displays (if running)
xrandr
```

## Troubleshooting

### Display Not Detected

1. **Check connections**: Ensure both HDMI cables are securely connected
2. **Force hotplug**: The configuration includes `hdmi_force_hotplug` for both ports
3. **Check power**: Ensure adequate power supply (3A+ recommended for Pi 4)

### Wrong Resolution

1. **Verify config**: Check `/boot/config.txt` for correct settings
2. **Reboot required**: Display changes require a reboot to take effect
3. **Monitor compatibility**: Ensure monitors support the configured resolutions

### Performance Issues

1. **GPU memory**: Increase `gpu_mem` if experiencing graphics issues
2. **Cooling**: Ensure adequate cooling for overclocked settings
3. **Power supply**: Use official Pi 4 power supply or equivalent

### Restore Backup

If you need to restore the original configuration:

```bash
bash raspberry-pi-4/setup-dual-displays.sh --restore
```

## Advanced Configuration

### Custom Resolutions

To use different resolutions, modify the `hdmi_cvt` lines in `/boot/config.txt`:

```ini
# Format: hdmi_cvt:port=width height refresh aspect margins interlace reduced
hdmi_cvt:0=1024 600 60 6 0 0 0  # Custom resolution for HDMI 0
hdmi_cvt:1=1920 1080 60 6 0 0 0  # Custom resolution for HDMI 1
```

### Display Rotation

Add rotation settings if needed:

```ini
display_hdmi_rotate:0=1  # 90° rotation for HDMI 0
display_hdmi_rotate:1=2  # 180° rotation for HDMI 1
```

### Extended Desktop vs Mirrored

The current setup configures an extended desktop. For mirrored displays, modify the Openbox autostart:

```bash
# In ~/.config/openbox/autostart
xrandr --output HDMI-A-1 --mode 800x480 --output HDMI-A-2 --same-as HDMI-A-1
```

## Application Usage

### Primary Display (HDMI 0 - 800x480)
- Main scoreboard interface
- Optimized for touch interaction
- Full-screen Chromium kiosk mode

### Secondary Display (HDMI 1 - 1280x768)
- Control interface (if implemented)
- Statistics display
- Administrative functions

## Notes

- **Reboot required**: All display configuration changes require a reboot
- **Backup created**: Original config is automatically backed up
- **Pi 4 specific**: This configuration is optimized for Raspberry Pi 4
- **Power requirements**: Dual displays require adequate power supply (3A+)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Test with `setup-dual-displays.sh --test`
3. Review system logs: `dmesg | grep -i hdmi`
4. Check GPU memory: `vcgencmd get_mem gpu`
## Zero-click dual-screen auto-launch (control + spectator)

This brings the Pi up ready with **no clicks**: the **5″ 800×480 touch screen**
shows the **control board** (with the score buttons) and the **HDMI monitor**
shows a clean **spectator board** — kept in sync locally, no Wi-Fi/internet.

How it works: a single Chromium instance opens the control window on the 5″,
which then auto-opens the spectator window on the second display. Because both
windows are in the same browser instance they sync over the app's
BroadcastChannel. (The app reads `?screen=control` / `?screen=viewer` and the
control page opens the viewer via `?spawnViewer=1`.)

### Install

```bash
# 1) Make sure both displays are configured (see Display Configuration above)
sudo bash raspberry-pi-4/setup-dual-displays.sh --apply
sudo reboot

# 2) Copy the launcher to the Pi home and make it executable
cp raspberry-pi-4/start-scoreboard-dual.sh ~/
chmod +x ~/start-scoreboard-dual.sh

# 3) Auto-start it on login
mkdir -p ~/.config/autostart
cp raspberry-pi-4/autostart-scoreboard-dual.desktop ~/.config/autostart/
```

Reboot — the scoreboard comes up on both screens automatically.

### Run manually / test

```bash
bash ~/start-scoreboard-dual.sh
```

### Adjusting for a different monitor

The spectator window position/size default to `800,0` and `1280×768`. If your
HDMI monitor is a different resolution (e.g. 1280×1024) or your displays are
arranged differently, override via env vars:

```bash
VIEWER_X=800 VIEWER_Y=0 VIEWER_W=1280 VIEWER_H=1024 bash ~/start-scoreboard-dual.sh
```

(`VIEWER_X` is where the second display begins on the extended desktop — it
equals the width of the 5″ screen, normally 800.)

### Notes

- Popups must be allowed; the launcher passes `--disable-popup-blocking`.
- If the spectator window doesn't land fullscreen on the monitor, install a
  window tool and fullscreen it once (`sudo apt install wmctrl`), or press F11
  on that window — Chromium remembers it for the kiosk profile.
- The 5″ touch screen scores via the on-screen **+** buttons; you can also pair
  a Bluetooth presentation remote (Menu ▸ Setup ▸ Scoring Keys).
