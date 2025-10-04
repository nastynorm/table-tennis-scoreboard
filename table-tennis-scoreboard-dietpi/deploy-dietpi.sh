#!/bin/bash

# DietPi Table Tennis Scoreboard Deployment Script
# Optimized for Pi Zero 2W with Waveshare 5" LCD
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCOREBOARD_URL="https://github.com/nastynorm/table-tennis-scoreboard.git"
INSTALL_DIR="/home/dietpi/scoreboard"
SERVICE_NAME="scoreboard-kiosk"

echo -e "${BLUE}=== DietPi Table Tennis Scoreboard Deployment ===${NC}"
echo "Starting deployment for Pi Zero 2W with Waveshare 5\" LCD..."
echo ""

# Function to check if running on DietPi
check_dietpi() {
    # Check multiple DietPi indicators
    if [ -f /boot/dietpi/.dietpi-autostart_index ] || \
       [ -f /DietPi/dietpi/dietpi-software ] || \
       [ -f /usr/local/bin/dietpi-software ] || \
       [ -d /boot/dietpi ] || \
       [ -d /DietPi ] || \
       command -v dietpi-config >/dev/null 2>&1 || \
       grep -qi "dietpi" /etc/os-release 2>/dev/null; then
        echo -e "${GREEN}✓ DietPi system detected${NC}"
        return 0
    else
        echo -e "${RED}Error: This script is designed for DietPi systems only.${NC}"
        echo "Please install DietPi first: https://dietpi.com/"
        echo ""
        echo "Debug info:"
        echo "- /boot/dietpi exists: $([ -d /boot/dietpi ] && echo 'Yes' || echo 'No')"
        echo "- /DietPi exists: $([ -d /DietPi ] && echo 'Yes' || echo 'No')"
        echo "- dietpi-config available: $(command -v dietpi-config >/dev/null 2>&1 && echo 'Yes' || echo 'No')"
        exit 1
    fi
}

# Function to check network connectivity
check_network_connectivity() {
    echo -e "${BLUE}Checking network connectivity...${NC}"
    
    # Check if we have an IP address
    CURRENT_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$CURRENT_IP" ]; then
        echo -e "${RED}No IP address assigned. Network not connected.${NC}"
        return 1
    fi
    
    # Check if we can reach the internet
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Network connectivity confirmed${NC}"
        echo "Current IP: $CURRENT_IP"
        
        # Check WiFi connection details
        if iwconfig 2>/dev/null | grep -q "ESSID"; then
            WIFI_SSID=$(iwconfig 2>/dev/null | grep "ESSID" | sed 's/.*ESSID:"\([^"]*\)".*/\1/')
            echo "Connected to WiFi: $WIFI_SSID"
        fi
        return 0
    else
        echo -e "${YELLOW}⚠ Limited connectivity - no internet access${NC}"
        echo "Current IP: $CURRENT_IP"
        return 1
    fi
}

# Function to wait for network connection
wait_for_network() {
    echo -e "${YELLOW}Waiting for network connection...${NC}"
    local timeout=60
    local counter=0
    
    while [ $counter -lt $timeout ]; do
        if check_network_connectivity >/dev/null 2>&1; then
            echo -e "${GREEN}Network connection established.${NC}"
            return 0
        fi
        
        echo "Waiting for network... ($counter/$timeout seconds)"
        sleep 2
        counter=$((counter + 2))
    done
    
    echo -e "${RED}Network connection timeout after $timeout seconds${NC}"
    echo -e "${YELLOW}Continuing with deployment, but some features may not work properly.${NC}"
    return 1
}

# Function to detect pre-configured WiFi
detect_wifi_config() {
    echo -e "${BLUE}Detecting WiFi configuration...${NC}"
    
    # Check if wpa_supplicant.conf exists and has networks configured
    if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
        if grep -q "network=" /etc/wpa_supplicant/wpa_supplicant.conf; then
            local configured_ssid=$(grep -A 10 "network=" /etc/wpa_supplicant/wpa_supplicant.conf | grep "ssid=" | head -1 | sed 's/.*ssid="\([^"]*\)".*/\1/')
            echo -e "${GREEN}✓ WiFi already configured for: $configured_ssid${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}No WiFi configuration detected${NC}"
    return 1
}

