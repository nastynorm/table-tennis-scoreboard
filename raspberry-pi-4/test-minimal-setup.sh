#!/bin/bash

# Minimal Pi 4 Test Configuration
# Run this to test basic functionality step by step

echo "🔧 Pi 4 Minimal Test Setup"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Step 1: Testing Network Connection${NC}"
ping -c 2 google.com > /dev/null 2>&1
check_status "Network connectivity"

echo -e "${YELLOW}Step 2: Testing WiFi Interface${NC}"
iwconfig wlan0 | grep -q "ESSID" 
check_status "WiFi interface active"

echo -e "${YELLOW}Step 3: Testing Display Configuration${NC}"
tvservice -s | grep -q "HDMI"
check_status "HDMI display detected"

echo -e "${YELLOW}Step 4: Testing X Server${NC}"
# Kill any existing X sessions first
sudo pkill X > /dev/null 2>&1
sudo pkill chromium > /dev/null 2>&1

# Test if X can start
DISPLAY=:0 xset q > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Starting X server..."
    startx &
    sleep 5
    DISPLAY=:0 xset q > /dev/null 2>&1
fi
check_status "X Server running"

echo -e "${YELLOW}Step 5: Testing Chromium${NC}"
DISPLAY=:0 chromium --version > /dev/null 2>&1
check_status "Chromium browser available"

echo -e "${YELLOW}Step 6: Testing Node.js${NC}"
node --version > /dev/null 2>&1
check_status "Node.js installed"

echo -e "${YELLOW}Step 7: Testing Scoreboard Service${NC}"
if [ -d "~/table-tennis-scoreboard" ]; then
    cd ~/table-tennis-scoreboard
    npm list > /dev/null 2>&1
    check_status "Scoreboard dependencies"
else
    echo -e "${RED}❌ Scoreboard directory not found${NC}"
fi

echo -e "${YELLOW}Step 8: Testing Port 3000${NC}"
curl -s http://localhost:3000 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    check_status "Scoreboard server running on port 3000"
else
    echo -e "${YELLOW}⚠️  Starting scoreboard server...${NC}"
    cd ~/table-tennis-scoreboard
    npm start &
    sleep 3
    curl -s http://localhost:3000 > /dev/null 2>&1
    check_status "Scoreboard server started"
fi

echo ""
echo "🎯 Quick Test Commands:"
echo "======================"
echo "Test display:     DISPLAY=:0 xeyes"
echo "Test browser:     DISPLAY=:0 chromium http://localhost:3000"
echo "Test kiosk mode:  DISPLAY=:0 chromium --kiosk http://localhost:3000"
echo "Check WiFi:       iwconfig"
echo "Check services:   sudo systemctl status table-tennis-scoreboard"

echo ""
echo "🔧 Quick Fixes:"
echo "==============="
echo "Fix display:      sudo cp ~/table-tennis-scoreboard/raspberry-pi-4/boot-config-minimal.txt /boot/config.txt && sudo reboot"
echo "Fix WiFi:         sudo raspi-config (System Options → Wireless LAN)"
echo "Restart service:  sudo systemctl restart table-tennis-scoreboard"

echo ""
echo "📋 System Info:"
echo "==============="
echo "OS Version:       $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel:           $(uname -r)"
echo "Pi Model:         $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
echo "Memory:           $(free -h | grep Mem | awk '{print $2}')"
echo "Disk Space:       $(df -h / | tail -1 | awk '{print $4}' | sed 's/G/ GB/')"
echo "Temperature:      $(vcgencmd measure_temp | cut -d'=' -f2)"

echo ""
echo -e "${GREEN}✅ Minimal test completed!${NC}"
echo "If any tests failed, check the emergency recovery guide."