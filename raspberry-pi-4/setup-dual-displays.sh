#!/bin/bash
# Dual Display Setup Script for Raspberry Pi 4
# Configures dual HDMI outputs for Table Tennis Scoreboard
# HDMI 0: 800x480 (Primary scoreboard display)
# HDMI 1: 1280x768 (Secondary/control display)
#
# Usage:
#   bash setup-dual-displays.sh [--apply|--test|--restore]
#
# Options:
#   --apply    Apply the dual display configuration
#   --test     Test current display configuration
#   --restore  Restore backup configuration

set -euo pipefail

ACTION="${1:-apply}"
BOOT_CONFIG="/boot/config.txt"
FIRMWARE_CONFIG="/boot/firmware/config.txt"
CONFIG_FILE=""

log() { echo "[display-setup] $*"; }

# Determine correct config file location
if [ -f "$BOOT_CONFIG" ]; then
  CONFIG_FILE="$BOOT_CONFIG"
elif [ -f "$FIRMWARE_CONFIG" ]; then
  CONFIG_FILE="$FIRMWARE_CONFIG"
else
  log "ERROR: Could not find boot config file."
  exit 1
fi

log "Using config file: $CONFIG_FILE"

apply_dual_display_config() {
  log "Applying dual HDMI display configuration..."
  
  # Create backup
  sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  log "Backup created: ${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  
  # Remove any existing dual HDMI configuration
  sudo sed -i '/# Dual HDMI Configuration/,/# End Dual HDMI Configuration/d' "$CONFIG_FILE"
  
  # Add optimized dual HDMI configuration
  sudo bash -c "cat >> '$CONFIG_FILE'" <<'EOF'

# Dual HDMI Configuration for Table Tennis Scoreboard
# HDMI 0: 800x480 (Primary scoreboard display)
# HDMI 1: 1280x768 (Secondary/control display)
max_framebuffers=2

# HDMI 0 Configuration (800x480)
hdmi_group:0=2
hdmi_mode:0=87
hdmi_cvt:0=800 480 60 6 0 0 0
hdmi_drive:0=2

# HDMI 1 Configuration (1280x768)
hdmi_group:1=2
hdmi_mode:1=87
hdmi_cvt:1=1280 768 60 6 0 0 0
hdmi_drive:1=2

# Force both HDMI outputs to be active
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1

# GPU memory split (important for dual displays)
gpu_mem=128

# Disable overscan for both displays
disable_overscan=1

# Enable hardware acceleration
dtoverlay=vc4-kms-v3d
max_framebuffer_width=1280
max_framebuffer_height=768

# Performance optimizations for Pi 4
arm_freq=1500
gpu_freq=500
over_voltage=2
arm_64bit=1

# Additional display optimizations
hdmi_pixel_freq_limit:0=400000000
hdmi_pixel_freq_limit:1=400000000
# End Dual HDMI Configuration
EOF

  log "Dual HDMI configuration applied successfully."
  log "Reboot required for changes to take effect: sudo reboot"
}

test_display_config() {
  log "Testing current display configuration..."
  
  # Check if dual HDMI config exists
  if grep -q "# Dual HDMI Configuration" "$CONFIG_FILE"; then
    log "✓ Dual HDMI configuration found in $CONFIG_FILE"
  else
    log "✗ Dual HDMI configuration not found"
  fi
  
  # Check connected displays
  if command -v tvservice >/dev/null 2>&1; then
    log "HDMI 0 status:"
    tvservice -s -v 2 || log "  HDMI 0 not detected"
    log "HDMI 1 status:"
    tvservice -s -v 7 || log "  HDMI 1 not detected"
  fi
  
  # Check framebuffer devices
  log "Available framebuffer devices:"
  ls -la /dev/fb* 2>/dev/null || log "  No framebuffer devices found"
  
  # Check display resolution
  if command -v fbset >/dev/null 2>&1; then
    log "Current framebuffer resolution:"
    fbset -s 2>/dev/null || log "  Could not get framebuffer info"
  fi
  
  # Check X11 displays (if running)
  if [ -n "${DISPLAY:-}" ]; then
    log "X11 display information:"
    xrandr 2>/dev/null || log "  xrandr not available or X11 not running"
  fi
}

restore_backup_config() {
  log "Restoring backup configuration..."
  
  # Find most recent backup
  BACKUP_FILE=$(ls -t "${CONFIG_FILE}.backup"* 2>/dev/null | head -1 || echo "")
  
  if [ -z "$BACKUP_FILE" ]; then
    log "ERROR: No backup file found."
    exit 1
  fi
  
  log "Restoring from: $BACKUP_FILE"
  sudo cp "$BACKUP_FILE" "$CONFIG_FILE"
  log "Configuration restored successfully."
  log "Reboot required for changes to take effect: sudo reboot"
}

setup_chromium_dual_display() {
  log "Setting up Chromium for dual display..."
  
  # Update Openbox autostart for dual display
  mkdir -p "$HOME/.config/openbox"
  cat > "$HOME/.config/openbox/autostart" <<'EOF'
# Disable screen blanking
xset -dpms
xset s off
xset s noblank

# Hide mouse cursor
unclutter &

# Give server a few seconds to start
sleep 5

# Configure dual displays with xrandr (if available)
if command -v xrandr >/dev/null 2>&1; then
  # Set up dual displays - adjust output names as needed
  xrandr --output HDMI-A-1 --mode 800x480 --primary --pos 0x0 2>/dev/null || true
  xrandr --output HDMI-A-2 --mode 1280x768 --pos 800x0 2>/dev/null || true
fi

# Launch Chromium in kiosk mode on primary display (HDMI 0)
DISPLAY=:0.0 chromium --noerrdialogs --disable-infobars --disable-gpu --kiosk http://localhost:3000
EOF
  chmod +x "$HOME/.config/openbox/autostart"
  log "Chromium dual display configuration updated."
}

case "$ACTION" in
  --apply|apply)
    apply_dual_display_config
    setup_chromium_dual_display
    ;;
  --test|test)
    test_display_config
    ;;
  --restore|restore)
    restore_backup_config
    ;;
  *)
    log "Usage: $0 [--apply|--test|--restore]"
    log "  --apply    Apply dual display configuration"
    log "  --test     Test current display setup"
    log "  --restore  Restore backup configuration"
    exit 1
    ;;
esac

log "Display setup operation completed."