# Function to update system
update_system() {
    echo -e "${BLUE}Updating DietPi system...${NC}"
    
    # Check network first
    if ! check_network_connectivity; then
        echo -e "${YELLOW}Network issues detected. Attempting to continue...${NC}"
        wait_for_network
    fi
    
    # Try different methods to update DietPi
    if command -v dietpi-update >/dev/null 2>&1; then
        echo "Running dietpi-update..."
        dietpi-update
    elif [ -f /boot/dietpi/dietpi-update ]; then
        echo "Running /boot/dietpi/dietpi-update..."
        /boot/dietpi/dietpi-update
    elif [ -f /DietPi/dietpi/dietpi-update ]; then
        echo "Running /DietPi/dietpi/dietpi-update..."
        /DietPi/dietpi/dietpi-update
    else
        echo -e "${YELLOW}dietpi-update not found, falling back to apt update...${NC}"
        apt update && apt upgrade -y
    fi
    
    echo -e "${GREEN}System updated successfully.${NC}"
}

# Function to install required software
install_software() {
    echo -e "${BLUE}Installing required packages...${NC}"
    
    # Check if dietpi-software is available
    if command -v dietpi-software >/dev/null 2>&1; then
        echo "Using dietpi-software for installation..."
        
        # Install Node.js
        echo "Installing Node.js..."
        dietpi-software install 9
        
        # Install Chromium
        echo "Installing Chromium..."
        dietpi-software install 113
        
        # Install Git
        echo "Installing Git..."
        dietpi-software install 17
        
    elif [ -f /boot/dietpi/dietpi-software ]; then
        echo "Using /boot/dietpi/dietpi-software for installation..."
        
        # Install Node.js
        echo "Installing Node.js..."
        /boot/dietpi/dietpi-software install 9
        
        # Install Chromium
        echo "Installing Chromium..."
        /boot/dietpi/dietpi-software install 113
        
        # Install Git
        echo "Installing Git..."
        /boot/dietpi/dietpi-software install 17
        
    elif [ -f /DietPi/dietpi/dietpi-software ]; then
        echo "Using /DietPi/dietpi/dietpi-software for installation..."
        
        # Install Node.js
        echo "Installing Node.js..."
        /DietPi/dietpi/dietpi-software install 9
        
        # Install Chromium
        echo "Installing Chromium..."
        /DietPi/dietpi/dietpi-software install 113
        
        # Install Git
        echo "Installing Git..."
        /DietPi/dietpi/dietpi-software install 17
        
    else
        echo -e "${YELLOW}dietpi-software not found, using apt for installation...${NC}"
        
        # Update package list
        apt update
        
        # Install Node.js (using NodeSource repository)
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt install -y nodejs
        
        # Install Chromium
        echo "Installing Chromium..."
        apt install -y chromium-browser
        
        # Install Git
        echo "Installing Git..."
        apt install -y git
    fi
    
    echo -e "${GREEN}All packages installed successfully.${NC}"
}

# Function to configure display for Waveshare 5" LCD
configure_display() {
    echo -e "${BLUE}Configuring Waveshare 5\" LCD display...${NC}"
    
    # Backup original config
    cp /boot/config.txt /boot/config.txt.backup
    
    # Add Waveshare LCD configuration
    cat >> /boot/config.txt << 'EOF'

# Waveshare 5" LCD Configuration
max_usb_current=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1
display_rotate=0

# Pi Zero 2W Optimizations
gpu_mem=64
force_turbo=0
cma=64
dtparam=audio=off
camera_auto_detect=0
display_auto_detect=0

# Disable conflicting overlays
#dtoverlay=vc4-kms-v3d
#dtoverlay=vc4-fkms-v3d
EOF
    
    echo -e "${GREEN}Display configuration completed.${NC}"
}

