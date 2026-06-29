#!/bin/bash

# Waveshare 5-inch HDMI LCD + XPT2046 Touch Setup Script
# For Raspberry Pi 4 Table Tennis Scoreboard

set -e

echo "🖥️  Setting up Waveshare 5-inch HDMI LCD with XPT2046 Touch..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup current config
echo "📋 Backing up current /boot/config.txt..."
sudo cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)

# Apply Waveshare configuration
echo "⚙️  Applying Waveshare 5-inch configuration..."
sudo cp "$SCRIPT_DIR/boot-config-waveshare-5inch.txt" /boot/config.txt

# Install touch screen drivers and utilities
echo "📦 Installing touch screen packages..."
sudo apt update
sudo apt install -y xinput-calibrator xserver-xorg-input-evdev

# Enable SPI interface (required for XPT2046)
echo "🔧 Enabling SPI interface..."
sudo raspi-config nonint do_spi 0

# Install additional touch utilities
echo "🎯 Installing additional touch utilities..."
sudo apt install -y evtest input-utils

# Create touch calibration script
echo "📝 Creating touch calibration script..."
cat > /home/pi/calibrate-touch.sh << 'EOF'
#!/bin/bash
echo "🎯 Touch Screen Calibration"
echo "Follow the on-screen instructions to calibrate your touch screen"
echo "Press Ctrl+C to cancel"
sleep 3
xinput_calibrator
EOF

chmod +x /home/pi/calibrate-touch.sh

# Create touch test script
echo "📝 Creating touch test script..."
cat > /home/pi/test-touch.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing Touch Input"
echo "Touch the screen - you should see events below"
echo "Press Ctrl+C to stop"
echo ""
sudo evtest /dev/input/event0
EOF

chmod +x /home/pi/test-touch.sh

# Display information
echo ""
echo "✅ Waveshare 5-inch setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot your Pi: sudo reboot"
echo "2. After reboot, test display output"
echo "3. Test touch: /home/pi/test-touch.sh"
echo "4. Calibrate if needed: /home/pi/calibrate-touch.sh"
echo ""
echo "🔧 Configuration applied:"
echo "   - Display: 800x480 HDMI output"
echo "   - Touch: XPT2046 controller enabled"
echo "   - SPI interface enabled"
echo ""
echo "📁 Backup saved: /boot/config.txt.backup.*"
echo ""
echo "🚀 Ready to reboot and test!"