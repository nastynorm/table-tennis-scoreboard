# Raspberry Pi 4B 4GB Deployment

This folder contains all scripts and documentation needed to deploy the Table Tennis Scoreboard on a Raspberry Pi 4B 4GB using the desktop version of Raspberry Pi OS.

## Contents
- `HOWTO-RASPBERRY-PI.md` — Complete step-by-step setup guide for Pi 4B 4GB
- `README-RASPBERRY-PI.md` — Hardware specs, display notes, and features
- `deploy.sh` — Automated setup script (installs dependencies)
- `setup-pi-chromium.sh` — Chromium install and configuration
- `start-scoreboard-chromium.sh` — Launch Chromium in fullscreen mode
- `autostart-scoreboard.desktop` — Desktop autostart entry for automatic boot startup

## Key Features for Pi 4B
- **Desktop Shortcut**: Easy-to-use desktop icon for launching the scoreboard
- **Optimized Performance**: Configured specifically for Pi 4B 4GB hardware
- **User-Friendly**: No kiosk mode - full desktop environment available
- **Auto-start Option**: Optional automatic startup on boot
- **Performance Tuning**: GPU memory optimization and service management

## Quick Start
1. Read `HOWTO-RASPBERRY-PI.md` for complete setup instructions
2. Follow the step-by-step guide to install dependencies and create desktop shortcut
3. Double-click the desktop icon to launch the scoreboard
4. Optionally enable auto-start for automatic launch on boot

## Hardware Requirements
- Raspberry Pi 4B with 4GB RAM (recommended)
- MicroSD card (32GB or larger, Class 10 recommended)
- Monitor with HDMI connection
- Keyboard and mouse for initial setup
- Reliable power supply (official Pi 4B adapter recommended)

## Notes
- All paths assume app files under `/home/pi/table-tennis-scoreboard/`
- Desktop shortcut provides easy access for non-technical users
- Performance optimizations included for smooth operation on Pi 4B hardware
- Full desktop environment allows for easy troubleshooting and maintenance