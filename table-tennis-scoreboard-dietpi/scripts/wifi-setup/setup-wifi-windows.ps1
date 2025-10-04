# WiFi Setup Script for DietPi (Windows PowerShell)
Write-Host "=== DietPi WiFi Setup for Windows ===" -ForegroundColor Blue
Write-Host ""

# Get WiFi credentials
$wifiSSID = Read-Host "Enter your WiFi network name (SSID)"
$wifiPassword = Read-Host "Enter your WiFi password"

# Validate inputs
if ([string]::IsNullOrEmpty($wifiSSID) -or [string]::IsNullOrEmpty($wifiPassword)) {
    Write-Host "Error: Both WiFi name and password are required" -ForegroundColor Red
    exit 1
}

# Create wpa_supplicant.conf content
$wpaContent = @"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$wifiSSID"
    psk="$wifiPassword"
    key_mgmt=WPA-PSK
}
"@

# Create the files
$wpaContent | Out-File -FilePath "wpa_supplicant.conf" -Encoding UTF8
New-Item -Path "ssh" -ItemType File -Force | Out-Null

# Create info file
$info = @"
WiFi Setup Complete!
===================

Network: $wifiSSID
Created: $(Get-Date)

Files created:
- wpa_supplicant.conf
- ssh

COPY THESE FILES TO SD CARD ROOT!

Next steps:
1. Copy both files to SD card root
2. Insert SD card into Pi
3. Power on and wait 3-5 minutes
4. Check router at 192.168.88.1 for Pi IP
5. SSH: ssh dietpi@[IP_ADDRESS]
"@

$info | Out-File -FilePath "WIFI-SETUP-COMPLETE.txt" -Encoding UTF8

Write-Host "✓ Files created successfully!" -ForegroundColor Green
Write-Host "Network: $wifiSSID" -ForegroundColor Yellow
Write-Host ""
Write-Host "COPY wpa_supplicant.conf and ssh to your SD card ROOT!" -ForegroundColor Cyan