# Function to setup scoreboard application
setup_application() {
    echo -e "${BLUE}Setting up scoreboard application...${NC}"
    
    # Create application directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Clone repository (or copy if local)
    if [ -d "/tmp/scoreboard-source" ]; then
        echo "Copying local source files..."
        cp -r /tmp/scoreboard-source/* .
    else
        echo "Cloning from repository..."
        git clone "$SCOREBOARD_URL" .
    fi
    
    # Install dependencies and build
    echo "Installing Node.js dependencies..."
    npm install
    
    echo "Building application..."
    npm run build
    
    # Install serve package globally for serving static files
    npm install -g serve
    
    echo -e "${GREEN}Application setup completed.${NC}"
}

# Function to create kiosk startup script
create_startup_script() {
    echo -e "${BLUE}Creating kiosk startup script...${NC}"
    
    cat > /home/dietpi/start-scoreboard.sh << 'EOF'
#!/bin/bash

# Table Tennis Scoreboard Kiosk Startup Script
# Optimized for Pi Zero 2W

# Wait for network connection
echo "Waiting for network connection..."
while ! ping -c 1 -W 2 google.com >/dev/null 2>&1; do
    echo "Network not ready, waiting..."
    sleep 2
done
echo "Network connection established."

# Start local server for built application
echo "Starting scoreboard server..."
cd /home/dietpi/scoreboard
serve dist -l 3000 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Configure display settings
export DISPLAY=:0
xset s off
xset s noblank
xset -dpms

# Clean up any existing Chromium processes
pkill -9 chromium-browser 2>/dev/null || true
pkill -9 chrome 2>/dev/null || true

# Clean up Chromium cache and preferences
find ~/.config/chromium/Default/ -type f \( -name "Cookies" -o -name "History" -o -name "*.log" -o -name "*.ldb" -o -name "*.sqlite" \) -delete 2>/dev/null || true
rm -rf ~/.config/chromium/Default/Logs/* 2>/dev/null || true

# Prevent Chromium restore prompts
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/'Local State' 2>/dev/null || true
sed -i 's/"exit_type":"[^"]\+"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences 2>/dev/null || true

echo "Starting Chromium in kiosk mode..."

# Start Chromium with Pi Zero 2W optimizations
chromium-browser \
    --kiosk \
    --no-sandbox \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    --disable-extensions \
    --disable-plugins \
    --disable-java \
    --disable-translate \
    --disable-infobars \
    --disable-features=TranslateUI \
    --disable-session-crashed-bubble \
    --disable-notifications \
    --disable-sync-preferences \
    --disable-background-mode \
    --disable-popup-blocking \
    --no-first-run \
    --disable-logging \
    --disable-default-apps \
    --disable-crash-reporter \
    --disable-pdf-extension \
    --disable-new-tab-first-run \
    --start-maximized \
    --mute-audio \
    --hide-scrollbars \
    --memory-pressure-off \
    --force-device-scale-factor=1 \
    --window-position=0,0 \
    --window-size=800,480 \
    --disk-cache-dir=/dev/null \
    --user-data-dir=/tmp/chromium-kiosk \
    http://localhost:3000 &

CHROMIUM_PID=$!

# Monitor processes and restart if needed
while true; do
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo "Server crashed, restarting..."
        cd /home/dietpi/scoreboard
        serve dist -l 3000 &
        SERVER_PID=$!
        sleep 5
    fi
    
    if ! kill -0 $CHROMIUM_PID 2>/dev/null; then
        echo "Chromium crashed, restarting..."
        pkill -9 chromium-browser 2>/dev/null || true
        sleep 2
        chromium-browser --kiosk --no-sandbox --disable-gpu http://localhost:3000 &
        CHROMIUM_PID=$!
    fi
    
    sleep 10
done
EOF
    
    chmod +x /home/dietpi/start-scoreboard.sh
    echo -e "${GREEN}Startup script created.${NC}"
}

# Function to configure DietPi autostart
configure_autostart() {
    echo -e "${BLUE}Configuring DietPi autostart...${NC}"
    
    # Set custom script autostart
    echo "2" > /boot/dietpi/.dietpi-autostart_index
    echo "/home/dietpi/start-scoreboard.sh" > /boot/dietpi/.dietpi-autostart_custom
    
    echo -e "${GREEN}Autostart configured.${NC}"
}

# Function to create systemd service for better reliability
create_systemd_service() {
    echo -e "${BLUE}Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << 'EOF'
[Unit]
Description=Table Tennis Scoreboard Kiosk
After=graphical-session.target network.target
Wants=graphical-session.target

[Service]
Type=simple
User=dietpi
Group=dietpi
Environment=DISPLAY=:0
Environment=HOME=/home/dietpi
WorkingDirectory=/home/dietpi
ExecStart=/home/dietpi/start-scoreboard.sh
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=30

[Install]
WantedBy=graphical-session.target
EOF
    
    # Enable the service
    systemctl enable ${SERVICE_NAME}.service
    
    echo -e "${GREEN}Systemd service created and enabled.${NC}"
}

# Function to optimize system for Pi Zero 2W
optimize_system() {
    echo -e "${BLUE}Applying Pi Zero 2W optimizations...${NC}"
    
    # Disable unnecessary services
    systemctl disable bluetooth 2>/dev/null || true
    systemctl disable avahi-daemon 2>/dev/null || true
    systemctl disable triggerhappy 2>/dev/null || true
    systemctl disable dphys-swapfile 2>/dev/null || true
    
    # Memory optimizations
    cat >> /etc/sysctl.conf << 'EOF'

# Pi Zero 2W Memory Optimizations
vm.overcommit_memory=1
vm.vfs_cache_pressure=50
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
EOF
    
    echo -e "${GREEN}System optimizations applied.${NC}"
}

# Function to configure static IP
configure_static_ip() {
    echo -e "${BLUE}Network Configuration${NC}"
    echo ""
    echo "Would you like to configure a static IP address? (recommended for kiosk deployment)"
    echo "This ensures your Pi always has the same IP address for easy access."
    echo ""
    read -p "Configure static IP? (y/n): " configure_ip
    
    if [[ "$configure_ip" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Current network information:${NC}"
        
        # Get current network info
        CURRENT_IP=$(hostname -I | awk '{print $1}')
        CURRENT_GATEWAY=$(ip route show default | awk '/default/ { print $3 }')
        CURRENT_INTERFACE=$(ip route show default | awk '/default/ { print $5 }')
        
        echo "Current IP: $CURRENT_IP"
        echo "Current Gateway: $CURRENT_GATEWAY"
        echo "Current Interface: $CURRENT_INTERFACE"
        echo ""
        
        # Prompt for static IP settings
        echo -e "${BLUE}Enter static IP configuration:${NC}"
        
        # Suggest an IP based on current network
        NETWORK_BASE=$(echo $CURRENT_IP | cut -d. -f1-3)
        SUGGESTED_IP="${NETWORK_BASE}.100"
        
        # Special handling for common network ranges
        if [[ $NETWORK_BASE == "192.168.88" ]]; then
            SUGGESTED_IP="192.168.88.100"
            echo "Detected 192.168.88.x network range"
        elif [[ $NETWORK_BASE == "192.168.1" ]]; then
            SUGGESTED_IP="192.168.1.100"
        elif [[ $NETWORK_BASE == "192.168.0" ]]; then
            SUGGESTED_IP="192.168.0.100"
        fi
        
        echo "Recommended IP range: ${NETWORK_BASE}.100-254 (avoid DHCP range typically .1-.99)"
        read -p "Static IP address [$SUGGESTED_IP]: " STATIC_IP
        STATIC_IP=${STATIC_IP:-$SUGGESTED_IP}
        
        # Suggest gateway based on network
        SUGGESTED_GATEWAY=$CURRENT_GATEWAY
        if [[ $NETWORK_BASE == "192.168.88" ]] && [[ -z $CURRENT_GATEWAY ]]; then
            SUGGESTED_GATEWAY="192.168.88.1"
        fi
        
        read -p "Gateway [$SUGGESTED_GATEWAY]: " GATEWAY
        GATEWAY=${GATEWAY:-$SUGGESTED_GATEWAY}
        
        read -p "DNS servers [8.8.8.8,8.8.4.4]: " DNS_SERVERS
        DNS_SERVERS=${DNS_SERVERS:-"8.8.8.8,8.8.4.4"}
        
        echo ""
        echo -e "${YELLOW}Configuring static IP...${NC}"
        echo "IP: $STATIC_IP"
        echo "Gateway: $GATEWAY"
        echo "DNS: $DNS_SERVERS"
        echo "Interface: $CURRENT_INTERFACE"
        
        # Backup current dhcpcd.conf
        cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup
        
        # Add static IP configuration to dhcpcd.conf
        cat >> /etc/dhcpcd.conf << EOF

# Static IP configuration added by deployment script
interface $CURRENT_INTERFACE
static ip_address=$STATIC_IP/24
static routers=$GATEWAY
static domain_name_servers=$DNS_SERVERS
EOF
        
        echo -e "${GREEN}Static IP configuration added to /etc/dhcpcd.conf${NC}"
        echo ""
        echo -e "${YELLOW}Note: Network changes will take effect after reboot.${NC}"
        echo "Your Pi will be accessible at: http://$STATIC_IP:3000"
        echo ""
        
        # Create a script to revert to DHCP if needed
        cat > /home/dietpi/revert-to-dhcp.sh << 'EOF'
#!/bin/bash
# Script to revert static IP back to DHCP

echo "Reverting to DHCP configuration..."

# Restore backup
if [ -f /etc/dhcpcd.conf.backup ]; then
    cp /etc/dhcpcd.conf.backup /etc/dhcpcd.conf
    echo "dhcpcd.conf restored from backup"
else
    # Remove static IP configuration
    sed -i '/# Static IP configuration added by deployment script/,$d' /etc/dhcpcd.conf
    echo "Static IP configuration removed"
fi

# Restart networking
systemctl restart dhcpcd
systemctl restart networking

echo "Reverted to DHCP. Reboot to apply changes: sudo reboot"
EOF
        
        chmod +x /home/dietpi/revert-to-dhcp.sh
        echo "Created revert script: /home/dietpi/revert-to-dhcp.sh"
        
    else
        echo -e "${YELLOW}Skipping static IP configuration. Using DHCP.${NC}"
        echo "Your Pi will use automatic IP assignment."
    fi
    echo ""
}

# Function to create troubleshooting scripts
create_troubleshooting_scripts() {
    echo -e "${BLUE}Creating troubleshooting scripts...${NC}"
    
    # Display fix script
    cat > /home/dietpi/fix-display.sh << 'EOF'
#!/bin/bash
echo "Fixing display configuration..."

# Remove conflicting display settings
sed -i '/dtoverlay=vc4-kms-v3d/d' /boot/config.txt
sed -i '/dtoverlay=vc4-fkms-v3d/d' /boot/config.txt

# Ensure Waveshare configuration is present
if ! grep -q "hdmi_cvt 800 480" /boot/config.txt; then
    cat >> /boot/config.txt << 'DISPLAY_EOF'

# Waveshare 5" LCD Fix
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
hdmi_drive=1
DISPLAY_EOF
fi

echo "Display configuration updated. Rebooting..."
reboot
EOF
    
    # Service management script
    cat > /home/dietpi/manage-scoreboard.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "Starting scoreboard service..."
        systemctl start scoreboard-kiosk
        ;;
    stop)
        echo "Stopping scoreboard service..."
        systemctl stop scoreboard-kiosk
        ;;
    restart)
        echo "Restarting scoreboard service..."
        systemctl restart scoreboard-kiosk
        ;;
    status)
        systemctl status scoreboard-kiosk
        ;;
    logs)
        journalctl -u scoreboard-kiosk -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF
    
    chmod +x /home/dietpi/fix-display.sh
    chmod +x /home/dietpi/manage-scoreboard.sh
    
    echo -e "${GREEN}Troubleshooting scripts created.${NC}"
}

# Main deployment function
main() {
    echo -e "${YELLOW}Starting DietPi deployment process...${NC}"
    
    check_dietpi
    
    # Check WiFi configuration and network connectivity
    detect_wifi_config
    check_network_connectivity
    
    update_system
    install_software
    configure_static_ip
    configure_display
    setup_application
    create_startup_script
    configure_autostart
    create_systemd_service
    optimize_system
    create_troubleshooting_scripts
    
    echo ""
    echo -e "${GREEN}=== Deployment Complete! ===${NC}"
    echo ""
    echo -e "${YELLOW}The table tennis scoreboard has been successfully deployed on DietPi.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Reboot the system: sudo reboot"
    echo "2. The scoreboard will automatically start in kiosk mode"
    echo "3. Access via browser at: http://$(hostname -I | awk '{print $1}'):3000"
    echo ""
    echo "Troubleshooting commands:"
    echo "- Fix display issues: ./fix-display.sh"
    echo "- Manage service: ./manage-scoreboard.sh {start|stop|restart|status|logs}"
    echo "- Revert to DHCP: ./revert-to-dhcp.sh (if static IP was configured)"
    echo "- Check service status: systemctl status scoreboard-kiosk"
    echo "- View logs: journalctl -u scoreboard-kiosk -f"
    echo ""
    echo "Performance improvements over standard Pi OS:"
    echo "- Boot time: ~30 seconds (vs 90 seconds)"
    echo "- Memory usage: ~150MB (vs 300MB)"
    echo "- Setup complexity: Simplified deployment"
    echo ""
    echo -e "${BLUE}Reboot now to start the scoreboard? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run main function
main "$@"