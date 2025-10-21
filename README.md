# Table Tennis Scoreboard

A modern, responsive table tennis scoreboard application designed for tournaments, clubs, and casual play. Features a clean interface, comprehensive match tracking, and specialized support for 7-match league formats.

## 🏓 Features

- **Match Formats**: Support for singles, doubles, and mixed league formats
- **7-Match League System**: Complete tournament structure with cross-singles
- **Real-time Scoring**: Live score updates with game and match tracking
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Fullscreen Mode**: Perfect for dedicated display screens
- **Raspberry Pi Ready**: Optimized for kiosk deployments

## 🚀 Quick Start

### Web Version
Visit [tabletennisscoreboard.com](https://tabletennisscoreboard.com) to use the online version immediately.

### Local Development
```bash
# Clone the repository
git clone https://github.com/nastynorm/table-tennis-scoreboard.git
cd table-tennis-scoreboard

# Install dependencies
npm install

# Start development server
npm run dev
```

The development server will start at `http://localhost:4321` with hot reloading enabled.

## 🔧 Raspberry Pi Folder
- Deployment scripts and docs are now organized under `raspberry-pi/`:
  - `raspberry-pi/README.md` — overview and contents
  - `raspberry-pi/HOWTO-RASPBERRY-PI.md` — complete step-by-step guide
  - `raspberry-pi/README-RASPBERRY-PI.md` — hardware and display notes
  - `raspberry-pi/setup-pi-chromium.sh` — Chromium setup
  - `raspberry-pi/start-scoreboard-chromium.sh` — start in kiosk mode
  - `raspberry-pi/autostart-scoreboard.desktop` — autostart entry

### Production Build
```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## 🖥️ Raspberry Pi 4 Installation Guide

This guide provides detailed instructions for setting up the scoreboard on a Raspberry Pi 4 (4GB) with desktop environment and Chromium fullscreen mode.

### Prerequisites

- **Raspberry Pi 4** (4GB RAM recommended)
- **MicroSD Card** (16GB+ Class 10)
- **Monitor/Display** (HDMI connection)
- **Keyboard and Mouse** (for initial setup)
- **Stable Internet Connection** (WiFi or Ethernet)

### Step 1: Prepare Raspberry Pi OS

1. **Download Raspberry Pi Imager**
   - Download from [rpi.org](https://www.raspberrypi.org/software/)
   - Install on your computer

2. **Flash Raspberry Pi OS**
   - Insert MicroSD card into your computer
   - Open Raspberry Pi Imager
   - Choose "Raspberry Pi OS (64-bit)" with Desktop
   - Select your MicroSD card
   - Click "Write" and wait for completion

3. **Initial Boot Setup**
   - Insert SD card into Raspberry Pi 4
   - Connect monitor, keyboard, and mouse
   - Power on the Pi
   - Follow the setup wizard:
     - Set country, language, and timezone
     - Create user account (default: `pi`)
     - Connect to WiFi
     - Update system when prompted

4. **Enable SSH (Optional but Recommended)**
   ```bash
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

### Step 2: Configure Auto-Login to Desktop

1. **Open Raspberry Pi Configuration**
   ```bash
   sudo raspi-config
   ```

2. **Configure Boot Options**
   - Navigate to "System Options" → "Boot / Auto Login"
   - Select "Desktop Autologin" (Desktop GUI, automatically logged in as 'pi' user)
   - Select "Finish" and reboot when prompted

### Step 3: Install Dependencies

1. **Update System Packages**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Chromium Browser**
   ```bash
   sudo apt install -y chromium-browser
   ```

3. **Install Node.js 20+**
   
   **Option A: Via NodeSource (Recommended)**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt install -y nodejs
   ```
   
   **Option B: Via NVM**
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
   source ~/.bashrc
   nvm install 20
   nvm use 20
   ```

4. **Verify Installation**
   ```bash
   node --version  # Should show v20.x.x
   npm --version   # Should show 10.x.x
   chromium-browser --version  # Should show Chromium version
   ```

### Step 4: Deploy the Scoreboard Application

1. **Download the Application**
   ```bash
   cd ~
   git clone https://github.com/nastynorm/table-tennis-scoreboard.git
   cd table-tennis-scoreboard
   ```

2. **Install Application Dependencies**
   ```bash
   npm ci
   ```

3. **Test the Application**
   ```bash
   npm run preview
   ```
   - Open a browser and navigate to `http://localhost:4321`
   - Verify the scoreboard loads correctly
   - Press `Ctrl+C` to stop the server

### Step 5: Create Desktop Shortcut

1. **Create Desktop Directory (if needed)**
   ```bash
   mkdir -p ~/Desktop
   ```

2. **Create Scoreboard Desktop Shortcut**
   ```bash
   cat > ~/Desktop/table-tennis-scoreboard.desktop << 'EOF'
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=Table Tennis Scoreboard
   Comment=Launch Table Tennis Scoreboard in Fullscreen
   Exec=/bin/bash -c 'cd ~/table-tennis-scoreboard && npm run preview > /dev/null 2>&1 & sleep 3 && chromium-browser --start-fullscreen --no-first-run --disable-session-crashed-bubble --disable-infobars --noerrdialogs --app=http://localhost:4321'
   Icon=applications-games
   Terminal=false
   Categories=Game;Sports;
   StartupNotify=true
   EOF
   ```

3. **Make Desktop Shortcut Executable**
   ```bash
   chmod +x ~/Desktop/table-tennis-scoreboard.desktop
   ```

4. **Test Desktop Shortcut**
   - Double-click the "Table Tennis Scoreboard" icon on desktop
   - The application should start in fullscreen mode
   - Press `F11` to exit fullscreen if needed

### Step 6: Configure Chromium Fullscreen Mode

1. **Create Startup Script**
   ```bash
   cat > ~/start-scoreboard.sh << 'EOF'
   #!/bin/bash
   
   # Configuration
   APP_DIR="$HOME/table-tennis-scoreboard"
   PORT="4321"
   URL="http://localhost:${PORT}"
   
   echo "Starting Table Tennis Scoreboard..."
   
   # Change to app directory
   cd "$APP_DIR" || exit 1
   
   # Start the server in background
   npm run preview > /dev/null 2>&1 &
   SERVER_PID=$!
   
   # Wait for server to be ready
   echo "Waiting for server to start..."
   for i in {1..30}; do
       if curl -s "$URL" > /dev/null 2>&1; then
           echo "Server is ready!"
           break
       fi
       sleep 1
   done
   
   # Launch Chromium in fullscreen
   echo "Launching Chromium in fullscreen mode..."
   chromium-browser \
       --start-fullscreen \
       --no-first-run \
       --disable-session-crashed-bubble \
       --disable-infobars \
       --noerrdialogs \
       --disable-translate \
       --disable-features=TranslateUI \
       --app="$URL"
   
   # Clean up: kill server when Chromium closes
   kill $SERVER_PID 2>/dev/null
   EOF
   ```

2. **Make Script Executable**
   ```bash
   chmod +x ~/start-scoreboard.sh
   ```

### Step 7: Auto-Start on Boot (Optional)

1. **Create Autostart Directory**
   ```bash
   mkdir -p ~/.config/autostart
   ```

2. **Create Autostart Entry**
   ```bash
   cat > ~/.config/autostart/table-tennis-scoreboard.desktop << 'EOF'
   [Desktop Entry]
   Type=Application
   Name=Table Tennis Scoreboard Autostart
   Comment=Automatically start Table Tennis Scoreboard on login
   Exec=/bin/bash /home/pi/start-scoreboard.sh
   Terminal=false
   Categories=Utility;
   X-GNOME-Autostart-enabled=true
   Hidden=false
   NoDisplay=false
   EOF
   ```

3. **Test Autostart**
   ```bash
   sudo reboot
   ```
   - After reboot, the scoreboard should automatically start in fullscreen
   - If it doesn't work, check the script permissions and paths

### Step 8: Chromium Fullscreen Configuration

#### Fullscreen Controls
- **Exit Fullscreen**: Press `F11`
- **Refresh Page**: Press `F5` or `Ctrl+R`
- **Close Application**: Press `Alt+F4`
- **Open Developer Tools**: Press `F12` (for debugging)

#### Advanced Chromium Options
For a more kiosk-like experience, you can modify the Chromium launch command:

```bash
chromium-browser \
    --start-fullscreen \
    --kiosk \
    --no-first-run \
    --disable-session-crashed-bubble \
    --disable-infobars \
    --noerrdialogs \
    --disable-translate \
    --disable-features=TranslateUI \
    --disable-web-security \
    --disable-features=VizDisplayCompositor \
    --app="http://localhost:4321"
```

#### Disable Screen Blanking (Optional)
To prevent the screen from going blank:

```bash
# Disable screen blanking
sudo nano /etc/xdg/lxsession/LXDE-pi/autostart
```

Add these lines:
```
@xset s off
@xset -dpms
@xset s noblank
```

## 🔧 Troubleshooting

### Common Issues

**Server won't start**
```bash
# Check if port is in use
sudo lsof -i :4321

# Kill existing processes
pkill -f "npm run preview"
```

**Chromium won't go fullscreen**
```bash
# Try alternative command
chromium --start-fullscreen --app=http://localhost:4321
```

**Permission denied errors**
```bash
# Fix script permissions
chmod +x ~/start-scoreboard.sh
chmod +x ~/Desktop/table-tennis-scoreboard.desktop
```

**Node.js version issues**
```bash
# Check Node.js version
node --version

# If version is too old, reinstall Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Remote Management

#### SSH Access
```bash
# Connect from another computer
ssh pi@<raspberry-pi-ip-address>

# Start scoreboard remotely
ssh pi@<raspberry-pi-ip-address> 'bash ~/start-scoreboard.sh'
```

#### Remote Updates
```bash
# Update application remotely
ssh pi@<raspberry-pi-ip-address> 'cd ~/table-tennis-scoreboard && git pull && npm ci'
```

## 🎮 Using the Scoreboard

### Match Types
- **Singles**: Individual player matches
- **Doubles**: Team matches (2v2)
- **7-Match League**: Complete tournament format
  - 3 Singles matches (H1 vs V1, H2 vs V2, H3 vs V3)
  - 1 Doubles match (Doubles-H vs Doubles-V)
  - 3 Cross-singles (H1 vs V2, H3 vs V1, H2 vs V3)

### Controls
- **Touch/Click**: Score points for each player
- **Setup**: Configure match settings
- **Help**: View instructions and rules
- **New Match**: Start fresh match

## 🛠️ Development

### Project Structure
```
├── src/
│   ├── components/          # React/Solid components
│   ├── layouts/            # Page layouts
│   ├── pages/              # Application pages
│   └── styles/             # CSS and styling
├── public/                 # Static assets
├── tests/                  # E2E tests
└── scripts/               # Build and deployment scripts
```

### Technologies Used
- **[Astro](https://astro.build/)** - Static site generator
- **[Solid.js](https://www.solidjs.com/)** - Reactive UI framework
- **[Tailwind CSS](https://tailwindcss.com/)** - Utility-first CSS
- **[TypeScript](https://www.typescriptlang.org/)** - Type safety
- **[Playwright](https://playwright.dev/)** - E2E testing

### Running Tests
```bash
# Run end-to-end tests
npm run test:e2e
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/nastynorm/table-tennis-scoreboard/issues)
- **Discussions**: Join conversations on [GitHub Discussions](https://github.com/nastynorm/table-tennis-scoreboard/discussions)
- **Documentation**: Additional guides in the `/docs` folder

---

**Made with ❤️ for the table tennis community**


