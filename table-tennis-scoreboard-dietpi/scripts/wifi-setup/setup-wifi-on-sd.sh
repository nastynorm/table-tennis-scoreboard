#!/bin/bash

# WiFi Pre-Configuration Script for DietPi SD Card
# This script configures WiFi settings on the SD card before first boot
# Run this on your computer with the SD card mounted

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="1.0.0"

echo -e "${BLUE}DietPi WiFi Pre-Configuration Script v${SCRIPT_VERSION}${NC}"
echo "=============================================="
echo ""

# Function to find SD card mount point
find_sd_card() {
    echo -e "${YELLOW}Looking for DietPi SD card...${NC}"
    
    # Common mount points for different systems
    local possible_mounts=(
        "/media"
        "/mnt"
        "/Volumes"  # macOS
        "/run/media"
    )
    
    for mount_base in "${possible_mounts[@]}"; do
        if [ -d "$mount_base" ]; then
            for mount_point in "$mount_base"/*; do
                if [ -d "$mount_point" ] && [ -f "$mount_point/dietpi.txt" ]; then
                    echo -e "${GREEN}Found DietPi SD card at: $mount_point${NC}"
                    SD_MOUNT="$mount_point"
                    return 0
                fi
            done
        fi
    done
    
    return 1
}

# Function to get WiFi credentials
get_wifi_credentials() {
    echo -e "${YELLOW}Enter your WiFi credentials:${NC}"
    echo ""
    
    read -p "WiFi Network Name (SSID): " WIFI_SSID
    read -s -p "WiFi Password: " WIFI_PASSWORD
    echo ""
    
    # Validate inputs
    if [ -z "$WIFI_SSID" ]; then
        echo -e "${RED}Error: WiFi SSID cannot be empty${NC}"
        exit 1
    fi
    
    if [ -z "$WIFI_PASSWORD" ]; then
        echo -e "${RED}Error: WiFi password cannot be empty${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}WiFi credentials entered successfully${NC}"
}

# Function to configure WiFi
configure_wifi() {
    local wpa_file="$SD_MOUNT/wpa_supplicant.conf"
    local dietpi_wifi_file="$SD_MOUNT/dietpi-wifi.txt"
    
    echo -e "${YELLOW}Configuring WiFi settings...${NC}"
    
    # Create wpa_supplicant.conf for immediate WiFi connection
    cat > "$wpa_file" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
    
    # Also configure DietPi's WiFi settings
    cat > "$dietpi_wifi_file" << EOF
# DietPi WiFi Configuration
# This file will be processed by DietPi on first boot

aWIFI_SSID[0]='$WIFI_SSID'
aWIFI_KEY[0]='$WIFI_PASSWORD'
aWIFI_KEYMGR[0]='WPA-PSK'
aWIFI_PROTO[0]='RSN'
aWIFI_PAIRWISE[0]='CCMP'
aWIFI_AUTH_ALG[0]='OPEN'
aWIFI_EAPMETHOD[0]=''
aWIFI_IDENTITY[0]=''
aWIFI_PASSWORD[0]=''
aWIFI_CERT[0]=''
aWIFI_CA_CERT[0]=''
aWIFI_PRIVATE_KEY[0]=''
aWIFI_PRIVATE_KEY_PASSWD[0]=''
aWIFI_PHASE1[0]=''
aWIFI_PHASE2[0]=''

# Enable WiFi by default
AUTO_SETUP_NET_WIFI_ENABLED=1
AUTO_SETUP_NET_WIFI_COUNTRY_CODE=US
EOF
    
    echo -e "${GREEN}WiFi configuration files created:${NC}"
    echo "  - $wpa_file"
    echo "  - $dietpi_wifi_file"
}

# Function to enable SSH
enable_ssh() {
    echo -e "${YELLOW}Enabling SSH for remote access...${NC}"
    
    # Create SSH enable file
    touch "$SD_MOUNT/ssh"
    
    # Configure DietPi to enable SSH
    local dietpi_txt="$SD_MOUNT/dietpi.txt"
    if [ -f "$dietpi_txt" ]; then
        # Enable SSH in dietpi.txt
        sed -i 's/AUTO_SETUP_SSH_SERVER_INDEX=.*/AUTO_SETUP_SSH_SERVER_INDEX=2/' "$dietpi_txt" 2>/dev/null || true
        sed -i 's/AUTO_SETUP_SSH_PUBKEY=.*/AUTO_SETUP_SSH_PUBKEY=""/' "$dietpi_txt" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}SSH enabled${NC}"
}

