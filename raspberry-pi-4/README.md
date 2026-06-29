# Raspberry Pi 4 Deployment

This folder contains all scripts and documentation needed to deploy the Table Tennis Scoreboard on a Raspberry Pi 4.

## Contents
- `HOWTO-RASPBERRY-PI.md` — Complete step-by-step setup guide
- `README-RASPBERRY-PI.md` — Hardware specs, display notes, and features
- `deploy-pi.sh` — Automated setup script (installs dependencies, kiosk mode, services)
- `setup-pi-chromium.sh` — Chromium install and configuration for kiosk mode
- `start-scoreboard-chromium.sh` — Launch Chromium in kiosk mode
- `autostart-scoreboard.desktop` — Desktop autostart entry (backup to systemd service)

## Quick Start
- Read `HOWTO-RASPBERRY-PI.md` first
- Run `deploy-pi.sh` on the Pi
- Verify `kiosk.service` and `scoreboard.service` are running

## Notes
- All paths assume app files under `/home/pi/table-tennis-scoreboard/dist/`
- For dual display setups, see `HOWTO-RASPBERRY-PI.md` display configuration