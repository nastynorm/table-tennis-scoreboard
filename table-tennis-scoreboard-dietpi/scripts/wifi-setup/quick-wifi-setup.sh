#!/bin/bash

# Quick WiFi Setup for DietPi SD Card
# Simple script to create WiFi configuration files

echo "=== DietPi WiFi Quick Setup ==="
echo ""

# Get WiFi credentials
read -p "Enter your WiFi network name (SSID): " wifi_ssid
read -s -p "Enter your WiFi password: " wifi_password
echo ""

# Validate inputs
if [ -z "$wifi_ssid" ] || [ -z "$wifi_password" ]; then
    echo "Error: Both WiFi name and password are required"
    exit 1
fi

# Create wpa_supplicant.conf
cat > wpa_supplicant.conf << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$wifi_ssid"
    psk="$wifi_password"
    key_mgmt=WPA-PSK
}
EOF

# Create SSH enable file
touch ssh

# Create connection info
cat > WIFI-SETUP-COMPLETE.txt << EOF
WiFi Configuration Created
=========================

Network: $wifi_ssid
Created: $(date)

Files created:
- wpa_supplicant.conf (WiFi configuration)
- ssh (enables SSH access)

Instructions:
1. Copy these files to the root of your DietPi SD card
2. Insert SD card into Raspberry Pi
3. Power on the Pi
4. Wait 2-3 minutes for boot and WiFi connection
5. Check your router (192.168.88.1) for the Pi's IP address
6. SSH into Pi: ssh dietpi@[IP_ADDRESS]
   Default password: dietpi

Your Pi should automatically connect to: $wifi_ssid
EOF

echo ""
echo "✓ WiFi configuration files created!"
echo ""
echo "Files created in current directory:"
echo "  - wpa_supplicant.conf"
echo "  - ssh"
echo "  - WIFI-SETUP-COMPLETE.txt"
echo ""
echo "Next steps:"
echo "1. Copy these files to the root of your DietPi SD card"
echo "2. Insert SD card into your Raspberry Pi"
echo "3. Power on the Pi"
echo ""
echo "The Pi should connect to your WiFi automatically!"