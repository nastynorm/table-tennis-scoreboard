# DietPi Network Diagnostic Script
# This script helps diagnose why your Pi isn't appearing on the network

Write-Host "=== DietPi Network Diagnostic Tool ===" -ForegroundColor Blue
Write-Host ""

# Check if files exist
Write-Host "1. CHECKING CONFIGURATION FILES:" -ForegroundColor Yellow
$wpaFile = "wpa_supplicant.conf"
$sshFile = "ssh"

if (Test-Path $wpaFile) {
    Write-Host "✓ wpa_supplicant.conf found" -ForegroundColor Green
    $content = Get-Content $wpaFile -Raw
    Write-Host "File size: $($content.Length) bytes" -ForegroundColor White
    
    # Check for common issues
    if ($content -match 'ssid="([^"]*)"') {
        $ssid = $matches[1]
        Write-Host "✓ SSID found: $ssid" -ForegroundColor Green
    } else {
        Write-Host "✗ No SSID found in file!" -ForegroundColor Red
    }
    
    if ($content -match 'psk="([^"]*)"') {
        $psk = $matches[1]
        Write-Host "✓ Password found (length: $($psk.Length))" -ForegroundColor Green
    } else {
        Write-Host "✗ No password found in file!" -ForegroundColor Red
    }
    
    if ($content -match 'country=') {
        Write-Host "✓ Country code set" -ForegroundColor Green
    } else {
        Write-Host "⚠ No country code - may cause issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ wpa_supplicant.conf NOT FOUND!" -ForegroundColor Red
}

if (Test-Path $sshFile) {
    $size = (Get-Item $sshFile).Length
    Write-Host "✓ ssh file found (size: $size bytes)" -ForegroundColor Green
} else {
    Write-Host "✗ ssh file NOT FOUND!" -ForegroundColor Red
}

Write-Host ""

# Network diagnostics
Write-Host "2. NETWORK DIAGNOSTICS:" -ForegroundColor Yellow

# Get network info
$networkInfo = Get-NetIPConfiguration | Where-Object {$_.NetAdapter.Status -eq "Up"}
foreach ($net in $networkInfo) {
    $adapter = $net.NetAdapter.Name
    $ip = $net.IPv4Address.IPAddress
    $gateway = $net.IPv4DefaultGateway.NextHop
    
    Write-Host "Network Adapter: $adapter" -ForegroundColor White
    Write-Host "Your PC IP: $ip" -ForegroundColor White
    Write-Host "Gateway/Router: $gateway" -ForegroundColor White
    
    # Determine network range
    if ($ip -match '^192\.168\.88\.') {
        Write-Host "✓ You're on 192.168.88.x network - matches Pi config" -ForegroundColor Green
        $piRange = "192.168.88.100-254"
    } elseif ($ip -match '^192\.168\.1\.') {
        Write-Host "⚠ You're on 192.168.1.x network - Pi configured for 192.168.88.x" -ForegroundColor Yellow
        $piRange = "192.168.1.100-254"
    } elseif ($ip -match '^192\.168\.0\.') {
        Write-Host "⚠ You're on 192.168.0.x network - Pi configured for 192.168.88.x" -ForegroundColor Yellow
        $piRange = "192.168.0.100-254"
    } else {
        Write-Host "⚠ Unusual network range: $ip" -ForegroundColor Yellow
        $piRange = "Unknown"
    }
    
    Write-Host "Expected Pi IP range: $piRange" -ForegroundColor Cyan
    Write-Host ""
}

# Test router connectivity
Write-Host "3. ROUTER CONNECTIVITY TEST:" -ForegroundColor Yellow
$routerIPs = @("192.168.88.1", "192.168.1.1", "192.168.0.1")

foreach ($routerIP in $routerIPs) {
    $ping = Test-Connection -ComputerName $routerIP -Count 1 -Quiet
    if ($ping) {
        Write-Host "✓ Router found at $routerIP" -ForegroundColor Green
        Write-Host "  → Open http://$routerIP in browser to check connected devices" -ForegroundColor Cyan
    } else {
        Write-Host "✗ No router at $routerIP" -ForegroundColor Red
    }
}

Write-Host ""

# WiFi diagnostics
Write-Host "4. WIFI DIAGNOSTICS:" -ForegroundColor Yellow

# Get WiFi networks
try {
    $wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ":")[1].Trim()
    }
    
    Write-Host "Available WiFi networks on your PC:" -ForegroundColor White
    foreach ($profile in $wifiProfiles) {
        Write-Host "  - $profile" -ForegroundColor Gray
        
        # Check if this matches Pi config
        if (Test-Path $wpaFile) {
            $wpaContent = Get-Content $wpaFile -Raw
            if ($wpaContent -match "ssid=`"$([regex]::Escape($profile))`"") {
                Write-Host "    ✓ MATCHES Pi configuration!" -ForegroundColor Green
            }
        }
    }
} catch {
    Write-Host "Could not retrieve WiFi information" -ForegroundColor Yellow
}

Write-Host ""

# Recommendations
Write-Host "5. TROUBLESHOOTING RECOMMENDATIONS:" -ForegroundColor Yellow

Write-Host ""
Write-Host "IMMEDIATE CHECKS:" -ForegroundColor Cyan
Write-Host "□ Verify files are in SD card ROOT (not in folders)" -ForegroundColor White
Write-Host "□ Ensure Pi Zero W (not regular Pi Zero - no WiFi)" -ForegroundColor White
Write-Host "□ Check WiFi is 2.4GHz (Pi Zero W doesn't support 5GHz)" -ForegroundColor White
Write-Host "□ Wait 5+ minutes after power on (first boot is slow)" -ForegroundColor White
Write-Host "□ Look for red LED (power) and green LED activity" -ForegroundColor White

Write-Host ""
Write-Host "NETWORK MISMATCH FIXES:" -ForegroundColor Cyan
if ($networkInfo[0].IPv4Address.IPAddress -notmatch '^192\.168\.88\.') {
    Write-Host "⚠ NETWORK MISMATCH DETECTED!" -ForegroundColor Red
    Write-Host "Your PC is NOT on 192.168.88.x network" -ForegroundColor Red
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  1. Change router to use 192.168.88.x range" -ForegroundColor White
    Write-Host "  2. Recreate wpa_supplicant.conf for your network" -ForegroundColor White
    Write-Host "  3. Use Ethernet cable temporarily" -ForegroundColor White
}

Write-Host ""
Write-Host "ALTERNATIVE DETECTION METHODS:" -ForegroundColor Cyan
Write-Host "□ Download 'Fing' app on phone and scan network" -ForegroundColor White
Write-Host "□ Check router admin panel for new devices" -ForegroundColor White
Write-Host "□ Try: ping 192.168.88.100 through ping 192.168.88.254" -ForegroundColor White
Write-Host "□ Use 'Advanced IP Scanner' software" -ForegroundColor White

Write-Host ""
Write-Host "HARDWARE VERIFICATION:" -ForegroundColor Cyan
Write-Host "□ Try different SD card" -ForegroundColor White
Write-Host "□ Verify Pi Zero W model (should have WiFi antenna)" -ForegroundColor White
Write-Host "□ Test with Ethernet cable if available" -ForegroundColor White
Write-Host "□ Try different power supply (2.5A recommended)" -ForegroundColor White

Write-Host ""
Write-Host "=== DIAGNOSTIC COMPLETE ===" -ForegroundColor Blue