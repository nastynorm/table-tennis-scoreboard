# Pi Detection Script for 192.168.88.x network
Write-Host "=== Scanning for DietPi on 192.168.88.x network ===" -ForegroundColor Blue
Write-Host ""

$network = "192.168.88"
$startIP = 100
$endIP = 254
$foundDevices = @()

Write-Host "Scanning range: $network.$startIP - $network.$endIP" -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray
Write-Host ""

# Progress tracking
$total = $endIP - $startIP + 1
$current = 0

for ($i = $startIP; $i -le $endIP; $i++) {
    $ip = "$network.$i"
    $current++
    
    # Show progress every 10 IPs
    if ($current % 10 -eq 0) {
        $percent = [math]::Round(($current / $total) * 100)
        Write-Host "Progress: $percent% ($current/$total)" -ForegroundColor Gray
    }
    
    # Quick ping test
    $ping = Test-Connection -ComputerName $ip -Count 1 -TimeoutSeconds 1 -Quiet
    
    if ($ping) {
        Write-Host "✓ Device found at $ip" -ForegroundColor Green
        
        # Try to get hostname
        try {
            $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            Write-Host "  Hostname: $hostname" -ForegroundColor Cyan
            
            # Check if it looks like a Pi
            if ($hostname -match "dietpi|raspberry|pi") {
                Write-Host "  🎯 LIKELY RASPBERRY PI!" -ForegroundColor Green
            }
        } catch {
            Write-Host "  Hostname: Unknown" -ForegroundColor Gray
        }
        
        # Try SSH connection test
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.ReceiveTimeout = 1000
            $tcpClient.SendTimeout = 1000
            $tcpClient.Connect($ip, 22)
            if ($tcpClient.Connected) {
                Write-Host "  SSH: Port 22 OPEN ✓" -ForegroundColor Green
                Write-Host "  Try: ssh dietpi@$ip" -ForegroundColor Yellow
            }
            $tcpClient.Close()
        } catch {
            Write-Host "  SSH: Port 22 closed" -ForegroundColor Red
        }
        
        $foundDevices += $ip
        Write-Host ""
    }
}

Write-Host ""
Write-Host "=== SCAN COMPLETE ===" -ForegroundColor Blue

if ($foundDevices.Count -eq 0) {
    Write-Host "❌ NO DEVICES FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "TROUBLESHOOTING STEPS:" -ForegroundColor Yellow
    Write-Host "1. Verify Pi is powered on (red LED should be solid)" -ForegroundColor White
    Write-Host "2. Wait longer - first boot can take 5-10 minutes" -ForegroundColor White
    Write-Host "3. Check SD card files are in ROOT directory" -ForegroundColor White
    Write-Host "4. Verify Pi Zero W model (has WiFi antenna)" -ForegroundColor White
    Write-Host "5. Check if WiFi is 2.4GHz (Pi Zero W requirement)" -ForegroundColor White
    Write-Host "6. Try different power supply (2.5A recommended)" -ForegroundColor White
    Write-Host ""
    Write-Host "ALTERNATIVE METHODS:" -ForegroundColor Cyan
    Write-Host "• Check router admin panel: http://192.168.88.1" -ForegroundColor White
    Write-Host "• Use Fing app on phone" -ForegroundColor White
    Write-Host "• Try Ethernet cable connection" -ForegroundColor White
} else {
    Write-Host "✅ FOUND $($foundDevices.Count) DEVICE(S)" -ForegroundColor Green
    Write-Host ""
    Write-Host "DEVICES FOUND:" -ForegroundColor Yellow
    foreach ($device in $foundDevices) {
        Write-Host "• $device" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "TO CONNECT:" -ForegroundColor Cyan
    Write-Host "Try SSH to each device:" -ForegroundColor White
    foreach ($device in $foundDevices) {
        Write-Host "ssh dietpi@$device" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Default password: dietpi" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Router admin panel: http://192.168.88.1" -ForegroundColor Cyan