# Fix SSH Issue for DietPi
Write-Host "=== DietPi SSH Fix Tool ===" -ForegroundColor Blue
Write-Host ""

Write-Host "ISSUE DETECTED: Devices found on network but SSH not enabled" -ForegroundColor Yellow
Write-Host ""

# Create proper SSH file
Write-Host "1. CREATING PROPER SSH FILE:" -ForegroundColor Cyan
try {
    # Remove existing ssh file if it exists
    if (Test-Path "ssh") {
        Remove-Item "ssh" -Force
    }
    
    # Create empty ssh file with proper attributes
    New-Item -Path "ssh" -ItemType File -Force | Out-Null
    
    # Ensure it's truly empty (0 bytes)
    Set-Content -Path "ssh" -Value $null -NoNewline
    
    $size = (Get-Item "ssh").Length
    Write-Host "✓ SSH file created (size: $size bytes)" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error creating SSH file: $($_.Exception.Message)" -ForegroundColor Red
}

# Create alternative SSH enable methods
Write-Host ""
Write-Host "2. ALTERNATIVE SSH ENABLE FILES:" -ForegroundColor Cyan

# Method 1: SSH with content
try {
    "# SSH Enable" | Out-File -FilePath "ssh_with_content" -Encoding ASCII -NoNewline
    Write-Host "✓ Created ssh_with_content file" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create ssh_with_content" -ForegroundColor Red
}

# Method 2: SSH.txt
try {
    New-Item -Path "ssh.txt" -ItemType File -Force | Out-Null
    Write-Host "✓ Created ssh.txt file" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create ssh.txt" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. IMPROVED WPA_SUPPLICANT.CONF:" -ForegroundColor Cyan

# Create improved wpa_supplicant with better compatibility
$improvedWpa = @"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="My Wifi"
    psk="Jordash!@#"
    key_mgmt=WPA-PSK
    proto=RSN
    pairwise=CCMP
    auth_alg=OPEN
    scan_ssid=1
    priority=1
}
"@

try {
    $improvedWpa | Out-File -FilePath "wpa_supplicant_improved.conf" -Encoding UTF8 -NoNewline
    Write-Host "✓ Created improved wpa_supplicant_improved.conf" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create improved config" -ForegroundColor Red
}

Write-Host ""
Write-Host "4. FILES TO COPY TO SD CARD:" -ForegroundColor Yellow
Write-Host "Copy ALL of these files to SD card ROOT:" -ForegroundColor White
Write-Host "  • ssh (0 bytes, no extension)" -ForegroundColor Cyan
Write-Host "  • ssh_with_content (backup method)" -ForegroundColor Cyan
Write-Host "  • ssh.txt (another backup method)" -ForegroundColor Cyan
Write-Host "  • wpa_supplicant_improved.conf (rename to wpa_supplicant.conf)" -ForegroundColor Cyan

Write-Host ""
Write-Host "5. STEP-BY-STEP RECOVERY:" -ForegroundColor Yellow
Write-Host ""
Write-Host "STEP 1: Replace files on SD card" -ForegroundColor White
Write-Host "  - Delete old wpa_supplicant.conf and ssh from SD card" -ForegroundColor Gray
Write-Host "  - Copy new wpa_supplicant_improved.conf to SD card" -ForegroundColor Gray
Write-Host "  - Rename it to wpa_supplicant.conf (remove _improved)" -ForegroundColor Gray
Write-Host "  - Copy all 3 SSH files to SD card" -ForegroundColor Gray

Write-Host ""
Write-Host "STEP 2: Boot sequence" -ForegroundColor White
Write-Host "  - Insert SD card into Pi" -ForegroundColor Gray
Write-Host "  - Power on Pi" -ForegroundColor Gray
Write-Host "  - Wait 5-10 minutes (first boot is slow)" -ForegroundColor Gray
Write-Host "  - Look for solid red LED (power) and blinking green LED (activity)" -ForegroundColor Gray

Write-Host ""
Write-Host "STEP 3: Find Pi IP" -ForegroundColor White
Write-Host "  - Check router admin: http://192.168.88.1" -ForegroundColor Gray
Write-Host "  - Look for new device in DHCP clients" -ForegroundColor Gray
Write-Host "  - Try the IPs we found: 192.168.88.124, 192.168.88.125, 192.168.88.188, etc." -ForegroundColor Gray

Write-Host ""
Write-Host "STEP 4: Test SSH connection" -ForegroundColor White
Write-Host "  ssh dietpi@192.168.88.124" -ForegroundColor Yellow
Write-Host "  ssh dietpi@192.168.88.125" -ForegroundColor Yellow
Write-Host "  ssh dietpi@192.168.88.188" -ForegroundColor Yellow
Write-Host "  Default password: dietpi" -ForegroundColor Gray

Write-Host ""
Write-Host "6. IF STILL NOT WORKING:" -ForegroundColor Red
Write-Host ""
Write-Host "HARDWARE CHECKS:" -ForegroundColor Cyan
Write-Host "□ Verify Pi Zero W (not regular Pi Zero)" -ForegroundColor White
Write-Host "□ Check power supply (2.5A minimum)" -ForegroundColor White
Write-Host "□ Try different SD card" -ForegroundColor White
Write-Host "□ Ensure WiFi is 2.4GHz (not 5GHz)" -ForegroundColor White

Write-Host ""
Write-Host "ALTERNATIVE METHODS:" -ForegroundColor Cyan
Write-Host "□ Use Ethernet cable temporarily" -ForegroundColor White
Write-Host "□ Try different WiFi network (phone hotspot)" -ForegroundColor White
Write-Host "□ Flash DietPi image again" -ForegroundColor White
Write-Host "□ Check DietPi documentation for your specific router" -ForegroundColor White

Write-Host ""
Write-Host "=== FILES READY FOR SD CARD ===" -ForegroundColor Blue