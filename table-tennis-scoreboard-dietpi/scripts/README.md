# DietPi Scripts Directory

This directory contains organized scripts for managing the Table Tennis Scoreboard on DietPi.

## Directory Structure

### 📶 wifi-setup/
Scripts for configuring WiFi on DietPi systems:
- `quick-wifi-setup.sh` - Interactive WiFi configuration script
- `setup-wifi-on-sd.sh` - Configure WiFi directly on SD card
- `setup-wifi-windows.ps1` - Windows PowerShell WiFi setup utility
- `manual-wifi-files.txt` - Manual WiFi configuration instructions

### 🔍 network-diagnostics/
Scripts for troubleshooting network and connectivity issues:
- `diagnose-pi-network.ps1` - Comprehensive network diagnostics
- `find-pi.ps1` - Locate Raspberry Pi on network
- `fix-ssh-issue.ps1` - Resolve common SSH connection problems

### 🏓 scoreboard-management/
Scripts for managing the scoreboard application:
- `manage-scoreboard.sh` - Main scoreboard management utility
- `start-scoreboard.sh` - Start the scoreboard application

## Usage

### WiFi Setup
For initial WiFi configuration, use the scripts in `wifi-setup/`:
```bash
# Interactive setup
./wifi-setup/quick-wifi-setup.sh

# Windows users
./wifi-setup/setup-wifi-windows.ps1
```

### Network Troubleshooting
If you can't connect to your Pi, use the diagnostic scripts:
```powershell
# Find your Pi on the network
./network-diagnostics/find-pi.ps1

# Diagnose network issues
./network-diagnostics/diagnose-pi-network.ps1
```

### Scoreboard Management
Once connected, manage the scoreboard application:
```bash
# Start the scoreboard
./scoreboard-management/start-scoreboard.sh

# Full management interface
./scoreboard-management/manage-scoreboard.sh
```

## Quick Start

1. **Setup WiFi**: Use `wifi-setup/quick-wifi-setup.sh`
2. **Find Pi**: Use `network-diagnostics/find-pi.ps1`
3. **Start Scoreboard**: Use `scoreboard-management/start-scoreboard.sh`

For detailed instructions, see the main [DietPi Deployment Guide](../README.md).