# Function to configure static IP (optional)
configure_static_ip() {
    echo ""
    read -p "Do you want to configure a static IP? (y/n): " configure_static
    
    if [[ $configure_static =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Static IP Configuration:${NC}"
        read -p "Static IP address [192.168.88.100]: " static_ip
        read -p "Gateway [192.168.88.1]: " gateway
        read -p "DNS servers [8.8.8.8,8.8.4.4]: " dns_servers
        
        # Set defaults
        static_ip=${static_ip:-192.168.88.100}
        gateway=${gateway:-192.168.88.1}
        dns_servers=${dns_servers:-8.8.8.8,8.8.4.4}
        
        # Create dhcpcd configuration
        local dhcpcd_file="$SD_MOUNT/dietpi-dhcpcd.conf"
        cat > "$dhcpcd_file" << EOF
# Static IP configuration for DietPi
# This will be applied on first boot

interface wlan0
static ip_address=$static_ip/24
static routers=$gateway
static domain_name_servers=$dns_servers
EOF
        
        echo -e "${GREEN}Static IP configuration created: $dhcpcd_file${NC}"
        echo "  IP: $static_ip"
        echo "  Gateway: $gateway"
        echo "  DNS: $dns_servers"
    fi
}

# Function to create connection info file
create_connection_info() {
    local info_file="$SD_MOUNT/WIFI-CONNECTION-INFO.txt"
    
    cat > "$info_file" << EOF
DietPi WiFi Connection Information
==================================

WiFi Network: $WIFI_SSID
Configuration Date: $(date)

After inserting this SD card into your Raspberry Pi:

1. The Pi should automatically connect to your WiFi network
2. You can find the Pi's IP address by:
   - Checking your router's admin panel (usually 192.168.88.1)
   - Using a network scanner app on your phone
   - Looking for "DietPi" or "raspberrypi" in connected devices

3. Once you have the IP address, you can SSH into the Pi:
   ssh dietpi@[IP_ADDRESS]
   Default password: dietpi

4. After SSH connection, you can run the scoreboard deployment:
   cd /tmp
   wget https://raw.githubusercontent.com/[your-repo]/deploy-dietpi.sh
   chmod +x deploy-dietpi.sh
   sudo ./deploy-dietpi.sh

Network Information:
- Expected IP range: 192.168.88.x
- Router/Gateway: 192.168.88.1
- Default credentials: dietpi/dietpi

Troubleshooting:
- If WiFi doesn't connect, check the SSID and password
- Make sure your router supports 2.4GHz (Pi Zero W requirement)
- Check router logs for connection attempts
EOF
    
    echo -e "${GREEN}Connection info saved: $info_file${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}This script will configure WiFi settings on your DietPi SD card${NC}"
    echo -e "${BLUE}so your Pi can connect to the network on first boot.${NC}"
    echo ""
    
    # Find SD card
    if ! find_sd_card; then
        echo -e "${RED}Error: Could not find DietPi SD card${NC}"
        echo "Please ensure:"
        echo "1. SD card is inserted and mounted"
        echo "2. SD card contains DietPi (dietpi.txt file should exist)"
        exit 1
    fi
    
    # Get WiFi credentials
    get_wifi_credentials
    
    # Configure WiFi
    configure_wifi
    
    # Enable SSH
    enable_ssh
    
    # Optional static IP
    configure_static_ip
    
    # Create info file
    create_connection_info
    
    echo ""
    echo -e "${GREEN}✓ WiFi pre-configuration complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Safely eject the SD card"
    echo "2. Insert it into your Raspberry Pi"
    echo "3. Power on the Pi"
    echo "4. Wait 2-3 minutes for first boot"
    echo "5. Check your router for the Pi's IP address"
    echo "6. SSH into the Pi: ssh dietpi@[IP_ADDRESS]"
    echo ""
    echo -e "${BLUE}The Pi should automatically connect to your WiFi network!${NC}"
}

# Run main function
main "$@"